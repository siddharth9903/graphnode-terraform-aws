aws_region = "us-east-1"

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

db_cluster_identifier = "graphnode-db-cluster-prod"
database_name         = "graph_node_prod"
master_username       = "postgres"
master_password       = "prodpassword456" # Change this to a secure password

cluster_name         = "gn-ec2-cluster"
ecs_ami_id           = "ami-0eaf7c3456e7b5b68" # Replace with the latest ECS-optimized AMI ID
instance_type        = "t3.large"
min_size             = 2
max_size             = 5
desired_capacity     = 2

task_definition_name = "gn-task-ec2"
container_image      = "siddharth9903/graphnode:latest" # Specify a stable version for production

ipfs_url     = "http://100.27.85.244:5001"
ethereum_url = "base:https://virtual.base.rpc.tenderly.co/7817edf3-f43a-4498-9cf9-c44c0164e1ed"

ec2_ami  = "ami-01b799c439fd5516a" # Replace with the latest Amazon Linux 2 AMI ID
key_name = "prod-key-pair"