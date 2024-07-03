aws_region = "us-east-1"

vpc_id = "vpc-00ee55721b41b49c1"
public_subnet_ids = [
  "subnet-057ae4d08b59686c4",
  "subnet-055a4d46ad83aa781",
]

db_cluster_identifier = "gn-rds-psg-db-ex"
postgres_host         = "gn-rds-psg-db-ex.c9keqc40m4bt.us-east-1.rds.amazonaws.com"
database_name         = "graph_node_dev"
master_username       = "postgres"
master_password       = "postgres" # Change this to a secure password

ecs_cluster_name     = "gn-ec2-clr-dev"
# ecs_ami_id           = "ami-01b799c439fd5516a" # Replace with the latest ECS-optimized AMI ID
instance_type        = "t2.small"
min_size             = 1
max_size             = 1
desired_capacity     = 1

task_definition_name = "gn-task-ec2-dev"
container_image      = "siddharth9903/graphnode:latest"

ipfs_url     = "http://18.206.168.62:5001"
ethereum_url = "base:https://virtual.base.rpc.tenderly.co/3fbaeb11-e428-4845-9be3-91c242fe550d"

ec2_ami  = "ami-01b799c439fd5516a" # Replace with the latest Amazon Linux 2 AMI ID
key_name = "apecity-ssh-keypair"

domain_name = "tend.apecity.xyz"
route53_zone_id = "Z0296707AHL64NN8DXS8"