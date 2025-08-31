#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Updating local repository and deploying to VM...${NC}"

# Add all changes and commit
echo -e "${YELLOW}📝 Committing local changes...${NC}"
git add .
git commit -m "Update for production deployment - $(date)" || echo "No changes to commit"

# Push to GitHub
echo -e "${YELLOW}📤 Pushing to GitHub...${NC}"
git push origin main

# Make deployment script executable
chmod +x deploy.sh

# Copy files to VM and execute deployment
echo -e "${YELLOW}🚀 Deploying to VM...${NC}"
scp deploy.sh production.env brendan_athlytic_io@34.93.231.230:~/

# SSH to VM and run deployment
ssh brendan_athlytic_io@34.93.231.230 << 'EOF'
chmod +x ~/deploy.sh
sudo ~/deploy.sh
EOF

echo -e "${GREEN}✅ Deployment completed! Your app should be available at: https://app.globalseatrans.com${NC}" 