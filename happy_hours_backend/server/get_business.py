from flask import Flask, request, jsonify
import mysql.connector
from mysql.connector import Error
import os

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': 'your_host',
    'user': 'your_user',
    'password': 'your_password',
    'database': 'your_database'
}

def get_db_connection():
    """Create and return a database connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

@app.route('/happy-hours-api/get_business', methods=['POST'])
def get_business():
    """
    Fetch business HTML content by business name
    
    Request body:
    {
        "business_name": "Business Name"
    }
    
    Response:
    {
        "success": true,
        "content_html": "<html>...</html>",
        "business_name": "Business Name"
    }
    """
    try:
        # Get request data
        data = request.get_json()
        
        if not data:
            return jsonify({
                "success": False,
                "message": "No data provided"
            }), 400
        
        business_name = data.get('business_name', '').strip()
        
        if not business_name:
            return jsonify({
                "success": False,
                "message": "business_name is required"
            }), 400
        
        # Connect to database
        connection = get_db_connection()
        if not connection:
            return jsonify({
                "success": False,
                "message": "Database connection failed"
            }), 500
        
        cursor = connection.cursor(dictionary=True)
        
        # Query to fetch business HTML content
        query = """
            SELECT business_name, content_html, email, updated_at 
            FROM businesses 
            WHERE business_name = %s
        """
        
        cursor.execute(query, (business_name,))
        result = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if result:
            return jsonify({
                "success": True,
                "business_name": result['business_name'],
                "content_html": result['content_html'],
                "email": result.get('email'),
                "updated_at": result.get('updated_at').isoformat() if result.get('updated_at') else None
            }), 200
        else:
            return jsonify({
                "success": False,
                "message": f"Business '{business_name}' not found"
            }), 404
    
    except Exception as e:
        print(f"Error in get_business: {e}")
        return jsonify({
            "success": False,
            "message": f"Server error: {str(e)}"
        }), 500

if __name__ == '__main__':
    app.run(debug=True)