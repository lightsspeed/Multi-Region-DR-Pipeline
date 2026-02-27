# Verify Data in Secondary RDS (Read-Only Replica)
$secondary_db = "dr-pipeline-secondary-91t6mr1h.clay6qma8kww.ap-southeast-1.rds.amazonaws.com"
$db_pass = "YourSecretPassword"

Write-Host "Verifying data in Secondary Region (ap-southeast-1)..." -ForegroundColor Cyan

python -c @"
import mysql.connector

try:
    conn = mysql.connector.connect(
        host='$secondary_db',
        user='admin',
        password='$db_pass',
        database='drdb'
    )
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM dr_tests ORDER BY timestamp DESC LIMIT 1')
    row = cursor.fetchone()
    
    if row:
        print(f'Found replicated data: ID={row[0]}, Time={row[1]}, Region={row[2]}, Data={row[3]}')
        print('SUCCESS: Database Replication Verified.')
    else:
        print('WARNING: No data found in secondary. Replication might be lagging.')
        
    cursor.close()
    conn.close()
except Exception as e:
    print(f'Error verifying data: {e}')
"@
