# justaskdavidb-infrastructure-as-code

This repository contains various CloudFormation template architectural designs for applications in AWS.

## Available Templates

### ECS Fargate Infrastructure with ALB

A comprehensive, production-ready CloudFormation template for deploying containerized applications on AWS ECS Fargate with secure networking and HTTPS load balancing.

**Features:**
- Custom VPC with public and private subnets across two Availability Zones
- Application Load Balancer with HTTPS support and HTTP→HTTPS redirect
- ECS Fargate cluster with configurable task definitions
- Security groups with least-privilege access
- IAM roles for ECS with proper permissions
- CloudWatch Logs integration
- NAT Gateway for private subnet internet access

**Quick Start:**
```bash
# Validate the template
./deploy.sh --validate-only

# Deploy the stack
./deploy.sh --stack-name my-app-prod --parameters parameters-example.json
```

📖 **[Read the full documentation](ECS-FARGATE-README.md)**

📄 **Template:** [ecs-fargate-infrastructure.yaml](ecs-fargate-infrastructure.yaml)

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- ACM certificate (for HTTPS)
- Container image (ECR or Docker Hub)

## Repository Structure

```
.
├── README.md                          # This file
├── ecs-fargate-infrastructure.yaml    # ECS Fargate CloudFormation template
├── ECS-FARGATE-README.md             # Detailed ECS Fargate documentation
├── parameters-example.json            # Example parameters file
├── deploy.sh                          # Deployment helper script
└── LICENSE                            # License information
```

## Usage

Each template comes with:
- Comprehensive documentation
- Example parameters
- Deployment scripts
- Architecture diagrams

Refer to the individual template documentation for detailed usage instructions.

## Contributing

Feel free to submit issues and enhancement requests!

## License

See [LICENSE](LICENSE) for details.
