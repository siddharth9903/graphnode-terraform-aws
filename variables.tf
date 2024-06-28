variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# variable "private_subnet_cidrs" {
#   description = "The CIDR blocks for the private subnets"
#   type        = list(string)
#   default     = ["10.0.3.0/24", "10.0.4.0/24"]
# }

variable "availability_zones" {
  description = "The availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_cluster_identifier" {
  description = "The identifier for the RDS cluster"
  type        = string
  default     = "graphnode-db-cluster"
}

variable "postgres_host" {
  description = "database host"
  type        = string
}

variable "database_name" {
  description = "The name of the database to create"
  type        = string
  default     = "graphnode"
}

variable "master_username" {
  description = "The master username for the database"
  type        = string
  default     = "postgres"
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

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "gn-ec2-cluster"
}

# variable "ecs_ami_id" {
#   description = "The AMI ID for the ECS instances"
#   type        = string
# }

variable "instance_type" {
  description = "The instance type for the ECS instances"
  type        = string
  default     = "t3.medium"
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
  default     = "gn-task-ec2"
}

variable "container_image" {
  description = "The Docker image to use for the ECS task"
  type        = string
  default     = "siddharth9903/graphnode:latest"
}

variable "ipfs_url" {
  description = "The URL of the IPFS node"
  type        = string
}

variable "ethereum_url" {
  description = "The URL of the Ethereum node"
  type        = string
}
variable "prod_db_instance_class" {
  description = "The instance class to use for the production RDS cluster"
  type        = string
  default     = "db.r5.large"
}

variable "dev_db_instance_class" {
  description = "The instance class to use for non-production RDS clusters"
  type        = string
  default     = "db.t3.medium"
}

variable "prod_backup_retention" {
  description = "The number of days to retain backups for in production"
  type        = number
  default     = 7
}

variable "dev_backup_retention" {
  description = "The number of days to retain backups for in non-production environments"
  type        = number
  default     = 1
}

variable "domain_name" {
  description = "Domain name for the ALB and SSL certificate"
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the Route 53 hosted zone"
  type        = string
}