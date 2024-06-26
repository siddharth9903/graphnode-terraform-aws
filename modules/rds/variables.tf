variable "db_cluster_identifier" {
  description = "The identifier for the RDS cluster"
  type        = string
  default     = "graphnode-db-cluster"
}

variable "database_name" {
  description = "The name of the database to create"
  type        = string
  default     = "graph-node"
}

variable "master_username" {
  description = "The master username for the RDS cluster"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "The master password for the RDS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS cluster"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for the RDS cluster"
  type        = list(string)
}


variable "ec2_ami" {
  description = "The AMI ID for the RDS connector EC2 instance"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair for the RDS connector EC2 instance"
  type        = string
}

variable "is_production" {
  description = "Whether this is a production environment"
  type        = bool
  default     = false
}

variable "instance_class" {
  description = "The instance class for the RDS cluster"
  type        = string
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for"
  type        = number
}