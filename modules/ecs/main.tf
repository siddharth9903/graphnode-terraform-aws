resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
#               EOF
#   )

#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
#               echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
#               echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=true >> /etc/ecs/ecs.config
#               systemctl restart ecs
#               EOF
#   )
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
              echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
              echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true" >> /etc/ecs/ecs.config
              yum update -y
              yum install -y ecs-init
              systemctl enable --now ecs
              EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.cluster_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

#   launch_template {
#     id      = aws_launch_template.ecs.id
#     version = "$Latest"
#   }
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs.id
        version            = "$Latest"
      }
    }
  }


  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "main" {
  name = "${var.cluster_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/${var.cluster_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "graphnode" {
  family                   = var.task_definition_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 1024
  memory                   = 3072
#   execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "graphnode"
      image = var.container_image
      essential = true
      cpu = 1024
      memory = 3072
    #   runtime_platform = "linux/x86_64"
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
          name          = "graphnode-http-8000"
          appProtocol   = "http"
        },
        {
          containerPort = 8001
          hostPort      = 8001
          protocol      = "tcp"
          name          = "graphnode-http-8001"
          appProtocol   = "http"
        },
        {
          containerPort = 8020
          hostPort      = 8020
          protocol      = "tcp"
          name          = "graphnode-http-8020"
          appProtocol   = "http"
        },
        {
          containerPort = 8030
          hostPort      = 8030
          protocol      = "tcp"
          name          = "graphnode-http-8030"
          appProtocol   = "http"
        }
      ]
      environment = [
        { name = "postgres_host", value = var.postgres_host },
        { name = "postgres_user", value = var.postgres_user },
        { name = "postgres_pass", value = var.postgres_pass },
        { name = "postgres_db", value = var.postgres_db },
        { name = "GRAPH_ALLOW_NON_DETERMINISTIC_IPFS", value = "true" },
        { name = "GRAPH_ALLOW_NON_DETERMINISTIC_FULLTEXT_SEARCH", value = "true" },
        { name = "ipfs", value = var.ipfs_url },
        { name = "ethereum", value = var.ethereum_url },
        { name = "GRAPH_LOG", value = "info" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "graphnode" {
  name            = "${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.graphnode.arn
  desired_count   = 1
#   iam_role        = aws_iam_role.ecs_instance_role.name
#   launch_type     = "EC2"
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.graphnode_8000.arn
    container_name   = "graphnode"
    container_port   = 8000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.graphnode_8001.arn
    container_name   = "graphnode"
    container_port   = 8001
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # Add health check grace period
  health_check_grace_period_seconds = 300
  
}

resource "aws_security_group" "ecs" {
  name        = "${var.cluster_name}-ecs-sg"
  description = "Security group for ECS cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
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

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.cluster_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# # Attach the AWSServiceRoleForECS managed policy to the ECS instance role
# resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
#   role       = aws_iam_role.ecs_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.cluster_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_lb" "graphnode" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "graphnode" {
  load_balancer_arn = aws_lb.graphnode.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No route match"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "graphnode_8000" {
  name        = "${var.cluster_name}-tg-8000"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/webui"
    port                = 8030
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "graphnode_8001" {
  name        = "${var.cluster_name}-tg-8001"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/webui"
    port                = 8030
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener_rule" "graphnode_8000" {
  listener_arn = aws_lb_listener.graphnode.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphnode_8000.arn
  }

  condition {
    query_string {
      key   = "type"
      value = "api"
    }
  }
}

resource "aws_lb_listener_rule" "graphnode_8001" {
  listener_arn = aws_lb_listener.graphnode.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphnode_8001.arn
  }

  condition {
    query_string {
      key   = "type"
      value = "ws"
    }
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

data "aws_region" "current" {}