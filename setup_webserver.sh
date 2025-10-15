#!/bin/bash

set -e

SITE_DIR="/var/www/my_site"
NGINX_CONF="/etc/nginx/sites-available/my_site"


sudo apt update -y
sudo apt install -y nginx ufw curl jq

#Firewall

sudo ufw allow OpenSSH
sudo ufw allow 'Nginx HTTP'
sudo ufw --force enable

# Create site
sudo mkdir -p $SITE_DIR
echo "<!doctype html><html><head><meta charset='utf-8'><title>Automated Web Server</title></head><body><h1>Welcome — automated web server</h1><p>Deployed: $(date)</p></body></html>" | sudo tee $SITE_DIR/index.html


sudo chown -R www-data:www-data $SITE_DIR
sudo chmod -R 755 $SITE_DIR

#nginx config

sudo tee $NGINX_CONF > /dev/null <<'NGINXCONF'
server {
listen 80;
server_name _;

root /var/www/my_site;
index index.html;

access_log /var/log/nginx/my_site.access.log;
error_log /var/log/nginx/my_site.error.log;

location / {
try_files $uri $uri/ =404;
}
}
NGINXCONF

#sudo ln -s /etc/nginx/sites-available/my_site /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
echo "Setup complete. Visist the server IP to verify"
