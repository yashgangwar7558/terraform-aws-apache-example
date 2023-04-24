Terraform module to provision an EC2 instance that is running Apache.

Not intented for production use. Just showcasing how to craete a custom public module on terrafrom registry.

```hcl
terraform {
  
}

provider "aws" {
  region = "us-east-1"
}

module "apache" {
  source           = "./terraform-aws-apache-example"
  vpc_id           = "vpc-000000"
  my_ip_with_cidr  = "YOUR_IP/32"
  public_key       = "ssh-rsa AAAAB3N"
  instance_type    = "t2.micro"
  server_name      = "Apache Example Server"
}

output "public_ip" {
  value = module.apache.public_ip
}

```
