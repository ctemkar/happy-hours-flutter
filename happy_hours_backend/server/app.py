from flask import Flask, request
from flask_cors import CORS

# Import the route function from business_registration.py
from business_registration import business_registration

app = Flask(__name__)

# Enable CORS for all origins (temporary for debugging)
CORS(app, resources={r"/*": {"origins": "*"}})

# Log every incoming request
@app.before_request
def log_request():
    print("\n--- Incoming Request ---")
    print(f"Method: {request.method}")
    print(f"Path: {request.path}")
    print(f"Headers: {dict(request.headers)}")
    if request.data:
        print(f"Body: {request.data.decode('utf-8')}")

# Register the /business_registration route
app.add_url_rule(
    '/business_registration',
    view_func=business_registration,
    methods=['POST']
)

if __name__ == "__main__":
    # Run Flask on all network interfaces at port 5000 with debug enabled
    app.run(host="0.0.0.0", port=5000, debug=True)
