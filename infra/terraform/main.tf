terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.0"
        }
    }
}
provider "aws" {
  region              = var.aws_region
  access_key          = var.aws_access_key_id
  secret_key          = var.aws_secret_access_key
  token               = var.aws_session_token != "" ? var.aws_session_token : null
  
  skip_credentials_validation = false
  skip_metadata_api_check     = false
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "eks-vpc"
  }
}
resource "aws_subnet" "eks_subnet_1" {
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-1"
  }
}
resource "aws_subnet" "eks_subnet_2" {
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-2"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-igw"
  }
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "eks-route-table"
  }
}
resource "aws_route_table_association" "rta_1" {
  subnet_id = aws_subnet.eks_subnet_1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rta_2" {
  subnet_id = aws_subnet.eks_subnet_2.id
  route_table_id = aws_route_table.rt.id
}
#EKS: elastic kubernet service:
resource "aws_eks_cluster" "eks" {
  name = "despachos-cluster"
  role_arn = data.aws_iam_role.labrole.arn
  vpc_config {
    subnet_ids = [aws_subnet.eks_subnet_1.id,
                  aws_subnet.eks_subnet_2.id]
  }     
}
resource "aws_eks_node_group" "workers" {
  cluster_name = aws_eks_cluster.eks.name
  node_group_name = "workers"
  node_role_arn = data.aws_iam_role.labrole.arn
  subnet_ids = [aws_subnet.eks_subnet_1.id,
                aws_subnet.eks_subnet_2.id]
  scaling_config {
    desired_size = 2
    max_size = 2
    min_size = 1
  }
  instance_types = ["t3.medium"]
  capacity_type = "ON_DEMAND"
}
#ECR: elastic container registry
resource "aws_ecr_repository" "backend_despacho_repo" {
  name = "backend-despacho"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  tags = {
    Name = "backend-despacho"
  }
}
resource "aws_ecr_repository" "backend_ventas_repo" {
  name = "backend-ventas"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  tags = {
    Name = "backend-ventas"
  }
}
resource "aws_ecr_repository" "frontend_despacho_repo" {
  name = "frontend-despacho"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  tags = {
    Name = "frontend-despacho"
  }
}