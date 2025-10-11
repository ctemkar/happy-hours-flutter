# ---------------------------------
# HTTPS server (Flutter Web + Flask API proxy)
# ---------------------------------
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

    # Flutter Web SPA routing (serve index.html for unknown routes)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy the Flask API under a clean path prefix
    # Client call example:
    #   https://app.lovehappyhours.com/happy-hours-api/business_login
    # Flask route example:
    #   @app.route("/happy-hours-api/business_login", methods=["POST","OPTIONS","GET"])
    location /happy-hours-api/ {
    	# Strip the /happy-hours-api/ prefix so:
    	#   /happy-hours-api/business_login -> /business_login (Flask)
    	rewrite ^/happy-hours-api/(.*)$ /$1 break;

    	proxy_pass http://127.0.0.1:5000;

    	proxy_http_version 1.1;
    	proxy_set_header Host $host;
    	proxy_set_header X-Real-IP $remote_addr;
    	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    	proxy_set_header X-Forwarded-Proto $scheme;

    	# Optional timeouts
    	proxy_connect_timeout 60s;
    	proxy_send_timeout 60s;
    	proxy_read_timeout 60s;

    	# Optional: debug header to verify this block is used
    	# remove after testing
    	add_header X-Debug-Api-Block "strip-prefix" always;
    }
    # Optional static file caching
    location ~* \.(?:js|css|png|jpg|jpeg|gif|svg|ico|webp|woff2?)$ {
        expires 7d;
        add_header Cache-Control "public, no-transform";
        try_files $uri =404;
    }

    # Optional gzip
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

# ---------------------------------
# HTTP -> HTTPS redirect + ACME challenge passthrough
# ---------------------------------
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