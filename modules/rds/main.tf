resource "aws_rds_cluster" "graphnode" {
  cluster_identifier      = var.db_cluster_identifier
  engine                 = "aurora-postgresql"
  engine_version         = "14.9"
#   instance_class         = var.instance_class
  backup_retention_period = var.backup_retention_period

  # Add other production-specific settings
  deletion_protection   = var.is_production
  skip_final_snapshot   = !var.is_production

  availability_zones      = var.availability_zones
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = var.master_password
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.graphnode.name

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "graphnode" {
  count              = 1
  identifier         = "${var.db_cluster_identifier}-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.graphnode.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.graphnode.engine
  engine_version     = aws_rds_cluster.graphnode.engine_version
}

resource "aws_db_subnet_group" "graphnode" {
  name       = "${var.db_cluster_identifier}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "rds" {
  name        = "${var.db_cluster_identifier}-sg"
  description = "Security group for RDS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "rds_connector" {
  ami           = var.ec2_ami
  instance_type = "t2.micro"
  key_name      = var.key_name
  subnet_id     = var.subnet_ids[0]

  vpc_security_group_ids = [aws_security_group.rds_connector.id]

  tags = {
    Name = "rds-connector"
  }
}

resource "aws_security_group" "rds_connector" {
  name        = "rds-connector-sg"
  description = "Security group for RDS connector EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "null_resource" "create_database" {
  depends_on = [aws_rds_cluster_instance.graphnode]

  provisioner "local-exec" {
    command = <<-EOT
      psql -h ${aws_rds_cluster.graphnode.endpoint} -U ${var.master_username} -d postgres -c "
        CREATE DATABASE ${var.database_name}
        WITH
        OWNER = ${var.master_username}
        TEMPLATE = template0
        LC_COLLATE = 'C'
        LC_CTYPE = 'C'
        CONNECTION LIMIT = -1
        IS_TEMPLATE = False;
      "
    EOT

    environment = {
      PGPASSWORD = var.master_password
    }
  }
}