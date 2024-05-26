#!/bin/bash

# Update package lists
sudo apt update

# Install required packages
sudo apt install -y git nginx python3 python3-pip python3-flask
sudo pip3 install sympy


# Create the application directory
sudo mkdir -p /var/www/app

# Change to the application directory
cd /var/www/app

# Clone the repository
sudo git clone https://github.com/RegentX/adminka_web_server .

# Verify files are present
ls

# Create the systemd service file
sudo bash -c 'cat > /etc/systemd/system/web_server.service <<EOF
[Unit]
Description=Web Server Flask App
After=network.target

[Service]
#ЗАМЕНИ ЗДЕСЬ НА СВОЕ ИМЯ ПОЛЬЗОВАТЕЛЯ
User=user
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/python3 /var/www/app/web_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the new service to start on boot
sudo systemctl enable web_server

# Start the new service
sudo systemctl start web_server

# Check the status of the service
sudo systemctl status web_server

# Get the IP address
IP_ADDRESS=$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
echo "Detected IP address: $IP_ADDRESS"

# Create the Nginx configuration file
sudo bash -c "cat > /etc/nginx/sites-available/web_server <<EOF
server {
    listen 80;
    server_name $IP_ADDRESS;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF"

# Enable the new Nginx site configuration
sudo ln -s /etc/nginx/sites-available/web_server /etc/nginx/sites-enabled
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Save command history
history > commands_history.txt

# Print completion message
echo "Setup complete. Web server should be running and accessible."