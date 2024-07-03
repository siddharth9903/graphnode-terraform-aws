
provider "aws" {
  region = var.aws_region
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "ecs" {
  source   = "./modules/ecs"

  cluster_name         = var.cluster_name
  ami_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type        = var.instance_type
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.public_subnet_ids
  task_definition_name = var.task_definition_name
  container_image      = var.container_image
  postgres_host        = var.postgres_host
  postgres_user        = var.master_username
  postgres_pass        = var.master_password
  postgres_db          = var.database_name
  ipfs_url             = var.ipfs_url
  ethereum_url         = var.ethereum_url
  key_name             = var.key_name
  domain_name          = var.domain_name
  route53_zone_id      = var.route53_zone_id
}

# Output the ALB DNS names for each workspace
output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

# Output the VPC ID
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Output the public subnet IDs
output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "ec2_public_ips" {
  value = data.aws_instances.ecs_instances.public_ips
}

data "aws_instances" "ecs_instances" {
  instance_tags = {
    "AmazonECSManaged" = "true"
  }
}

output "ecs_optimized_ami_id" {
  value = data.aws_ssm_parameter.ecs_optimized_ami.value
   sensitive = true
}
