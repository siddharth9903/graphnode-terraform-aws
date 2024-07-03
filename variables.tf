variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of subnet IDs for the ECS cluster"
  type        = list(string)
}

variable "db_cluster_identifier" {
  description = "The identifier for the RDS cluster"
  type        = string
}

variable "postgres_host" {
  description = "database host"
  type        = string
}

variable "database_name" {
  description = "The name of the database to create"
  type        = string
}

variable "master_username" {
  description = "The master username for the database"
  type        = string
}

variable "master_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
}

variable "ec2_ami" {
  description = "The AMI ID for the EC2 instances"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for EC2 instances"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the ECS instances"
  type        = string
  default     = "t2.small"
}

variable "min_size" {
  description = "The minimum size of the ECS cluster"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum size of the ECS cluster"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "The desired capacity of the ECS cluster"
  type        = number
  default     = 1
}

variable "task_definition_name" {
  description = "The name of the ECS task definition"
  type        = string
}

variable "container_image" {
  description = "The Docker image to use for the ECS task"
  type        = string
}

variable "ipfs_url" {
  description = "The URL of the IPFS node"
  type        = string
}

variable "ethereum_url" {
  description = "The URL of the Ethereum node"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the ALB and SSL certificate"
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the Route 53 hosted zone"
  type        = string
}