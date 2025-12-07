# Deploy Steps

## Step 1 – Prep Template

- Save your CloudFormation template (YAML/JSON) into a file (e.g. `infra.yml`).  
- Make sure you know your parameter values: `VpcName`, `ApplicationName`, `DomainName`, `CertificateArn`.  

## Step 2 – Launch Stack

- In AWS Console, go to AWS CloudFormation → “Create stack” → “With new resources (standard)”.  
- Upload your template file.  
- Fill in parameters.  
- Acknowledge IAM resource creation (since the stack creates roles/policies).  
- Click “Create stack”.  

## Step 3 – Wait for Creation

- Stack status will go from `CREATE_IN_PROGRESS` to `CREATE_COMPLETE`. This may take a few minutes, since it provisions VPC, subnets, NAT, ALB, ECS cluster, etc.  

## Step 4 – Check Outputs & DNS

- Once complete, go to “Outputs” — copy the ALB DNS name (or other outputs).  
- If using custom domain: update DNS to point domain/subdomain to ALB (via Alias or CNAME).  
- Wait for DNS propagation, then access your application via HTTPS.  

## Step 5 – Verify Everything Works

- Ensure load-balancer is healthy, ECS service running, container reachable.  
- Check that traffic flows correctly from Internet → ALB → ECS tasks (in private subnets), and that containers can still reach external resources (via NAT) if needed.  
