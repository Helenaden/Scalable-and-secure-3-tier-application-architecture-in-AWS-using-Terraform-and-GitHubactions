#!/bin/bash

# A simple user data script for an Ubuntu EC2 instance.
# This script installs Node.js and a process manager for an application.

# Update the package repository cache.
echo "Updating package list..."
sudo apt-get update -y

# Install Node.js and npm using the recommended NVM (Node Version Manager) method.
echo "Installing Node.js and npm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 20  # You can specify the version you need here

# Create a simple Node.js application.
echo "Creating a simple Node.js application file (app.js)..."
sudo sh -c "echo 'const http = require(\"http\");' > app.js"
sudo sh -c "echo 'const server = http.createServer((req, res) => {' >> app.js"
sudo sh -c "echo '  res.statusCode = 200;' >> app.js"
sudo sh -c "echo '  res.setHeader(\"Content-Type\", \"text/plain\");' >> app.js"
sudo sh -c "echo '  res.end(\"Hello from your Application Server!\");' >> app.js"
sudo sh -c "echo '});' >> app.js"
sudo sh -c "echo 'server.listen(3000, () => {' >> app.js"
sudo sh -c "echo '  console.log(\"Server running at http://localhost:3000/\");' >> app.js"
sudo sh -c "echo '});' >> app.js"

# Install a process manager to keep the application running.
# PM2 is a great choice as it handles restarts and logging.
echo "Installing PM2 process manager..."
sudo npm install -g pm2

# Start the application with PM2.
echo "Starting the application with PM2..."
pm2 start app.js --name "my-node-app"

# Configure PM2 to restart the app on reboot.
echo "Configuring PM2 to start on reboot..."
pm2 startup
pm2 save

echo "Application server setup complete!"