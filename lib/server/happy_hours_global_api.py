#!/usr/bin/env python3
"""
happy_hours_global_api.py
Flask API for Happy Hours listing (Python replacement for the PHP endpoint)
"""
from business_registration import business_registration as br_handler
from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
from urllib.parse import urlparse, quote
import os
import logging

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# ---- Logging ----
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("happy_hours_api")

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

# Base URL for migrated images (public HTTPS URL you configured to serve images)
BASE_URL = "https://app.lovehappyhours.com/business_images/"  # keep trailing slash


def get_db_connection():
    """Create and return a database connection"""
    try:
        connection = pymysql.connect(**DB_CONFIG)
        return connection
    except pymysql.Error as e:
        logger.exception(f"Database connection failed: {e}")
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

    if city and city.upper() != "ALL":
        sql += " AND city = %s"
        params.append(city)

    if business and business.upper() != "ALL":
        sql += " AND Business_category = %s"
        params.append(business)

    try:
        with connection.cursor() as cursor:
            cursor.execute(sql, params)
            return cursor.fetchall()
    except pymysql.Error as e:
        logger.exception(f"Query error: {e}")
        return []


def fix_image_link(image_link: str) -> str:
    """
    Re-point images that were previously hosted on customercallsapp.com to the
    new HTTPS base URL under your domain. Leave absolute URLs on other domains unchanged.
    """
    if not image_link:
        return ""

    # Only fix if it's from customercallsapp.com
    if image_link.startswith('https://customercallsapp.com') or image_link.startswith('http://customercallsapp.com'):
        filename = os.path.basename(urlparse(image_link).path)
        # URL-encode filename to safely handle spaces and special chars
        filename = quote(filename)
        return BASE_URL + filename

    # If a relative path accidentally comes from DB, normalize it to absolute under our base
    if image_link.startswith('/business_images/'):
        filename = os.path.basename(image_link)
        filename = quote(filename)
        return BASE_URL + filename

    # Leave Unsplash/CDN or any other external URL unchanged
    return image_link


def sanitize_row(row: dict) -> dict:
    """Sanitize row data - convert None/False to empty strings and fix encoding"""
    sanitized = {}
    for key, value in row.items():
        if value is None or value is False:
            sanitized[key] = ""
        else:
            sanitized[key] = value

    # Fix image_link
    if 'image_link' in sanitized:
        sanitized['image_link'] = fix_image_link(str(sanitized['image_link']))

    return sanitized


# Keep a php-like route for drop-in replacement, and the root path
@app.route('/happy_hours_api.php', methods=['GET', 'OPTIONS'])
@app.route('/', methods=['GET', 'OPTIONS'])
def happy_hours_api():
    """Main API endpoint"""
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        return '', 200

    # Get parameters
    city = (request.args.get('city') or 'ALL').strip()
    business = (request.args.get('business') or 'ALL').strip()

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
        #logger.exception(f"Error processing request: {e}")
        #return jsonify({"error": "Internal server error"}), 500
        print(f"DB insert failed: {str(e)}")
        return jsonify({"status": "error", "message": f"DB insert failed: {str(e)}"}), 500

    finally:
        try:
            conn.close()
        except Exception:
            pass

# add this route
@app.route('/business_registration', methods=['POST', 'OPTIONS'])
def business_registration_route():
    if request.method == 'OPTIONS':
        return '', 200
    return br_handler()

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    # For development only
    app.run(host='0.0.0.0', port=5000, debug=True)