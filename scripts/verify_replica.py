import os
import mysql.connector
import sys

def verify():
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
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM dr_tests ORDER BY write_time DESC LIMIT 5")
        rows = cursor.fetchall()
        
        if rows:
            print(f"Verification Success: Found {len(rows)} records in replica at {host}")
            for row in rows:
                print(f"  - [{row['write_time']}] {row['region']}: {row['message']}")
            return True
        else:
            print("Verification Failed: No records found in replica.")
            return False
            
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Failed to verify data: {e}")
        sys.exit(1)

if __name__ == "__main__":
    result = verify()
    sys.exit(0 if result else 1)
