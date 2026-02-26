import psycopg2
import os

DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://")

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cursor = conn.cursor()

    print("Adding review_comment column to complaints table...")
    cursor.execute('ALTER TABLE complaints ADD COLUMN review_comment VARCHAR;')
    print("Column added successfully (or it was already there).")

except Exception as e:
    print(f"Error executing statement: {e}")
finally:
    if 'cursor' in locals():
        cursor.close()
    if 'conn' in locals():
        conn.close()
