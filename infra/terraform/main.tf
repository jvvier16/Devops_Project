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
  token               = var.aws_session_token
  
  skip_credentials_validation = false
  skip_metadata_api_check     = false
}

# ============================================
# IAM ROLES
# ============================================

# IAM Role para EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# IAM Role para EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# IAM Role para ECR (Task/Pod Execution)
resource "aws_iam_role" "eks_execution_role" {
  name = "eks-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  role       = aws_iam_role.eks_execution_role.name
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

# ============================================
# SECURITY GROUPS
# ============================================

# Security Group para EKS Cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.eks_vpc.id

  # Ingress: Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  # Ingress: Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  # Ingress: Allow communication between nodes
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
    description     = "Allow communication from nodes"
  }

  # Egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# Security Group para EKS Nodes
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  # Ingress: Allow traffic from cluster SG
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
    description     = "Allow traffic from EKS cluster"
  }

  # Ingress: Allow node-to-node communication
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow node-to-node communication"
  }

  # Ingress: Allow kubelet
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.eks_vpc.cidr_block]
    description = "Allow kubelet"
  }

  # Egress: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}

# Security Group para ALB (Application Load Balancer)
resource "aws_security_group" "alb_sg" {
  name        = "eks-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.eks_vpc.id

  # Ingress: HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # Ingress: HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  # Egress: Allow all traffic to nodes
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "eks-alb-sg"
  }
}
resource "aws_eks_cluster" "eks" {
  name = "despachos-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.eks_subnet_1.id,
                  aws_subnet.eks_subnet_2.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }     
}
resource "aws_eks_node_group" "workers" {
  cluster_name = aws_eks_cluster.eks.name
  node_group_name = "workers"
  node_role_arn = aws_iam_role.eks_node_role.arn
  subnet_ids = [aws_subnet.eks_subnet_1.id,
                aws_subnet.eks_subnet_2.id]
  security_groups = [aws_security_group.eks_nodes_sg.id]
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