# business_registration.py
from flask import request, jsonify
from werkzeug.utils import secure_filename
import pymysql
import requests
import smtplib
from email.mime.text import MIMEText
import os
import datetime
import secrets
import logging
import hashlib
import shutil

# ================== Config ==================
DB_HOST = "87.106.214.100"
DB_USER = "happyuser"
DB_PASS = "HappyUser@2025"
DB_NAME = "happy_hours_businesses"

# External services (best-effort)
TEXTBEE_URL = "http://192.168.0.100:8080/sms/send"
TEXTBEE_API_KEY = "1bccf6bf-4e98-4ad6-899d-2ce9f48d5234"

FROM_EMAIL = "no-reply@app.lovehappyhours.com"
SMTP_SERVER = "localhost"
SMTP_PORT = 25

VERIFY_LINK_BASE = "https://customercallsapp.com/prod/customercallsapp/verified.php"

# ✅ Image upload directory
BUSINESS_IMAGES_DIR = "/var/www/app.lovehappyhours.com/business_images"
os.makedirs(BUSINESS_IMAGES_DIR, exist_ok=True)

# ✅ Allowed image extensions (only jpg, jpeg, png)
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp', 'gif'}

# ✅ Write to BOTH locations to match API expectations
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
STORE_DIR = os.path.join(BASE_DIR, 'output_html_store')  # API reads from here
OUTPUT_DIR = "/var/www/app.lovehappyhours.com/alpha/output_html"  # Web serves from here

# Create both directories
os.makedirs(STORE_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ================== Logger ==================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("business_registration")

def logMessage(message: str):
    try:
        logFile = os.path.join(os.path.dirname(__file__), "debug_log.txt")
        with open(logFile, "a") as f:
            f.write(f"{datetime.datetime.now()} | {message}\n")
    except Exception:
        logger.info(message)

# Log paths at startup
logger.info(f"📁 BUSINESS_IMAGES_DIR => {BUSINESS_IMAGES_DIR}")
logger.info(f"📁 STORE_DIR => {STORE_DIR}")
logger.info(f"📁 OUTPUT_DIR => {OUTPUT_DIR}")

# ================== Helpers ==================
# ✅ Image file validation (only jpg, jpeg, png)
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def as_text(v, default=""):
    if v is None:
        return default
    return str(v).strip()

def none_if_empty(v):
    s = as_text(v, "")
    return None if s == "" else s

def to_int_yes_no(value):
    if value is None:
        return None
    v = as_text(value).lower()
    if v in ("yes", "y", "true", "1"):
        return 1
    if v in ("no", "n", "false", "0"):
        return 0
    try:
        return 1 if int(float(v)) != 0 else 0
    except Exception:
        return 0

def md5_hash(password: str) -> str:
    """Generate MD5 hash of password"""
    return hashlib.md5(password.encode('utf-8')).hexdigest()

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        charset="utf8mb4",
        autocommit=False,
    )

# ================== SMS Sender (best-effort) ==================
def sendSMS_TextBee(toPhone: str, textMessage: str) -> bool:
    try:
        payload = {"apikey": TEXTBEE_API_KEY, "to": toPhone, "message": textMessage}
        response = requests.post(TEXTBEE_URL, json=payload, timeout=20)
        if response.status_code == 200:
            logMessage(f"✅ SMS sent to {toPhone}: {response.text}")
            return True
        else:
            logMessage(f"❌ SMS send failed {response.status_code} {response.text}")
            return False
    except Exception as e:
        logMessage(f"❌ SMS send exception: {str(e)}")
        return False

# ================== Static Page Generator ==================
def generate_static_page(business_data, image_filename=None):
    """
    Generate a static HTML page for the business using the provided data.
    ✅ Uses secure_filename and writes to BOTH directories.
    ✅ Includes uploaded image if available
    """
    try:
        # Extract city with detailed logging
        city_raw = business_data.get('city', '')
        city = as_text(city_raw, 'City')  # Default to 'City' if empty
        
        logMessage(f"🔍 DEBUG - City extraction:")
        logMessage(f"   - Raw city value: '{city_raw}'")
        logMessage(f"   - Processed city value: '{city}'")
        
        # Extract other data with safe defaults
        business_name = as_text(business_data.get('businessName', ''), 'Business')
        description = as_text(business_data.get('description', ''), '')
        address = as_text(business_data.get('address', ''), '')
        state = as_text(business_data.get('state', ''), '')
        country = as_text(business_data.get('country', ''), '')
        category = as_text(business_data.get('category', ''), '')
        open_hours = as_text(business_data.get('open_hours', ''), '')
        happy_hour_start = as_text(business_data.get('happy_hour_start', ''), '')
        happy_hour_end = as_text(business_data.get('happy_hour_end', ''), '')
        phone = as_text(business_data.get('phone', ''), '')
        remark = as_text(business_data.get('remark', ''), '')
        latitude = as_text(business_data.get('latitude', ''), '')
        longitude = as_text(business_data.get('longitude', ''), '')
        happy_hours_id = as_text(business_data.get('happy_hours_id', ''), '')
        
        logMessage(f"🔍 DEBUG - Business data summary:")
        logMessage(f"   - Business Name: {business_name}")
        logMessage(f"   - City for Header: '{city} Happy Hours'")
        logMessage(f"   - State: {state}")
        logMessage(f"   - Category: {category}")
        
        # Build location string for chips
        location_parts = [city, state] if state else [city]
        location_str = ' • '.join(filter(None, location_parts))
        
        # Build full address
        full_address_parts = [address, city, state, country]
        full_address = ', '.join(filter(None, full_address_parts))
        
        # Build map query string
        from urllib.parse import quote
        map_query = quote(full_address) if full_address else f"{latitude},{longitude}" if latitude and longitude else ""
        
        # ✅ Image HTML construction
        image_html = ""
        if image_filename:
            image_url = f"https://app.lovehappyhours.com/business_images/{image_filename}"
            image_html = f'<img src="{image_url}" alt="{business_name}" class="hero-img" />'
            logMessage(f"✅ Image will be displayed: {image_url}")
        else:
            image_html = '<div class="hero-placeholder">Image Coming Soon</div>'
        
        # Log the header that will be generated
        header_text = f"{city} Happy Hours"
        logMessage(f"🎯 HEADER TEXT WILL BE: '{header_text}'")
        
        # Generate HTML content
        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{business_name} | {city}</title>
  <meta name="description" content="{business_name} in {city} — hours, happy hours, offers, photos, map, and contact details." />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root{{--card:#f9fafb;--muted:#6b7280;--brand-2:#12a56a;--shadow:0 2px 8px rgba(0,0,0,0.08);--radius:12px}}
    *{{box-sizing:border-box}}
    html,body{{height:100%}}
    body{{margin:0;font-family:Inter,system-ui,Arial;color:#1f2937;background:#fff;line-height:1.6;padding-top:68px}}
    a{{color:#2563eb;text-decoration:none}}
    .container{{width:min(1120px,92vw);margin:0 auto;padding:0 12px}}
    header{{position:fixed;top:0;left:0;right:0;z-index:999;background:#fff;border-bottom:1px solid #e5e7eb;box-shadow:0 2px 4px rgba(0,0,0,0.04)}}
    .nav{{display:flex;align-items:center;justify-content:space-between;padding:12px 0}}
    .brand{{font-weight:800}}
    .nav-links a{{color:var(--muted);margin:0 6px}}
    .nav-links a:hover{{text-decoration:underline}}
    .hero{{padding:48px 0}}
    .hero-card{{background:var(--card);border-radius:20px;padding:22px;display:grid;grid-template-columns:1.6fr 1fr;gap:18px;box-shadow:var(--shadow)}}
    .title{{font-size:clamp(28px,4vw,40px);margin:6px 0}}
    .sub{{color:var(--muted)}}
    .chip{{background:#eef2ff;border-radius:10px;padding:8px 10px;color:#4338ca;font-size:12px;margin-right:8px;display:inline-block}}
    .hero-img{{width:100%;height:100%;object-fit:cover;border-radius:12px}}
    .hero-placeholder{{width:100%;height:300px;background:#e5e7eb;border-radius:12px;display:flex;align-items:center;justify-content:center;color:var(--muted)}}
    .card{{background:var(--card);border-radius:var(--radius);padding:16px;box-shadow:var(--shadow);margin-bottom:14px}}
    .grid{{display:grid;grid-template-columns:1.1fr 1fr;gap:18px}}
    .list{{list-style:none;padding:0;margin:10px 0 0}}
    .muted{{color:var(--muted)}}
    .badge{{font-size:12px;padding:6px 8px;border-radius:8px;background:#dcfce7;color:#166534;border:1px solid #bbf7d0}}
    .hours-list{{list-style:none;padding:0;margin:10px 0 0}}
    .hours-row{{display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px dashed #e5e7eb}}
    .hours-row:last-child{{border-bottom:none}}
    .day{{font-weight:500}}
    .time{{margin-left:auto;text-align:right;color:#1f2937}}
    .gtk-list{{list-style:none;padding:0;margin:10px 0 0}}
    .gtk-item{{display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px dashed #e5e7eb}}
    .gtk-item:last-child{{border-bottom:none}}
    .gtk-label{{font-weight:600;white-space:nowrap;color:#1f2937}}
    .gtk-value{{color:#1f2937}}
    .map{{width:100%;height:280px;border:0;border-radius:12px}}
    footer{{color:var(--muted);padding:18px 0}}
    html{{scroll-behavior:smooth;scroll-padding-top:80px}}
    @media (max-width:900px){{
      .nav{{flex-direction:column;align-items:center;gap:6px;padding:10px 0}}
      .brand{{font-size:16px;white-space:nowrap}}
      .nav-links{{font-size:13px;white-space:nowrap}}
      .nav-links a{{margin:0 4px}}
      .hero-card{{grid-template-columns:1fr}}
      .grid{{grid-template-columns:1fr}}
      body{{padding-top:85px}}
      html{{scroll-padding-top:95px}}
    }}
  </style>
</head>
<body>
  <header>
    <div class="container nav">
      <div class="brand">{city} Happy Hours</div>
      <nav class="nav-links">
        <a href="#about">About</a> •
        <a href="#hours">Hours</a> •
        <a href="#happy">Happy Hour</a> •
        <a href="#contact">Contact</a>
      </nav>
    </div>
  </header>

  <main>
    <section class="hero">
      <div class="container hero-card">
        <div>
          <h1 class="title">{business_name}</h1>
          <p class="sub">{description if description else 'Welcome to our establishment'}</p>
          <div style="margin-top:12px">
            {f'<span class="chip">{location_str}</span>' if location_str else ''}
            {f'<span class="chip">Category: {category}</span>' if category else ''}
            {f'<span class="chip">Open: {open_hours}</span>' if open_hours else ''}
            {f'<span class="chip">Happy Hour: {happy_hour_start}–{happy_hour_end}</span>' if happy_hour_start and happy_hour_end else ''}
          </div>
        </div>
        <div class="hero-media">
          {image_html}
        </div>
      </div>
    </section>

    <section id="about" class="container grid">
      <article class="card">
        <h3>About</h3>
        <div>{description if description else 'Information coming soon.'}</div>
      </article>

      <aside id="hours" class="card">
        <h3>Opening Hours</h3>
        {f'<p>{open_hours}</p>' if open_hours else '<p class="muted">Hours information coming soon.</p>'}
        <p class="meta muted">Note: Hours may vary on holidays and during special events.</p>
      </aside>
    </section>

    {f'''<section id="happy" class="container grid">
      <article class="card">
        <h3>Happy Hour</h3>
        <ul class="list"><li class="hours-row"><span>Daily</span><span class="time" style="color:var(--brand-2);font-weight:700">{happy_hour_start} – {happy_hour_end}</span></li></ul>
      </article>

      <aside class="card">
        <h3>Special Notes</h3>
        <p>{remark if remark else 'Enjoy our happy hour specials!'}</p>
      </aside>
    </section>''' if happy_hour_start and happy_hour_end else ''}

    {f'''<section id="map" class="container" style="margin-top:14px">
      <div class="card">
        <h3>Location</h3>
        <p>{full_address}</p>
        <iframe class="map" loading="lazy" src="https://www.google.com/maps?q={map_query}&output=embed" allowfullscreen></iframe>
      </div>
    </section>''' if map_query else ''}

    <section id="contact" class="container" style="margin-top:14px">
      <div class="card">
        <h3>Contact</h3>
        {f'''<div style="margin-bottom:8px">
          <div class="muted">Phone: </div>
          <div><a href="tel:{phone.replace(" ", "")}">{phone}</a></div>
        </div>''' if phone else ''}
        
        {f'''<div class="muted" style="margin-top:8px">Address: </div>
        <div>{full_address}</div>''' if full_address else ''}
      </div>
    </section>

    {f'''<section class="container" style="margin-top:14px">
      <div class="card">
        <h3>Additional Information</h3>
        <ul class="gtk-list">
          <li class="gtk-item"><span class="gtk-label">Category: </span><span class="gtk-value">{category}</span></li>
          {f'<li class="gtk-item"><span class="gtk-label">Remarks: </span><span class="gtk-value">{remark}</span></li>' if remark else ''}
        </ul>
      </div>
    </section>''' if category or remark else ''}
  </main>

  <footer class="container">
    <div>© 2025 {city} Happy Hours • This is a static informational page.</div>
  </footer>
</body>
</html>"""

        # ✅ Use secure_filename to match API expectations
        filename = secure_filename(f"{business_name}.html")
        
        logMessage(f"📝 Generated filename: {filename}")
        
        # ✅ Write to BOTH locations
        store_path = os.path.join(STORE_DIR, filename)
        output_path = os.path.join(OUTPUT_DIR, filename)
        
        # Write to STORE_DIR (where API reads from)
        with open(store_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        logMessage(f"✅ File written to STORE_DIR: {store_path}")
        
        # Copy to OUTPUT_DIR (where web serves from)
        shutil.copy2(store_path, output_path)
        
        logMessage(f"✅ File copied to OUTPUT_DIR: {output_path}")
        logMessage(f"✅ Static page created in BOTH locations: {filename}")
        logMessage(f"🎯 FINAL CONFIRMATION - Header contains: '{city} Happy Hours'")
        
        # Verify file contents by reading first 500 chars
        try:
            with open(output_path, 'r', encoding='utf-8') as f:
                content_preview = f.read(1000)
                if f"{city} Happy Hours" in content_preview:
                    logMessage(f"✅ VERIFIED: City name '{city}' found in generated HTML header")
                else:
                    logMessage(f"⚠️ WARNING: City name '{city}' NOT found in generated HTML!")
                    logMessage(f"   Preview: {content_preview[:200]}")
        except Exception as e:
            logMessage(f"⚠️ Could not verify file contents: {str(e)}")
        
        return store_path, filename
        
    except Exception as e:
        logMessage(f"❌ Static page generation failed: {str(e)}")
        import traceback
        logMessage(traceback.format_exc())
        return None, None

# ================== Main Route Function ==================
def business_registration():
    logMessage("=" * 80)
    logMessage("🚀 NEW BUSINESS REGISTRATION REQUEST RECEIVED")
    
    # ✅ Log request details
    logMessage(f"📥 Request Method: {request.method}")
    logMessage(f"📥 Content-Type: {request.content_type}")
    logMessage(f"📥 Request Headers: {dict(request.headers)}")
    
    # ✅ Check what data we're receiving
    logMessage(f"📥 request.form keys: {list(request.form.keys())}")
    logMessage(f"📥 request.files keys: {list(request.files.keys())}")
    
    json_data = request.get_json(silent=True)
    logMessage(f"📥 request.get_json(silent=True): {json_data}")
    
    # ✅ Accept both JSON and form-data (for image upload)
    data = json_data or (request.form.to_dict() if request.form else {})
    
    logMessage(f"📥 Extracted data keys: {list(data.keys())}")
    logMessage(f"📥 POST data (without password): {str({k: v for k, v in data.items() if k != 'password'})}")

    # Extract and normalize inputs
    businessName     = as_text(data.get("businessName"))
    ownerName        = as_text(data.get("ownerName"))
    email            = as_text(data.get("email"))
    phone            = as_text(data.get("phone"))
    password         = as_text(data.get("password"))
    address          = as_text(data.get("address"))
    city             = as_text(data.get("city"))
    state            = as_text(data.get("state"))
    pin              = as_text(data.get("pin"))
    country          = as_text(data.get("country"))
    category         = as_text(data.get("category"))
    description      = as_text(data.get("description"))
    openHours        = as_text(data.get("open_hours"))
    happyHourStart   = as_text(data.get("happy_hour_start"))
    happyHourEnd     = as_text(data.get("happy_hour_end"))
    happyHourYesNo   = to_int_yes_no(data.get("happy_hour_yes_no", "0"))
    remark           = as_text(data.get("remark"))

    latitude_raw     = data.get("latitude")
    longitude_raw    = data.get("longitude")
    latitude         = none_if_empty(latitude_raw)
    longitude        = none_if_empty(longitude_raw)

    # ✅ New: Google Marker (Map Link)
    google_marker    = as_text(data.get("google_marker"))  # may be empty string

    logMessage(f"🔍 EXTRACTED VALUES:")
    logMessage(f"   - Business Name: '{businessName}'")
    logMessage(f"   - Owner Name: '{ownerName}'")
    logMessage(f"   - Email: '{email}'")
    logMessage(f"   - City: '{city}'")
    logMessage(f"   - State: '{state}'")
    logMessage(f"   - Category: '{category}'")
    logMessage(f"   - Password length: {len(password)}")
    logMessage(f"   - Google Marker: '{google_marker}'")  # ✅ log new field

    # Basic validation
    required = {
        "businessName": businessName,
        "ownerName": ownerName,
        "email": email,
        "password": password,
        "city": city,
        "category": category,
    }
    missing = [k for k, v in required.items() if not v]
    if missing:
        logMessage(f"❌ Validation failed - Missing fields: {missing}")
        return jsonify({"status": "error", "message": f"Missing required fields: {', '.join(missing)}"}), 400

    if len(password) < 6:
        logMessage(f"❌ Validation failed - Password too short")
        return jsonify({"status": "error", "message": "Password must be at least 6 characters"}), 400

    logMessage(f"✅ Validation passed")

    password_hash = md5_hash(password)

    happy_hours_id = secrets.token_hex(8)
    token          = secrets.token_hex(16)
    verified       = 0

    logMessage(f"🆔 Generated happy_hours_id: {happy_hours_id}")
    logMessage(f"🔑 Generated token: {token}")

    # ✅ Handle image upload - SAVE TO FOLDER with businessName as filename
    uploaded_image_filename = None
    image_link_for_db = None  # ADDED for image_link
    
    logMessage(f"📸 Checking for image upload...")
    logMessage(f"   - 'business_image' in request.files: {'business_image' in request.files}")
    
    if 'business_image' in request.files:
        file = request.files['business_image']
        logMessage(f"   - File object: {file}")
        logMessage(f"   - File filename: {file.filename}")
        logMessage(f"   - File content_type: {file.content_type if hasattr(file, 'content_type') else 'N/A'}")
        
        if file and file.filename:
            logMessage(f"   - File has filename: {file.filename}")
            
            if allowed_file(file.filename):
                logMessage(f"   - File extension is allowed")
                
                # Get file extension
                ext = file.filename.rsplit('.', 1)[1].lower()
                logMessage(f"   - Extension: {ext}")
                
                # ✅ Validate extension (only jpg, jpeg, png allowed)
                if ext not in ['jpg', 'jpeg', 'png']:
                    logMessage(f"❌ Invalid image extension: {ext}. Only jpg, jpeg, png allowed.")
                    return jsonify({"status": "error", "message": "Only JPG, JPEG, and PNG images are allowed"}), 400
                
                # ✅ Use businessName as filename (sanitized)
                safe_business_name = secure_filename(businessName)
                uploaded_image_filename = f"{safe_business_name}.{ext}"
                image_path = os.path.join(BUSINESS_IMAGES_DIR, uploaded_image_filename)
                
                logMessage(f"   - Safe business name: {safe_business_name}")
                logMessage(f"   - Image filename: {uploaded_image_filename}")
                logMessage(f"   - Full image path: {image_path}")
                logMessage(f"   - Directory exists: {os.path.exists(BUSINESS_IMAGES_DIR)}")
                logMessage(f"   - Directory writable: {os.access(BUSINESS_IMAGES_DIR, os.W_OK)}")
                
                try:
                    logMessage(f"   - Attempting to save file...")
                    file.save(image_path)
                    logMessage(f"✅ Image saved successfully to: {image_path}")
                    logMessage(f"   - File exists after save: {os.path.exists(image_path)}")
                    if os.path.exists(image_path):
                        logMessage(f"   - File size: {os.path.getsize(image_path)} bytes")
                    # ADDED for image_link: build full public URL for DB
                    image_link_for_db = f"https://app.lovehappyhours.com/business_images/{uploaded_image_filename}"
                    logMessage(f"   - Image link for DB: {image_link_for_db}")
                except Exception as e:
                    logMessage(f"❌ Image upload failed: {str(e)}")
                    import traceback
                    logMessage(traceback.format_exc())
                    uploaded_image_filename = None
                    image_link_for_db = None
            else:
                logMessage(f"   - File extension NOT allowed: {file.filename}")
        else:
            logMessage(f"   - File object has no filename")
    else:
        logMessage(f"ℹ️ No 'business_image' in request.files")

    logMessage(f"📸 Image upload result: {uploaded_image_filename or 'None'}")

    # ✅ Database INSERT (added Google_Marker column)
    # ADDED for image_link: append image_link column and value at the end
    sql = """
        INSERT INTO happy_hours_global_test
        (happy_hours_id, owner_name, email, password, Name, Description, Address, business_category, 
         city, country, Open_hours, Happy_hour_start, Happy_hour_end, Happy_hours_yes_no, 
         Telephone, Remark, latitude, longitude, token, verified, Google_Marker, image_link)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """

    params = (
        happy_hours_id,
        ownerName,
        email,
        password_hash,
        businessName,
        description,
        address,
        category,
        city,
        country,
        openHours,
        happyHourStart,
        happyHourEnd,
        happyHourYesNo,
        phone,
        remark,
        latitude,
        longitude,
        token,
        verified,
        google_marker,       # ✅ existing Google_Marker
        image_link_for_db    # ADDED for image_link (None if no image uploaded)
    )

    logMessage(f"💾 Attempting database insert...")
    logMessage(f"   - SQL: {sql}")
    logMessage(f"   - Params count: {len(params)}")
    logMessage(f"   - Params: {params}")

    try:
        logMessage(f"   - Connecting to database...")
        conn = get_db_connection()
        logMessage(f"   - Database connection successful")
        
        with conn:
            with conn.cursor() as cursor:
                # Check if email already exists
                logMessage(f"   - Checking if email exists: {email}")
                cursor.execute("SELECT email FROM happy_hours_global_test WHERE email = %s", (email,))
                existing = cursor.fetchone()
                
                if existing:
                    logMessage(f"❌ Registration failed - Email already exists: {email}")
                    return jsonify({"status": "error", "message": "Email already registered"}), 400
                
                logMessage(f"   - Email is unique, proceeding with insert")
                logMessage(f"   - Executing INSERT query...")
                cursor.execute(sql, params)
                logMessage(f"   - INSERT executed, rows affected: {cursor.rowcount}")
                
            logMessage(f"   - Committing transaction...")
            conn.commit()
            logMessage(f"   - Transaction committed successfully")

        logMessage(f"✅ Database insert successful for email: {email} (id={happy_hours_id})")

        # ✅ Generate static business page
        logMessage(f"📄 Starting static page generation...")
        business_data = {
            'happy_hours_id': happy_hours_id,
            'businessName': businessName,
            'description': description,
            'city': city,
            'state': state,
            'country': country,
            'address': address,
            'category': category,
            'open_hours': openHours,
            'happy_hour_start': happyHourStart,
            'happy_hour_end': happyHourEnd,
            'phone': phone,
            'remark': remark,
            'latitude': latitude,
            'longitude': longitude
        }
        
        filepath, filename = generate_static_page(business_data, uploaded_image_filename)
        
        if filepath:
            logMessage(f"✅ Page generation successful: {filename}")
        else:
            logMessage(f"⚠️ Page generation failed but registration succeeded")

        # Send verification email (best-effort)
        try:
            verifyLink = f"{VERIFY_LINK_BASE}?email={email}&token={token}"
            subject = "Verify Your Business Registration"
            message_body = f"Hi {ownerName},\n\nPlease verify your business registration by clicking:\n{verifyLink}\n\nThank you!"

            msg = MIMEText(message_body)
            msg["Subject"] = subject
            msg["From"] = FROM_EMAIL
            msg["To"] = email

            with smtplib.SMTP(SMTP_SERVER, SMTP_PORT, timeout=20) as server:
                server.sendmail(FROM_EMAIL, [email], msg.as_string())

            logMessage(f"✅ Verification email sent to {email}")

            # Send SMS via TextBee (best-effort)
            if phone:
                smsMessage = f"Hi {ownerName}! A verification email has been sent to {email}. Please check your inbox to activate your business registration."
                sendSMS_TextBee(phone, smsMessage)

        except Exception as e:
            logMessage(f"⚠️ Mail/SMS step failed for {email}: {str(e)}")

        logMessage(f"✅ Registration process completed successfully")
        logMessage(f"   - Database: ✅ Record inserted (Name={businessName})")
        logMessage(f"   - Image: {'✅ Saved as ' + uploaded_image_filename if uploaded_image_filename else '⚠️ No image'}")
        logMessage(f"   - Static page: {'✅ Created' if filepath else '⚠️ Failed'}")
        logMessage("=" * 80)

        return jsonify({
            "status": "success", 
            "message": "Business Registration Successful",
            "id": happy_hours_id,
            "page_created": filepath is not None,
            "filename": filename,
            "image_saved": uploaded_image_filename is not None,
            "image_filename": uploaded_image_filename,
            "image_path": f"{BUSINESS_IMAGES_DIR}/{uploaded_image_filename}" if uploaded_image_filename else None
        }), 200

    except Exception as e:
        logMessage(f"❌ DB insert failed: {repr(e)}")
        import traceback
        logMessage(traceback.format_exc())
        logMessage("=" * 80)
        return jsonify({"status": "error", "message": f"Database error: {str(e)}"}), 500