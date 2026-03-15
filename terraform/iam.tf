# IAM Role for EC2
resource "aws_iam_role" "creorez_ec2_role" {
  name = "${var.project_name}-ec2-role"

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

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.creorez_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach ECR policy
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.creorez_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance Profile
resource "aws_iam_instance_profile" "creorez_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.creorez_ec2_role.name

  tags = {
    Name        = "${var.project_name}-instance-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}