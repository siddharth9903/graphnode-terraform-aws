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
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# module "rds" {
#   source = "./modules/rds"

#   db_cluster_identifier = var.db_cluster_identifier
#   database_name         = var.database_name
#   master_username       = var.master_username
#   master_password       = var.master_password
#   vpc_id                = module.vpc.vpc_id
#   subnet_ids            = module.vpc.private_subnet_ids
#   availability_zones    = var.availability_zones
#   ec2_ami               = var.ec2_ami
#   key_name              = var.key_name

#   # Use production settings for production workspace, dev settings for others
#   is_production         = terraform.workspace == "production"
#   instance_class        = terraform.workspace == "production" ? var.prod_db_instance_class : var.dev_db_instance_class
#   backup_retention_period = terraform.workspace == "production" ? var.prod_backup_retention : var.dev_backup_retention
# }

# Create a map of ECS modules for different workspaces
locals {
#   workspaces = ["dev", "staging", "production"]
  workspaces = ["dev"]
  ecs_modules = {
    for ws in local.workspaces :
    ws => {
      cluster_name         = "${var.cluster_name}-${ws}"
      task_definition_name = "${var.task_definition_name}-${ws}"
    }
  }
}

module "ecs" {
  source   = "./modules/ecs"
  for_each = local.ecs_modules


  cluster_name         = each.value.cluster_name
#   ami_id               = var.ecs_ami_id
  ami_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type        = var.instance_type
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  task_definition_name = each.value.task_definition_name
  container_image      = var.container_image
#   postgres_host        = module.rds.rds_endpoint
  postgres_host        = "gn-rds-db-ex.cluster-c9keqc40m4bt.us-east-1.rds.amazonaws.com"
  postgres_user        = var.master_username
  postgres_pass        = var.master_password
#   postgres_db          = var.database_name
  postgres_db          = "graph_node_dev"
  ipfs_url             = var.ipfs_url
  ethereum_url         = var.ethereum_url
}

# resource "aws_security_group_rule" "rds_ingress_ecs" {
#   for_each                 = module.ecs
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = each.value.ecs_security_group_id
#   security_group_id        = module.rds.rds_security_group_id
# }


# Output the ALB DNS names for each workspace
output "alb_dns_names" {
  value = {
    for ws, ecs in module.ecs :
    ws => ecs.alb_dns_name
  }
}

# # Output the RDS endpoint
# output "rds_endpoint" {
#   value = module.rds.rds_endpoint
# }

# Output the VPC ID
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Output the private subnet IDs
output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
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
