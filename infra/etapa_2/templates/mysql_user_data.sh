#!/bin/bash
set -e

# Update system
yum update -y

# Install MySQL Server
yum install -y mysql-server

# Start MySQL
systemctl start mysqld
systemctl enable mysqld

# Wait for MySQL to be ready
sleep 5

# Create database and user
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${db_name};
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
EOF

echo "MySQL setup completed successfully"
