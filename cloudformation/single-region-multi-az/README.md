## What is this

This repository contains an AWS CloudFormation template and supporting documentation to deploy a **single-region, multi-AZ**, development-ready infrastructure for containerized web applications.  
It uses AWS services such as VPC, subnets, NAT Gateway, ECS (Fargate), Application Load Balancer (ALB), Security Groups, and IAM roles — all orchestrated via CloudFormation — to provide a reusable, secure, scalable deployment setup.

## Why use this

- ✅ Infrastructure as Code: Fully defined via CloudFormation — makes deployment repeatable, version-controlled, and consistent across environments. :contentReference[oaicite:0]{index=0}  
- 🔐 Secure by design: Public load balancer in public subnets, application containers in private subnets, secure communication (HTTPS via ALB with SSL), limited access via security groups, NAT for outbound.  
- 🌐 High availability: Multi-AZ setup — public + private subnets across two Availability Zones.  
- 🐳 Modern container-based architecture: Uses ECS Fargate — no need to manage EC2 hosts.  
- 🔄 Configurable & Reusable: Via parameters (VPC name, application name, domain, certificate ARN, etc.), so template can be reused for different apps/environments.  

## What the template provisions

- VPC (single VPC)  
- 2 Public subnets (public-facing)  
- 2 Private subnets (for ECS tasks)  
- Internet Gateway + VPC gateway attachment  
- NAT Gateway (with Elastic IP) for private subnet outbound internet access  
- Public and private route tables with appropriate routing (IGW for public, NAT for private)  
- Security groups: one for ALB (public ingress), one for ECS tasks (private)  
- Application Load Balancer (internet-facing), spanning both public subnets  
  - HTTPS listener (port 443) — uses provided SSL certificate  
  - HTTP listener (port 80) — redirects to HTTPS  
  - Target group for ECS tasks (port 80, health checks)  
- ECS Cluster  
- ECS Task Definition (Fargate) — runs container image (e.g. `justaskdavidb-flask-simwire-basic`)  
- ECS Service with desired count (default = 1), using Fargate, in private subnets  
- IAM role for ECS tasks (permissions to pull image, write logs, etc.)  
- CloudFormation Outputs for key resource identifiers (VPC ID, subnet IDs, ALB DNS, etc.)  


## Params

The template expects several input parameters. Here are the key ones:

| Param | Purpose |
|-------|---------|
| `VpcName` | A name/tag for your VPC and related resources. |
| `ApplicationName` | The application name — used in naming the ECS cluster, ALB, etc. |
| `DomainName` | Your domain (e.g. example.com) that you plan to use for the app. |
| `CertificateArn` | ARN of a valid SSL/TLS certificate in AWS Certificate Manager (ACM), to enable HTTPS on the load-balancer. |
| `InstanceType` *(optional)* | For EC2-based use (not used with Fargate). |
| `LatestAmiId` *(optional)* | AMI ID (for EC2) — not used if you run containers on Fargate. |

## Common Pitfalls

- **Name length / characters:** The `VpcName` and `ApplicationName` must adhere to the allowed pattern (alphanumeric + hyphens) and length limits. If names are too long or contain invalid characters, resource names may exceed AWS limits or fail to create.  
- **Missing / invalid CertificateArn:** If the `CertificateArn` is invalid, expired, or referencing a certificate in a different region, the stack will fail when creating the load-balancer listener.  
- **Assuming certificate creation:** The template does *not* create certificates. You must have obtained the certificate in ACM ahead of time.  
- **Using optional EC2 parameters for Fargate:** Parameters like `InstanceType` or `LatestAmiId` are irrelevant when using Fargate — they’re included for flexibility but not needed. Don’t depend on them unless you modify the template for EC2 tasks.  


## Quick Start (Deploy in Under 10 Minutes)

1. Ensure you have an SSL/TLS certificate in AWS Certificate Manager (ACM) for your domain name.  
2. Clone or download this repository containing the CloudFormation template.  
3. In AWS CloudFormation (or via AWS CLI / Systems Manager), create a new stack using the template.  
4. Provide the required parameters: `VpcName`, `ApplicationName`, `DomainName`, `CertificateArn`.  
5. Wait for stack status → `CREATE_COMPLETE`.  
6. Obtain the ALB DNS name from the outputs, and update your DNS (e.g. via Route 53) to point your domain to that DNS.  
7. Your application container (via ECS + Fargate) is now accessible via HTTPS through the ALB.  

Welcome to your fully deployed containerized web app infrastructure! 🎉
