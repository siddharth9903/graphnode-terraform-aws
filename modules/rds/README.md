# AWS VPC Terraform Module

This module creates an AWS VPC with public and private subnets, along with a NAT Gateway.

## Usage

```hcl
module "vpc" {
  source = "./aws-vpc-module"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}