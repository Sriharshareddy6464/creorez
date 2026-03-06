# 🚀 Creorez — AI Resume Builder

Smart resume creation with AI, LaTeX → PDF generation, and ATS scoring.

Built with **Next.js**, deployed on **Vercel**, and powered by a **Node.js backend** running on **AWS EC2** with **Docker + Nginx** for production stability.

---

## 🌐 Live

| Service | URL |
|---------|-----|
| Frontend (Vercel) | https://cerores.vercel.app/ |
| Backend (AWS EC2) | http://\<YOUR-ELASTIC-IP\>/ |

---

## ⭐ Overview

Creorez is an AI-driven resume builder that helps users:

- Generate professional resumes
- Convert form inputs → LaTeX → PDF
- Analyze resumes using ATS scoring
- Export downloadable PDFs
- Fast cloud-based PDF rendering

### **System Architecture**
```
User Browser
    ↓
Vercel (Next.js Frontend)
    ↓ HTTP API Call
AWS EC2 — Tokyo (ap-northeast-1)
    ↓
Nginx (Port 80) → Docker Container (Port 3001)
    ↓
Node.js 22 + Tectonic (LaTeX → PDF)
    ↓
PDF Response → Frontend → User
```

---

## 🔧 Tech Stack

### Frontend
- Next.js (App Router)
- React.js
- TailwindCSS
- Vercel Deployment

### Backend
- Node.js 22
- Express
- Tectonic (LaTeX → PDF engine)
- Docker
- Nginx

### Cloud / DevOps
- AWS EC2 (t3.micro, Ubuntu 24.04, 32GB gp3)
- Elastic IP (static)
- Docker + DockerHub
- CloudWatch (memory, disk, CPU monitoring)
- IAM Role (CloudWatch permissions)
- GitHub / Git

---

## 🛠️ DevOps Contribution

**Sri Harsha — Cloud & DevOps Engineer**

- Provisioned AWS EC2 instance (t3.micro, Tokyo region)
- Assigned Elastic IP for permanent static addressing
- Containerized backend using Docker
- Pushed image to DockerHub for disaster recovery
- Configured Nginx as reverse proxy
- Set up CloudWatch Agent for memory and disk monitoring
- Configured CloudWatch Alarms with SNS email alerts
- Set up AWS Security Groups and firewall rules
- Connected Vercel frontend ↔ EC2 backend
- Designed complete DevOps documentation suite
- Entire Phase 1 setup completed from mobile (Android + Termius)

---

## 📘 Documentation

All DevOps documentation is inside `/devops`:

| File | Description |
|------|-------------|
| [`devops/doc/architecture.md`](devops/doc/architecture.md) | System architecture overview |
| [`devops/doc/deployment.md`](devops/doc/deployment.md) | Full deployment steps |
| [`devops/doc/aws-setup.md`](devops/doc/aws-setup.md) | AWS configuration guide |
| [`devops/doc/server-setup.md`](devops/doc/server-setup.md) | Server operations guide |
| [`devops/doc/docker-setup.md`](devops/doc/docker-setup.md) | Docker and container guide |
| [`devops/configs/nginx.conf`](devops/configs/nginx.conf) | Nginx configuration |

---

## 🧪 Run Locally

### Frontend
```bash
npm install
npm run dev
```
App runs at: http://localhost:3000/

### Backend
```bash
cd resume-backend
npm install
node server.js
```
API runs at: http://localhost:3001/

### Backend via Docker
```bash
docker build -t pdf-server .
docker run -d --name pdf-server --restart always -p 3001:3001 pdf-server
```

---

## 🔐 Environment Variables

### Frontend
Set inside `.env.local`:
```env
NEXT_PUBLIC_API_URL=http://<YOUR-ELASTIC-IP>/generate
```

### Backend
```env
PORT=3001
```

---

## 🚀 Deployment

### Frontend
Deployed via GitHub → Vercel integration (auto-deploy on push)

### Backend
Dockerized and deployed on AWS EC2:
```bash
# Pull from DockerHub and run
docker pull sriharshareddy6464/pdf-server:latest
docker run -d --name pdf-server --restart always -p 3001:3001 sriharshareddy6464/pdf-server:latest
```

Full steps: [`devops/doc/deployment.md`](devops/doc/deployment.md)

---

## 📡 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/generate` | POST | LaTeX → PDF |

**Request:**
```json
{
  "code": "your latex code here"
}
```
**Response:** PDF file

---

## 🔜 Roadmap (Phase 2)

- [ ] Domain + SSL (Let's Encrypt)
- [ ] Docker Compose
- [ ] Terraform (Infrastructure as Code)
- [ ] EKS + Kubernetes
- [ ] Prometheus + Grafana
- [ ] GitHub Actions CI/CD pipeline

---

## 👤 Author

**Adapala Sriharsha Reddy**
Cloud & DevOps Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://www.linkedin.com/in/sriharshareddy-adapala-781a76299/)
[![Gmail](https://img.shields.io/badge/Gmail-Mail-red)](mailto:adapalasriharshareddy@gmail.com)

---

## ⭐ What This Project Demonstrates

- Real-world AWS cloud deployment
- Docker containerization and DockerHub backup
- Nginx reverse proxy configuration
- CloudWatch monitoring and alerting
- Production-grade disaster recovery
- Complete DevOps documentation
- Full infrastructure setup from a mobile device