#!/usr/bin/env python3
"""
happy_hours_api.py
Python Flask API replicating PHP happy hours functionality
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
from urllib.parse import urlparse
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# ---- Config ----
DB_CONFIG = {
    'host': '87.106.214.100',
    'user': 'happyuser',
    'password': 'HappyUser@2025',
    'database': 'happy_hours_businesses',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor,
    'connect_timeout': 60
}

# Base URL for migrated images
BASE_URL = "https://app.lovehappyhours.com/business_images/"


def get_db_connection():
    """Create and return a database connection"""
    try:
        connection = pymysql.connect(**DB_CONFIG)
        return connection
    except pymysql.Error as e:
        app.logger.error(f"Database connection failed: {e}")
        return None


def get_happy_hours(connection, city, business):
    """Fetch happy hours data based on city and business filters"""
    sql = """
        SELECT happy_hours_id, Name, Address, Google_Marker, image_link, Open_hours, 
               Happy_hour_start, Happy_hour_end, Telephone, latitude, longitude, city, Business_category
        FROM happy_hours_global_test
        WHERE TRIM(COALESCE(Open_hours, '')) NOT IN ('', 'false')
          AND TRIM(COALESCE(Happy_hour_start, '')) NOT IN ('', 'false')
          AND TRIM(COALESCE(Happy_hour_end, '')) NOT IN ('', 'false')
    """
    
    params = []
    
    # Apply filters
    if city.upper() != "ALL":
        sql += " AND city = %s"
        params.append(city)
    
    if business.upper() != "ALL":
        sql += " AND Business_category = %s"
        params.append(business)
    
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchall()
    except pymysql.Error as e:
        app.logger.error(f"Query error: {e}")
        return []


def fix_image_link(image_link):
    """Fix image links that came from customercallsapp.com"""
    if not image_link:
        return ""
    
    # Only fix if it's from customercallsapp.com
    if image_link.startswith('https://customercallsapp.com'):
        # Extract filename only
        filename = os.path.basename(urlparse(image_link).path)
        # Apply new base URL
        return BASE_URL + filename
    
    # Leave Unsplash or any other external URL unchanged
    return image_link


def sanitize_row(row):
    """Sanitize row data - convert None/False to empty strings and fix encoding"""
    sanitized = {}
    for key, value in row.items():
        if value is None or value is False:
            sanitized[key] = ""
        elif isinstance(value, str):
            # Python 3 handles UTF-8 by default, but ensure proper encoding
            sanitized[key] = value
        else:
            sanitized[key] = value
    
    # Fix image_link
    if 'image_link' in sanitized:
        sanitized['image_link'] = fix_image_link(sanitized['image_link'])
    
    return sanitized


@app.route('/happy_hours_api.php', methods=['GET', 'OPTIONS'])
@app.route('/', methods=['GET', 'OPTIONS'])
def happy_hours_api():
    """Main API endpoint"""
    
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        return '', 200
    
    # Get parameters
    city = request.args.get('city', 'ALL').strip()
    business = request.args.get('business', 'ALL').strip()
    
    # Connect to database
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        # Fetch results
        results = get_happy_hours(conn, city, business)
        
        # Sanitize data
        data = [sanitize_row(row) for row in results]
        
        return jsonify(data), 200
        
    except Exception as e:
        app.logger.error(f"Error processing request: {e}")
        return jsonify({"error": "Internal server error"}), 500
        
    finally:
        conn.close()


@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    # For development
    app.run(host='0.0.0.0', port=5000, debug=True)