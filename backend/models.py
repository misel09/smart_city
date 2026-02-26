from sqlalchemy import Column, Integer, String, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, index=True, nullable=True)
    email = Column(String, index=True, nullable=False)
    password_hash = Column(String)
    role = Column(String, default="user")
    contractor_type = Column(String, nullable=True)
    mobile_number = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint('email', 'role', 'contractor_type', name='uix_user_identity'),
    )

class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    category = Column(String, nullable=False)
    status = Column(String, default="Registered")
    latitude = Column(String, nullable=False)
    longitude = Column(String, nullable=False)
    address = Column(String, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    image_path = Column(String, nullable=True)
    # Link complaint to the user who submitted it
    user_email = Column(String, nullable=True, index=True)
    # New fields for Priority, Due Time, and Task Assignment
    priority = Column(String, nullable=True, default="Normal")
    due_date = Column(DateTime(timezone=True), nullable=True) # or due_time
    contractor_email = Column(String, nullable=True, index=True)

    # Resolution fields
    after_image_path = Column(String, nullable=True)
    after_description = Column(String, nullable=True)
    
    # Review fields
    review_comment = Column(String, nullable=True)

    # Status transition timestamps
    taken_at = Column(DateTime(timezone=True), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
