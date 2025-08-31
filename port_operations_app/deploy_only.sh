#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying latest changes to VM...${NC}"

# Make deployment script executable
chmod +x deploy.sh

# Copy files to VM and execute deployment
echo -e "${YELLOW}📤 Copying deployment files to VM...${NC}"
scp deploy.sh production.env brendan_athlytic_io@34.93.231.230:~/

# SSH to VM and run deployment
echo -e "${YELLOW}🔄 Executing deployment on VM...${NC}"
ssh brendan_athlytic_io@34.93.231.230 << 'EOF'
chmod +x ~/deploy.sh
sudo ~/deploy.sh
EOF

echo -e "${GREEN}✅ Deployment completed! Your changes are live at: https://app.globalseatrans.com${NC}" 