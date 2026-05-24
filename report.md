# **Creorez — AI Resume Builder**
## Complete Infrastructure & DevOps Documentation

---

## 1. Executive Summary

**What the system is:**
Creorez is a full-stack AI-powered resume builder that accepts user form inputs, converts them into LaTeX code, and generates professionally formatted ATS-friendly PDF resumes via a cloud-hosted backend engine.

**Why it exists:**
Most resume builders generate basic HTML/CSS PDFs that fail ATS (Applicant Tracking System) scans. Creorez uses LaTeX — the gold standard for typesetting — to produce PDFs that are structurally clean, visually professional, and ATS-optimized.

**What problem it solves:**
- Users fill a form → system generates LaTeX code → Tectonic compiles it → PDF returned instantly
- Eliminates manual LaTeX knowledge requirement for users
- Produces higher quality PDFs than browser-rendered alternatives

**Current architecture maturity:**
Production-ready backend with Dockerized microservice, Infrastructure as Code via Terraform, automated CI/CD pipeline, and permanent static IP. Frontend on Vercel. SSL and domain name pending team decision.

---

## 2. Recruiter Snapshot

| Category | Details |
|----------|---------|
| **Stack** | Node.js 22, Express, Tectonic (LaTeX engine), Next.js, React, TailwindCSS |
| **Infrastructure** | AWS EC2 (t3.micro), Elastic IP, ECR, IAM, Security Groups |
| **IaC** | Terraform — entire infra provisioned as code |
| **CI/CD** | GitHub Actions — auto build, push, deploy on every git push |
| **Deployment** | Docker container on EC2, Nginx reverse proxy, DockerHub backup |
| **Monitoring** | CloudWatch Agent (memory, disk, CPU alarms via SNS email) |
| **Security** | IAM roles, Security Groups, GitHub Secrets, no credentials in code |
| **Scale assumptions** | Alpha stage — single EC2, single container, no load balancing yet |

---

## 3. Problem Statement

**What was broken or missing:**
- No infrastructure as code — everything was manually clicked
- No CI/CD — deployments required manual SSH and commands
- Single EC2 with no backup or reproducibility
- LaTeX engine (Tectonic) not containerized — installed directly on server
- No monitoring — failures were invisible
- No disaster recovery plan

**Why simpler systems fail:**
- Raw Node.js on EC2 without Docker = hard to reproduce, version conflicts
- Manual deployments = human error, inconsistency, slow iteration
- No IaC = if EC2 dies, rebuilding takes hours of manual work
- Tectonic downloads 200+ LaTeX packages on first run = timeout on cold starts

**Why this architecture matters:**
- Docker ensures identical environment everywhere
- Terraform means entire infrastructure rebuilds in minutes
- GitHub Actions means zero manual deployments
- Elastic IP means the endpoint never changes even after full infrastructure rebuild

---

## 4. System Evolution Timeline

### Version 1 — Prototype (Nov 2025)
- Manual EC2 setup via AWS Console
- Node.js + Tectonic installed directly on server
- PM2 for process management
- Nginx reverse proxy
- No Docker, no CI/CD, no IaC
- Deployed by SSH and manual commands

### Version 2 — Containerized (Mar 2026)
- Dockerized Node.js + Tectonic backend
- DockerHub image backup
- GitHub Actions CI/CD pipeline
- CloudWatch monitoring with SNS alerts
- Elastic IP for permanent addressing
- Complete DevOps documentation suite
- Entire Phase 1 setup done from Android mobile via Termius

### Version 3 — Infrastructure as Code (Mar 2026)
- Full Terraform IaC — EC2, Security Groups, EIP, IAM, ECR
- Automated server setup via user_data script
- Multi-region experiment (Tokyo + Hyderabad)
- AWS ECR private registry
- Serverless migration attempt (Lambda) — documented failure
- Zero manual server configuration on fresh deploy

### Version 4 — Roadmap
- EKS + Kubernetes for auto-scaling
- Prometheus + Grafana replacing CloudWatch
- Domain name + SSL (Let's Encrypt)
- RDS for user data persistence
- S3 for PDF storage
- ALB for load balancing
- Staging environment
- Remote Terraform state (S3 + DynamoDB)

---

## 5. Architecture Evolution

### Local
```
Developer machine
Node.js + Tectonic installed locally
Manual testing only
No deployment pipeline
```

### Dockerized (Phase 1)
```
EC2 (manual)
    ↓
Docker container (Node.js + Tectonic)
    ↓
Nginx reverse proxy
    ↓
Elastic IP
```

### EC2 + IaC (Phase 2 — Current)
```
Terraform provisions:
    EC2 + Security Groups + EIP + IAM + ECR
        ↓
user_data auto-installs:
    Docker + Nginx + Tectonic
        ↓
GitHub Actions auto-deploys:
    Build → DockerHub → SSH → Deploy
```

### RDS (Planned)
```
Current: No persistent storage
Planned: RDS PostgreSQL for user accounts and resume history
```

### S3 + CloudFront (Planned)
```
Current: PDFs returned directly in response
Planned: S3 storage → CloudFront CDN → signed URLs for downloads
```

### Private Subnet Backend (Planned)
```
Current: EC2 in public subnet
Planned: EC2 in private subnet → ALB in public subnet → traffic routing
```

### ALB (Planned)
```
Current: Single EC2 + Nginx
Planned: ALB → multiple EC2 instances → auto scaling
```

### IaC (Current)
```
terraform apply
    ↓
Entire infrastructure provisioned automatically
Zero manual AWS Console clicks
Reproducible in minutes
```

---

## 6. Infrastructure Decisions

**Why EC2?**
Tectonic (LaTeX engine) downloads packages from the internet at runtime. Lambda and other serverless options restrict outbound internet access — making Tectonic non-functional without expensive VPC + NAT Gateway setup. EC2 gives full internet access and filesystem control.

**Why Elastic IP?**
EC2 public IP changes on every reboot and every terraform rebuild. Elastic IP is permanent — the GitHub Actions CI/CD pipeline and frontend API URL never need updating regardless of how many times infrastructure is rebuilt.

**Why Nginx reverse proxy?**
- Clean URL on port 80 (no :3001 in the endpoint)
- Single entry point for future SSL termination
- Buffer between internet and Node.js process
- Handles connection upgrades and headers

**Why Docker?**
- Identical environment on every machine
- DockerHub backup — restore entire backend in 2 minutes anywhere
- `--restart always` handles crashes and reboots automatically
- No dependency conflicts on the host machine
- CI/CD just pulls and restarts — no install steps

**Why GitHub Actions?**
- Free for public repos
- Tight GitHub integration — triggers on push automatically
- No separate CI server to maintain
- Secrets management built in
- Runs in minutes

**Why Terraform?**
- Infrastructure becomes version controlled code
- Entire AWS setup reproducible with `terraform apply`
- Team can see exactly what infrastructure exists
- Easy to rebuild in new region or new account
- Eliminates "works on my AWS account" problems

---

## 7. CI/CD Workflow

### Build
```
git push to main (resume-backend/**)
    ↓
GitHub Actions runner (ubuntu-latest)
    ↓
docker build -t sriharshareddy6464/pdf-server:latest .
```

### Push
```
docker login (DockerHub credentials from GitHub Secrets)
    ↓
docker push sriharshareddy6464/pdf-server:latest
```

### Pull & Deploy
```
SSH into EC2 via Elastic IP (key from GitHub Secrets)
    ↓
docker pull sriharshareddy6464/pdf-server:latest
    ↓
docker rm -f pdf-server
    ↓
docker run -d --name pdf-server --restart always -p 3001:3001
```

### Rollback approach
```
DockerHub keeps previous image tags
    ↓
SSH into EC2
    ↓
docker run previous tag manually
    ↓
(Proper versioned tags planned for Phase 3)
```

### Failure handling
```
--restart always = container auto-restarts on crash
GitHub Actions shows failed step with logs
DockerHub image remains unchanged if push fails
EC2 keeps running old container if deploy fails
```

---

## 8. Networking & Security

### Security Groups
| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH access |
| 80 | HTTP | Nginx reverse proxy |
| 443 | HTTPS | Future SSL |
| 3001 | TCP | Docker container direct |

### SSL/TLS
- Currently HTTP only
- SSL pending domain name decision by team
- Let's Encrypt planned (free)
- Mixed content issue: Vercel (HTTPS) calling EC2 (HTTP) blocked by browsers
- Workaround: direct API testing via curl works fine

### IAM
- EC2 IAM Role: `creorez-ec2-role`
- Attached policies: `CloudWatchAgentServerPolicy`, `AmazonEC2ContainerRegistryReadOnly`
- IAM User: `creorez` with AdministratorAccess (dev stage — will scope down in production)
- No credentials stored on EC2 — IAM role handles permissions

### Traffic routing
```
Internet → Elastic IP → Security Group → Nginx (80) → Docker (3001) → Node.js
```

### Public/private boundaries
- Currently: EC2 in public subnet (alpha stage)
- Planned: EC2 in private subnet, ALB in public subnet

---

## 9. Monitoring & Observability

### Logs
```bash
# Application logs
docker logs pdf-server --follow

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System startup logs
sudo tail -f /var/log/user-data.log

# CloudWatch Agent logs
sudo tail -f /var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log
```

### Metrics
| Metric | Source | Interval |
|--------|--------|----------|
| CPU Utilization | EC2 default | 1 minute |
| Memory Used % | CloudWatch Agent | 1 hour |
| Disk Used % | CloudWatch Agent | 1 hour |

### Dashboards
- CloudWatch metrics dashboard (mem_used_percent, disk_used_percent)
- Prometheus + Grafana planned for Phase 3

### Alerts
| Alarm | Threshold | Action |
|-------|-----------|--------|
| `creorez-cpu-alarm` | CPU > 60% | SNS email |
| `creorez-memory-alarm` | Memory > 75% | SNS email |
| `creorez-disk-alarm` | Disk > 60% | SNS email |

> CloudWatch Agent currently disabled to reduce costs (~$10-15/month). Re-enable in production.

### Failure visibility
- CloudWatch alarms → SNS → email notification
- GitHub Actions shows build/deploy failures with full logs
- Docker `--restart always` auto-recovers without alerting

---

## 10. Failure Stories

### Failure 1 — Tectonic Cold Start Timeout
**What broke:** PDF generation failed for users on fresh container start.

**Why it broke:** Tectonic downloads 200+ LaTeX packages from the internet on first run. This takes 30-60 seconds. Frontend request timed out before completion.

**How debugged:**
```bash
docker logs pdf-server --follow
# Saw: note: downloading hyph-en-us.tex... (200+ files)
```

**What changed:** Pre-warm Tectonic cache during Docker build by adding a warmup compile step to Dockerfile. Packages baked into image — no runtime downloads.

---

### Failure 2 — EC2 Terminated Accidentally
**What broke:** Entire backend went down. Team noticed PDF generation stopped working.

**Why it broke:** EC2 instance was terminated manually thinking it was unused.

**How debugged:** AWS Console showed instance terminated. Elastic IP showed unassociated.

**What changed:** Rebuilt entire infrastructure using Terraform in under 10 minutes. DockerHub image pulled automatically. Led to implementing full IaC strategy so this can never be a multi-hour recovery again.

---

### Failure 3 — Terraform Created Duplicate EC2
**What broke:** Two EC2 instances running simultaneously in Tokyo. Elastic IP moved to new Terraform-created instance. Old instance became orphaned.

**Why it broke:** Terraform was run without importing existing resources. Created new EC2 and stole the Elastic IP from the original manually-created instance.

**How debugged:** AWS Console showed two instances: `Creorez` (old) and `creorez-prod` (new). SSH into both — old had no traffic, new was receiving all requests.

**What changed:** Terminated old instance. Established rule: always use `terraform import` for existing resources before `terraform apply`. Permanent Elastic IP strategy implemented — same IP survives any number of rebuilds.

---

### Failure 4 — GitHub Actions SSH Key Invalid Format
**What broke:** CI/CD pipeline failed with `Load key: invalid format`.

**Why it broke:** PowerShell default encoding adds BOM characters to `.pem` files, corrupting them.

**How debugged:** Pipeline logs showed SSH key rejection. Local test confirmed file encoding issue.

**What changed:**
```powershell
# Fixed with explicit ASCII encoding
aws ec2 create-key-pair ... | Out-File -FilePath "key.pem" -Encoding ascii
```

---

### Failure 5 — Lambda Serverless Migration Failed
**What broke:** Attempted migration from EC2 to AWS Lambda for cost savings. Lambda function created but PDF generation failed with exit code 1.

**Why it broke:** Tectonic downloads LaTeX packages from internet at runtime. Lambda restricts outbound internet access. Even with `/tmp` filesystem correctly configured, Tectonic couldn't reach download servers.

**How debugged:**
```
CloudWatch logs showed:
error: Read-only file system (os error 30)
Tectonic failed with exit code 1
```

Multiple fix attempts: env vars, `--cache-dir` flag, pre-creating directories — all failed.

**What changed:** Aborted Lambda migration. Documented entire attempt in `serverless-attempt.md`. Identified ECS Fargate as better serverless option (full internet access, writable filesystem). Stayed on EC2.

---

### Failure 6 — user_data Script Silent Failure
**What broke:** Fresh Terraform-provisioned EC2 had nothing installed. Docker not found, Nginx not running.

**Why it broke:** Terraform `user_data` heredoc with nested `<<'NGINX'` block conflicted with outer `<<-EOF`. Script failed silently at the Nginx configuration step.

**How debugged:**
```bash
sudo cat /var/log/cloud-init-output.log
# Showed: Failed to run module scripts_user
# Finished in 14 seconds (should take 3-5 minutes)
```

**What changed:** Replaced heredoc Nginx config with `echo` command. Added `exec > /var/log/user-data.log 2>&1` for proper logging. Now all setup steps visible in log file.

---

## 11. Tradeoffs & Limitations

### What is NOT production-ready:
- HTTP only — no SSL/TLS (mixed content blocks browser calls from Vercel HTTPS)
- Single EC2 — no high availability or load balancing
- No database — no user accounts, no resume history
- No PDF storage — PDFs generated fresh every time, not stored
- Tectonic cold start — first PDF on fresh container takes 30-60 seconds
- CloudWatch disabled — no active monitoring to save costs

### What still needs work:
- Domain name (team decision pending)
- SSL certificate (blocked by domain)
- RDS for user persistence
- S3 for PDF storage
- EKS for auto-scaling
- Prometheus + Grafana for proper observability
- Staging environment separate from production
- Versioned Docker image tags (currently only `latest`)
- Remote Terraform state (currently local — risky)

### What was intentionally skipped:
- VPC private subnets (overkill for alpha stage)
- ALB (single instance, no need yet)
- WAF (no public traffic yet)
- Multi-AZ (cost not justified for alpha)
- Docker Compose (single container, unnecessary complexity)
- Kubernetes (planned Phase 3 — not needed yet)

---

## 12. Screenshots & Evidence

> Screenshots intentionally omitted from version control for security.
> Sensitive data (IP addresses, instance IDs, account IDs) never committed to Git.

### What exists as evidence:
- GitHub Actions run history — visible in repo Actions tab
- DockerHub repository — `sriharshareddy6464/pdf-server:latest`
- Terraform state — complete infrastructure definition in `terraform/` folder
- CloudWatch alarms — configured in AWS Console (Tokyo region)
- Git commit history — full timeline of all infrastructure changes
- `devops/doc/` — complete documentation of every decision made

### What to capture for portfolio (blur sensitive data):
- [ ] EC2 instance dashboard (blur IP + instance ID)
- [ ] CloudWatch metrics graph (mem + disk)
- [ ] CloudWatch alarms (3 alarms — OK state)
- [ ] GitHub Actions successful pipeline run
- [ ] DockerHub repository page
- [ ] Terraform apply output (blur IPs)
- [ ] `docker ps` output on EC2
- [ ] Nginx status output

---

## Architecture Files Reference

| File | Description |
|------|-------------|
| `devops/doc/architecture.md` | System architecture overview |
| `devops/doc/deployment.md` | Full deployment steps |
| `devops/doc/aws-setup.md` | AWS configuration guide |
| `devops/doc/server-setup.md` | Server operations guide |
| `devops/doc/docker-setup.md` | Docker and container guide |
| `devops/doc/terraform-setup.md` | Terraform IaC guide |
| `devops/doc/serverless-attempt.md` | Lambda migration attempt |
| `terraform/` | Complete IaC configuration |
| `.github/workflows/deploy.yml` | CI/CD pipeline |

---

## Author

**Adapala Sriharsha Reddy — DevOps & Cloud Engineer**

- Designed and provisioned entire AWS infrastructure
- Containerized backend using Docker
- Implemented Terraform IaC for full infrastructure automation
- Built GitHub Actions CI/CD pipeline
- Attempted and documented serverless Lambda migration
- Set up CloudWatch monitoring and alerting
- Configured Nginx reverse proxy
- Implemented DockerHub + ECR backup strategy
- Assigned permanent Elastic IP strategy
- Phase 1 entire setup completed from Android mobile via Termius

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://www.linkedin.com/in/sriharshareddy-adapala-781a76299/)
[![Gmail](https://img.shields.io/badge/Gmail-Mail-red)](mailto:adapalasriharshareddy@gmail.com)
