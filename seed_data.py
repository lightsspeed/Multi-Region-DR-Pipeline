import mysql.connector
import datetime
import sys

# Configuration - Matches seed_data.ps1
PRIMARY_DB = "dr-pipeline-primary-4mrnx5c1.cxos2k6kq1jb.ap-south-1.rds.amazonaws.com"
DB_USER = "admin"
DB_PASS = "YourSecretPassword"
DB_NAME = "drdb"

def seed_data():
    print(f"Seeding data into Primary Region (ap-south-1) at {PRIMARY_DB}...")
    
    try:
        conn = mysql.connector.connect(
            host=PRIMARY_DB,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME
        )
        cursor = conn.cursor()
        
        # Create table if not exists
        print("Ensuring table 'dr_tests' exists...")
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS dr_tests (
                id INT AUTO_INCREMENT PRIMARY KEY, 
                timestamp DATETIME, 
                region VARCHAR(50), 
                data VARCHAR(255)
            )
        ''')
        
        # Insert seed record
        now = datetime.datetime.now()
        region = "ap-south-1"
        data = "Initial Seed Data (Python Script)"
        
        print(f"Inserting record for region {region}...")
        cursor.execute(
            'INSERT INTO dr_tests (timestamp, region, data) VALUES (%s, %s, %s)', 
            (now, region, data)
        )
        conn.commit()
        
        print(f"Successfully seeded data at {now}")
        cursor.close()
        conn.close()
        
    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    seed_data()
