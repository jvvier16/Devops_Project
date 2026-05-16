terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ECR Repositories
resource "aws_ecr_repository" "backend" {
  name             = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete     = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "frontend" {
  name             = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete     = true

  image_scanning_configuration {
    scan_on_push = false
  }
}