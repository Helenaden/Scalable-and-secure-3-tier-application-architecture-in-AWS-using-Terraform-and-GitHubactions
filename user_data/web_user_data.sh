#!/bin/bash

# A simple user data script for an Ubuntu EC2 instance.
# This script installs and configures the Nginx web server.

# Update the package repository cache.
echo "Updating package list..."
sudo apt-get update -y

# Install Nginx, the lightweight web server.
echo "Installing Nginx..."
sudo apt-get install -y nginx

# Start the Nginx service.
echo "Starting Nginx service..."
sudo systemctl start nginx

# Enable Nginx to start automatically on system boot.
echo "Enabling Nginx to start on boot..."
sudo systemctl enable nginx

# Create a simple index.html file to confirm the server is working.
# This file will be served when you navigate to the public IP of the EC2 instance.
echo "Creating a simple index.html file..."
sudo sh -c "echo '<h1>Hello from your Web Server!</h1>' > /var/www/html/index.html"

echo "Web server setup complete!"