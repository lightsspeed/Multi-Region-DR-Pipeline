import os
import mysql.connector
import sys
from datetime import datetime

def seed():
    host = os.environ.get('DB_HOST')
    user = os.environ.get('DB_USER', 'admin')
    password = os.environ.get('DB_PASS')
    db_name = os.environ.get('DB_NAME', 'drdb')

    if not all([host, password]):
        print("Error: DB_HOST and DB_PASS environment variables must be set.")
        sys.exit(1)

    try:
        conn = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=db_name
        )
        cursor = conn.cursor()
        
        # Create table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS dr_tests (
                id INT AUTO_INCREMENT PRIMARY KEY,
                write_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                region VARCHAR(50),
                message TEXT
            )
        """)
        
        # Insert seed data
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        msg = f"Seed data inserted at {now}"
        cursor.execute(
            "INSERT INTO dr_tests (region, message) VALUES (%s, %s)",
            ("us-east-1", msg)
        )
        conn.commit()
        print(f"Successfully seeded data into {host}")
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Failed to seed data: {e}")
        sys.exit(1)

if __name__ == "__main__":
    seed()
