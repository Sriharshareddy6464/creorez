# **Docker Setup Guide – Creorez Backend**

This document describes the complete Docker setup for the Creorez PDF generation backend. It includes Dockerfile explanation, image building, container management, DockerHub backup, and future Docker Compose planning.

---

## ✅ **1. Why Docker?**

| Without Docker | With Docker |
|----------------|-------------|
| Manual dependency install every time | All dependencies baked into image |
| "Works on my machine" problems | Runs identically everywhere |
| Hard to recover from EC2 loss | Pull image → running in 2 minutes |
| No version control for environment | Dockerfile is version controlled |
| PM2 restarts only the process | Docker restarts entire container |

---

## ✅ **2. What's Inside the Container**
```
Docker Container (pdf-server)
├── Node.js 22 (runtime)
├── Express (API server)
├── Tectonic 0.15.0 (LaTeX → PDF engine)
├── server.js (API logic)
├── libgraphite2-3 (Tectonic dependency)
├── libharfbuzz0b (Tectonic dependency)
├── libfontconfig1 (Tectonic dependency)
└── libssl-dev (Tectonic dependency)
```

---

## ✅ **3. Dockerfile**

Location: `~/resume-backend/Dockerfile`
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

### **Line by line explanation:**

| Line | What it does | Why |
|------|-------------|-----|
| `FROM node:22-slim` | Base image — Node 22 minimal | Smallest possible image size |
| `apt-get install` | Install Tectonic dependencies | Required libraries for LaTeX engine |
| `rm -rf /var/lib/apt/lists/*` | Clean apt cache | Reduces image size |
| `WORKDIR /app` | Set working directory | All files go here inside container |
| `COPY package*.json` | Copy package files first | Leverage Docker layer caching |
| `RUN npm install` | Install Node dependencies | Before copying source code |
| `RUN curl tectonic` | Download and install Tectonic | LaTeX → PDF engine |
| `COPY . .` | Copy source code | After dependencies (cache efficiency) |
| `EXPOSE 3001` | Document the port | Informational — doesn't open port itself |
| `CMD node server.js` | Start the server | Runs when container starts |

---

## ✅ **4. Build Image**
```bash
cd ~/resume-backend
docker build -t pdf-server .
```

**Verify build:**
```bash
docker images
```

Expected output:
```
REPOSITORY    TAG       IMAGE ID       CREATED         SIZE
pdf-server    latest    dc83f1d62abe   X minutes ago   ~500MB
```

---

## ✅ **5. Run Container**
```bash
docker run -d \
  --name pdf-server \
  --restart always \
  -p 3001:3001 \
  pdf-server
```

### **Flags explained:**

| Flag | Meaning |
|------|---------|
| `-d` | Detached mode — runs in background |
| `--name pdf-server` | Name the container |
| `--restart always` | Auto restart on crash or EC2 reboot |
| `-p 3001:3001` | Map host port 3001 → container port 3001 |

---

## ✅ **6. Container Management**
```bash
docker ps                          # list running containers
docker ps -a                       # list all containers including stopped
docker start pdf-server            # start stopped container
docker stop pdf-server             # stop running container
docker restart pdf-server          # restart container
docker rm -f pdf-server            # force delete container
docker logs pdf-server             # view logs
docker logs pdf-server --follow    # live logs
docker logs pdf-server --tail 50   # last 50 lines
docker exec -it pdf-server bash    # enter container shell
```

---

## ✅ **7. DockerHub Backup**

DockerHub acts as a remote backup for the image. If EC2 is lost, the image can be pulled instantly.

### **Login:**
```bash
docker login
```

### **Tag image:**
```bash
docker tag pdf-server sriharshareddy6464/pdf-server:latest
```

### **Push:**
```bash
docker push sriharshareddy6464/pdf-server:latest
```

### **Pull (restore):**
```bash
docker pull sriharshareddy6464/pdf-server:latest
```

> 💡 Always push to DockerHub after any changes to `server.js` or `Dockerfile`.

---

## ✅ **8. Updating the Container**

Whenever code changes:
```bash
# 1. Make changes to server.js
nano ~/resume-backend/server.js

# 2. Rebuild image
cd ~/resume-backend
docker build -t pdf-server .

# 3. Replace running container
docker rm -f pdf-server
docker run -d \
  --name pdf-server \
  --restart always \
  -p 3001:3001 \
  pdf-server

# 4. Verify
docker ps
docker logs pdf-server

# 5. Push updated image to DockerHub
docker tag pdf-server sriharshareddy6464/pdf-server:latest
docker push sriharshareddy6464/pdf-server:latest
```

---

## ✅ **9. Disk Cleanup**

Docker images and stopped containers accumulate over time:
```bash
# Remove all unused images, containers, networks
docker system prune -f

# Check disk usage
df -h
```

---

## ✅ **10. Traffic Flow**
```
Internet
    ↓
Elastic IP (static)
    ↓
EC2 Security Group (port 80 allowed)
    ↓
Nginx (port 80)
    ↓ proxy_pass localhost:3001
Docker Container (port 3001)
    ↓
server.js → Tectonic → PDF
    ↓
Response back to user
```

---

## ✅ **11. Disaster Recovery**

Full restore from zero in under 10 minutes:
```bash
# 1. New EC2 — install Docker
sudo apt update && sudo apt install -y docker.io
sudo systemctl start docker
sudo usermod -aG docker ubuntu
newgrp docker

# 2. Pull from DockerHub
docker pull sriharshareddy6464/pdf-server:latest

# 3. Run
docker run -d \
  --name pdf-server \
  --restart always \
  -p 3001:3001 \
  sriharshareddy6464/pdf-server:latest

# ✅ API is live again
```

---

## 🔜 **Next Steps (Phase 2)**

### Docker Compose (coming soon):
```yaml
version: '3.8'
services:
  pdf-server:
    image: sriharshareddy6464/pdf-server:latest
    ports:
      - "3001:3001"
    restart: always
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    depends_on:
      - pdf-server

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

- [ ] Docker Compose for multi-container setup
- [ ] Terraform to provision infra as code
- [ ] EKS + Kubernetes for auto-scaling
- [ ] Prometheus + Grafana for advanced monitoring
- [ ] GitHub Actions for automated builds and deploys