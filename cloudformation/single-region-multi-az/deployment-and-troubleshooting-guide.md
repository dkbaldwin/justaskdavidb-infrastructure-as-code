## Deployment Steps

### Step 1 – Prep Template

- Save your CloudFormation template (YAML/JSON) into a file (e.g. `infra.yml`).  
- Make sure you know your parameter values: `VpcName`, `ApplicationName`, `DomainName`, `CertificateArn`.  

### Step 2 – Launch Stack

- In AWS Console, go to AWS CloudFormation → “Create stack” → “With new resources (standard)”.  
- Upload your template file.  
- Fill in parameters.  
- Acknowledge IAM resource creation (since the stack creates roles/policies).  
- Click “Create stack”.  

### Step 3 – Wait for Creation

- Stack status will go from `CREATE_IN_PROGRESS` to `CREATE_COMPLETE`. This may take a few minutes, since it provisions VPC, subnets, NAT, ALB, ECS cluster, etc.  

### Step 4 – Check Outputs & DNS

- Once complete, go to “Outputs” — copy the ALB DNS name (or other outputs).  
- If using custom domain: update DNS to point domain/subdomain to ALB (via Alias or CNAME).  
- Wait for DNS propagation, then access your application via HTTPS.  

### Step 5 – Verify Everything Works

- Ensure load-balancer is healthy, ECS service running, container reachable.  
- Check that traffic flows correctly from Internet → ALB → ECS tasks (in private subnets), and that containers can still reach external resources (via NAT) if needed.

## Troubleshooting Difficulties

### Common Issues

- **Stack fails during creation** — often due to invalid parameter (e.g. bad `CertificateArn`, invalid name). Double-check parameter values.  
- **Site unreachable after deployment** — maybe DNS record not created / propagated, or ALB not yet healthy. Confirm ALB health-checks and DNS settings.  
- **Certificate / HTTPS issues** — if certificate expired, invalid, or in wrong region. Ensure certificate is “Issued” and in same region as ALB. :contentReference[oaicite:7]{index=7}  
- **Containers can’t pull image / no external access** — private subnets + NAT gateway ensure outbound connectivity; check NAT + route-tables if image pull fails.  
- **Security group misconfiguration** — e.g. container SG too permissive (exposed to internet) or too restrictive (blocking ALB).  

### What to Check First

1. AWS CloudFormation Events tab — shows which resource failed (if any).  
2. ALB status and target-group health — make sure back-ends are registered and healthy.  
3. DNS settings (Alias/CNAME), TTL, propagation.  
4. Certificate status in ACM (valid, not expired, correct domain, correct region).  
5. Network configuration: subnets, route tables, NAT gateway, security groups.  

