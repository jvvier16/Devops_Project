terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ============================================
# IAM ROLE (Utiliza el rol preexistente del laboratorio)
# ============================================

data "aws_iam_role" "lab_role" {
  name = "LabRole" # Nota: Si tu lab usa Vocareum puro, puedes cambiarlo por "VocareumLabRole" si este falla.
}

# ============================================
# VPC y REDES
# ============================================

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "eks-vpc" }
}

resource "aws_subnet" "eks_subnet_1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_1" {
  subnet_id      = aws_subnet.eks_subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta_2" {
  subnet_id      = aws_subnet.eks_subnet_2.id
  route_table_id = aws_route_table.rt.id
}

# ============================================
# SECURITY GROUPS
# ============================================

resource "aws_security_group" "eks_cluster_sg" {
  name   = "eks-cluster-sg"
  vpc_id = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes_sg" {
  name   = "eks-nodes-sg"
  vpc_id = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "cluster_from_nodes" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "nodes_from_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.eks_nodes_sg.id
}

# ============================================
# EKS CLUSTER Y NODOS
# ============================================

resource "aws_eks_cluster" "eks" {
  name     = "despachos-cluster"
  role_arn = data.aws_iam_role.lab_role.arn
  vpc_config {
    subnet_ids         = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "workers"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
  instance_types = ["t3.medium"]
}

# ============================================
# ECR REPOSITORIES
# ============================================

resource "aws_ecr_repository" "backend_despacho_repo" {
  name                 = "backend-despacho"
  image_scanning_configuration { scan_on_push = true }
  force_delete         = true
}

resource "aws_ecr_repository" "backend_ventas_repo" {
  name                 = "backend-ventas"
  image_scanning_configuration { scan_on_push = true }
  force_delete         = true
}

resource "aws_ecr_repository" "frontend_despacho_repo" {
  name                 = "frontend-despacho"
  image_scanning_configuration { scan_on_push = true }
  force_delete         = true
}