#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI
yum install -y aws-cli

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}

# Create docker-compose file
cat > /home/ec2-user/docker-compose.yml <<'COMPOSE'
version: '3.8'

services:
  frontend:
    image: ${image_frontend}
    container_name: frontend-despacho
    ports:
      - "80:80"
      - "443:443"
    environment:
      VITE_API_URL: http://${backend_host}:8080
      VITE_API_DESPACHO_URL: http://${backend_host}:8081
    networks:
      - frontend

networks:
  frontend:
    driver: bridge
COMPOSE

# Start containers
cd /home/ec2-user
docker-compose up -d

echo "Frontend setup completed successfully"
