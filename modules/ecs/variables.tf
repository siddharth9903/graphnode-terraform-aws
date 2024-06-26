variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "gn-ec2-cluster"
}

variable "ami_id" {
  description = "AMI ID for ECS instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for ECS instances"
  type        = string
  default     = "t2.medium"
}

variable "min_size" {
  description = "Minimum size of the ECS cluster"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the ECS cluster"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired capacity of the ECS cluster"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS cluster"
  type        = list(string)
}

variable "task_definition_name" {
  description = "Name of the ECS task definition"
  type        = string
  default     = "gn-task-ec2"
}

variable "container_image" {
  description = "Docker image for the ECS task"
  type        = string
}

variable "postgres_host" {
  description = "PostgreSQL host"
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL user"
  type        = string
}

variable "postgres_pass" {
  description = "PostgreSQL password"
  type        = string
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}

variable "ipfs_url" {
  description = "IPFS URL"
  type        = string
}

variable "ethereum_url" {
  description = "Ethereum URL"
  type        = string
}