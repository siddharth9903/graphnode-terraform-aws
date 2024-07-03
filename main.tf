
provider "aws" {
  region = var.aws_region
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

module "ecs" {
  source   = "./modules/ecs"

  cluster_name         = var.ecs_cluster_name
  ami_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type        = var.instance_type
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_id               = var.vpc_id
  subnet_ids           = var.public_subnet_ids
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