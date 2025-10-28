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

# ✅ FIXED: Write to BOTH locations to match API expectations
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
logger.info(f"📁 STORE_DIR => {STORE_DIR}")
logger.info(f"📁 OUTPUT_DIR => {OUTPUT_DIR}")

# ================== Helpers ==================
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
def generate_static_page(business_data):
    """
    Generate a static HTML page for the business using the provided data.
    ✅ FIXED: Uses secure_filename and writes to BOTH directories.
    """
    try:
        # Extract data with safe defaults
        business_name = as_text(business_data.get('businessName', ''), 'Business')
        description = as_text(business_data.get('description', ''), '')
        city = as_text(business_data.get('city', ''), '')
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
        
        # Build location string for chips
        location_parts = [city, state] if state else [city]
        location_str = ' • '.join(filter(None, location_parts))
        
        # Build full address
        full_address_parts = [address, city, state, country]
        full_address = ', '.join(filter(None, full_address_parts))
        
        # Build map query string
        from urllib.parse import quote
        map_query = quote(full_address) if full_address else f"{latitude},{longitude}" if latitude and longitude else ""
        
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
          <div class="hero-placeholder">Image Coming Soon</div>
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

        # ✅ FIXED: Use secure_filename to match API expectations
        filename = secure_filename(f"{business_name}.html")
        
        # ✅ FIXED: Write to BOTH locations
        store_path = os.path.join(STORE_DIR, filename)
        output_path = os.path.join(OUTPUT_DIR, filename)
        
        # Write to STORE_DIR (where API reads from)
        with open(store_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        # Copy to OUTPUT_DIR (where web serves from)
        shutil.copy2(store_path, output_path)
        
        logMessage(f"✅ Static page created in BOTH locations: {filename}")
        logMessage(f"   - STORE: {store_path}")
        logMessage(f"   - WEB: {output_path}")
        
        return store_path, filename
        
    except Exception as e:
        logMessage(f"❌ Static page generation failed: {str(e)}")
        import traceback
        logMessage(traceback.format_exc())
        return None, None

# ================== Main Route Function ==================
def business_registration():
    # Accept JSON or form-encoded
    data = request.get_json(silent=True) or (request.form.to_dict() if request.form else {})
    logMessage("POST data: " + str({k: v for k, v in data.items() if k != 'password'}))

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
    happyHourYesNo   = to_int_yes_no(data.get("happy_hour_yes_no", "No"))
    remark           = as_text(data.get("remark"))

    latitude_raw     = data.get("latitude")
    longitude_raw    = data.get("longitude")
    latitude         = none_if_empty(latitude_raw)
    longitude        = none_if_empty(longitude_raw)

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
        return jsonify({"status": "error", "message": f"Missing required fields: {', '.join(missing)}"}), 400

    if len(password) < 6:
        return jsonify({"status": "error", "message": "Password must be at least 6 characters"}), 400

    password_hash = md5_hash(password)

    happy_hours_id = secrets.token_hex(8)
    token          = secrets.token_hex(16)
    verified       = 0

    sql = """
        INSERT INTO happy_hours_global_test
        (happy_hours_id, owner_name, email, password, Name, Description, Address, business_category, city, country, Open_hours,
         Happy_hour_start, Happy_hour_end, Happy_hours_yes_no, Telephone, Remark, latitude, longitude, token, verified)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
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
        verified
    )

    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cursor:
                # Check if email already exists
                cursor.execute("SELECT email FROM happy_hours_global_test WHERE email = %s", (email,))
                if cursor.fetchone():
                    return jsonify({"status": "error", "message": "Email already registered"}), 400
                
                cursor.execute(sql, params)
            conn.commit()

        logMessage(f"✅ Insert successful for email: {email} (id={happy_hours_id})")

        # ✅ Generate static business page with all data including state
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
        
        filepath, filename = generate_static_page(business_data)
        
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

            logMessage(f"✅ Mail sent to {email}")

            # Send SMS via TextBee (best-effort)
            if phone:
                smsMessage = f"Hi {ownerName}! A verification email has been sent to {email}. Please check your inbox to activate your business registration."
                sendSMS_TextBee(phone, smsMessage)

        except Exception as e:
            logMessage(f"⚠️ Mail/SMS step failed for {email}: {str(e)}")

        return jsonify({
            "status": "success", 
            "message": "Business registered successfully. Verification email & SMS sent.", 
            "id": happy_hours_id,
            "page_created": filepath is not None,
            "filename": filename
        }), 200

    except Exception as e:
        logMessage(f"❌ DB insert failed: {repr(e)}")
        import traceback
        logMessage(traceback.format_exc())
        return jsonify({"status": "error", "message": f"DB insert failed: {str(e)}"}), 500