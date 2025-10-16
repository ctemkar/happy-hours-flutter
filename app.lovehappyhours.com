#---------------------------------
#HTTPS server (Flutter Web + Flask API proxy)
#---------------------------------
server {
server_name app.lovehappyhours.com;

# Flutter Web root
root /var/www/app.lovehappyhours.com;
index index.html;

# ACME challenge (allow over HTTPS; avoids SPA rewrites on challenge paths)
location ^~ /.well-known/acme-challenge/ {
    default_type "text/plain";
    alias /var/www/app.lovehappyhours.com/.well-known/acme-challenge/;
    try_files $uri =404;
}

# ==============================
# Flask API (prefix: /happy-hours-api/)
# Example public URL:
#   https://app.lovehappyhours.com/happy-hours-api/happy_hours_business?city=Bangkok&business=ALL
# This forwards to Flask as:
#   http://127.0.0.1:5000/happy_hours_business?city=Bangkok&business=ALL
# ==============================
location /happy-hours-api/ {
    # IMPORTANT: trailing slash strips the prefix and forwards remaining path.
    proxy_pass http://127.0.0.1:5000/;

    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Timeouts (tune as needed)
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # CORS (Flask CORS should also handle this; leaving here as belt-and-suspenders)
    add_header Access-Control-Allow-Origin * always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;

    # Preflight
    if ($request_method = OPTIONS) {
        return 204;
    }

    # Debug header (remove after verification)
    add_header X-Debug-Api-Block "api-prefix-pass" always;
}

# OPTIONAL: direct, no-prefix API path for compatibility
# Public URL:
#   https://app.lovehappyhours.com/happy_hours_business?city=Bangkok&business=ALL
location = /happy_hours_business {
    proxy_pass http://127.0.0.1:5000/happy_hours_business;

    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    add_header Access-Control-Allow-Origin * always;
    add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;

    if ($request_method = OPTIONS) {
        return 204;
    }

    add_header X-Debug-Api-Block "api-direct-pass" always;
}

# Flutter Web SPA routing (serve index.html for unknown non-API routes)
# Keep this AFTER the API locations so API paths don’t fall through.
location / {
    try_files $uri $uri/ /index.html;
}

# Static file caching
location ~* \.(?:js|css|png|jpg|jpeg|gif|svg|ico|webp|woff2?)$ {
    expires 7d;
    add_header Cache-Control "public, no-transform";
    try_files $uri =404;
}

# gzip
gzip on;
gzip_types text/plain text/css application/javascript application/json image/svg+xml;
gzip_min_length 256;

# SSL (managed by Certbot)
listen [::]:443 ssl ipv6only=on; # managed by Certbot
listen 443 ssl;                  # managed by Certbot
ssl_certificate /etc/letsencrypt/live/app.lovehappyhours.com/fullchain.pem;    # managed by Certbot
ssl_certificate_key /etc/letsencrypt/live/app.lovehappyhours.com/privkey.pem;  # managed by Certbot
include /etc/letsencrypt/options-ssl-nginx.conf;                               # managed by Certbot
ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;                                 # managed by Certbot
}

#---------------------------------
#HTTP -> HTTPS redirect + ACME challenge passthrough
#---------------------------------
server {
listen 80;
listen [::]:80;
server_name app.lovehappyhours.com;

# Serve ACME challenges on HTTP (do not redirect these)
location ^~ /.well-known/acme-challenge/ {
    default_type "text/plain";
    alias /var/www/app.lovehappyhours.com/.well-known/acme-challenge/;
    try_files $uri =404;
}

# Redirect everything else to HTTPS
return 301 https://$host$request_uri;
}