# **System Architecture – Creorez (AI Resume Builder)**

## ✅ Overview

Creorez is a full-stack AI-powered resume builder consisting of:

- **Frontend** — Next.js (App Router) deployed on **Vercel**
- **Backend** — Node.js microservice deployed on **AWS EC2**
- **Core Engine** — LaTeX → PDF resume generation via Tectonic
- **Container** — Dockerized backend for portability and reproducibility
- **IaC** — Terraform for infrastructure provisioning
- **CI/CD** — GitHub Actions for automated builds and deployments
- **Monitoring** — CloudWatch (optional, re-enable in production)

---

## ✅ High-Level Architecture Diagram
```
                 ┌────────────────────────────────┐
                 │            User Browser         │
                 └───────────────┬────────────────┘
                                 │
                                 ▼
                     (Vercel Frontend - Next.js)
                 ┌────────────────────────────────┐
                 │  Resume Builder UI              │
                 │  Fill Form → Generate Resume    │
                 │  ATS Score Page                 │
                 │  Enhance Resume                 │
                 └───────────────┬────────────────┘
                                 │  HTTP API Call
                                 ▼
                 ┌────────────────────────────────┐
                 │   AWS EC2 (Ubuntu 24.04)        │
                 │   Region: ap-northeast-1        │
                 │   Provisioned by Terraform      │
                 │  ┌──────────────────────────┐  │
                 │  │   Nginx (Port 80)         │  │
                 │  │   Reverse Proxy           │  │
                 │  └────────────┬─────────────┘  │
                 │               ↓                 │
                 │  ┌──────────────────────────┐  │
                 │  │   Docker Container        │  │
                 │  │   Node.js 22 + Tectonic   │  │
                 │  │   Port 3001               │  │
                 │  └──────────────────────────┘  │
                 └───────────────┬────────────────┘
                                 │
                                 ▼
                         PDF Response
                 ┌────────────────────────────────┐
                 │   Vercel Frontend (Next.js)     │
                 │   Renders PDF to user           │
                 └────────────────────────────────┘
```

---

## ✅ Terraform Infrastructure Architecture
```
Developer runs terraform apply
            ↓
    Terraform provisions:
  ┌───────────────────────────────┐
  │  1. EC2 Instance              │
  │  2. Security Group            │
  │  3. Elastic IP Association    │
  │  4. IAM Role + Profile        │
  │  5. ECR Repository            │
  └──────────────┬────────────────┘
                 ↓
      EC2 user_data runs automatically:
  ┌───────────────────────────────┐
  │  6. Install Docker + Nginx    │
  │  7. Install Tectonic          │
  │  8. Pull DockerHub image      │
  │  9. Start PDF container       │
  │  10. Configure Nginx          │
  └───────────────────────────────┘
                 ↓
    Zero manual server setup ✅
```

---

## ✅ CI/CD Pipeline Architecture
```
Developer pushes to main (resume-backend/)
            ↓
    GitHub Actions
  ┌───────────────────────────┐
  │  1. Checkout code         │
  │  2. Login to DockerHub    │
  │  3. Build Docker image    │
  │  4. Push to DockerHub     │
  └──────────┬────────────────┘
             ↓
      SSH into EC2 (same Elastic IP always)
  ┌───────────────────────────┐
  │  5. Pull latest image     │
  │  6. Remove old container  │
  │  7. Run new container     │
  │  8. Verify docker ps      │
  └───────────────────────────┘
             ↓
    Zero downtime deploy ✅
```

---

## ✅ Components Breakdown

### **1. Frontend (Vercel + Next.js)**
- Interactive resume builder UI
- Form inputs sent to backend for PDF generation
- Receives PDF response and renders to user
- Auto-deploys from GitHub on every push

### **2. Backend (Node.js on AWS EC2)**

| Component | Purpose |
|-----------|---------|
| **Node.js 22** | Serves API endpoints |
| **Express** | Handles `/generate` route |
| **Tectonic** | Lightweight LaTeX → PDF engine (70-100MB vs TeXLive 3GB+) |
| **Docker** | Containerizes entire backend — portable and reproducible |
| **Nginx** | Reverse proxy, routes port 80 → Docker container port 3001 |
| **Elastic IP** | Permanent static IP — survives EC2 reboots and terraform rebuilds |

### **3. Terraform (IaC)**

| Resource | Purpose |
|----------|---------|
| `aws_instance` | EC2 server provisioning |
| `aws_security_group` | Firewall rules as code |
| `aws_eip` (data) | Reference existing static IP |
| `aws_eip_association` | Attach static IP to EC2 |
| `aws_iam_role` | EC2 permissions |
| `aws_ecr_repository` | Private Docker registry |

### **4. CI/CD (GitHub Actions)**

| Step | Action |
|------|--------|
| Trigger | Push to `main` on `resume-backend/**` |
| Build | Docker image built on GitHub runner |
| Push | Image pushed to DockerHub |
| Deploy | SSH into EC2 → pull image → restart container |
| Manual | `workflow_dispatch` for manual triggers |

### **5. DockerHub Backup**

| Item | Value |
|------|-------|
| Image | `sriharshareddy6464/pdf-server:latest` |
| Purpose | Backup — restore entire backend in under 10 minutes |

### **6. ECR Registry**

| Item | Value |
|------|-------|
| Repository | `cloud/creorez-latex` |
| Region | ap-northeast-1 (Tokyo) |
| Purpose | Private AWS registry for future EKS migration |

### **7. Monitoring (CloudWatch — Optional)**

> 💡 Disabled in alpha stage to reduce costs. Re-enable in production.

| Metric | Interval | Alarm Threshold |
|--------|----------|-----------------|
| CPU Utilization | 1 min (default) | > 60% |
| Memory Used % | 1 hour | > 75% |
| Disk Used % | 1 hour | > 60% |

---

## ✅ API Communication
```
Frontend (Vercel)
    → POST /generate { "code": "<latex>" }
    → Backend (EC2)
    → Tectonic compiles LaTeX → PDF
    → Returns PDF binary
    → Frontend renders to user
```

---

## ✅ Deployment Architecture

### **Frontend**
- Hosted on **Vercel**
- Auto-deploys from GitHub on push
- Points to EC2 Elastic IP for backend calls

### **Backend**
- Hosted on **AWS EC2** (Ubuntu 24.04, t3.micro, 32GB gp3)
- Region: Asia Pacific Tokyo (ap-northeast-1)
- Provisioned entirely by **Terraform**
- Elastic IP for permanent addressing — never changes
- Dockerized — `--restart always` handles crashes and reboots
- Nginx reverse proxy on port 80
- GitHub Actions handles all code deployments automatically

---

## ✅ DevOps Workflow

### Infrastructure (Terraform — run once):
1. `terraform init`
2. `terraform plan`
3. `terraform apply` → entire infra provisioned automatically

### Code Deployment (GitHub Actions — automatic):
1. Push code to `main`
2. Pipeline triggers automatically
3. New Docker image built and deployed
4. Zero manual work ✅

---

## ✅ Security Considerations

- SSH limited to authorised IPs only
- Ports open: **22 / 80 / 443 / 3001**
- Docker `--restart always` — auto recovery on crash or reboot
- Nginx prevents direct Node exposure
- No credentials or secrets committed to Git
- Real IPs and keys never in version control
- GitHub Secrets used for all sensitive pipeline values
- IAM Role scoped to CloudWatch + ECR only
- Terraform state files excluded from Git

---

## ✅ Disaster Recovery

If EC2 is lost or terminated:
```bash
# 1. Run Terraform — entire infra rebuilds automatically
terraform apply

# 2. Same Elastic IP reassigned automatically
# 3. Docker container starts automatically via user_data
# 4. GitHub Actions CI/CD resumes automatically
# Back online in under 10 minutes ✅
```

---

## 🔜 Upcoming Architecture (Phase 3)
```
Current (Phase 2)              Upcoming (Phase 3)
──────────────────             ──────────────────
Single EC2             →       EKS (Kubernetes)
Docker run             →       Helm Charts + Pods
Terraform EC2          →       Terraform EKS
Nginx                  →       Ingress Controller
CloudWatch             →       Prometheus + Grafana
HTTP only              →       HTTPS (SSL via Let's Encrypt)
DockerHub              →       ECR (private registry)
```

---

## ✅ Architecture Files

- `deployment.md` — full deployment steps
- `aws-setup.md` — AWS configuration guide
- `server-setup.md` — server operations guide
- `docker-setup.md` — Docker and container guide
- `terraform-setup.md` — Terraform IaC guide
- `serverless-attempt.md` — Lambda migration attempt
- `configs/nginx.conf` — Nginx configuration
- `.github/workflows/deploy.yml` — CI/CD pipeline
- `terraform/` — complete IaC configuration

---

## ✅ Author

**Adapala Sriharsha Reddy — DevOps & Cloud Engineer**

Responsibilities:
- Designed and provisioned AWS EC2 architecture
- Containerized backend using Docker
- Configured Nginx reverse proxy
- Implemented Terraform IaC for full infrastructure automation
- Implemented GitHub Actions CI/CD pipeline
- Implemented DockerHub + ECR backup strategy
- Assigned Elastic IP for permanent availability
- Attempted serverless migration (Lambda + ECR)
- Set up CloudWatch monitoring and alerting
- Connected backend with Vercel frontend
- Phase 1 setup completed from mobile (Android + Termius)