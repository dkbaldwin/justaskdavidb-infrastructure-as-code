# Quick Start Guide - ECS Fargate Infrastructure

Get your containerized application running on AWS in minutes!

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] AWS Account with admin or appropriate permissions
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] ACM Certificate ARN (in the same region you're deploying to)
- [ ] Container image available (Docker Hub, ECR, or other registry)

## Step 1: Get Your ACM Certificate ARN

### If you don't have a certificate:

```bash
# Request a certificate (replace with your domain)
aws acm request-certificate \
  --domain-name example.com \
  --validation-method DNS \
  --region us-east-1

# Note the certificate ARN from the output
```

### If you have a certificate:

```bash
# List your certificates
aws acm list-certificates --region us-east-1

# Copy the CertificateArn you want to use
```

## Step 2: Prepare Your Parameters

Copy the example parameters file and customize it:

```bash
cp parameters-example.json my-parameters.json
```

Edit `my-parameters.json` and update:

```json
{
  "ParameterKey": "CertificateArn",
  "ParameterValue": "arn:aws:acm:us-east-1:YOUR-ACCOUNT:certificate/YOUR-CERT-ID"
},
{
  "ParameterKey": "ContainerImage",
  "ParameterValue": "YOUR-IMAGE:TAG"
}
```

## Step 3: Validate the Template

Before deploying, validate the template:

```bash
./deploy.sh --validate-only
```

Expected output:
```
✓ Template validation successful
```

## Step 4: Deploy Your Infrastructure

Deploy the stack with your customized parameters:

```bash
./deploy.sh \
  --stack-name my-app-production \
  --region us-east-1 \
  --parameters my-parameters.json
```

This will:
1. Create or update the CloudFormation stack
2. Deploy all infrastructure components
3. Wait for completion (10-15 minutes)
4. Display stack outputs

## Step 5: Access Your Application

After deployment completes, get your application URL:

```bash
# Get the ALB DNS name
aws cloudformation describe-stacks \
  --stack-name my-app-production \
  --query 'Stacks[0].Outputs[?OutputKey==`HTTPSEndpoint`].OutputValue' \
  --output text
```

Or find it in the deployment output under "Stack Outputs".

Visit the URL in your browser: `https://your-alb-dns-name.region.elb.amazonaws.com`

## Common Deployment Scenarios

### Scenario 1: Deploy with Default Nginx

Quick test deployment using the default nginx image:

```bash
./deploy.sh \
  --stack-name nginx-test \
  --parameters <(cat <<EOF
[
  {
    "ParameterKey": "EnvironmentName",
    "ParameterValue": "development"
  },
  {
    "ParameterKey": "CertificateArn",
    "ParameterValue": "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  },
  {
    "ParameterKey": "ContainerImage",
    "ParameterValue": "nginx:latest"
  }
]
EOF
)
```

### Scenario 2: Deploy Your Custom Application from ECR

```bash
./deploy.sh \
  --stack-name my-app-prod \
  --parameters <(cat <<EOF
[
  {
    "ParameterKey": "EnvironmentName",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "CertificateArn",
    "ParameterValue": "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  },
  {
    "ParameterKey": "ContainerImage",
    "ParameterValue": "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0"
  },
  {
    "ParameterKey": "ContainerPort",
    "ParameterValue": "8080"
  },
  {
    "ParameterKey": "DesiredCount",
    "ParameterValue": "3"
  }
]
EOF
)
```

### Scenario 3: Deploy with Higher Resources

For applications that need more CPU/memory:

```bash
./deploy.sh \
  --stack-name my-app-prod \
  --parameters <(cat <<EOF
[
  {
    "ParameterKey": "EnvironmentName",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "CertificateArn",
    "ParameterValue": "arn:aws:acm:us-east-1:123456789012:certificate/abc123"
  },
  {
    "ParameterKey": "ContainerImage",
    "ParameterValue": "my-app:latest"
  },
  {
    "ParameterKey": "ContainerCPU",
    "ParameterValue": "1024"
  },
  {
    "ParameterKey": "ContainerMemory",
    "ParameterValue": "2048"
  }
]
EOF
)
```

## Monitoring Your Deployment

### Watch Stack Creation Progress

```bash
# In another terminal, watch the events
watch -n 5 "aws cloudformation describe-stack-events \
  --stack-name my-app-production \
  --max-items 10 \
  --query 'StackEvents[].[Timestamp,ResourceType,ResourceStatus]' \
  --output table"
```

### Check ECS Service Status

```bash
aws ecs describe-services \
  --cluster production-cluster \
  --services production-service \
  --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
  --output table
```

### View Container Logs

```bash
# Get the latest log stream
aws logs tail /ecs/production --follow
```

## Troubleshooting

### Issue: Certificate validation error

**Problem:** ACM certificate ARN is invalid or in wrong region

**Solution:**
```bash
# Verify certificate exists in the correct region
aws acm describe-certificate \
  --certificate-arn YOUR-CERT-ARN \
  --region us-east-1
```

### Issue: Tasks won't start

**Problem:** Container image can't be pulled

**Solution:**
```bash
# Check ECS task stopped reason
aws ecs list-tasks --cluster production-cluster --desired-status STOPPED
aws ecs describe-tasks --cluster production-cluster --tasks TASK-ARN

# Common fixes:
# 1. Verify image name is correct
# 2. Check ECR repository permissions
# 3. Verify execution role has ECR pull permissions
```

### Issue: Health checks failing

**Problem:** ALB can't reach the application

**Solution:**
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn TARGET-GROUP-ARN

# Common fixes:
# 1. Verify HealthCheckPath is correct
# 2. Ensure app returns 200 status on health check path
# 3. Check container is listening on specified port
```

### Issue: Stack creation failed

**Problem:** CloudFormation encountered an error

**Solution:**
```bash
# View failure reason
aws cloudformation describe-stack-events \
  --stack-name my-app-production \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]' \
  --output table

# Common fixes:
# 1. Check IAM permissions
# 2. Verify certificate ARN
# 3. Check subnet CIDR conflicts
# 4. Ensure region has enough capacity
```

## Updating Your Application

### Update Container Image

1. Build and push new image
2. Update parameters file with new image tag
3. Run deployment script:

```bash
./deploy.sh \
  --stack-name my-app-production \
  --parameters my-parameters-updated.json
```

CloudFormation will perform a rolling update of your ECS tasks.

### Scale Your Application

Update the `DesiredCount` parameter and redeploy:

```bash
# Scale to 5 tasks
# Update DesiredCount in parameters file, then:
./deploy.sh \
  --stack-name my-app-production \
  --parameters my-parameters.json
```

## Cleanup

To delete all resources:

```bash
aws cloudformation delete-stack --stack-name my-app-production

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name my-app-production
```

**Warning:** This will delete:
- VPC and all networking components
- NAT Gateway and Elastic IP
- Application Load Balancer
- ECS cluster and all tasks
- CloudWatch log groups
- IAM roles

## Next Steps

After successful deployment:

1. **Configure Custom Domain:**
   - Create Route 53 hosted zone
   - Add CNAME pointing to ALB DNS
   - Update certificate if needed

2. **Set Up Monitoring:**
   - Create CloudWatch dashboards
   - Configure alarms for critical metrics
   - Set up SNS notifications

3. **Implement Auto Scaling:**
   - Add Application Auto Scaling targets
   - Configure scaling policies
   - Test scaling behavior

4. **Enhance Security:**
   - Review security group rules
   - Implement AWS WAF if needed
   - Enable AWS Shield
   - Configure VPC Flow Logs

5. **Optimize Costs:**
   - Enable Fargate Spot
   - Review log retention
   - Implement cost tags
   - Set up cost alerts

## Getting Help

- 📖 Full Documentation: [ECS-FARGATE-README.md](ECS-FARGATE-README.md)
- 📋 Validation Report: [VALIDATION-REPORT.md](VALIDATION-REPORT.md)
- 🔧 Template: [ecs-fargate-infrastructure.yaml](ecs-fargate-infrastructure.yaml)

## Success Indicators

You know your deployment is successful when:

- ✅ Stack status is `CREATE_COMPLETE` or `UPDATE_COMPLETE`
- ✅ ECS service running count matches desired count
- ✅ Target group shows healthy targets
- ✅ HTTPS endpoint is accessible
- ✅ Application responds correctly
- ✅ CloudWatch logs show container output

Congratulations! Your ECS Fargate infrastructure is running! 🎉
