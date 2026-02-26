from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import models, schemas, auth, database
from datetime import timedelta, datetime
import os
import secrets
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv
from pathlib import Path

# Load .env from project root
load_dotenv(dotenv_path=Path(__file__).resolve().parents[2] / ".env")

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

# In-memory OTP store: { email: { otp, expires_at, name, google_id } }
_otp_store: dict = {}
_fp_otp_store: dict = {}
_mobile_otp_store: dict = {}

# ─── Email config from environment ───────────────────────────────────────────
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")        # your Gmail address
SMTP_PASS = os.getenv("SMTP_PASS", "")        # your Gmail App Password

def _send_otp_email(to_email: str, otp: str, name: str):
    """Send OTP via Gmail SMTP."""
    msg = MIMEMultipart("alternative")
    msg["Subject"] = "Smart City – Your Login Code"
    msg["From"] = SMTP_USER
    msg["To"] = to_email

    html = f"""
    <div style="font-family:sans-serif;max-width:480px;margin:auto;padding:32px;
                background:#0A1D37;border-radius:16px;color:#fff;">
      <h2 style="color:#4FC3F7;">Smart City 🏙️</h2>
      <p>Hi <b>{name}</b>,</p>
      <p>Your one-time login code is:</p>
      <div style="font-size:40px;font-weight:bold;letter-spacing:12px;
                  color:#4FC3F7;text-align:center;padding:16px 0;">{otp}</div>
      <p style="color:#90CAF9;">This code expires in <b>10 minutes</b>.</p>
      <p style="color:#78909C;font-size:12px;">
        If you did not request this, please ignore this email.
      </p>
    </div>
    """
    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_USER, SMTP_PASS)
        server.sendmail(SMTP_USER, to_email, msg.as_string())

# ─── Smart Initiate: decide what to do based on existing user ────────────────
@router.post("/google/initiate")
def google_initiate(data: schemas.GoogleInitiateRequest, db: Session = Depends(database.get_db)):
    """
    Called right after Google Sign-In.
    Returns one of three actions:
      - "direct_login" + token  → user exists with one role, log them in
      - "choose_role"           → email known (OTP already verified before), just pick role
      - "otp_required"          → new email, OTP needed
    """
    # Find all accounts with this email
    existing_users = db.query(models.User).filter(
        models.User.email == data.email
    ).all()

    if existing_users:
        if len(existing_users) == 1:
            # ✅ Exactly one account → direct login
            user = existing_users[0]
            access_token = auth.create_access_token(
                data={"sub": user.email},
                expires_delta=timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
            )
            return {
                "action": "direct_login",
                "token": access_token,
                "role": user.role,
                "contractor_type": user.contractor_type,
            }
        else:
            # Multiple roles for this email → let them choose
            roles = [{"role": u.role, "contractor_type": u.contractor_type} for u in existing_users]
            return {"action": "choose_role", "existing_roles": roles}
    else:
        # Brand new email → send OTP
        if not SMTP_USER or not SMTP_PASS:
            raise HTTPException(
                status_code=500,
                detail="Email service not configured. Set SMTP_USER and SMTP_PASS in .env"
            )
        otp = str(secrets.randbelow(900000) + 100000)
        _otp_store[data.email] = {
            "otp": otp,
            "name": data.name,
            "google_id": data.google_id,
            "expires_at": datetime.utcnow() + timedelta(minutes=10),
        }
        try:
            _send_otp_email(data.email, otp, data.name)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")
        return {"action": "otp_required"}

# ─── Select role (no OTP needed, email already trusted) ──────────────────────
@router.post("/google/select-role")
def google_select_role(data: schemas.GoogleSelectRoleRequest, db: Session = Depends(database.get_db)):
    """
    Used when email already exists and user picks a role.
    Finds contractor_type from DB automatically — no need to ask user.
    """
    # Find by email + role only (contractor_type auto-resolved from DB)
    user = db.query(models.User).filter(
        models.User.email == data.email,
        models.User.role == data.role,
    ).first()

    if not user:
        # First time using this role — create account (email already verified)
        dummy_password = secrets.token_urlsafe(16)
        user = models.User(
            email=data.email,
            username=data.name,
            password_hash=auth.get_password_hash(dummy_password),
            role=data.role,
            contractor_type=data.contractor_type
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = auth.create_access_token(
        data={"sub": user.email},
        expires_delta=timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "contractor_type": user.contractor_type,
    }

# ─── Separate OTP store for forgot-password to avoid conflicts ────────────────
_fp_otp_store: dict = {}

# ─── Step 1: Send OTP to email for password reset ────────────────────────────
@router.post("/forgot-password/send-otp")
def forgot_password_send_otp(data: schemas.ForgotPasswordRequest, db: Session = Depends(database.get_db)):
    # Make sure this email is registered
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="No account found with this email")

    if not SMTP_USER or not SMTP_PASS:
        raise HTTPException(status_code=500, detail="Email service not configured")

    otp = str(secrets.randbelow(900000) + 100000)
    _fp_otp_store[data.email] = {
        "otp": otp,
        "name": user.username or "User",
        "expires_at": datetime.utcnow() + timedelta(minutes=10),
    }

    html = f"""
    <div style="font-family:sans-serif;max-width:480px;margin:auto;padding:32px;
                background:#0A1D37;border-radius:16px;color:#fff;">
      <h2 style="color:#EF5350;">Smart City 🏙️ — Password Reset</h2>
      <p>Hi <b>{user.username or 'User'}</b>,</p>
      <p>Your password reset code is:</p>
      <div style="font-size:40px;font-weight:bold;letter-spacing:12px;
                  color:#EF5350;text-align:center;padding:16px 0;">{otp}</div>
      <p style="color:#90CAF9;">Expires in <b>10 minutes</b>.</p>
      <p style="color:#78909C;font-size:12px;">If you did not request this, ignore this email.</p>
    </div>"""

    try:
        msg = __import__('email.mime.multipart', fromlist=['MIMEMultipart']).MIMEMultipart("alternative")
        msg["Subject"] = "Smart City – Password Reset Code"
        msg["From"] = SMTP_USER
        msg["To"] = data.email
        msg.attach(__import__('email.mime.text', fromlist=['MIMEText']).MIMEText(html, "html"))
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASS)
            server.sendmail(SMTP_USER, data.email, msg.as_string())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

    return {"message": f"OTP sent to {data.email}"}

# ─── Step 2a: Verify OTP → log in directly (Continue) ────────────────────────
@router.post("/forgot-password/verify-otp")
def forgot_password_verify_otp(data: schemas.ForgotPasswordVerifyOtp, db: Session = Depends(database.get_db)):
    record = _fp_otp_store.get(data.email)
    if not record:
        raise HTTPException(status_code=400, detail="No OTP found. Request a new one.")
    if datetime.utcnow() > record["expires_at"]:
        del _fp_otp_store[data.email]
        raise HTTPException(status_code=400, detail="OTP has expired. Request a new one.")
    if record["otp"] != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP.")

    # Find the user to build a token for
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    access_token = auth.create_access_token(
        data={"sub": user.email},
        expires_delta=timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {
        "valid": True,
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
    }

# ─── Step 2b: Reset password → update DB ──────────────────────────────────────
@router.post("/forgot-password/reset-password")
def forgot_password_reset(data: schemas.ForgotPasswordReset, db: Session = Depends(database.get_db)):
    record = _fp_otp_store.get(data.email)
    if not record:
        raise HTTPException(status_code=400, detail="No OTP found or already used.")
    if datetime.utcnow() > record["expires_at"]:
        del _fp_otp_store[data.email]
        raise HTTPException(status_code=400, detail="OTP has expired.")
    if record["otp"] != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP.")

    # Update ALL accounts with this email (same password across roles)
    users = db.query(models.User).filter(models.User.email == data.email).all()
    if not users:
        raise HTTPException(status_code=404, detail="User not found.")

    new_hash = auth.get_password_hash(data.new_password)
    for u in users:
        u.password_hash = new_hash
    db.commit()

    # OTP used — remove it
    del _fp_otp_store[data.email]

    # Return a token for the first/primary account
    access_token = auth.create_access_token(
        data={"sub": users[0].email},
        expires_delta=timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {
        "message": "Password updated successfully.",
        "access_token": access_token,
        "token_type": "bearer",
        "role": users[0].role,
    }

@router.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(
        models.User.email == user.email,
        models.User.role == user.role,
        models.User.contractor_type == user.contractor_type
    ).first()
    
    if db_user:
        raise HTTPException(status_code=400, detail="User already registered with this role")
    
    hashed_password = auth.get_password_hash(user.password)
    new_user = models.User(
        email=user.email,
        username=user.username,
        password_hash=hashed_password,
        role=user.role,
        contractor_type=user.contractor_type
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login", response_model=schemas.Token)
def login(user_credentials: schemas.UserLogin, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(
        models.User.email == user_credentials.email,
        models.User.role == user_credentials.role,
        models.User.contractor_type == user_credentials.contractor_type
    ).first()
    
    if not user:
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    if not auth.verify_password(user_credentials.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# ─── Step 1: Google Sign-In done → send OTP to email ─────────────────────────
@router.post("/google/send-otp")
def google_send_otp(data: schemas.GoogleOtpRequest):
    if not SMTP_USER or not SMTP_PASS:
        raise HTTPException(
            status_code=500,
            detail="Email service not configured. Set SMTP_USER and SMTP_PASS in .env"
        )

    otp = str(secrets.randbelow(900000) + 100000)  # 6-digit OTP
    _otp_store[data.email] = {
        "otp": otp,
        "name": data.name,
        "google_id": data.google_id,
        "expires_at": datetime.utcnow() + timedelta(minutes=10),
    }

    try:
        _send_otp_email(data.email, otp, data.name)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

    return {"message": f"OTP sent to {data.email}"}

# ─── Step 2: Verify OTP + role → return JWT ───────────────────────────────────
@router.post("/google/verify-otp", response_model=schemas.Token)
def google_verify_otp(data: schemas.GoogleOtpVerify, db: Session = Depends(database.get_db)):
    record = _otp_store.get(data.email)

    if not record:
        raise HTTPException(status_code=400, detail="No OTP found. Please request a new one.")

    if datetime.utcnow() > record["expires_at"]:
        del _otp_store[data.email]
        raise HTTPException(status_code=400, detail="OTP has expired. Please try again.")

    if record["otp"] != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP.")

    # OTP valid — remove it
    del _otp_store[data.email]

    # Find or create user
    user = db.query(models.User).filter(
        models.User.email == data.email,
        models.User.role == data.role,
        models.User.contractor_type == data.contractor_type
    ).first()

    if not user:
        dummy_password = secrets.token_urlsafe(16)
        hashed_password = auth.get_password_hash(dummy_password)
        user = models.User(
            email=data.email,
            username=data.name,
            password_hash=hashed_password,
            role=data.role,
            contractor_type=data.contractor_type
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# ─── Legacy single-step Google endpoint (kept for compatibility) ──────────────
@router.post("/google", response_model=schemas.Token)
def google_login(google_data: schemas.UserGoogleLogin, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(
        models.User.email == google_data.email,
        models.User.role == google_data.role,
        models.User.contractor_type == google_data.contractor_type
    ).first()

    if not user:
        dummy_password = secrets.token_urlsafe(16)
        hashed_password = auth.get_password_hash(dummy_password)
        user = models.User(
            email=google_data.email,
            username=google_data.name,
            password_hash=hashed_password,
            role=google_data.role,
            contractor_type=google_data.contractor_type
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# ─── Get Current User Profile ────────────────────────────────────────────────
@router.get("/me", response_model=schemas.UserResponse)
def get_user_profile(current_user: models.User = Depends(auth.get_current_user)):
    """Return the profile data for the currently authenticated user."""
    return current_user

# ─── Get Public User Info by Email (for contractors to see complainant details) ─
@router.get("/user-info")
def get_user_info(
    email: str,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Return a user's public info (username + mobile) by email. Requires authentication."""
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "email": user.email,
        "username": user.username,
        "mobile_number": user.mobile_number,
    }

# ─── Get All Contractors ─────────────────────────────────────────────────────
from typing import List
@router.get("/contractors", response_model=List[schemas.UserResponse])
def get_all_contractors(db: Session = Depends(database.get_db)):
    """Return a list of all contractors."""
    contractors = db.query(models.User).filter(
        models.User.role.in_(['Contractor', 'contractor'])
    ).all()
    return contractors

# ─── Delete Account ──────────────────────────────────────────────────────────
@router.delete("/delete-account")
def delete_account(current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    """Deletes the current user's account and any associated complaints based on email."""
    # Delete associated complaints
    db.query(models.Complaint).filter(models.Complaint.user_email == current_user.email).delete()
    
    # Delete the user account(s) matching this email (in case of multiple roles)
    db.query(models.User).filter(models.User.email == current_user.email).delete()
    
    db.commit()
    return {"message": "Account and all associated records deleted successfully"}

# ─── Update Mobile Number with OTP ───────────────────────────────────────────
@router.post("/mobile/send-otp")
def mobile_send_otp(data: schemas.MobileOtpRequest, current_user: models.User = Depends(auth.get_current_user)):
    """Sends an OTP to the user's currently registered email to verify a mobile number change."""
    if not SMTP_USER or not SMTP_PASS:
        raise HTTPException(status_code=500, detail="Email service not configured")
        
    otp = str(secrets.randbelow(900000) + 100000)
    _mobile_otp_store[current_user.email] = {
        "otp": otp,
        "new_mobile": data.new_mobile_number,
        "expires_at": datetime.utcnow() + timedelta(minutes=10)
    }
    
    html = f"""
    <div style="font-family:sans-serif;max-width:480px;margin:auto;padding:32px;
                background:#0A1D37;border-radius:16px;color:#fff;">
      <h2 style="color:#4FC3F7;">Smart City 🏙️ — Update Mobile Number</h2>
      <p>Hi <b>{current_user.username or 'User'}</b>,</p>
      <p>You requested to update your mobile number to <b>{data.new_mobile_number}</b>.</p>
      <p>Your verification code is:</p>
      <div style="font-size:40px;font-weight:bold;letter-spacing:12px;
                  color:#4FC3F7;text-align:center;padding:16px 0;">{otp}</div>
      <p style="color:#90CAF9;">Expires in <b>10 minutes</b>.</p>
      <p style="color:#78909C;font-size:12px;">If you did not request this, please ignore this email and your mobile number will remain unchanged.</p>
    </div>"""

    try:
        msg = __import__('email.mime.multipart', fromlist=['MIMEMultipart']).MIMEMultipart("alternative")
        msg["Subject"] = "Smart City – Mobile Number Verification Code"
        msg["From"] = SMTP_USER
        msg["To"] = current_user.email
        msg.attach(__import__('email.mime.text', fromlist=['MIMEText']).MIMEText(html, "html"))
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASS)
            server.sendmail(SMTP_USER, current_user.email, msg.as_string())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

    return {"message": f"OTP sent to {current_user.email}"}

@router.post("/mobile/verify-otp", response_model=schemas.UserResponse)
def mobile_verify_otp(data: schemas.MobileOtpVerify, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(database.get_db)):
    """Verifies the OTP and updates the user's mobile number."""
    record = _mobile_otp_store.get(current_user.email)
    
    if not record:
        raise HTTPException(status_code=400, detail="No pending mobile number update found. Request a new OTP.")
    if datetime.utcnow() > record["expires_at"]:
        del _mobile_otp_store[current_user.email]
        raise HTTPException(status_code=400, detail="OTP has expired. Request a new one.")
    if record["otp"] != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP.")
    if record["new_mobile"] != data.new_mobile_number:
        raise HTTPException(status_code=400, detail="Mobile number mismatch. Request a new OTP.")

    # Update mobile number for ALL roles associated with this email
    users = db.query(models.User).filter(models.User.email == current_user.email).all()
    for u in users:
        u.mobile_number = data.new_mobile_number
    
    db.commit()
    
    # Clear the OTP
    del _mobile_otp_store[current_user.email]
    
    # Return the updated primary user object
    db.refresh(current_user)
    return current_user

