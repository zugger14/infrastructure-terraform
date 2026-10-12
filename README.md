# Multi-App AWS Infrastructure as Code (Terraform)

A modular, production-grade, and 100% DRY Terraform repository providing two parallel deployment paradigms for the **DevOps Portfolio**, **AMS**, and **MusicBook** web applications:

1. **Option A: EC2 Multi-App Single-Host Architecture**
   - Directly mirrors the active AWS EC2 setup (`t3.micro`, Amazon Linux 2023).
   - Inbound rules configured for Port `22` (SSH), Port `80` (HTTP root & subdomain reverse proxy), Port `8080` (AMS direct port), Port `8000` (MusicBook direct port), and Port `3000` (Portfolio container direct port).

2. **Option B: Serverless ECS Fargate Microservices with Application Load Balancer**
   - High-availability, self-healing, zero-OS maintenance.
   - Deploys **three isolated containers** for `ams`, `devops-portfolio`, and `musicbook`.
   - Uses the **lowest compute options available on AWS Fargate**:
     - **CPU**: `256` (`0.25 vCPU`) per task
     - **Memory**: `512` (`0.5 GB RAM`) per task
   - Automatically provisions an **AWS Application Load Balancer (ALB)** with Host-based routing rules forwarding:
     - `http://<ALB_DNS>/` (or any custom domain) ➔ `portfolio` container
     - `http://ams.*` ➔ `ams` container
     - `http://musicbook.*` ➔ `musicbook` container

---

## 📁 Modular Directory Structure

```text
infrastructure-terraform/
├── main.tf                      # Terraform & AWS provider requirements
├── variables.tf                 # Global input variables & app mapping
├── infra.tf                     # Master orchestrator connecting all modules
├── outputs.tf                   # Public IP, ALB DNS, and cluster outputs
├── terraform.tfvars.example     # Ready-to-use variables template
└── modules/
    ├── vpc/                     # Multi-AZ VPC, public subnets, private subnets, IGW
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/                     # EC2 t3.micro instance, gp3 volume, security groups
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── alb/                     # Public Application Load Balancer & HTTP listener
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecs/                     # DRY ECS Fargate cluster, task definitions, and target groups
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 🌟 How the DRY Architecture Works

You **never need to duplicate module code or write new task definitions** to add another application.

Everything in the `ecs` module is dynamically generated using Terraform's `for_each` over the `var.ecs_apps` map.

To add a 4th or 5th app in the future, simply add an entry in `terraform.tfvars`:
```hcl
ecs_apps = {
  # ... existing apps ...

  new_app = {
    cpu                 = 256
    memory              = 512
    container_port      = 5000
    container_image     = "public.ecr.aws/youruser/new_app:latest"
    desired_count       = 1
    priority            = 400
    host_header_pattern = ["newapp.*"]
    health_check_path   = "/"
  }
}
```
Terraform automatically creates the CloudWatch Log Group, ECS Task Definition, Fargate Service, Target Group, and ALB routing rule.

---

## 🚀 Quickstart & Execution

### 1. Prerequisites
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (`brew install terraform`)
- AWS CLI configured (`aws configure`) with valid credentials.

### 2. Configure Variables
Copy the sample file:
```bash
cp terraform.tfvars.example terraform.tfvars
```
Adjust `enable_ec2_deployment` or `enable_ecs_deployment` to `true`/`false` depending on what you want to provision.

### 3. Initialize & Plan
```bash
terraform init
terraform plan
```

### 4. Apply
```bash
terraform apply
```

Outputs will display your EC2 Public IP and the ALB DNS endpoint to test the applications in your browser.
