
# Output the ALB DNS names for each workspace
output "alb_dns_name" {
  value = module.ecs.alb_dns_name
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
