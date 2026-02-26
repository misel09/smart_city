import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path)

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("No DATABASE_URL found.")
    exit(1)

engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    print("Adding columns...")
    try:
        conn.execute(text("ALTER TABLE complaints ADD COLUMN after_image_path VARCHAR;"))
        conn.execute(text("ALTER TABLE complaints ADD COLUMN after_description VARCHAR;"))
        conn.commit()
        print("Columns added successfully.")
    except Exception as e:
        print(f"Error adding columns: {e}")
