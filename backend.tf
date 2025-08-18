terraform {
  backend "s3" {
    bucket         = "mybackendbucket-11"
    key            = "Scalable-and-secure-3-tier-application-architecture-in-AWS-using-Terraform-and-GitHubactions/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}