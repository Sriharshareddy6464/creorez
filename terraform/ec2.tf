# EC2 Instance
resource "aws_instance" "creorez_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.creorez_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.creorez_profile.name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1

    # Update system
    apt-get update -y
    apt-get upgrade -y

    # Install dependencies
    apt-get install -y curl unzip docker.io nginx libgraphite2-3 libharfbuzz0b libfontconfig1 libssl-dev

    # Start Docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    # Start Nginx
    systemctl start nginx
    systemctl enable nginx

    # Install Tectonic
    curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh
    mv /root/tectonic /usr/local/bin/tectonic
    chmod +x /usr/local/bin/tectonic

    # Pull and run Docker container
    docker pull sriharshareddy6464/pdf-server:latest
    docker run -d \
      --name pdf-server \
      --restart always \
      -p 3001:3001 \
      sriharshareddy6464/pdf-server:latest

    # Configure Nginx
    echo 'server {
        listen 80;
        server_name _;
        location / {
            proxy_pass http://localhost:3001;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection upgrade;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }' > /etc/nginx/sites-available/default

    nginx -t && systemctl restart nginx
  EOF

  tags = {
    Name        = "${var.project_name}-prod"
    Environment = var.environment
    Project     = var.project_name
  }
}