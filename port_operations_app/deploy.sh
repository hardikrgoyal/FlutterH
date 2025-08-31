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
BACKEND_DIR="$APP_DIR/port_operations_app/backend"
FRONTEND_DIR="$APP_DIR/port_operations_app/frontend"
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
if ! command -v flutter &> /dev/null; then
    sudo snap install flutter --classic
    echo 'export PATH="$PATH:/snap/flutter/current/bin"' >> ~/.bashrc
    source ~/.bashrc
else
    echo "Flutter already installed"
fi

# Install Node.js for web build tools
echo -e "${YELLOW}📦 Installing Node.js...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js already installed"
fi

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
sudo -u postgres psql -c "ALTER USER port_user CREATEDB;" 2>/dev/null || echo "CREATEDB privilege already granted"

# Grant schema permissions
sudo -u postgres psql -d port_operations_db -c "GRANT ALL ON SCHEMA public TO port_user;" 2>/dev/null || echo "Schema permissions already granted"
sudo -u postgres psql -d port_operations_db -c "GRANT CREATE ON SCHEMA public TO port_user;" 2>/dev/null || echo "CREATE permissions already granted"

# For PostgreSQL 15+, grant additional permissions
sudo -u postgres psql -d port_operations_db -c "GRANT CREATE ON DATABASE port_operations_db TO port_user;" 2>/dev/null || echo "Database CREATE permissions already granted"

# Setup Python virtual environment
echo -e "${YELLOW}🐍 Setting up Python environment...${NC}"
cd $BACKEND_DIR

# Remove existing venv if it exists
if [ -d "venv" ]; then
    rm -rf venv
fi

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Copy production environment file
if [ -f "$APP_DIR/port_operations_app/production.env" ]; then
    cp $APP_DIR/port_operations_app/production.env .env
else
    echo -e "${RED}Error: production.env file not found at $APP_DIR/port_operations_app/production.env${NC}"
    echo -e "${YELLOW}Creating basic .env file...${NC}"
    cat > .env << EOF
SECRET_KEY=your-super-secret-production-key-change-this
DEBUG=False
ALLOWED_HOSTS=app.globalseatrans.com,34.93.231.230,localhost,127.0.0.1

# Database Configuration for PostgreSQL
DATABASE_ENGINE=django.db.backends.postgresql
DATABASE_NAME=port_operations_db
DATABASE_USER=port_user
DATABASE_PASSWORD=secure_db_password_123
DATABASE_HOST=localhost
DATABASE_PORT=5432

# CORS Settings for production
CORS_ALLOWED_ORIGINS=https://app.globalseatrans.com,http://app.globalseatrans.com
EOF
fi

# Generate Django secret key
echo -e "${YELLOW}🔐 Generating Django secret key...${NC}"
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
sed -i "s/your-super-secret-production-key-change-this/$SECRET_KEY/" .env

# Update Django settings for production
echo -e "${YELLOW}⚙️ Configuring Django for production...${NC}"
python manage.py collectstatic --noinput

# Try PostgreSQL migration first, fallback to SQLite if it fails
echo -e "${YELLOW}📊 Running database migrations...${NC}"
if ! python manage.py migrate; then
    echo -e "${YELLOW}⚠️ PostgreSQL migration failed, falling back to SQLite...${NC}"
    # Update .env to use SQLite
    sed -i 's/DATABASE_ENGINE=django.db.backends.postgresql/DATABASE_ENGINE=sqlite/' .env
    python manage.py migrate
fi

# Create Django superuser (optional)
echo -e "${YELLOW}👤 Creating Django superuser...${NC}"
echo "from authentication.models import User; User.objects.filter(email='admin@globalseatrans.com').exists() or User.objects.create_superuser('admin@globalseatrans.com', 'admin123')" | python manage.py shell

# Install Gunicorn
pip install gunicorn

# Build Flutter web app
echo -e "${YELLOW}🌐 Building Flutter web application...${NC}"
cd $FRONTEND_DIR

# Update API base URL for production - use a more specific replacement
sed -i "s|static const String devBaseUrl = 'http://10.0.2.2:8001/api';|static const String devBaseUrl = 'https://$DOMAIN/api';|g" lib/core/constants/app_constants.dart

# Ensure Flutter is in PATH
export PATH="$PATH:/snap/flutter/current/bin"
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

# Create Nginx configuration
echo -e "${YELLOW}🌐 Creating Nginx configuration...${NC}"
sudo tee $NGINX_AVAILABLE/port-operations > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # For now, serve HTTP until SSL is configured
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

# Start and enable services
echo -e "${YELLOW}🚀 Starting services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable port-operations
sudo systemctl start port-operations
sudo systemctl enable nginx
sudo systemctl restart nginx

# Install Certbot for SSL (skip for now to get basic setup working)
echo -e "${YELLOW}🔒 Installing Certbot for SSL...${NC}"
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

echo -e "${GREEN}✅ Basic deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Your app should now be available at: http://$DOMAIN${NC}"
echo -e "${GREEN}🔧 Django admin: http://$DOMAIN/admin${NC}"
echo -e "${GREEN}📱 API endpoints: http://$DOMAIN/api${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "  1. Test the app at http://$DOMAIN"
echo -e "  2. If working, run: sudo certbot --nginx -d $DOMAIN"
echo -e "  3. Update Nginx config to redirect HTTP to HTTPS"
echo ""
echo -e "${YELLOW}📋 Useful commands:${NC}"
echo -e "  View backend logs: sudo journalctl -u port-operations -f"
echo -e "  Restart backend: sudo systemctl restart port-operations"
echo -e "  Restart nginx: sudo systemctl restart nginx"
echo -e "  Check SSL certificate: sudo certbot certificates" 