#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="app.globalseatrans.com"
APP_DIR="/var/www/port_operations"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"

echo -e "${GREEN}🚀 Starting deployment for Port Operations App${NC}"

# Update system packages
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Install required packages
echo -e "${YELLOW}📦 Installing required packages...${NC}"
sudo apt install -y nginx postgresql postgresql-contrib python3-pip python3-venv git curl snapd

# Install Flutter
echo -e "${YELLOW}📱 Installing Flutter...${NC}"
if [ ! -d "/opt/flutter" ]; then
    sudo snap install flutter --classic
    echo 'export PATH="$PATH:/snap/flutter/current/bin"' >> ~/.bashrc
    source ~/.bashrc
fi

# Install Node.js for web build tools
echo -e "${YELLOW}📦 Installing Node.js...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Create app directory
echo -e "${YELLOW}📁 Creating application directory...${NC}"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Clone the repository
echo -e "${YELLOW}📥 Cloning repository...${NC}"
if [ -d "$APP_DIR/.git" ]; then
    cd $APP_DIR && git pull origin main
else
    git clone https://github.com/hardikrgoyal/FlutterH.git $APP_DIR
    cd $APP_DIR
fi

# Setup PostgreSQL
echo -e "${YELLOW}🗄️ Setting up PostgreSQL...${NC}"
sudo -u postgres psql -c "CREATE DATABASE port_operations_db;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER port_user WITH PASSWORD 'secure_db_password_123';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE port_operations_db TO port_user;" 2>/dev/null || echo "Privileges already granted"

# Setup Python virtual environment
echo -e "${YELLOW}🐍 Setting up Python environment...${NC}"
cd $BACKEND_DIR
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Copy production environment file
cp ../production.env .env

# Generate Django secret key
echo -e "${YELLOW}🔐 Generating Django secret key...${NC}"
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
sed -i "s/your-super-secret-production-key-change-this/$SECRET_KEY/" .env

# Update Django settings for production
echo -e "${YELLOW}⚙️ Configuring Django for production...${NC}"
python manage.py collectstatic --noinput
python manage.py migrate

# Create Django superuser (optional)
echo -e "${YELLOW}👤 Creating Django superuser...${NC}"
echo "from authentication.models import User; User.objects.filter(email='admin@globalseatrans.com').exists() or User.objects.create_superuser('admin@globalseatrans.com', 'admin123')" | python manage.py shell

# Build Flutter web app
echo -e "${YELLOW}🌐 Building Flutter web application...${NC}"
cd $FRONTEND_DIR

# Update API base URL for production
sed -i "s|http://10.0.2.2:8001/api|https://$DOMAIN/api|g" lib/core/constants/app_constants.dart

flutter pub get
flutter build web --release

# Create Gunicorn service
echo -e "${YELLOW}🔧 Creating Gunicorn service...${NC}"
sudo tee /etc/systemd/system/port-operations.service > /dev/null <<EOF
[Unit]
Description=Port Operations Django App
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$BACKEND_DIR
Environment="PATH=$BACKEND_DIR/venv/bin"
ExecStart=$BACKEND_DIR/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8001 port_operations_backend.wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Install Gunicorn
cd $BACKEND_DIR
source venv/bin/activate
pip install gunicorn

# Create Nginx configuration
echo -e "${YELLOW}🌐 Creating Nginx configuration...${NC}"
sudo tee $NGINX_AVAILABLE/port-operations > /dev/null <<EOF
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
        root $FRONTEND_DIR/build/web;
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
        alias $BACKEND_DIR/staticfiles/;
    }

    # Django media files
    location /media/ {
        alias $BACKEND_DIR/media/;
    }
}
EOF

# Enable the site
sudo ln -sf $NGINX_AVAILABLE/port-operations $NGINX_ENABLED/
sudo rm -f $NGINX_ENABLED/default

# Install Certbot for SSL
echo -e "${YELLOW}🔒 Installing Certbot for SSL...${NC}"
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

# Get SSL certificate
echo -e "${YELLOW}🔒 Obtaining SSL certificate...${NC}"
sudo certbot certonly --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@globalseatrans.com || echo "SSL certificate already exists or failed to obtain"

# Start and enable services
echo -e "${YELLOW}🚀 Starting services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable port-operations
sudo systemctl start port-operations
sudo systemctl enable nginx
sudo systemctl restart nginx

# Create auto-renewal cron job for SSL
echo -e "${YELLOW}🔄 Setting up SSL auto-renewal...${NC}"
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Your app should now be available at: https://$DOMAIN${NC}"
echo -e "${GREEN}🔧 Django admin: https://$DOMAIN/admin${NC}"
echo -e "${GREEN}📱 API endpoints: https://$DOMAIN/api${NC}"
echo ""
echo -e "${YELLOW}📋 Useful commands:${NC}"
echo -e "  View backend logs: sudo journalctl -u port-operations -f"
echo -e "  Restart backend: sudo systemctl restart port-operations"
echo -e "  Restart nginx: sudo systemctl restart nginx"
echo -e "  Check SSL certificate: sudo certbot certificates" 