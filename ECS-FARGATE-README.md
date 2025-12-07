# ECS Fargate Infrastructure-as-Code Template

This CloudFormation template provides a comprehensive, production-ready infrastructure for deploying containerized applications on AWS ECS Fargate with secure networking and HTTPS load balancing.

## Overview

This template deploys a fully functional AWS infrastructure including:

- **Networking**: Custom VPC with public and private subnets across two Availability Zones
- **Security**: Security groups with least-privilege access and IAM roles for ECS
- **Compute**: ECS Fargate cluster with configurable task definitions
- **Load Balancing**: Application Load Balancer with HTTPS support and HTTP→HTTPS redirect
- **Monitoring**: CloudWatch Logs integration for container logs

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ Internet Gateway │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
    ┌─────────▼─────────┐       ┌─────────▼─────────┐
    │  Public Subnet 1  │       │  Public Subnet 2  │
    │       (AZ1)       │       │       (AZ2)       │
    │                   │       │                   │
    │  ┌─────────────┐  │       │                   │
    │  │ NAT Gateway │  │       │                   │
    │  └──────┬──────┘  │       │                   │
    └─────────┼─────────┘       └───────────────────┘
              │         Application Load Balancer
              │         (HTTPS + HTTP→HTTPS)
              │
    ┌─────────▼─────────┐       ┌───────────────────┐
    │ Private Subnet 1  │       │ Private Subnet 2  │
    │      (AZ1)        │       │      (AZ2)        │
    │                   │       │                   │
    │  ┌─────────────┐  │       │  ┌─────────────┐  │
    │  │ ECS Fargate │  │       │  │ ECS Fargate │  │
    │  │    Task     │  │       │  │    Task     │  │
    │  └─────────────┘  │       │  └─────────────┘  │
    └───────────────────┘       └───────────────────┘
```

## Features

### Networking
- **Custom VPC** with configurable CIDR block
- **Public Subnets** (2) for load balancer and NAT gateway
- **Private Subnets** (2) for ECS tasks (no direct internet access)
- **Internet Gateway** for public subnet internet access
- **NAT Gateway** for private subnet outbound internet access
- **Route Tables** properly configured for public and private traffic

### Security
- **ALB Security Group**: Allows HTTP (80) and HTTPS (443) from internet
- **ECS Security Group**: Allows traffic only from ALB on container port
- **IAM Execution Role**: Allows ECS to pull images from ECR and write to CloudWatch
- **IAM Task Role**: Allows tasks to write logs and perform app-specific actions

### ECS Infrastructure
- **ECS Cluster** with Container Insights enabled
- **Task Definition** with configurable CPU/memory
- **ECS Service** running in private subnets with no public IPs
- **CloudWatch Logs** for centralized container logging

### Load Balancing
- **Application Load Balancer** in public subnets
- **HTTPS Listener** using ACM certificate
- **HTTP→HTTPS Redirect** for automatic upgrade
- **Target Group** with health checks configured
- **Health Checks** with configurable path and interval

## Prerequisites

Before deploying this template, you need:

1. **AWS Account** with appropriate permissions
2. **ACM Certificate** in the same region where you're deploying
   - Go to AWS Certificate Manager
   - Request or import a certificate
   - Copy the certificate ARN
3. **Container Image** either in:
   - Amazon ECR (private registry)
   - Docker Hub (public registry)
   - Any other accessible container registry

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `EnvironmentName` | Environment name for resource naming | `production` | No |
| `VpcCIDR` | CIDR block for VPC | `10.0.0.0/16` | No |
| `PublicSubnet1CIDR` | CIDR for public subnet in AZ1 | `10.0.1.0/24` | No |
| `PublicSubnet2CIDR` | CIDR for public subnet in AZ2 | `10.0.2.0/24` | No |
| `PrivateSubnet1CIDR` | CIDR for private subnet in AZ1 | `10.0.11.0/24` | No |
| `PrivateSubnet2CIDR` | CIDR for private subnet in AZ2 | `10.0.12.0/24` | No |
| `ContainerImage` | Docker image to run | `nginx:latest` | No |
| `ContainerPort` | Port container listens on | `80` | No |
| `ContainerCPU` | CPU units (256 = 0.25 vCPU) | `256` | No |
| `ContainerMemory` | Memory in MB | `512` | No |
| `DesiredCount` | Number of tasks to run | `2` | No |
| `HealthCheckPath` | ALB health check path | `/` | No |
| `HealthCheckIntervalSeconds` | Health check interval | `30` | No |
| `CertificateArn` | ACM certificate ARN | - | **Yes** |

## Deployment

### Using AWS Console

1. Go to **CloudFormation** in AWS Console
2. Click **Create Stack** → **With new resources**
3. Choose **Upload a template file**
4. Upload `ecs-fargate-infrastructure.yaml`
5. Click **Next**
6. Enter **Stack name** (e.g., `my-app-production`)
7. Fill in **Parameters**:
   - Required: `CertificateArn`
   - Optional: Customize other parameters as needed
8. Click **Next** through remaining steps
9. Check **acknowledgment** boxes for IAM resources
10. Click **Create Stack**

### Using AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name my-app-production \
  --template-body file://ecs-fargate-infrastructure.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=production \
    ParameterKey=CertificateArn,ParameterValue=arn:aws:acm:us-east-1:123456789012:certificate/abc123 \
    ParameterKey=ContainerImage,ParameterValue=nginx:latest \
    ParameterKey=DesiredCount,ParameterValue=2 \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Validate Template Before Deployment

```bash
aws cloudformation validate-template \
  --template-body file://ecs-fargate-infrastructure.yaml
```

## Outputs

After deployment, the stack provides these outputs:

### Networking
- VPC ID and CIDR
- Subnet IDs (public and private)
- Internet Gateway ID
- NAT Gateway ID and Elastic IP
- Route Table IDs

### Security
- Security Group IDs (ALB and ECS)
- IAM Role ARNs

### ECS
- Cluster Name and ARN
- Service Name
- Task Definition ARN
- Log Group Name

### Load Balancer
- ALB DNS Name
- ALB ARN
- Target Group ARN
- HTTPS Endpoint URL
- HTTP Endpoint URL

## Accessing Your Application

After stack creation completes:

1. Go to **CloudFormation** → **Stacks** → Your stack
2. Click **Outputs** tab
3. Find `HTTPSEndpoint` or `LoadBalancerDNS`
4. Access your application at: `https://<alb-dns-name>`

**Note**: DNS propagation may take a few minutes.

## Updating the Stack

To update the stack with new parameters or template changes:

```bash
aws cloudformation update-stack \
  --stack-name my-app-production \
  --template-body file://ecs-fargate-infrastructure.yaml \
  --parameters \
    ParameterKey=DesiredCount,ParameterValue=4 \
  --capabilities CAPABILITY_NAMED_IAM
```

## Monitoring

### CloudWatch Logs
Container logs are automatically sent to CloudWatch:
- Log Group: `/ecs/{EnvironmentName}`
- Retention: 7 days (configurable in template)

### ECS Service Metrics
The cluster has Container Insights enabled, providing:
- CPU and memory utilization
- Network metrics
- Task count metrics

Access metrics in: **CloudWatch** → **Container Insights** → **ECS Clusters**

## Troubleshooting

### Tasks Won't Start
- Check IAM roles have correct permissions
- Verify container image is accessible
- Check CloudWatch logs for error messages

### Health Checks Failing
- Verify `HealthCheckPath` returns 200 status code
- Ensure container is listening on specified `ContainerPort`
- Check security group rules allow ALB → ECS traffic

### Can't Access Application
- Verify certificate ARN is correct and valid
- Check DNS resolution for ALB
- Ensure security groups allow inbound 80/443

### Deployment Timeout
- NAT Gateway can take 3-5 minutes to create
- ECS service creation waits for healthy targets
- Total stack creation typically takes 10-15 minutes

## Cost Considerations

This infrastructure will incur costs for:
- **NAT Gateway**: ~$0.045/hour + data transfer
- **Application Load Balancer**: ~$0.0225/hour + LCU charges
- **ECS Fargate**: Based on vCPU and memory allocated
- **CloudWatch Logs**: Storage and data ingestion
- **Data Transfer**: Outbound data transfer charges

**Estimated monthly cost** (2 tasks, 0.25 vCPU, 0.5 GB each): ~$50-80

## Deleting the Stack

To remove all resources:

```bash
aws cloudformation delete-stack --stack-name my-app-production
```

**Warning**: This will delete all resources including the VPC, subnets, NAT Gateway, ALB, and ECS cluster.

## Customization

### Using Your Own Container Image

Replace the `ContainerImage` parameter:

```yaml
ParameterKey=ContainerImage,ParameterValue=123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

### Different Container Ports

If your app listens on a different port:

```yaml
ParameterKey=ContainerPort,ParameterValue=8080
```

### Scaling

Adjust the number of tasks:

```yaml
ParameterKey=DesiredCount,ParameterValue=4
```

### Resource Allocation

For larger applications:

```yaml
ParameterKey=ContainerCPU,ParameterValue=1024
ParameterKey=ContainerMemory,ParameterValue=2048
```

## Multiple Environments

Deploy separate stacks for each environment:

```bash
# Development
aws cloudformation create-stack \
  --stack-name my-app-dev \
  --parameters ParameterKey=EnvironmentName,ParameterValue=development ...

# Staging
aws cloudformation create-stack \
  --stack-name my-app-staging \
  --parameters ParameterKey=EnvironmentName,ParameterValue=staging ...

# Production
aws cloudformation create-stack \
  --stack-name my-app-prod \
  --parameters ParameterKey=EnvironmentName,ParameterValue=production ...
```

## Security Best Practices

This template implements several security best practices:

1. ✅ ECS tasks run in private subnets (no direct internet access)
2. ✅ Security groups follow principle of least privilege
3. ✅ IAM roles have minimal required permissions
4. ✅ HTTPS enforced via redirect
5. ✅ VPC with DNS support enabled
6. ✅ CloudWatch logging enabled for auditing

## Additional Considerations

### Auto Scaling
This template doesn't include auto-scaling. To add it, you can:
- Create an Application Auto Scaling Target
- Create scaling policies based on CPU/memory

### Multi-Region Deployment
For multi-region:
- Deploy stack in each region
- Use Route 53 for DNS routing
- Replicate container images to each region's ECR

### Blue/Green Deployments
For zero-downtime deployments:
- Use CodeDeploy with ECS
- Configure deployment configuration
- Set up traffic shifting

## Support

For issues or questions:
1. Check CloudFormation stack events for errors
2. Review CloudWatch logs at `/ecs/{EnvironmentName}`
3. Check ECS service events in the ECS console

## License

See LICENSE file for details.
