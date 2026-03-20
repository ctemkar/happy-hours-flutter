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
from werkzeug.utils import secure_filename
import os
import logging
import shutil

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# ---- Logging ----
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("happy_hours_api")

# ---- Config ----
DB_CONFIG = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': '',  # XAMPP default is empty
    'database': 'happy_hours_businesses',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor,
    'connect_timeout': 60
}
# Base URL for migrated images (public HTTPS URL you configured to serve images)
BASE_URL = "http://localhost/happy_hours_application/business_images/"  # keep trailing slash

# Directory to store edited HTML files
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
STORE_DIR = os.path.join(BASE_DIR, 'output_html_store')
OUTPUT_DIR = "C:/xampp/htdocs/happy_hours_application/output_html"
os.makedirs(STORE_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Log directory paths at startup
logger.info(f"📁 STORE_DIR: {STORE_DIR}")
logger.info(f"📁 OUTPUT_DIR: {OUTPUT_DIR}")


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


# Root path only (PHP route removed)
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
        print(f"DB query failed: {str(e)}")
        return jsonify({"status": "error", "message": f"DB query failed: {str(e)}"}), 500

    finally:
        try:
            conn.close()
        except Exception:
            pass


# NEW: Route that replicates the "business" API endpoint (without PHP filename)
@app.route('/happy_hours_business', methods=['GET', 'OPTIONS'])
def happy_hours_business():
    """
    Business API route (Python). Same behavior as root:
      - ?city=ALL|ExactCity
      - ?business=ALL|ExactCategory
    Example:
      /happy_hours_business?city=Bangkok&business=Bar
    """
    if request.method == 'OPTIONS':
        return '', 200

    city = (request.args.get('city') or 'ALL').strip()
    business = (request.args.get('business') or 'ALL').strip()

    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    try:
        results = get_happy_hours(conn, city, business)
        data = [sanitize_row(row) for row in results]
        return jsonify(data), 200
    except Exception as e:
        logger.exception(f"/happy_hours_business error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        try:
            conn.close()
        except Exception:
            pass


# ---- Business Registration Routes (BOTH prefixed and unprefixed) ----
@app.route('/happy-hours-api/business_registration', methods=['POST', 'OPTIONS'])
def business_registration_route_prefixed():
    """Business registration endpoint with /happy-hours-api/ prefix"""
    if request.method == 'OPTIONS':
        return '', 200
    return br_handler()


@app.route('/business_registration', methods=['POST', 'OPTIONS'])
def business_registration_route():
    """Business registration endpoint without prefix"""
    if request.method == 'OPTIONS':
        return '', 200
    return br_handler()


# ---- Business Login Routes ----
def handle_business_login():
    """Shared handler for business login logic"""
    if request.method == "OPTIONS":
        return ("", 204)
    
    if request.method == "GET":
        return jsonify({"ok": True, "message": "business_login endpoint is alive. Use POST with JSON."}), 200

    # POST logic
    data = request.get_json(silent=True) or {}
    email = data.get("email")
    password = data.get("password")
    
    if not email:
        return jsonify({"success": False, "message": "Email required"}), 400
    
    if not password:
        return jsonify({"success": False, "message": "Password required"}), 400

    # Hash the password using MD5
    import hashlib
    password_hash = hashlib.md5(password.encode('utf-8')).hexdigest()

    conn = get_db_connection()
    if not conn:
        return jsonify({"success": False, "message": "Database connection failed"}), 500

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT `Name` FROM `happy_hours_global_test` WHERE `email`=%s AND `password`=%s LIMIT 1",
                (email, password_hash)
            )
            row = cursor.fetchone()
        
        if row:
            return jsonify({
                "success": True,
                "message": "Login successful",
                "business_name": row["Name"]
            }), 200
        else:
            return jsonify({"success": False, "message": "Invalid email or password"}), 401

    except Exception as e:
        logger.exception(f"Business login error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    
    finally:
        try:
            conn.close()
        except Exception:
            pass


# Expose BOTH routes so either Nginx strategy works
@app.route("/happy-hours-api/business_login", methods=["GET", "POST", "OPTIONS"])
def business_login_prefixed():
    """Business login with /happy-hours-api/ prefix"""
    return handle_business_login()


@app.route("/business_login", methods=["GET", "POST", "OPTIONS"])
def business_login_unprefixed():
    """Business login without prefix (for Nginx rewrite)"""
    return handle_business_login()


# ---- Business Page Update & Fetch Routes ----
@app.route('/happy-hours-api/update_business', methods=['POST', 'OPTIONS'])
def update_business():
    """
    Save edited business HTML page to disk.
    Adds missing responsive/mobile-friendly styles to maintain consistent look.
    Expects JSON: { business_name: str, content_html: str, email?: str }
    """
    if request.method == 'OPTIONS':
        return '', 204

    data = request.get_json(silent=True) or {}
    business_name = (data.get('business_name') or '').strip()
    content_html = data.get('content_html')

    if not business_name or not content_html:
        return jsonify({
            "success": False,
            "message": "business_name and content_html are required"
        }), 400

    # ✅ Identify and inject responsive CSS if missing
    css_snippet = """
    html{scroll-behavior:smooth;scroll-padding-top:80px}
    @media (max-width:900px){
      .nav{flex-direction:column;align-items:center;gap:6px;padding:10px 0}
      .brand{font-size:16px;white-space:nowrap}
      .nav-links{font-size:13px;white-space:nowrap}
      .nav-links a{margin:0 4px}
      .hero-card{grid-template-columns:1fr}
      .grid{grid-template-columns:1fr}
      body{padding-top:85px}
      html{scroll-padding-top:95px}
    }
    """

    # Check if <style> section already has responsive code, otherwise inject it
    import re
    if "scroll-behavior:smooth" not in content_html or "@media (max-width:900px)" not in content_html:
        # Try to insert just before </style>
        content_html = re.sub(
            r"</style>",
            css_snippet + "\n</style>",
            content_html,
            flags=re.IGNORECASE
        )

    # Prepare file paths
    filename = secure_filename(f"{business_name}.html")
    store_path = os.path.join(STORE_DIR, filename)
    output_path = os.path.join(OUTPUT_DIR, filename)

    try:
        # 1) Save canonical copy
        with open(store_path, 'w', encoding='utf-8') as f:
            f.write(content_html)

        # 2) Copy it to web serving directory
        shutil.copy2(store_path, output_path)

        logger.info(f"✅ Saved business page with responsive styles: {filename}")
        return jsonify({
            "success": True,
            "message": "Updated successfully (responsive styles ensured)",
            "file": filename
        }), 200

    except Exception as e:
        logger.exception(f"Failed to save/deploy business page: {e}")
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500


@app.route('/happy-hours-api/page', methods=['GET', 'OPTIONS'])
def get_business_page():
    """
    Fetch saved business HTML page.
    Query params: ?business_name=Exact%20Name
    Returns the saved HTML if present; otherwise 404.
    """
    if request.method == 'OPTIONS':
        return '', 204
    
    business_name = (request.args.get('business_name') or '').strip()
    
    if not business_name:
        return jsonify({
            "success": False, 
            "message": "business_name query parameter is required"
        }), 400

    filename = secure_filename(f"{business_name}.html")
    saved_path = os.path.join(STORE_DIR, filename)
    
    if os.path.exists(saved_path):
        try:
            with open(saved_path, 'r', encoding='utf-8') as f:
                html_content = f.read()
            return html_content, 200, {'Content-Type': 'text/html; charset=utf-8'}
        except Exception as e:
            logger.exception(f"Failed to read business page: {e}")
            return jsonify({
                "success": False, 
                "message": str(e)
            }), 500
    else:
        return jsonify({
            "success": False, 
            "message": "Page not found"
        }), 404


@app.route('/happy-hours-api/get_business', methods=['POST', 'OPTIONS'])
def get_business_json():
    """
    Fetch saved business HTML from filesystem and return it directly as HTML.
    Request JSON: { "business_name": "Exact Name" }
    Returns: Raw HTML content (not JSON)
    """
    if request.method == 'OPTIONS':
        return '', 204

    data = request.get_json(silent=True) or {}
    business_name = (data.get('business_name') or '').strip()

    if not business_name:
        logger.warning("❌ get_business called without business_name")
        return jsonify({
            "success": False,
            "message": "business_name is required"
        }), 400

    filename = secure_filename(f"{business_name}.html")
    saved_path = os.path.join(STORE_DIR, filename)

    logger.info(f"🔍 Searching for: {saved_path}")

    if not os.path.exists(saved_path):
        logger.warning(f"❌ File not found: {saved_path}")
        # List available files for debugging
        try:
            available = os.listdir(STORE_DIR)
            logger.info(f"📁 Available files in STORE_DIR: {available[:10]}")
        except Exception as e:
            logger.error(f"❌ Can't list STORE_DIR: {str(e)}")
        
        return jsonify({
            "success": False,
            "message": f"Page not found for '{business_name}'"
        }), 404

    try:
        with open(saved_path, 'r', encoding='utf-8') as f:
            html_content = f.read()

        logger.info(f"✅ Serving HTML for: {business_name}")
        # Return raw HTML, not JSON
        return html_content, 200, {'Content-Type': 'text/html; charset=utf-8'}

    except Exception as e:
        logger.exception(f"Failed to read business page: {e}")
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500


@app.route('/happy-hours-api/delete_business', methods=['POST', 'OPTIONS'])
def delete_business():
    """
    Delete saved business HTML page from disk.
    Expects JSON: { business_name: str, email?: str }
    """
    if request.method == 'OPTIONS':
        return '', 204
    
    data = request.get_json(silent=True) or {}
    business_name = (data.get('business_name') or '').strip()
    
    if not business_name:
        return jsonify({
            "success": False, 
            "message": "business_name is required"
        }), 400

    filename = secure_filename(f"{business_name}.html")
    saved_path = os.path.join(STORE_DIR, filename)
    
    if os.path.exists(saved_path):
        try:
            os.remove(saved_path)
            logger.info(f"🗑️ Deleted business page: {filename}")
            return jsonify({
                "success": True, 
                "message": "Deleted successfully"
            }), 200
        except Exception as e:
            logger.exception(f"Failed to delete business page: {e}")
            return jsonify({
                "success": False, 
                "message": str(e)
            }), 500
    else:
        return jsonify({
            "success": False, 
            "message": "Page not found"
        }), 404


# ---- UNPREFIXED ALIASES (for Nginx trailing-slash proxy_pass) ----
# These allow requests rewritten from /happy-hours-api/... to /... to still match.

@app.route('/get_business', methods=['POST', 'OPTIONS'])
def get_business_json_unprefixed():
    return get_business_json()

@app.route('/update_business', methods=['POST', 'OPTIONS'])
def update_business_unprefixed():
    return update_business()

@app.route('/delete_business', methods=['POST', 'OPTIONS'])
def delete_business_unprefixed():
    return delete_business()


# Debug route to list all available routes (optional, remove in production)
@app.route("/__routes__", methods=["GET"])
def list_routes():
    """List all registered routes for debugging"""
    output = []
    for rule in app.url_map.iter_rules():
        methods = ",".join(sorted(rule.methods))
        output.append({
                "rule": str(rule),
                "methods": methods,
                "endpoint": rule.endpoint
        })
    return jsonify(output)


@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    # For development only
    print("Flask starting from:", __file__)
    app.run(host='0.0.0.0', port=5000, debug=True)