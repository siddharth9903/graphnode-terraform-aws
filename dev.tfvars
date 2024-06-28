aws_region = "us-east-1"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
# private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# db_cluster_identifier = "graphnode-db-cluster-dev"
# db_cluster_identifier = "gn-rds-db-ex"
db_cluster_identifier = "gn-rds-psg-db-ex"
postgres_host         = "gn-rds-psg-db-ex.c9keqc40m4bt.us-east-1.rds.amazonaws.com"
database_name         = "graph_node_dev"
master_username       = "postgres"
master_password       = "postgres" # Change this to a secure password

cluster_name         = "gn-ec2-clr"
# ecs_ami_id           = "ami-0eaf7c3456e7b5b68" # Replace with the latest ECS-optimized AMI ID
ecs_ami_id           = "ami-01b799c439fd5516a" # Replace with the latest ECS-optimized AMI ID
instance_type        = "t3.medium"
min_size             = 1
max_size             = 1
desired_capacity     = 1

task_definition_name = "gn-task-ec2"
container_image      = "siddharth9903/graphnode:latest"

ipfs_url     = "http://100.27.85.244:5001"
ethereum_url = "base:https://virtual.base.rpc.tenderly.co/7817edf3-f43a-4498-9cf9-c44c0164e1ed"

ec2_ami  = "ami-01b799c439fd5516a" # Replace with the latest Amazon Linux 2 AMI ID
key_name = "apecity-ssh-keypair"

domain_name = "tend.apecity.xyz"
route53_zone_id = "Z0296707AHL64NN8DXS8"