# EC2 Instance ID
output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.creorez_ec2.id
}

# Elastic IP
output "elastic_ip" {
  description = "Elastic IP address"
  value       = data.aws_eip.creorez_eip.public_ip
}

# ECR Repository URL
output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.creorez_ecr.repository_url
}

# Security Group ID
output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.creorez_sg.id
}

# IAM Role ARN
output "iam_role_arn" {
  description = "IAM Role ARN"
  value       = aws_iam_role.creorez_ec2_role.arn
}

# Instance Profile ARN
output "instance_profile_arn" {
  description = "Instance Profile ARN"
  value       = aws_iam_instance_profile.creorez_profile.arn
}

# API Endpoint
output "api_endpoint" {
  description = "Backend API endpoint"
  value       = "http://${data.aws_eip.creorez_eip.public_ip}/generate"
}