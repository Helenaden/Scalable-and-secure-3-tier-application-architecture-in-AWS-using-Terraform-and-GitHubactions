# Building a Secure & Scalable 3-Tier Architecture on AWS 

## Why This Project Matters

In software, *how* you build something is just as important as *what* you build.

Back in the early days, applications were built as **1-tier monoliths**. Everything, the UI, the logic, and the data, lived in one single block of code. It worked fine at first, but as systems grew, these monoliths became messy, difficult to maintain, and nearly impossible to scale.

Then came **2-tier client-server systems**. Better? Yes! The client talked to a server that handled both business logic and the database. But this setup still had major drawbacks: one server doing too much, becoming a bottleneck and single point of failure.

Today, we solve those problems with the **3-tier architecture**—the modern standard for scalable, secure systems. It cleanly separates:

- **Presentation Tier** → Where users interact (UI/web).  
- **Application Tier** → Where the business logic runs (the “brain”).  
- **Data Tier** → Where information is securely stored.  

This separation isn’t just neat, it enables independent scaling, better maintainability, and stronger security.

And that’s exactly what I set out to build.

## My Mission: A Secure Three-Tier Fortress

I didn’t want to just spin up some servers and call it a day.  
My mission was to **build a production-grade, secure, and resilient 3-tier application from scratch**, showcasing how security and scalability can be baked in from day one.

The foundation of everything? **Infrastructure as Code (IaC)**.  
I used **Terraform** to define the entire architecture, so every EC2 instance, subnet, and security group was created consistently, repeatably, and securely.  

Deployed across multiple availability zones, the system was designed for **high availability and resilience**. But I didn’t stop there, security was at the core of every design decision.

## The Foundation: Network & Access Controls

- **Custom VPC** with public and private subnets.  
- **Strict isolation** → App and DB tiers lived in private subnets, invisible to the internet.  

### Application Load Balancers (ALBs)

I isolated and controlled traffic flow with **two ALBs**:

- **Web ALB** → exposed to the internet, serving frontend requests.  
- **App ALB** → only accepted filtered traffic from the web tier.  

This design meant the **web tier had no direct access** to the application servers.  

### Other Security Controls

- **Web Application Firewall (WAF)** integrated with ALBs to block SQL injection, XSS, and malicious IPs.  
- **Security Groups (virtual firewalls)** enforced least privilege:
  - Web tier → only from Web ALB.  
  - App tier → only from App ALB.  
  - Database tier → only from app tier (MySQL 3306).  
  - Bastion host → the *only* way in via SSH, restricted to trusted IPs.  

- **IAM roles** followed least-privilege principles:
  - Web → Secrets Manager access for DB credentials.  
  - App → Secrets Manager + S3.  
  - Bastion → Admin tasks only.  

**No hardcoded secrets** → all credentials lived in **Secrets Manager**, rotated automatically.  

## The Core: Encryption & Application Security

Everything to *everything*, was encrypted:

- **EBS volumes**, **RDS databases**, and **S3 buckets** → encrypted with **KMS Customer-Managed Keys (CMK)**.  
- Automatic **KMS key rotation** enabled.  
- Data in motion restricted to secure communication paths.  

At the application layer:

- **WAF** acted as a proactive shield.  
- **ALB health checks** kept unhealthy instances out of rotation.  

## The Watchtower: Monitoring & Threat Detection

Secure infrastructure also needs **constant vigilance**:

- **CloudTrail** → logged every API activity (multi-region, immutable).  
- **CloudWatch** → real-time logs and alarms.  
- **GuardDuty** → continuous threat detection with anomaly analysis.  
- **Inspector v2** → vulnerability scans on workloads.  
- **SNS & EventBridge** → instant alerts and automated responses.  

This gave me **visibility, detection, and fast response capabilities**.

## The Final Layer: CI/CD & Compliance

I built a **GitHub Actions pipeline** with:

- **OIDC authentication** → secure, short-lived AWS credentials (no secrets in pipelines).  
- **Terraform automation** → validate, plan, and apply changes.  
- **Checkov scans** → detect misconfigurations before deployment.  
- **GitHub Secrets** → safe handling of sensitive variables.  

This wasn’t just DevOps, it was **SecOps**, ensuring deployments were automated *and* secure.  

The entire setup aligned with:

- AWS **Well-Architected Framework**  
- **Zero Trust principles**  
- **Defense-in-depth strategy**  

## Steps I Took

1. **Designed the architecture** → 3-tier with ALB, EC2, RDS (Multi-AZ).  
2. **Built the network** → custom VPC, public/private subnets, internet gateway, NAT gateways.  
3. **Implemented security** → IAM least privilege, Security Groups, WAF, Secrets Manager.  
4. **Added monitoring** → CloudTrail, GuardDuty, Inspector, CloudWatch.  
5. **Automated with Terraform** → modular design, remote state, Checkov scans.  
6. **Secured CI/CD** → GitHub Actions + OIDC + security scans.  
7. **Validated the design** → AWS best practices, defense-in-depth, compliance checks.  

## Outcome

The result was more than just a deployed 3-tier app.  
It was a **production-grade, enterprise-ready infrastructure**:

- High availability with Multi-AZ and Auto Scaling.  
- Strong security boundaries with IAM, WAF, and encryption.  
- Full observability and real-time threat detection.  
- Automated, compliant, repeatable deployments.  

This project demonstrated my ability to **design, build, and secure cloud infrastructure at scale**, from architecture design to Terraform automation and CI/CD pipelines.

## Key Skills Demonstrated

- Infrastructure as Code (**Terraform**)  
- Cloud Architecture & Security (**AWS**)  
- IAM & Secrets Management  
- Encryption & KMS Key Management  
- Monitoring & Threat Detection  
- CI/CD Automation with **GitHub Actions**  
- Compliance (**Well-Architected, Zero Trust, Defense in Depth**)  

This wasn’t just about spinning up servers. It was about **proving I can build secure, scalable, and auditable cloud infrastructure that’s production-ready from day one.**
