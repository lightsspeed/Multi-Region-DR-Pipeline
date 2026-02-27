# Seed Data into Primary RDS
$primary_db = "dr-pipeline-primary-91t6mr1h.cxos2k6kq1jb.ap-south-1.rds.amazonaws.com"
$db_pass = "YourSecretPassword"

Write-Host "Seeding data into Primary Region (ap-south-1)..." -ForegroundColor Cyan

# Note: This requires mysql client installed. If not, we can use a python script.
# Let's use Python for better compatibility since we installed it earlier.

python -c @"
import mysql.connector
import datetime

try:
    conn = mysql.connector.connect(
        host='$primary_db',
        user='admin',
        password='$db_pass',
        database='drdb'
    )
    cursor = conn.cursor()
    
    # Create table if not exists
    cursor.execute('CREATE TABLE IF NOT EXISTS dr_tests (id INT AUTO_INCREMENT PRIMARY KEY, timestamp DATETIME, region VARCHAR(50), data VARCHAR(255))')
    
    # Insert seed record
    now = datetime.datetime.now()
    cursor.execute('INSERT INTO dr_tests (timestamp, region, data) VALUES (%s, %s, %s)', (now, 'ap-south-1', 'Initial Seed Data'))
    conn.commit()
    
    print(f'Successfully seeded data at {now}')
    cursor.close()
    conn.close()
except Exception as e:
    print(f'Error seeding data: {e}')
"@
