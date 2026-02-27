import mysql.connector
import sys

# Configuration - Matches verify_replication.ps1
SECONDARY_DB = "dr-pipeline-secondary-4mrnx5c1.clay6qma8kww.ap-southeast-1.rds.amazonaws.com"
DB_USER = "admin"
DB_PASS = "YourSecretPassword"
DB_NAME = "drdb"

def verify_replication():
    print(f"Verifying data in Secondary Region (ap-southeast-1) at {SECONDARY_DB}...")
    
    try:
        conn = mysql.connector.connect(
            host=SECONDARY_DB,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME
        )
        cursor = conn.cursor()
        
        print("Querying latest record from 'dr_tests'...")
        cursor.execute('SELECT id, timestamp, region, data FROM dr_tests ORDER BY timestamp DESC LIMIT 1')
        row = cursor.fetchone()
        
        if row:
            print(f"Found replicated data: ID={row[0]}, Time={row[1]}, Region={row[2]}, Data={row[3]}")
            print("SUCCESS: Database Replication Verified.")
        else:
            print("WARNING: No data found in secondary. Replication might be lagging.")
            
        cursor.close()
        conn.close()
        
    except mysql.connector.Error as err:
        print(f"MySQL Error: {err}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    verify_replication()
