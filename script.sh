#!/bin/bash

sudo apt update

sudo apt install -y git nginx python3 python3-pip python3-flask
sudo pip3 install sympy


sudo mkdir -p /var/www/app

cd /var/www/app

sudo git clone https://github.com/RegentX/adminka_web_server .

ls

sudo bash -c 'cat > /etc/systemd/system/web_server.service <<EOF
[Unit]
Description=Web Server Flask App
After=network.target

[Service]
User=user
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/python3 /var/www/app/web_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload

sudo systemctl enable web_server

sudo systemctl start web_server

sudo systemctl status web_server

IP_ADDRESS=$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
echo "Detected IP address: $IP_ADDRESS"

sudo bash -c "cat > /etc/nginx/sites-available/web_server <<EOF
server {
    listen 80;
    server_name $IP_ADDRESS;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF"

sudo ln -s /etc/nginx/sites-available/web_server /etc/nginx/sites-enabled
sudo rm /etc/nginx/sites-enabled/default

sudo nginx -t

sudo systemctl restart nginx

history > commands_history.txt

echo "Setup complete. Web server should be running and accessible."
