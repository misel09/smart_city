from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv
from pathlib import Path
import bcrypt

def get_password_hash(password):
    if isinstance(password, str):
        password = password.encode('utf-8')
    return bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')

def create_officer():
    # Load .env from backend directory
    env_path = Path(__file__).resolve().parent / ".env"
    load_dotenv(dotenv_path=env_path)
    
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("DATABASE_URL not found in .env. Skipping.")
        return

    engine = create_engine(db_url)

    try:
        email = "officer@smartcity.gov"
        password = "Officer@123"
        role = "municipality_officer"
        username = "Municipality Officer"
        district = "Anand"

        hashed_password = get_password_hash(password)

        with engine.connect() as connection:
            # Check if user already exists
            res = connection.execute(text("SELECT id FROM users WHERE email = :email AND role = :role"), {"email": email, "role": role})
            if res.fetchone():
                print(f"Officer with email {email} already exists. Updating district to {district}...")
                connection.execute(text("UPDATE users SET district = :district WHERE email = :email"), {"district": district, "email": email})
                connection.commit()
                return

            # Insert new user
            connection.execute(
                text("INSERT INTO users (username, email, password_hash, role, district) VALUES (:username, :email, :password_hash, :role, :district)"),
                {"username": username, "email": email, "password_hash": hashed_password, "role": role, "district": district}
            )
            connection.commit()
            print(f"Successfully created Municipality Officer:")
            print(f"Email: {email}")
            print(f"Password: {password}")
            print(f"Role: {role}")
            print(f"District: {district}")

    except Exception as e:
        print(f"Error creating officer: {e}")
    finally:
        engine.dispose()

if __name__ == "__main__":
    create_officer()
