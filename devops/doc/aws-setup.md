# **AWS Setup – Creorez Backend Infrastructure**

This document describes the exact AWS configurations used for deploying the Creorez backend. It includes EC2 provisioning, Elastic IP, security groups, IAM roles, and CloudWatch monitoring setup.

---

## ✅ **1. EC2 Instance Configuration**

### **Instance Details**

| Parameter | Value |
|-----------|-------|
| AMI | Ubuntu 24.04 LTS (x86_64) |
| Instance Type | t3.micro |
| vCPU | 2 |
| RAM | 1GB |
| Storage | 32GB gp3 |
| Architecture | 64-bit |
| Region | Asia Pacific Tokyo (ap-northeast-1) |
| Network | Default VPC |

### **Why t3.micro over t2.micro?**
- t3 has unlimited CPU burst (t2 has limited burst credits)
- Better performance for PDF compilation spikes
- Same free-tier eligible cost

### **Why Ubuntu 24.04?**
- Latest stable LTS release
- Excellent Docker and Node.js support
- Lightweight for microservices
- Compatible with all DevOps tooling

### **Why 32GB gp3?**
- Phase 2 tools (Terraform, Helm, EKS, Prometheus) consume significant disk
- gp3 is faster and cheaper than gp2
- Future-proof for log storage and Docker image layers

---

## ✅ **2. Key Pair Setup**

When creating the EC2 instance:
- Generate a `.pem` key pair
- Download immediately — cannot be retrieved later
- Set correct permissions locally:
```bash
chmod 400 your-key.pem
```

> ⚠️ Never commit `.pem` files to Git. Add to `.gitignore` immediately.

---

## ✅ **3. Elastic IP (Static IP)**

> ⚠️ Without Elastic IP, your public IP changes on every reboot.

**Steps:**
1. EC2 → **Elastic IPs** → Allocate Elastic IP
2. Select allocated IP → Actions → **Associate**
3. Select your instance → Associate

**Cost:**
- Free when attached to a running instance
- Small hourly charge if instance is stopped — release IP if not needed

> 💡 Keep your Elastic IP private — never commit to public repos.

---

## ✅ **4. Security Group Rules**

### **Inbound Rules**

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH access |
| 80 | TCP | HTTP via Nginx |
| 443 | TCP | HTTPS (SSL — future) |
| 3001 | TCP | Docker container direct access |

### **Outbound Rules**
- Allow all (default)

### **Security Best Practices**
- SSH key-pair only — no password login
- Never expose database ports publicly
- Never commit `.pem` or secrets to Git
- Restrict port 22 to your IP only in production

---

## ✅ **5. IAM Role — CloudWatch**

CloudWatch Agent requires EC2 to have permission to push metrics.

**Steps:**
1. IAM → **Roles** → Create Role
2. Trusted entity: **AWS Service → EC2**
3. Attach policy: `CloudWatchAgentServerPolicy`
4. Role name: `creorez-cloudwatch-role`
5. EC2 → Instance → Actions → Security → **Modify IAM Role**
6. Select `creorez-cloudwatch-role` → Update

---

## ✅ **6. Storage**

### **Volume**
- 32GB gp3 (General Purpose SSD)

### **Why gp3 over gp2?**

| Feature | gp2 | gp3 |
|---------|-----|-----|
| Baseline IOPS | 100-3000 | 3000 (always) |
| Cost | Higher | 20% cheaper |
| Throughput | Limited | 125 MB/s baseline |

---

## ✅ **7. Connect to Instance**
```bash
chmod 400 your-key.pem
ssh -i "your-key.pem" ubuntu@<YOUR-ELASTIC-IP>
```

**Using Termius (mobile):**
- Host: `<YOUR-ELASTIC-IP>`
- Username: `ubuntu`
- Key: import `.pem` file

---

## ✅ **8. System Update**
```bash
sudo apt update && sudo apt upgrade -y
```

---

## ✅ **9. Node.js 22 Installation**
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v
```

> ⚠️ Use Node.js 22 LTS — Node 18 is deprecated and no longer receives security updates.

---

## ✅ **10. Docker Installation**
```bash
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
newgrp docker
docker --version
docker ps
```

---

## ✅ **11. Nginx Installation**
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

**Useful Nginx commands:**
```bash
sudo systemctl restart nginx   # restart after config changes
sudo systemctl status nginx    # check if running
sudo nginx -t                  # test config syntax
```

---

## ✅ **12. CloudWatch Agent Installation**
```bash
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
```

**Config (hourly metrics, no logs — cost optimized):**
```bash
sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json > /dev/null << 'EOF'
{
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 3600
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "resources": ["/"],
        "metrics_collection_interval": 3600
      }
    }
  }
}
EOF
```

**Start agent:**
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s

sudo systemctl status amazon-cloudwatch-agent
```

---

## ✅ **13. CloudWatch Alarms**

| Alarm Name | Metric | Threshold | Action |
|------------|--------|-----------|--------|
| `creorez-cpu-alarm` | CPUUtilization | > 60% | SNS Email |
| `creorez-memory-alarm` | mem_used_percent | > 75% | SNS Email |
| `creorez-disk-alarm` | disk_used_percent | > 60% | SNS Email |

**SNS Topic:** `creorez-alerts`

> 💡 Confirm SNS subscription email immediately after creation — alerts won't work without confirmation.

---

## ✅ **14. Cost Breakdown**

| Service | Cost |
|---------|------|
| EC2 t3.micro | ~$7.50/month |
| CloudWatch metrics (hourly) | ~$1-2/month |
| Elastic IP (attached) | Free |
| gp3 Storage 32GB | ~$2.56/month |
| **Total** | **~$11-12/month** |

---

## ✅ **15. Summary — AWS Stack**

| Component | Value |
|-----------|-------|
| Instance | EC2 t3.micro |
| OS | Ubuntu 24.04 LTS |
| Region | ap-northeast-1 (Tokyo) |
| Storage | 32GB gp3 |
| IP | Elastic IP (static) |
| Runtime | Node.js 22 |
| Container | Docker |
| Proxy | Nginx |
| Monitoring | CloudWatch Agent |
| Backup | DockerHub |

---

## 🔜 **Next Steps (Phase 2)**

- [ ] Domain + SSL (Route 53 + Let's Encrypt)
- [ ] Terraform for all above resources as IaC
- [ ] EKS cluster replacing single EC2
- [ ] Prometheus + Grafana replacing CloudWatch
- [ ] GitHub Actions CI/CD pipeline