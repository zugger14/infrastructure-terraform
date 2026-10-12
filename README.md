# Multi-App AWS Infrastructure as Code (Terraform)

A modular, production-grade, and 100% DRY Terraform repository providing flexible deployment paradigms for the **DevOps Portfolio**, **AMS**, and **MusicBook** web applications:

1. **Option A: EC2 Multi-App Single-Host Architecture (`deployment_target = "ec2"`)**
   - Directly provisions an AWS EC2 instance (`t3.micro`, Amazon Linux 2023) designed to be configured with the standalone Ansible repository.
   - Inbound security groups configured for Port `22` (SSH), Port `80` (HTTP root & subdomain reverse proxy), Port `8080` (AMS direct), Port `8000` (MusicBook direct), and Port `3000` (Portfolio container direct).

2. **Option B: Serverless ECS Fargate Microservices with ALB (`deployment_target = "ecs"`)**
   - High-availability, self-healing, zero-OS maintenance.
   - Deploys **three isolated containers** for `ams`, `devops-portfolio`, and `musicbook`.
   - Uses the **lowest compute options available on AWS Fargate**:
     - **CPU**: `256` (`0.25 vCPU`) per task
     - **Memory**: `512` (`0.5 GB RAM`) per task
   - Automatically provisions an **AWS Application Load Balancer (ALB)** with path and host routing rules forwarding:
     - `http://<ALB_DNS>/` (and root path `/*`) ➔ `portfolio` container
     - `http://<ALB_DNS>/ams*` (or `http://ams.*`) ➔ `ams` container
     - `http://<ALB_DNS>/musicbook*` (or `http://musicbook.*`) ➔ `musicbook` container

3. **Option C: Elastic Container Registry (ECR)**
   - DRY private ECR repositories for all applications with 14-day automated image lifecycle expiration.
   - Built with `force_delete = true` so running `terraform destroy` cleanly tears down repositories even if container images have been pushed.

4. **Option D: Remote State & Locking (S3 + DynamoDB)**
   - Remote state storage in AWS S3 (`multiapp-terraform-state-<ACCOUNT_ID>`) with server-side encryption and versioning.
   - Concurrency locking via DynamoDB (`terraform-state-locks`) to safely sync state between local runs and GitHub Actions CI/CD.

---

## 📁 Modular Directory Structure

```text
infrastructure-terraform/
├── main.tf                      # S3 Remote backend & AWS provider requirements
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
    ├── ecr/                     # DRY ECR repos with force_delete and lifecycle policies
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

Everything in the `ecs` and `ecr` modules is dynamically generated using Terraform's `for_each` over the `var.ecs_apps` map.

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
    path_pattern        = "/newapp*"
    host_header_pattern = ["newapp.*"]
    health_check_path   = "/"
  }
}
```
Terraform automatically creates the private ECR repo, CloudWatch Log Group, ECS Task Definition, Fargate Service, Target Group, and ALB routing rule.

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

### 3. Initialize & Plan
Initialize the S3 remote backend:
```bash
terraform init
```

### 4. Interactive Apply
Run:
```bash
terraform apply
```
Terraform will interactively prompt you:
```text
var.deployment_target
  Target infrastructure to deploy: 'ec2' (single EC2 host with Ansible), 'ecs' (Fargate containers + ALB), 'both', or 'none'

  Enter a value: 
```

You can also pass it directly as a CLI flag or in `terraform.tfvars`:
```bash
# Deploy ECS Fargate containers and ALB
terraform apply -var="deployment_target=ecs"

# Deploy EC2 host
terraform apply -var="deployment_target=ec2"

# Deploy both
terraform apply -var="deployment_target=both"
```

Outputs will display your EC2 Public IP, ECR repository URLs, and the ALB DNS endpoint to test the applications in your browser.

---

## 🧹 Destroying Resources
When destroying resources:
```bash
terraform destroy
```
Because `force_delete = true` is configured on all ECR repositories, Terraform will cleanly destroy all resources without failing on non-empty image repositories.

---

## 🔄 Automated CI/CD Pipeline (GitHub Actions)

This repository includes a multi-stage GitHub Actions workflow in [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml):

### 1. Automatic Validation on Push / Pull Request
Whenever code is pushed to `main` (or a PR is opened):
- Checks code formatting (`terraform fmt`)
- Validates configuration and module schemas (`terraform validate`)
- Generates an execution plan preview (`terraform plan`) and stores the plan artifact

### 2. On-Demand One-Click Deployment (`workflow_dispatch`)
To apply changes to AWS without risking accidental runs on intermediate commits:
1. Navigate to the repository on GitHub: **[Actions](https://github.com/zugger14/infrastructure-terraform/actions)**
2. Select **"Terraform CI/CD"** in the left sidebar
3. Click the **"Run workflow"** button
4. Select the action:
   - `apply` (default): Applies the planned changes safely to AWS
   - `destroy`: Tears down all resources when no longer needed
5. Click **"Run workflow"** to execute
