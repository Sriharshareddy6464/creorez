# **Serverless Migration Attempt – Creorez PDF Generator**

## 🎯 Goal
Migrate PDF generation backend from EC2 to AWS Lambda to reduce costs and eliminate server management.

---

## 📋 What Happened — In Order

1. Started thinking about migrating PDF generation from EC2 to serverless (Lambda) to reduce costs and eliminate server management

2. Conflict 1 — Lambda 250MB deployment package limit. Tectonic ~100MB + Node modules ~50MB + LaTeX fonts download at runtime = won't fit

3. Alternative found — Lambda supports Docker container images up to 10GB. This bypasses the 250MB limit entirely

4. Created AWS ECR private registry. Repository: `cloud/creorez-latex` (ap-northeast-1 Tokyo). Access conflict — IAM user had no permissions. Fix — created IAM user `creorez` with AdministratorAccess

5. Configured AWS CLI on laptop
```bash
aws configure
# access key + secret + region ap-northeast-1
```

6. Pulled existing image from DockerHub → tagged → pushed to ECR successfully

7. Created Lambda function with container image from ECR

8. First test — Timeout. Reason — `server.js` starts Express HTTP server. Lambda needs `exports.handler` not an HTTP server

9. Rewrote `server.js` → `lambda.js` with proper Lambda handler. No Express, returns base64 PDF, statusCode responses

10. Updated Dockerfile for Lambda — added `aws-lambda-ric` (Lambda runtime interface client). Error — cmake not installed. Fix — added `cmake`, `make`, `g++`, `python3`, `xz-utils` to Dockerfile

11. Build succeeded but Lambda rejected the image
    - Error — image manifest not supported
    - Reason — `docker buildx` creates multi-platform manifest, Lambda only accepts single platform OCI manifest
    - Fix — added `--provenance=false` flag to build command
```bash
docker build --platform linux/amd64 --provenance=false -t <ECR-URI>:latest .
```

12. Lambda accepted image but Tectonic failed at runtime
    - Error — shared libraries missing (exit code 127)
    - Reason — Tectonic binary copied from Debian image, Lambda runs Amazon Linux — different OS, different libraries
    - Fix — switched to Tectonic musl static binary (no external dependencies)
```
tectonic-0.15.0-x86_64-unknown-linux-musl.tar.gz
```

13. Lambda accepted new image but Tectonic still failed
    - Error — `Read-only file system (os error 30)`
    - Reason — Lambda filesystem is read-only except `/tmp`, Tectonic tries to write cache/config to default locations

14. Multiple fix attempts for read-only filesystem:
    - Attempt 1 — set `HOME=/tmp`, `TECTONIC_CACHE_DIR=/tmp/tectonic-cache` via env vars
    - Attempt 2 — passed env vars directly to spawn + `--cache-dir` flag
    - Attempt 3 — pre-created all `/tmp` directories before spawn
    - Attempt 4 — added `XDG_CACHE_HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME` all pointing to `/tmp`
    - **All failed — same error persisted**

15. Root cause identified — Tectonic downloads LaTeX packages from internet at runtime. Lambda has restricted outbound internet access by default. Even with `/tmp` writable, Tectonic can't reach download servers. This is a fundamental incompatibility — not fixable without VPC + NAT Gateway (~$30/month extra)

16. Decision — abort Lambda migration. EC2 remains best option for Tectonic-based PDF generation. EC2 was untouched and still running throughout entire session

17. Reverted Dockerfile back to EC2 version. `lambda.js` kept in repo for future reference

---

## ❌ Why Lambda Failed

| Requirement | Lambda | EC2 |
|-------------|--------|-----|
| Tectonic runtime downloads | ❌ Blocked | ✅ Works |
| Writable filesystem | ❌ Only /tmp | ✅ Full access |
| Binary dependencies | ❌ OS mismatch | ✅ apt install |
| Outbound internet | ❌ Restricted | ✅ Full access |

---

## ✅ Current State

| Component | Status |
|-----------|--------|
| EC2 + Docker + Tectonic | ✅ Running (untouched) |
| ECR Repository | ✅ Created and populated |
| Lambda Function | ✅ Created but not in use |
| AWS CLI | ✅ Configured |
| `lambda.js` | ✅ Kept for future reference |

---

## 🔜 Future Options
```
Option A — Stay on EC2 (current)
→ Terraform for infrastructure as code
→ EKS + Kubernetes
→ Prometheus + Grafana


Option B — ECS Fargate (recommended future migration)
→ Serverless containers
→ Full internet access (Tectonic works)
→ Scales to zero when not used
→ No EC2 to manage
```

---

## 💡 Key Learnings

- Lambda is not suitable for tools that download dependencies at runtime
- Lambda image format requires `--provenance=false` for single platform builds
- Debian binaries don't work on Amazon Linux (Lambda) — always use musl static binaries
- ECS Fargate is a better serverless option for containerized workloads like this