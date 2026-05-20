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
  backend-ventas:
    image: ${image_ventas}
    container_name: backend-ventas
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://${db_endpoint}:3306/${db_name}
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: ${db_password}
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    networks:
      - backend

  backend-despachos:
    image: ${image_despachos}
    container_name: backend-despachos
    ports:
      - "8081:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://${db_endpoint}:3306/${db_name}
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: ${db_password}
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    networks:
      - backend

networks:
  backend:
    driver: bridge
COMPOSE

# Start containers
cd /home/ec2-user
docker-compose up -d

echo "Backend setup completed successfully"
