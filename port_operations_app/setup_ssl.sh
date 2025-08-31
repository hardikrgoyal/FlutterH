#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOMAIN="app.globalseatrans.com"

echo -e "${GREEN}🔒 Setting up SSL for $DOMAIN${NC}"

# Get SSL certificate
echo -e "${YELLOW}🔒 Obtaining SSL certificate...${NC}"
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@globalseatrans.com

# Update Nginx configuration to redirect HTTP to HTTPS
echo -e "${YELLOW}🌐 Updating Nginx configuration for HTTPS redirect...${NC}"
sudo tee /etc/nginx/sites-available/port-operations > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    client_max_body_size 100M;

    # Serve Flutter web app
    location / {
        root /var/www/port_operations/port_operations_app/frontend/build/web;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Django API
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Django admin
    location /admin/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Django static files
    location /static/ {
        alias /var/www/port_operations/port_operations_app/backend/staticfiles/;
    }

    # Django media files
    location /media/ {
        alias /var/www/port_operations/port_operations_app/backend/media/;
    }
}
EOF

# Restart Nginx
sudo systemctl restart nginx

# Create auto-renewal cron job for SSL
echo -e "${YELLOW}🔄 Setting up SSL auto-renewal...${NC}"
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

echo -e "${GREEN}✅ SSL setup completed successfully!${NC}"
echo -e "${GREEN}🌐 Your app should now be available at: https://$DOMAIN${NC}" 