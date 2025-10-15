#!/usr/bin/env python3
"""
Flask replica of the original PHP endpoint happy_hours_api.php

- GET /happy_hours_api.php?city=Mumbai&business=Restaurant
- GET / (optional root route alias)

Returns a JSON array of rows with fields:
happy_hours_id, Name, Address, Google_Marker, image_link, Open_hours,
Happy_hour_start, Happy_hour_end, Telephone, latitude, longitude, city, Business_category
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
from urllib.parse import urlparse, quote
import os
import logging

app = Flask(__name__)
CORS(app)  # Allow all origins (like PHP headers did)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("happy_hours_php_clone")

# ====== CONFIG (adjust as needed) ======
DB_CONFIG = {
    # These are from your Python version; update if you want to hit the same DB as PHP did
    'host': '87.106.214.100',
    'user': 'happyuser',
    'password': 'HappyUser@2025',
    'database': 'happy_hours_businesses',  # If your data is in a different DB/table, change below
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor,
    'connect_timeout': 60,
}

# Table: In your PHP, table was `happy_hours_global`. If your data is there, use that.
# In your current Python file you queried `happy_hours_global_test`.
TABLE_NAME = "happy_hours_global_test"  # change to "happy_hours_global_test" if needed

# Base URL to remap images that were on customercallsapp.com
IMAGES_BASE_URL = "https://app.lovehappyhours.com/business_images/"  # keep trailing slash


def db_conn():
    try:
        return pymysql.connect(**DB_CONFIG)
    except Exception as e:
        logger.exception(f"DB connection failed: {e}")
        return None


def fix_image_link(image_link: str) -> str:
    """
    Replicates PHP logic:
    - If image_link starts with https://customercallsapp.com or http://customercallsapp.com,
      extract the filename and prepend IMAGES_BASE_URL
    - Otherwise leave as is (Unsplash/CDN links pass through)
    """
    if not image_link:
        return ""

    try:
        if image_link.startswith('https://customercallsapp.com') or image_link.startswith('http://customercallsapp.com'):
            # Extract filename and URL-encode it
            filename = os.path.basename(urlparse(image_link).path)
            filename = quote(filename)
            return IMAGES_BASE_URL + filename
    except Exception:
        # If anything goes wrong, fall back to original
        return image_link

    return image_link


def sanitize_row(row: dict) -> dict:
    """
    - Convert None/False to empty string (like PHP)
    - Ensure strings are UTF-8 compatible
    - Fix image_link using fix_image_link
    """
    out = {}
    for k, v in row.items():
        if v is None or v is False:
            out[k] = ""
        else:
            out[k] = v

    if 'image_link' in out:
        out['image_link'] = fix_image_link(str(out['image_link']))

    return out


def get_happy_hours(city: str, business: str):
    sql = f"""
        SELECT happy_hours_id, Name, Address, Google_Marker, image_link, Open_hours,
               Happy_hour_start, Happy_hour_end, Telephone, latitude, longitude, city, Business_category
        FROM {TABLE_NAME}
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

    conn = db_conn()
    if not conn:
        return None, "Database connection failed"

    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            rows = cur.fetchall()
            return rows, None
    except Exception as e:
        logger.exception(f"Query error: {e}")
        return None, str(e)
    finally:
        try:
            conn.close()
        except Exception:
            pass


# Keep the same paths as PHP and also support root
@app.route('/happy_hours_api.php', methods=['GET', 'OPTIONS'])
@app.route('/', methods=['GET', 'OPTIONS'])
def happy_hours_api():
    # Preflight
    if request.method == 'OPTIONS':
        # Mirrors PHP behavior
        return ('', 200, {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
        })

    city = (request.args.get('city') or 'ALL').strip()
    business = (request.args.get('business') or 'ALL').strip()

    rows, err = get_happy_hours(city, business)
    if err is not None:
        return jsonify({"error": "Database error", "detail": err}), 500

    data = [sanitize_row(r) for r in (rows or [])]

    # PHP used JSON_UNESCAPED_UNICODE and JSON_UNESCAPED_SLASHES implicitly via Python’s default
    return jsonify(data), 200


# Optional: debugging route to list registered routes (remove for prod)
@app.route('/__routes__', methods=['GET'])
def list_routes():
    output = []
    for rule in app.url_map.iter_rules():
        methods = ",".join(sorted(rule.methods))
        output.append({"rule": str(rule), "methods": methods, "endpoint": rule.endpoint})
    return jsonify(output), 200


@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    # Dev run
    print("Starting Flask PHP-clone on http://0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)