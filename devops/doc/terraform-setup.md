# **Terraform Setup Guide – Creorez Infrastructure as Code**

This document describes the complete Terraform setup for provisioning Creorez backend infrastructure on AWS. It includes provider configuration, resource definitions, and deployment workflow.

---

## ✅ **1. Why Terraform?**

| Without Terraform | With Terraform |
|-------------------|----------------|
| Click through AWS Console | Write infrastructure as code |
| Hard to reproduce | Rebuild entire infra in minutes |
| No version control | Full Git history of infra changes |
| Manual and error-prone | Automated and consistent |
| Hard to share with team | Everyone runs same config |

---

## ✅ **2. Folder Structure**
```
terraform/
├── main.tf          ← AWS provider configuration
├── variables.tf     ← Input variables
├── outputs.tf       ← Output values
├── ec2.tf           ← EC2 instance + user_data
├── security.tf      ← Security groups
├── network.tf       ← Elastic IP association
├── iam.tf           ← IAM roles and policies
├── ecr.tf           ← ECR repository
└── .gitignore       ← Excludes sensitive files
```

---

## ✅ **3. Prerequisites**

### Install Terraform:
```bash
winget install Hashicorp.Terraform
terraform --version
```

### Install AWS CLI:
```bash
winget install Amazon.AWSCLI
aws --version
```

### Configure AWS CLI:
```bash
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region: ap-northeast-1
# Default output format: json
```

### Verify:
```bash
aws sts get-caller-identity
```

---

## ✅ **4. Infrastructure Overview**
```
Terraform provisions:
├── EC2 Instance (t3.micro, Ubuntu 24.04, 32GB gp3)
├── Security Group (ports 22, 80, 443, 3001)
├── Elastic IP Association (existing static IP)
├── IAM Role (CloudWatch + ECR permissions)
├── IAM Instance Profile
└── ECR Repository (cloud/creorez-latex)

Auto-configured via user_data:
├── Node.js 22
├── Docker
├── Nginx (reverse proxy)
├── Tectonic (LaTeX engine)
└── PDF server container (from DockerHub)
```

---

## ✅ **5. Variables**

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `ap-northeast-1` | AWS region (Tokyo) |
| `project_name` | `creorez` | Project name for tagging |
| `environment` | `production` | Environment tag |
| `instance_type` | `t3.micro` | EC2 instance type |
| `ami_id` | `ami-0d52744d6551d851e` | Ubuntu 24.04 Tokyo AMI |
| `key_pair_name` | `Creorez` | EC2 SSH key pair name |
| `volume_size` | `32` | Storage size in GB |

---

## ✅ **6. Deployment Workflow**

### First time setup:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Rebuild infrastructure:
```bash
terraform destroy
terraform apply
```

### Check outputs:
```bash
terraform output
```

### Validate config:
```bash
terraform validate
```

---

## ✅ **7. Outputs**

| Output | Description |
|--------|-------------|
| `instance_id` | EC2 Instance ID |
| `elastic_ip` | Static Elastic IP |
| `api_endpoint` | Backend API URL |
| `ecr_repository_url` | ECR image registry URL |
| `security_group_id` | Security Group ID |
| `iam_role_arn` | IAM Role ARN |
| `instance_profile_arn` | Instance Profile ARN |

---

## ✅ **8. Elastic IP Strategy**

Elastic IP is **permanent** — never changes even after destroy + apply.
```
terraform destroy
    ↓
EC2 deleted
EIP released from instance (NOT deleted)
    ↓
terraform apply
    ↓
New EC2 created
Same EIP reassociated ✅
GitHub Actions IP never changes ✅
```

**Current Elastic IP:** kept private — never commit to Git.

---

## ✅ **9. user_data — Automated Server Setup**

When EC2 launches, user_data script automatically:
```
1. Updates Ubuntu packages
2. Installs Node.js 22
3. Installs Docker
4. Installs Nginx
5. Installs Tectonic dependencies
6. Installs Tectonic LaTeX engine
7. Pulls Docker image from DockerHub
8. Starts PDF server container
9. Configures Nginx reverse proxy
10. Everything live — zero manual work ✅
```

Monitor progress:
```bash
sudo tail -f /var/log/user-data.log
```

---

## ✅ **10. Rebuild from Scratch (New AWS Account)**

If starting completely fresh:
```
1. Create new IAM user → AdministratorAccess
2. Generate new access keys → aws configure
3. Create new key pair in Tokyo → download .pem
4. Allocate new Elastic IP
5. Update variables.tf → new key pair name
6. Update network.tf → new Elastic IP
7. terraform init
8. terraform apply
9. Update GitHub Actions secrets:
   - EC2_HOST → new Elastic IP
   - EC2_SSH_KEY → new .pem contents
```

---

## ✅ **11. CI/CD Integration**

Terraform provisions infrastructure once.
GitHub Actions handles all code deployments automatically.
```
Terraform (you run manually)
    ↓
EC2 exists with correct config
    ↓
GitHub Actions (automatic on push)
    ↓
Build → Push DockerHub → SSH → Deploy
    ↓
Zero manual work for code changes ✅
```

---

## ✅ **12. Cost**

| Resource | Cost |
|----------|------|
| EC2 t3.micro | ~$7.50/month |
| Elastic IP (attached) | Free |
| ECR (500MB free tier) | Free |
| gp3 32GB storage | ~$2.56/month |
| **Total** | **~$10/month** |

---

## ⚠️ **Security Rules**

- Never commit `.tfstate` files — contain sensitive data
- Never commit `.pem` files — SSH private keys
- Never commit `terraform.tfvars` — may contain secrets
- Always use `.gitignore` for terraform folder
- IAM access keys → never in any file in repo

---

## 🔜 **Next Steps (Phase 3)**

- [ ] EKS + Kubernetes
- [ ] Helm Charts
- [ ] Prometheus + Grafana
- [ ] Terraform modules for reusability
- [ ] Remote state backend (S3 + DynamoDB)