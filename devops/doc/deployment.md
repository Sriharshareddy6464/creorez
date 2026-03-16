# **AWS Deployment Steps – Creorez Backend (Node.js + Docker + Nginx + Terraform + GitHub Actions)**

This document provides the full sequence of actions used to deploy the Creorez backend on AWS EC2. It covers both manual setup (Phase 1) and automated Terraform provisioning (Phase 2).

---

## ✅ **Deployment Methods**

| Method | When to use |
|--------|-------------|
| **Terraform (recommended)** | Fresh infrastructure setup |
| **Manual** | Reference only / troubleshooting |

---

## ✅ **Method 1 — Terraform (Phase 2 — Recommended)**

### Prerequisites:
```bash
# Install Terraform
winget install Hashicorp.Terraform

# Install AWS CLI
winget install Amazon.AWSCLI

# Configure AWS CLI
aws configure
# Region: ap-northeast-1
```

### Deploy entire infrastructure:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### What Terraform provisions automatically:
```
✅ EC2 Instance (t3.micro, Ubuntu 24.04, 32GB gp3)
✅ Security Group (ports 22, 80, 443, 3001)
✅ Elastic IP Association (permanent static IP)
✅ IAM Role + Instance Profile
✅ ECR Repository
✅ Node.js + Docker + Nginx + Tectonic (via user_data)
✅ Docker container running from DockerHub
✅ Nginx configured as reverse proxy
```

### Monitor setup progress:
```bash
ssh -i "your-key.pem" ubuntu@<YOUR-ELASTIC-IP>
sudo tail -f /var/log/user-data.log
```

### Rebuild infrastructure:
```bash
terraform destroy
terraform apply
# Same Elastic IP reassigned automatically ✅
```

> Full Terraform details: `devops/doc/terraform-setup.md`

---

## ✅ **Method 2 — Manual Setup (Phase 1 — Reference)**

### **1. Launch EC2 Instance**

**Configuration used:**

| Setting | Value |
|---------|-------|
| AMI | Ubuntu 24.04 LTS |
| Instance Type | t3.micro |
| Storage | 32GB gp3 |
| Region | Asia Pacific (Tokyo) ap-northeast-1 |
| Inbound Rules | 22 (SSH), 80 (HTTP), 443 (HTTPS), 3001 (Custom TCP) |

---

### **2. Allocate Elastic IP (Permanent IP)**

> ⚠️ Without Elastic IP, your server IP changes every reboot.

1. Go to EC2 → Elastic IPs
2. Click **Allocate Elastic IP address** → Allocate
3. Select the new IP → Actions → **Associate Elastic IP**
4. Select your instance → Associate

> 💡 Keep your Elastic IP private — never commit it to public repos.

---

### **3. Connect to Instance**

**Using terminal:**
```bash
ssh -i "your-key.pem" ubuntu@<YOUR-ELASTIC-IP>
```

**Using Termius (Android/iOS — recommended for mobile):**
- Host: `<YOUR-ELASTIC-IP>`
- Username: `ubuntu`
- Key: import your `.pem` file

---

### **4. Server Setup**
```bash
sudo apt update && sudo apt upgrade -y
```

**Install Node.js 22:**
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v && npm -v
```

**Install Docker:**
```bash
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
newgrp docker
```

---

### **5. Setup Backend**
```bash
mkdir ~/resume-backend && cd ~/resume-backend
npm init -y
npm install express cors
```

**Install Tectonic:**
```bash
sudo apt install -y libgraphite2-3 libharfbuzz0b libfontconfig1 libssl-dev curl
curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh
sudo mv tectonic /usr/local/bin/tectonic
sudo chmod +x /usr/local/bin/tectonic
tectonic --version
```

---

### **6. Dockerize the Backend**
```dockerfile
FROM node:22-slim

RUN apt-get update && apt-get install -y \
    libgraphite2-3 \
    libharfbuzz0b \
    libfontconfig1 \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install

RUN curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net | sh \
    && mv tectonic /usr/local/bin/tectonic \
    && chmod +x /usr/local/bin/tectonic

COPY . .

EXPOSE 3001

CMD ["node", "server.js"]
```
```bash
docker build -t pdf-server .
docker run -d --name pdf-server --restart always -p 3001:3001 pdf-server
docker ps
```

---

### **7. Push to DockerHub (Backup)**
```bash
docker login
docker tag pdf-server sriharshareddy6464/pdf-server:latest
docker push sriharshareddy6464/pdf-server:latest
```

**To restore from scratch:**
```bash
docker pull sriharshareddy6464/pdf-server:latest
docker run -d --name pdf-server --restart always -p 3001:3001 sriharshareddy6464/pdf-server:latest
```

---

### **8. Setup Nginx (Reverse Proxy)**
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo nano /etc/nginx/sites-available/default
```
```nginx
server {
    listen 80;
    server_name <YOUR-ELASTIC-IP>;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```
```bash
sudo nginx -t && sudo systemctl restart nginx
```

---

## ✅ **GitHub Actions CI/CD Pipeline**

Every push to `main` inside `resume-backend/` automatically builds, pushes, and deploys.

### **Pipeline Flow:**
```
Push to main (resume-backend/ changes)
    ↓
GitHub Actions triggered
    ↓
Build Docker image → Push to DockerHub
    ↓
SSH into EC2 (same Elastic IP always)
    ↓
Pull new image → Restart container
    ↓
Zero manual intervention ✅
```

### **Workflow file:**
```yaml
name: Deploy to EC2

on:
  push:
    branches:
      - main
    paths:
      - 'resume-backend/**'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build Docker image
        run: |
          cd resume-backend
          docker build -t ${{ secrets.DOCKER_USERNAME }}/pdf-server:latest .

      - name: Push to DockerHub
        run: |
          docker push ${{ secrets.DOCKER_USERNAME }}/pdf-server:latest

      - name: Deploy to EC2
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ubuntu
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            docker pull sriharshareddy6464/pdf-server:latest
            docker rm -f pdf-server || true
            docker run -d \
              --name pdf-server \
              --restart always \
              -p 3001:3001 \
              sriharshareddy6464/pdf-server:latest
            docker ps
```

### **GitHub Secrets required:**

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | DockerHub username |
| `DOCKER_PASSWORD` | DockerHub password |
| `EC2_HOST` | Elastic IP address |
| `EC2_SSH_KEY` | Contents of `.pem` key file |

---

## ✅ **CloudWatch Monitoring (Optional)**

> 💡 Disabled in alpha stage to reduce costs. Re-enable in production.
```bash
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
```
```bash
sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json > /dev/null << 'EOF'
{
  "metrics": {
    "append_dimensions": { "InstanceId": "${aws:InstanceId}" },
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"], "metrics_collection_interval": 3600 },
      "disk": { "measurement": ["disk_used_percent"], "resources": ["/"], "metrics_collection_interval": 3600 }
    }
  }
}
EOF
```

| Alarm | Metric | Threshold |
|-------|--------|-----------|
| `creorez-cpu-alarm` | CPUUtilization | > 60% |
| `creorez-memory-alarm` | mem_used_percent | > 75% |
| `creorez-disk-alarm` | disk_used_percent | > 60% |

---

## ✅ **Cost Breakdown**

| Service | Cost |
|---------|------|
| EC2 t3.micro | ~$7.50/month |
| Elastic IP (attached) | Free |
| gp3 Storage 32GB | ~$2.56/month |
| ECR (500MB free) | Free |
| CloudWatch (disabled) | $0 |
| GitHub Actions | Free |
| **Total** | **~$10/month** |

---

## ✅ **API Endpoints**

| Endpoint | Method | Description |
|----------|--------|-------------|
| `http://<YOUR-ELASTIC-IP>/` | GET | Health check |
| `http://<YOUR-ELASTIC-IP>/generate` | POST | LaTeX → PDF |

**Request body:**
```json
{
  "code": "your latex code here"
}
```

---

## ✅ **Disaster Recovery**
```bash
# Option 1 — Terraform (fastest)
terraform apply
# Everything back in under 10 minutes ✅

# Option 2 — Manual Docker restore
docker pull sriharshareddy6464/pdf-server:latest
docker run -d --name pdf-server --restart always -p 3001:3001 sriharshareddy6464/pdf-server:latest
```

---

## ✅ **Summary**

| Step | What | Why |
|------|------|-----|
| Terraform | IaC provisioning | Reproducible infrastructure |
| EC2 | Ubuntu 24.04 t3.micro 32GB | Cloud server |
| Elastic IP | Static IP | Never changes on reboot or rebuild |
| Node.js 22 | Runtime | Backend engine |
| Tectonic | LaTeX engine | Lightweight PDF compiler |
| Docker | Containerization | Portable, reproducible |
| DockerHub | Image backup | Restore in 2 mins anywhere |
| ECR | Private registry | Future EKS migration |
| Nginx | Reverse proxy | Clean URL on port 80 |
| GitHub Actions | CI/CD pipeline | Zero manual deployments |
| CloudWatch | Monitoring (optional) | Re-enable in production |

---

## 🔜 **Next Steps (Phase 3)**

- [ ] Domain name + SSL (Let's Encrypt)
- [ ] EKS + Kubernetes
- [ ] Prometheus + Grafana
- [ ] Remote Terraform state (S3 + DynamoDB)
- [ ] Staging environment