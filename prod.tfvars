aws_region = "us-east-1"

vpc_id = "vpc-0a7e77168de71fbdd"
public_subnet_ids = [
  "subnet-0dfa98f8e42f2c472",
  "subnet-0f5ebfa1ccd1954c1",
]

db_cluster_identifier = "gn-rds-psg-db-ex"
postgres_host         = "gn-rds-psg-db-ex.c9keqc40m4bt.us-east-1.rds.amazonaws.com"
database_name         = "graph_node_prod"
master_username       = "postgres"
master_password       = "postgres" # Change this to a secure password

ecs_cluster_name         = "gn-ec2-clr-prod"
# ecs_ami_id           = "ami-01b799c439fd5516a" # Replace with the latest ECS-optimized AMI ID
instance_type        = "t2.small"
min_size             = 1
max_size             = 1
desired_capacity     = 1

task_definition_name = "gn-task-ec2-prod"
container_image      = "siddharth9903/graphnode:latest"

ipfs_url     = "http://18.208.209.235:5001"
ethereum_url = "base:https://base.gateway.tenderly.co/5hihJD3KoAdswisWt96oTm"

ec2_ami  = "ami-01b799c439fd5516a" # Replace with the latest Amazon Linux 2 AMI ID
key_name = "apecity-ssh-keypair"

domain_name = "base.apecity.xyz"
route53_zone_id = "Z0296707AHL64NN8DXS8"