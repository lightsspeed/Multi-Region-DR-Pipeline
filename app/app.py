import os
from flask import Flask, jsonify, request
import mysql.connector
from datetime import datetime

app = Flask(__name__)

# Environment Variables
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASS = os.environ.get('DB_PASS')
DB_NAME = os.environ.get('DB_NAME', 'drdb')
REGION  = os.environ.get('AWS_REGION', 'unknown')

def get_db_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME
    )

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "region": REGION,
        "timestamp": datetime.now().isoformat()
    })

@app.route('/write', methods=['GET', 'POST'])
def write_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create table if not exists
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS dr_tests (
                id INT AUTO_INCREMENT PRIMARY KEY,
                write_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                region VARCHAR(50),
                message TEXT
            )
        """)
        
        msg = request.args.get('message', 'Automatic DR Test Write')
        cursor.execute(
            "INSERT INTO dr_tests (region, message) VALUES (%s, %s)",
            (REGION, msg)
        )
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"status": "success", "message": "Data written to RDS", "region": REGION})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/read')
def read_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM dr_tests ORDER BY write_time DESC LIMIT 10")
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify({"status": "success", "data": rows, "region": REGION})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
