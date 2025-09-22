# business_registration.py
from flask import Flask, request, jsonify
import pymysql
import requests
import smtplib
from email.mime.text import MIMEText
import os
import datetime
import secrets

app = Flask(__name__)

# ================== Config ==================
DB_HOST = "mysql2-p2.ezhostingserver.com"
DB_USER = "sanjay"
DB_PASS = "BU@R9gr2971{"
DB_NAME = "interview_helper"

TEXTBEE_URL = "http://192.168.0.100:8080/sms/send"
TEXTBEE_API_KEY = "1bccf6bf-4e98-4ad6-899d-2ce9f48d5234"

FROM_EMAIL = "no-reply@customercallsapp.com"
SMTP_SERVER = "localhost"   # Change if using Gmail/other
SMTP_PORT = 25              # Change if needed

# ================== Logger ==================
def log_message(message):
    log_file = os.path.join(os.path.dirname(__file__), "debug_log.txt")
    with open(log_file, "a") as f:
        f.write(f"{datetime.datetime.now()} | {message}\n")

# ================== SMS Sender ==================
def send_sms_textbee(to_phone, text_message):
    try:
        payload = {
            "apikey": TEXTBEE_API_KEY,
            "to": to_phone,
            "message": text_message
        }
        response = requests.post(TEXTBEE_URL, json=payload, timeout=20)
        if response.status_code == 200:
            log_message(f"✅ SMS sent to {to_phone}: {response.text}")
            return True
        else:
            log_message(f"❌ SMS send failed {response.status_code} {response.text}")
            return False
    except Exception as e:
        log_message(f"❌ SMS send exception: {str(e)}")
        return False

# ================== Email Sender ==================
def send_verification_email(email, owner_name, token):
    try:
        verify_link = f"https://customercallsapp.com/prod/customercallsapp/verify.php?email={email}&token={token}"
        subject = "Verify Your Business Registration"
        body = f"Hi {owner_name},\n\nPlease verify your business registration by clicking:\n{verify_link}\n\nThank you!"

        msg = MIMEText(body)
        msg["Subject"] = subject
        msg["From"] = FROM_EMAIL
        msg["To"] = email

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.sendmail(FROM_EMAIL, [email], msg.as_string())

        log_message(f"Mail sent to {email}")
        return True
    except Exception as e:
        log_message(f"Mail failed to {email} - {str(e)}")
        return False

# ================== API Endpoint ==================
@app.route("/business_registration", methods=["POST"])
def register_business():
    data = request.form if request.form else request.json

    log_message("POST data: " + str(data))

    businessName   = data.get("businessName", "")
    ownerName      = data.get("ownerName", "")
    email          = data.get("email", "")
    phone          = data.get("phone", "")
    address        = data.get("address", "")
    city           = data.get("city", "")
    country        = data.get("country", "")
    pin            = data.get("pin", "")
    category       = data.get("category", "")
    description    = data.get("description", "")
    openHours      = data.get("open_hours", "")
    happyHourStart = data.get("happy_hour_start", "")
    happyHourEnd   = data.get("happy_hour_end", "")
    happyHourYesNo = data.get("happy_hour_yes_no", "No")
    remark         = data.get("remark", "")
    latitude       = data.get("latitude", "")
    longitude      = data.get("longitude", "")

    token = secrets.token_hex(16)
    uniqID = secrets.token_hex(8)
    verified = 0

    try:
        conn = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME)
        cursor = conn.cursor()

        sql = """INSERT INTO happy_hours_global_test
            (happy_hours_id, owner_name, email, Name, Description, Address, business_category, city, country,
            Open_hours, Happy_hour_start, Happy_hour_end, Happy_hours_yes_no, Telephone, Remark, latitude, longitude, token, verified)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"""

        cursor.execute(sql, (
            uniqID, ownerName, email, businessName, description, address, category, city, country,
            openHours, happyHourStart, happyHourEnd, happyHourYesNo, phone, remark, latitude, longitude, token, verified
        ))

        conn.commit()
        cursor.close()
        conn.close()

        log_message(f"Insert successful for email: {email}")

        if send_verification_email(email, ownerName, token):
            sms_message = f"Hi {ownerName}! A verification email has been sent to {email}. Please check your inbox."
            send_sms_textbee(phone, sms_message)

        return jsonify({"status": "success", "message": "Business registered successfully. Verification email & SMS sent."})

    except Exception as e:
        log_message(f"DB insert failed: {str(e)}")
        return jsonify({"status": "error", "message": "DB insert failed."})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
