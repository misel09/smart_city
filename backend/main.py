from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import auth, complaints

from fastapi.staticfiles import StaticFiles
import os

# Create database tables (new tables only)
Base.metadata.create_all(bind=engine)

# Auto-migration: add columns that didn't exist in older DB versions
with engine.connect() as conn:
    conn.execute(__import__('sqlalchemy').text(
        "ALTER TABLE complaints ADD COLUMN IF NOT EXISTS user_email VARCHAR;"
    ))
    conn.execute(__import__('sqlalchemy').text(
        "ALTER TABLE complaints ADD COLUMN IF NOT EXISTS taken_at TIMESTAMP WITH TIME ZONE;"
    ))
    conn.execute(__import__('sqlalchemy').text(
        "ALTER TABLE complaints ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE;"
    ))
    conn.execute(__import__('sqlalchemy').text(
        "ALTER TABLE complaints ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;"
    ))
    conn.commit()

app = FastAPI(title="Smart City Backend")

# Create uploads directory if it doesn't exist
if not os.path.exists("uploads"):
    os.makedirs("uploads")

# Mount uploads directory
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow all origins for development, restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(complaints.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to Smart City API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
