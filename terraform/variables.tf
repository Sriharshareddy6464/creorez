variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "creorez"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu 24.04 LTS AMI ID for ap-northeast-1"
  type        = string
  default     = "ami-0f8faa29480e7e6de"
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "Creorez"
}

variable "volume_size" {
  description = "EC2 root volume size in GB"
  type        = number
  default     = 32
}