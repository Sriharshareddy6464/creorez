# **Server Setup & Operational Guide – Creorez Backend**

This document describes all server-level commands, maintenance workflows, monitoring steps, and operational procedures required for running the Creorez backend on AWS EC2.
It includes Docker operations, Nginx management, logs, debugging, and overall server lifecycle actions.

---

## ✅ **1. Directory Structure on EC2**
```
/home/ubuntu/
├── resume-backend/
│   ├── server.js
│   ├── package.json
│   ├── package-lock.json
│   ├── Dockerfile
│   └── node_modules/
│
└── amazon-cloudwatch-agent.deb  ← installer (can delete after setup)
```

---

## ✅ **2. Environment Variables**

Currently the server runs on port 3001 hardcoded in `server.js`.

For future `.env` support:
```bash
nano ~/resume-backend/.env
```
```env
PORT=3001
```

> 💡 Never commit `.env` to Git. Add to `.gitignore`.

---

## ✅ **3. Docker Operations**

### **Check running containers:**
```bash
docker ps
```

### **Start container:**
```bash
docker start pdf-server
```

### **Stop container:**
```bash
docker stop pdf-server
```

### **Restart container:**
```bash
docker restart pdf-server
```

### **Delete container:**
```bash
docker rm -f pdf-server
```

### **View container logs:**
```bash
docker logs pdf-server
docker logs pdf-server --tail 50        # last 50 lines
docker logs pdf-server --follow         # live logs
```

### **Run fresh container:**
```bash
docker run -d \
  --name pdf-server \
  --restart always \
  -p 3001:3001 \
  pdf-server
```

---

## ✅ **4. Docker Image Operations**

### **List local images:**
```bash
docker images
```

### **Build image:**
```bash
cd ~/resume-backend
docker build -t pdf-server .
```

### **Remove old image:**
```bash
docker rmi pdf-server
```

### **Pull from DockerHub (disaster recovery):**
```bash
docker pull sriharshareddy6464/pdf-server:latest
```

### **Push updated image to DockerHub:**
```bash
docker tag pdf-server sriharshareddy6464/pdf-server:latest
docker push sriharshareddy6464/pdf-server:latest
```

> 💡 Always push to DockerHub after any server.js or Dockerfile changes.

---

## ✅ **5. Nginx Operations**

### **Check status:**
```bash
sudo systemctl status nginx
```

### **Restart after config changes:**
```bash
sudo systemctl restart nginx
```

### **Test config syntax:**
```bash
sudo nginx -t
```

### **Edit config:**
```bash
sudo nano /etc/nginx/sites-available/default
```

### **Current Nginx config:**
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

---

## ✅ **6. CloudWatch Agent Operations**

### **Check status:**
```bash
sudo systemctl status amazon-cloudwatch-agent
```

### **Restart agent:**
```bash
sudo systemctl restart amazon-cloudwatch-agent
```

### **Reload config after changes:**
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s
```

---

## ✅ **7. Server Health Check**

Quick full system check — run all at once:
```bash
docker ps                                        # container running?
sudo systemctl status nginx                      # nginx running?
sudo systemctl status amazon-cloudwatch-agent   # cloudwatch running?
df -h                                            # disk usage
free -h                                          # memory usage
top                                              # CPU usage
```

---

## ✅ **8. API Testing**

### **Health check:**
```bash
curl http://localhost:3001/
```

### **Test PDF generation:**
```bash
curl -X POST http://localhost:3001/generate \
  -H "Content-Type: application/json" \
  -d '{"code": "\\documentclass{article}\\begin{document}Hello World\\end{document}"}' \
  --output test.pdf
```

---

## ✅ **9. Updating server.js**

Whenever `server.js` is modified:
```bash
# 1. Edit the file
cd ~/resume-backend
nano server.js

# 2. Rebuild Docker image
docker build -t pdf-server .

# 3. Stop and remove old container
docker rm -f pdf-server

# 4. Run new container
docker run -d \
  --name pdf-server \
  --restart always \
  -p 3001:3001 \
  pdf-server

# 5. Verify
docker ps
docker logs pdf-server

# 6. Push updated image to DockerHub
docker tag pdf-server sriharshareddy6464/pdf-server:latest
docker push sriharshareddy6464/pdf-server:latest
```

---

## ✅ **10. Disk Cleanup**

Run periodically to free up disk space:
```bash
# Remove unused Docker images and containers
docker system prune -f

# Check disk usage
df -h
```

> 💡 Set this as a weekly cron job in Phase 2.

---

## ✅ **11. Disaster Recovery**

If everything is lost — full restore in under 10 minutes:
```bash
# 1. Launch new EC2 (Ubuntu 24.04, t3.micro, 32GB gp3)
# 2. SSH in and install Docker
sudo apt update && sudo apt install -y docker.io
sudo systemctl start docker
sudo usermod -aG docker ubuntu
newgrp docker

# 3. Pull image from DockerHub
docker pull sriharshareddy6464/pdf-server:latest

# 4. Run container
docker run -d \
  --name pdf-server \
  --restart always \
  -p 3001:3001 \
  sriharshareddy6464/pdf-server:latest

# 5. Install and configure Nginx
sudo apt install -y nginx
sudo nano /etc/nginx/sites-available/default
sudo systemctl restart nginx

# 6. Install CloudWatch Agent
# (refer to aws-setup.md)

# ✅ Back online!
```

---

## ✅ **12. Summary — Key Commands**

| Action | Command |
|--------|---------|
| Check container | `docker ps` |
| View logs | `docker logs pdf-server --follow` |
| Restart container | `docker restart pdf-server` |
| Rebuild image | `docker build -t pdf-server .` |
| Push to DockerHub | `docker push sriharshareddy6464/pdf-server:latest` |
| Restart Nginx | `sudo systemctl restart nginx` |
| Check disk | `df -h` |
| Check memory | `free -h` |
| Health check | `curl http://localhost:3001/` |

---

## 🔜 **Next Steps (Phase 2)**

- [ ] Docker Compose for multi-container management
- [ ] Terraform to provision EC2 as code
- [ ] Kubernetes (EKS) for auto-scaling
- [ ] Prometheus + Grafana replacing CloudWatch
- [ ] GitHub Actions for automated deployments
- [ ] Weekly cron job for Docker cleanup