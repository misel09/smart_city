from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from .. import models, schemas, database, auth
from fastapi import File, Form, UploadFile
import shutil
import uuid
import math

from datetime import datetime

router = APIRouter(
    prefix="/complaints",
    tags=["Complaints"],
)

CONTRACTOR_CATEGORY_MAP = {
    "Civil / Structural Repair Contractor": ["Damaged concrete structures"],
    "Electrical Contractor": ["Damaged Electrical Poles"],
    "Traffic Management & Road Safety Contractor": ["Damaged Road Signs"],
    "Animal Control Services Contractor": ["Dead Animals / Pollution"],
    "Municipal Sanitation & Waste Management Contractor": ["Garbage", "Dead Animals / Pollution"],
    "Tree Removal / Arborist Contractor": ["Fallen Trees"],
    "Urban Surface Cleaning & Maintenance Contractor": ["Graffiti"],
    "Traffic Enforcement Authority": ["Illegal Parking"],
    "Road Construction": ["Potholes and Road Cracks"], 
    "Road Construction Contractor": ["Potholes and Road Cracks"]
}

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0  # Earth radius in kilometers
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)

    a = math.sin(dLat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dLon / 2)**2
    c = 2 * math.asin(math.sqrt(a))
    return R * c

def enrich_complaints(db: Session, complaints: List[models.Complaint]) -> List[schemas.ComplaintResponse]:
    emails = {c.user_email for c in complaints if c.user_email}
    c_emails = {c.contractor_email for c in complaints if c.contractor_email}
    all_emails = emails.union(c_emails)
    users = db.query(models.User).filter(models.User.email.in_(all_emails)).all() if all_emails else []
    user_map = {u.email: u for u in users}
    
    res = []
    for c in complaints:
        u = user_map.get(c.user_email)
        cu = user_map.get(c.contractor_email)
        
        c_dict = {
            "id": c.id,
            "title": c.title,
            "description": c.description,
            "category": c.category,
            "latitude": float(c.latitude) if c.latitude else 0.0,
            "longitude": float(c.longitude) if c.longitude else 0.0,
            "address": c.address,
            "district": c.district,
            "status": c.status,
            "timestamp": c.timestamp,
            "image_path": c.image_path,
            "user_email": c.user_email,
            "user_name": u.username if u else None,
            "user_mobile": u.mobile_number if u else None,
            "priority": c.priority,
            "contractor_email": c.contractor_email,
            "contractor_name": cu.username if cu else None,
            "contractor_mobile": cu.mobile_number if cu else None,
            "taken_at": c.taken_at,
            "resolved_at": c.resolved_at,
            "reviewed_at": c.reviewed_at,
            "after_image_path": c.after_image_path,
            "after_description": c.after_description,
            "review_comment": c.review_comment,
        }
        res.append(schemas.ComplaintResponse(**c_dict))
    return res

def enrich_single(db: Session, c: models.Complaint) -> schemas.ComplaintResponse:
    u = db.query(models.User).filter(models.User.email == c.user_email).first() if c.user_email else None
    cu_email = c.contractor_email
    cu = db.query(models.User).filter(models.User.email == cu_email).first() if cu_email else None
    
    c_dict = {
        "id": c.id,
        "title": c.title,
        "description": c.description,
        "category": c.category,
        "latitude": float(c.latitude) if c.latitude else 0.0,
        "longitude": float(c.longitude) if c.longitude else 0.0,
        "address": c.address,
        "district": c.district,
        "status": c.status,
        "timestamp": c.timestamp,
        "image_path": c.image_path,
        "user_email": c.user_email,
        "user_name": u.username if u else None,
        "user_mobile": u.mobile_number if u else None,
        "priority": c.priority,
        "contractor_email": c.contractor_email,
        "contractor_name": cu.username if cu else None,
        "contractor_mobile": cu.mobile_number if cu else None,
        "taken_at": c.taken_at,
        "resolved_at": c.resolved_at,
        "reviewed_at": c.reviewed_at,
        "after_image_path": c.after_image_path,
        "after_description": c.after_description,
        "review_comment": c.review_comment,
    }
    return schemas.ComplaintResponse(**c_dict)

@router.get("/nearby", response_model=List[schemas.ComplaintResponse])
def get_nearby_complaints(
    lat: float = Query(..., description="User latitude"),
    lng: float = Query(..., description="User longitude"),
    radius: float = Query(10.0, description="Search radius in kilometers"),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    query = db.query(models.Complaint)
    
    if current_user.role and current_user.role.lower() == "contractor" and current_user.contractor_type:
        allowed_categories = CONTRACTOR_CATEGORY_MAP.get(current_user.contractor_type, [])
        if allowed_categories:
            query = query.filter(models.Complaint.category.in_(allowed_categories))
            
    all_complaints = query.all()
    
    # Calculate distance and store in a list of tuples (complaint, distance) if within `radius` km
    complaints_with_distance = []
    for c in all_complaints:
        try:
            c_lat = float(c.latitude)
            c_lng = float(c.longitude)
            dist = haversine_distance(lat, lng, c_lat, c_lng)
            if dist <= radius:  # Use the passed radius
                complaints_with_distance.append((c, dist))
        except (ValueError, TypeError):
            # If coordinates are invalid, skip them for nearby
            pass
            
    # Sort by distance
    complaints_with_distance.sort(key=lambda x: x[1])
    
    # Return the enriched models
    return enrich_complaints(db, [c for c, dist in complaints_with_distance])

@router.post("/analyze-image", response_model=schemas.AnalysisResponse)
def analyze_image(
    image: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_user)
):
    """
    Analyzes an uploaded image and returns a suggested category and description.
    """
    file_extension = image.filename.split(".")[-1]
    filename = f"temp_analysis_{uuid.uuid4()}.{file_extension}"
    file_location = f"uploads/{filename}"
    
    try:
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        from ..ai_utils import ai_utils
        
        # 1. Analyze image (consolidated call for speed)
        analysis = ai_utils.analyze_image(file_location)
        category = analysis.get("category", "Unclassified")
        description = analysis.get("description", "")
        priority = analysis.get("priority", "Normal")
        
        return {
            "category": category, 
            "description": description, 
            "priority": priority
        }
    finally:
        # Cleanup temp file if necessary, though we might keep it or use a specific temp dir
        # For now, we'll keep it simple and just return the data. 
        # In a real app, you'd delete the temp file here.
        pass

@router.post("/", response_model=schemas.ComplaintResponse)

def create_complaint(
    title: str = Form(...),
    description: str = Form(...),
    category: str = Form(...),
    latitude: str = Form(...),
    longitude: str = Form(...),
    address: str = Form(...),
    district: Optional[str] = Form(None),
    priority: str = Form("Normal"),
    image: UploadFile = File(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    if not current_user.mobile_number:
        raise HTTPException(
            status_code=400, 
            detail="A verified mobile number is required to report an issue."
        )
            
    image_path = None
    if image:
        file_extension = image.filename.split(".")[-1]
        filename = f"{uuid.uuid4()}.{file_extension}"
        file_location = f"uploads/{filename}"
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        image_path = f"uploads/{filename}"

        # --- AI Pipeline Integration ---
        from ..ai_utils import ai_utils
        
        # Consolidated AI check for multiple fields
        if (category in ["Auto-Detect", "Unclassified", "", "None", "undefined"]) or (description in ["Auto-Generate", "", "None", "undefined"] or len(description) < 5):
            try:
                # Consolidated parallel AI call
                analysis = ai_utils.analyze_image(file_location)
                
                if category in ["Auto-Detect", "Unclassified", "", "None", "undefined"]:
                    category = analysis.get("category", category)
                
                if description in ["Auto-Generate", "", "None", "undefined"] or len(description) < 5:
                    description = analysis.get("description", description)
                
                # Assign priority from Gemini
                priority = analysis.get("priority", priority)
            except Exception as e:
                print(f"AI Pipeline failed: {e}")
        # --- End AI Pipeline ---

    db_complaint = models.Complaint(
        title=title,
        description=description,
        category=category,
        latitude=latitude,
        longitude=longitude,
        address=address,
        district=district,
        image_path=image_path,
        user_email=current_user.email,   # ← link to user
        priority=priority,
    )
    db.add(db_complaint)
    db.commit()
    db.refresh(db_complaint)
    return enrich_single(db, db_complaint)

@router.put("/{complaint_id}/take", response_model=schemas.ComplaintResponse)
def take_complaint(
    complaint_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    if current_user.role != "contractor":
        raise HTTPException(status_code=403, detail="Only contractors can take tasks.")

    if not current_user.mobile_number:
        raise HTTPException(
            status_code=403,
            detail="You must verify your mobile number before taking tasks."
        )
        
    complaint = db.query(models.Complaint).filter(models.Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
        
    if complaint.contractor_email:
        raise HTTPException(status_code=400, detail="Complaint already taken by a contractor.")
        
    complaint.contractor_email = current_user.email
    complaint.status = "In Progress"
    from sqlalchemy.sql import func
    complaint.taken_at = func.now()
    
    db.commit()
    db.refresh(complaint)
    return enrich_single(db, complaint)

@router.put("/{complaint_id}/resolve", response_model=schemas.ComplaintResponse)
def resolve_complaint(
    complaint_id: int,
    description: str = Form(...),
    image: UploadFile = File(...),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    if current_user.role != "contractor":
        raise HTTPException(status_code=403, detail="Only contractors can resolve tasks.")

    complaint = db.query(models.Complaint).filter(models.Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
        
    if complaint.contractor_email != current_user.email:
        raise HTTPException(status_code=403, detail="You can only resolve tasks you have taken.")
        
    file_extension = image.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{file_extension}"
    file_location = f"uploads/{filename}"
    
    with open(file_location, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
        
    complaint.after_description = description
    complaint.after_image_path = file_location
    complaint.status = "Resolved"
    from sqlalchemy.sql import func
    complaint.resolved_at = func.now()
    
    db.commit()
    db.refresh(complaint)
    return enrich_single(db, complaint)

@router.put("/{complaint_id}/review", response_model=schemas.ComplaintResponse)
def review_complaint(
    complaint_id: int,
    status: str = Form(..., description="E.g. Reviewed or Rejected"),
    comment: str = Form(None),
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    complaint = db.query(models.Complaint).filter(models.Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
        
    if complaint.user_email != current_user.email:
        raise HTTPException(status_code=403, detail="You can only review tasks you registered.")
        
    complaint.status = status
    if comment:
        complaint.review_comment = comment
    from sqlalchemy.sql import func
    complaint.reviewed_at = func.now()
        
    db.commit()
    db.refresh(complaint)
    return enrich_single(db, complaint)

# All complaints (admin / contractor view)
@router.get("/", response_model=List[schemas.ComplaintResponse])
def read_complaints(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    query = db.query(models.Complaint)
    
    user_role = current_user.role.lower() if current_user.role else ""

    if user_role == "contractor" and current_user.contractor_type:
        allowed_categories = CONTRACTOR_CATEGORY_MAP.get(current_user.contractor_type, [])
        if allowed_categories:
            query = query.filter(models.Complaint.category.in_(allowed_categories))
            
    if user_role == "municipality_officer" and current_user.district:
        # Case insensitive match for safety
        query = query.filter(models.Complaint.district.ilike(f"%{current_user.district}%"))
            
    complaints = query.offset(skip).limit(limit).all()
    return enrich_complaints(db, complaints)

# Only the current user's complaints
@router.get("/me", response_model=List[schemas.ComplaintResponse])
def read_my_complaints(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    complaints = (
        db.query(models.Complaint)
        .filter(models.Complaint.user_email == current_user.email)
        .order_by(models.Complaint.timestamp.desc())
        .all()
    )
    return enrich_complaints(db, complaints)

# Complaints taken by this contractor
@router.get("/taken", response_model=List[schemas.ComplaintResponse])
def read_taken_complaints(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    complaints = (
        db.query(models.Complaint)
        .filter(models.Complaint.contractor_email == current_user.email)
        .order_by(models.Complaint.timestamp.desc())
        .all()
    )
    return enrich_complaints(db, complaints)

@router.delete("/{complaint_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_complaint(
    complaint_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    complaint = db.query(models.Complaint).filter(models.Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
        
    # Security check: only the reporter can delete
    if complaint.user_email != current_user.email:
        raise HTTPException(status_code=403, detail="You can only delete your own reports.")
        
    # Status check: only Registered reports can be deleted
    if complaint.status != "Registered":
        raise HTTPException(status_code=400, detail="Only 'Registered' reports can be deleted.")
        
    db.delete(complaint)
    db.commit()
    return None
