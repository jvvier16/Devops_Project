variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token (for temporary credentials)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}
