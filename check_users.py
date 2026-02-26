from backend.database import SessionLocal
from backend.models import User

db = SessionLocal()
users = db.query(User).all()

print(f"Total Users: {len(users)}")
for user in users:
        print(f"ID: {user.id}, Username: {user.username}, Email: {user.email}, Created: {user.created_at}")

db.close()
