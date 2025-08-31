# Port Operations App - Deployment Guide

This guide covers the deployment of the Port Operations App to your production server at `app.globalseatrans.com`.

## 🏗️ Architecture Overview

The application consists of:
- **Frontend**: Flutter Web Application (served by Nginx)
- **Backend**: Django REST API (served by Gunicorn)
- **Database**: PostgreSQL
- **Web Server**: Nginx (with SSL/TLS)
- **Process Manager**: Systemd

## 🚀 Quick Deployment

### Prerequisites
- VM with Ubuntu 20.04+ at IP: 34.93.231.230
- Domain `app.globalseatrans.com` pointing to the VM IP
- SSH access: `ssh brendan_athlytic_io@34.93.231.230`

### One-Click Deployment
```bash
# From your local machine
./update_and_deploy.sh
```

This script will:
1. Commit and push your changes to GitHub
2. Copy deployment files to the VM
3. Execute the full deployment process
4. Configure SSL certificates
5. Start all services

## 📋 Manual Deployment Steps

If you prefer to deploy manually:

### 1. Prepare Local Environment
```bash
# Make scripts executable
chmod +x deploy.sh update_and_deploy.sh

# Review configuration
cat production.env
```

### 2. Copy Files to VM
```bash
scp deploy.sh production.env brendan_athlytic_io@34.93.231.230:~/
```

### 3. Execute Deployment on VM
```bash
ssh brendan_athlytic_io@34.93.231.230
chmod +x ~/deploy.sh
sudo ~/deploy.sh
```

## 🔧 Configuration Details

### Environment Variables (`production.env`)
```bash
SECRET_KEY=your-super-secret-production-key-change-this
DEBUG=False
ALLOWED_HOSTS=app.globalseatrans.com,34.93.231.230,localhost,127.0.0.1
DATABASE_ENGINE=django.db.backends.postgresql
DATABASE_NAME=port_operations_db
DATABASE_USER=port_user
DATABASE_PASSWORD=secure_db_password_123
DATABASE_HOST=localhost
DATABASE_PORT=5432
CORS_ALLOWED_ORIGINS=https://app.globalseatrans.com,http://app.globalseatrans.com
```

### Nginx Configuration
- **HTTP**: Redirects to HTTPS
- **HTTPS**: Serves Flutter web app and proxies API requests
- **SSL**: Let's Encrypt certificates with auto-renewal

### Systemd Service
- **Service Name**: `port-operations`
- **User**: `brendan_athlytic_io`
- **Workers**: 3 Gunicorn workers
- **Bind**: `127.0.0.1:8001`

## 📱 Application URLs

After deployment, your app will be available at:

- **Main App**: https://app.globalseatrans.com
- **Django Admin**: https://app.globalseatrans.com/admin
- **API Endpoints**: https://app.globalseatrans.com/api
- **API Documentation**: https://app.globalseatrans.com/api/docs (if configured)

## 👤 Default Admin User

The deployment script creates a default admin user:
- **Email**: admin@globalseatrans.com
- **Password**: admin123

**⚠️ IMPORTANT**: Change this password immediately after first login!

## 🛠️ Management Commands

### Service Management
```bash
# View backend logs
sudo journalctl -u port-operations -f

# Restart backend
sudo systemctl restart port-operations

# Restart Nginx
sudo systemctl restart nginx

# Check service status
sudo systemctl status port-operations
sudo systemctl status nginx
```

### Database Management
```bash
# Access PostgreSQL
sudo -u postgres psql port_operations_db

# Django migrations
cd /var/www/port_operations/backend
source venv/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
```

### SSL Certificate Management
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates manually
sudo certbot renew

# Test renewal process
sudo certbot renew --dry-run
```

## 🔄 Updates and Maintenance

### Code Updates
```bash
# From local machine
./update_and_deploy.sh

# Or manually on VM
cd /var/www/port_operations
git pull origin main
sudo systemctl restart port-operations
sudo systemctl reload nginx
```

### Database Backups
```bash
# Create backup
sudo -u postgres pg_dump port_operations_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
sudo -u postgres psql port_operations_db < backup_file.sql
```

### Log Monitoring
```bash
# Backend application logs
sudo journalctl -u port-operations -f

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

## 🔒 Security Considerations

### Firewall Configuration
```bash
# Allow required ports
sudo ufw allow 22      # SSH
sudo ufw allow 80      # HTTP
sudo ufw allow 443     # HTTPS
sudo ufw enable
```

### SSL Configuration
- TLS 1.2 and 1.3 only
- Strong cipher suites
- HSTS enabled
- Auto-renewal configured

### Application Security
- DEBUG=False in production
- Secure cookie settings
- XSS and CSRF protection
- SQL injection protection via Django ORM

## 📊 Monitoring and Performance

### Health Checks
```bash
# Check if services are running
systemctl is-active port-operations
systemctl is-active nginx
systemctl is-active postgresql

# Check application response
curl -f https://app.globalseatrans.com/api/auth/health/
```

### Performance Monitoring
- Monitor Gunicorn worker processes
- Check Nginx access logs for response times
- Monitor PostgreSQL performance
- Set up log rotation

## 🐛 Troubleshooting

### Common Issues

1. **Service Won't Start**
   ```bash
   sudo journalctl -u port-operations --no-pager
   ```

2. **SSL Certificate Issues**
   ```bash
   sudo certbot certificates
   sudo nginx -t
   ```

3. **Database Connection Issues**
   ```bash
   sudo -u postgres psql -c "\l"
   sudo systemctl status postgresql
   ```

4. **Permission Issues**
   ```bash
   sudo chown -R brendan_athlytic_io:www-data /var/www/port_operations
   ```

### Log Files Locations
- Django: `sudo journalctl -u port-operations`
- Nginx: `/var/log/nginx/`
- PostgreSQL: `/var/log/postgresql/`
- System: `/var/log/syslog`

## 📞 Support

For deployment issues:
1. Check the logs using commands above
2. Verify all services are running
3. Check firewall and DNS configuration
4. Verify SSL certificates

## 🔄 Rollback Procedure

If you need to rollback:
```bash
# On VM
cd /var/www/port_operations
git log --oneline  # Find commit to rollback to
git reset --hard <commit-hash>
sudo systemctl restart port-operations
```

## 📈 Scaling Considerations

For high traffic:
1. Increase Gunicorn workers
2. Set up database connection pooling
3. Add Redis for caching
4. Configure load balancing
5. Set up monitoring (Prometheus/Grafana)

---

**Last Updated**: $(date)
**Deployment Version**: 1.0.0 