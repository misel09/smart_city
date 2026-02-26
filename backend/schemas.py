from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    username: Optional[str] = None
    mobile_number: Optional[str] = None

class UserCreate(UserBase):
    password: str
    role: str = "user"
    contractor_type: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str
    role: str = "user"
    contractor_type: Optional[str] = None

class UserGoogleLogin(BaseModel):
    email: EmailStr
    name: str
    google_id: str
    role: str = "user"
    contractor_type: Optional[str] = None

# Smart initiate: check if user exists before deciding what to do
class GoogleInitiateRequest(BaseModel):
    email: EmailStr
    name: str
    google_id: str

# For role-only selection (email already verified)
class GoogleSelectRoleRequest(BaseModel):
    email: EmailStr
    name: str
    google_id: str
    role: str = "user"
    contractor_type: Optional[str] = None

# Step 1: After Google Sign-In, send OTP to email
class GoogleOtpRequest(BaseModel):
    email: EmailStr
    name: str
    google_id: str

# Step 2: Verify OTP + select role → get JWT
class GoogleOtpVerify(BaseModel):
    email: EmailStr
    name: str
    google_id: str
    otp: str
    role: str = "user"
    contractor_type: Optional[str] = None

# ─── Forgot Password ──────────────────────────────────────────────────────────
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ForgotPasswordVerifyOtp(BaseModel):
    email: EmailStr
    otp: str

class ForgotPasswordReset(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

# ─── Mobile Number Verification ───────────────────────────────────────────────
class MobileOtpRequest(BaseModel):
    new_mobile_number: str

class MobileOtpVerify(BaseModel):
    new_mobile_number: str
    otp: str

class UserResponse(UserBase):
    id: int
    role: str
    contractor_type: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class ComplaintBase(BaseModel):
    title: str
    description: str
    category: str
    latitude: float
    longitude: float
    address: str
    image_path: Optional[str] = None
    priority: str = "Normal"
    due_date: Optional[datetime] = None
    contractor_email: Optional[str] = None

class ComplaintCreate(ComplaintBase):
    timestamp: Optional[datetime] = None

class ComplaintResponse(ComplaintBase):
    id: int
    status: str
    timestamp: datetime
    user_email: Optional[str] = None
    user_name: Optional[str] = None
    user_mobile: Optional[str] = None
    contractor_name: Optional[str] = None
    contractor_mobile: Optional[str] = None
    after_image_path: Optional[str] = None
    after_description: Optional[str] = None
    review_comment: Optional[str] = None
    taken_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None

    class Config:
        from_attributes = True
