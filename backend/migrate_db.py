from database import engine
from sqlalchemy import text

with engine.begin() as conn:
    print("Migrating complaints table...")
    try:
        conn.execute(text("ALTER TABLE complaints ADD COLUMN priority VARCHAR DEFAULT 'Normal'"))
    except Exception as e:
        print(f"Priority error: {e}")
        
    try:
        conn.execute(text("ALTER TABLE complaints ADD COLUMN due_date TIMESTAMP WITH TIME ZONE"))
    except Exception as e:
        print(f"DueDate error: {e}")
        
    try:
        conn.execute(text("ALTER TABLE complaints ADD COLUMN contractor_email VARCHAR"))
    except Exception as e:
        print(f"Contractor error: {e}")
        
    print("Migration complete!")
