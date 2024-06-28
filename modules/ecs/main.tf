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
  default_version = 1
  key_name        = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs.id]
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs.arn
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
              EOF
  )

  tag_specifications {
    resource_type = "instance"
      tags = {
        Name = "ecs-instance"
      }
 }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.cluster_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
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
      target_capacity           = 1
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
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = 1024
  memory                   = 3072
  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name  = "graphnode"
      image = var.container_image
      essential = true
      cpu = 1024
      memory = 2048
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        },
        {
          containerPort = 8001
          hostPort      = 8001
        },
        {
          containerPort = 8020
          hostPort      = 8020
        },
        {
          containerPort = 8030
          hostPort      = 8030
        },
        {
          containerPort = 8040
          hostPort      = 8040
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

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 100
    base              = 1
  }

  force_new_deployment = true
  placement_constraints {
    type = "distinctInstance"
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

  depends_on = [aws_autoscaling_group.ecs]
}

resource "aws_security_group" "ecs" {
  name        = "${var.cluster_name}-ecs-sg"
  description = "Security group for ECS cluster"
  vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow inter-container communication"
  }

  ingress {
    from_port       = 8000
    to_port         = 8040
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB on ports 8000-8040"
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.graphnode.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "graphnode" {
  load_balancer_arn = aws_lb.graphnode.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.graphnode_8000.arn
  }
}


resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id = var.route53_zone_id
  records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# resource "aws_lb" "graphnode" {
#   name               = "${var.cluster_name}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = var.subnet_ids
# }

# resource "aws_lb_listener" "graphnode" {
#   load_balancer_arn = aws_lb.graphnode.arn

#   port              = 80
#   protocol          = "HTTP"
# #   port              = 443
# #   protocol          = "HTTPS"
# #   ssl_policy        = "ELBSecurityPolicy-2016-08"
# #   certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

#   default_action {
#     type = "fixed-response"
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "No route match"
#       status_code  = "404"
#     }
#   }

# #   depends_on = [aws_acm_certificate_validation.cert]
# }


resource "aws_lb_target_group" "graphnode_8000" {
  name        = "${var.cluster_name}-tg-8000"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = 8030
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200-499"
  }
}

resource "aws_lb_target_group" "graphnode_8001" {
  name        = "${var.cluster_name}-tg-8001"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = 8030
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200-499"
  }
}

# resource "aws_lb_listener_rule" "graphnode_8000" {
#   listener_arn = aws_lb_listener.graphnode.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.graphnode_8000.arn
#   }

#   condition {
#     query_string {
#       key   = "type"
#       value = "api"
#     }
#   }
# }

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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_route53_record" "graphnode" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.graphnode.dns_name
    zone_id                = aws_lb.graphnode.zone_id
    evaluate_target_health = true
  }
}

data "aws_region" "current" {}
# resource "aws_ecs_cluster" "main" {
#   name = var.cluster_name

#   setting {
#     name  = "containerInsights"
#     value = "enabled"
#   }
# }

# resource "aws_launch_template" "ecs" {
#   name_prefix   = "${var.cluster_name}-lt-"
#   image_id      = var.ami_id
#   instance_type = var.instance_type
#   default_version = 1
#   key_name        = var.key_name


#   network_interfaces {
#     associate_public_ip_address = true
#     security_groups             = [aws_security_group.ecs.id]
#   }

# #   iam_instance_profile {
# #     name = aws_iam_instance_profile.ecs.name
# #   }
#   iam_instance_profile {
#     arn = aws_iam_instance_profile.ecs.arn
#   }


#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
#               EOF
#   )

# #   systemctl restart ecs


# #   user_data = filebase64("${path.module}/ecs.sh")

# #   user_data = base64encode(templatefile("${path.module}/ecs.sh", {
# #     cluster_name = var.cluster_name
# #   }))

#   tag_specifications {
#     resource_type = "instance"
#       tags = {
#         Name = "ecs-instance"
#       }
#  }
# }

# resource "aws_autoscaling_group" "ecs" {
#   name                = "${var.cluster_name}-asg"
#   vpc_zone_identifier = var.subnet_ids
#   min_size            = var.min_size
#   max_size            = var.max_size
#   desired_capacity    = var.desired_capacity

#   launch_template {
#     id      = aws_launch_template.ecs.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "AmazonECSManaged"
#     value               = true
#     propagate_at_launch = true
#   }
# }

# resource "aws_ecs_capacity_provider" "main" {
#   name = "${var.cluster_name}-cp"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn = aws_autoscaling_group.ecs.arn
#     managed_scaling {
#       maximum_scaling_step_size = 1000
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 1
#     }
#   }
# }

# resource "aws_ecs_cluster_capacity_providers" "main" {
#   cluster_name       = aws_ecs_cluster.main.name
#   capacity_providers = [aws_ecs_capacity_provider.main.name]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = aws_ecs_capacity_provider.main.name
#   }
# }

# resource "aws_cloudwatch_log_group" "ecs_logs" {
#   name = "/ecs/${var.cluster_name}"
#   retention_in_days = 7
# }

# resource "aws_ecs_task_definition" "graphnode" {
#   family                   = var.task_definition_name
#   network_mode             = "bridge"
#   requires_compatibilities = ["EC2"]
#   cpu                      = 1024
#   memory                   = 3072
# #   execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
# #   execution_role_arn = "arn:aws:iam::532199187081:role/ecsTaskExecutionRole"
  
#   runtime_platform {
#     operating_system_family = "LINUX"
#     cpu_architecture        = "X86_64"
#   }

#   container_definitions = jsonencode([
#     {
#       name  = "graphnode"
#       image = var.container_image
#       essential = true
#       cpu = 1024
#       memory = 3072
#     #   runtime_platform = "linux/x86_64"
#       portMappings = [
#         {
#           containerPort = 8000
#           hostPort      = 8000
#         #   protocol      = "tcp"
#         #   name          = "graphnode-http-8000"
#         #   appProtocol   = "http"
#         },
#         {
#           containerPort = 8001
#           hostPort      = 8001
#         #   protocol      = "tcp"
#         #   name          = "graphnode-http-8001"
#         #   appProtocol   = "http"
#         },
#         {
#           containerPort = 8020
#           hostPort      = 8020
#         #   protocol      = "tcp"
#         #   name          = "graphnode-http-8020"
#         #   appProtocol   = "http"
#         },
#         {
#           containerPort = 8030
#           hostPort      = 8030
#         #   protocol      = "tcp"
#         #   name          = "graphnode-http-8030"
#         #   appProtocol   = "http"
#         },
#         {
#           containerPort = 8040
#           hostPort      = 8040
#         #   protocol      = "tcp"
#         #   name          = "graphnode-http-8040"
#         #   appProtocol   = "http"
#         }
#       ]
#       environment = [
#         { name = "postgres_host", value = var.postgres_host },
#         { name = "postgres_user", value = var.postgres_user },
#         { name = "postgres_pass", value = var.postgres_pass },
#         { name = "postgres_db", value = var.postgres_db },
#         { name = "GRAPH_ALLOW_NON_DETERMINISTIC_IPFS", value = "true" },
#         { name = "GRAPH_ALLOW_NON_DETERMINISTIC_FULLTEXT_SEARCH", value = "true" },
#         { name = "ipfs", value = var.ipfs_url },
#         { name = "ethereum", value = var.ethereum_url },
#         { name = "GRAPH_LOG", value = "info" }
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
#           awslogs-region        = data.aws_region.current.name
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#     }
#   ])
# }

# resource "aws_ecs_service" "graphnode" {
#   name            = "${var.cluster_name}-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.graphnode.arn
#   desired_count   = 1
# #   iam_role        = aws_iam_role.ecs_instance_role.name
# #   launch_type     = "EC2"
#   capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.main.name
#     weight            = 100
#     base              = 1
#   }
# #   triggers = {
# #     redeployment = timestamp()
# #   }
#   force_new_deployment = true
#   placement_constraints {
#     type = "distinctInstance"
#   }

#   network_configuration {
#     subnets         = var.subnet_ids
#     security_groups = [aws_security_group.ecs.id]
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.graphnode_8000.arn
#     container_name   = "graphnode"
#     container_port   = 8000
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.graphnode_8001.arn
#     container_name   = "graphnode"
#     container_port   = 8001
#   }

# #   deployment_circuit_breaker {
# #     enable   = true
# #     rollback = true
# #   }

# #   deployment_maximum_percent         = 200
# #   deployment_minimum_healthy_percent = 100

# #   enable_ecs_managed_tags = true
# #   propagate_tags          = "SERVICE"

# #   # Add health check grace period
# #   health_check_grace_period_seconds = 300

#   depends_on = [aws_autoscaling_group.ecs]
  
# }

# resource "aws_security_group" "ecs" {
#   name        = "${var.cluster_name}-ecs-sg"
#   description = "Security group for ECS cluster"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#   from_port   = 0
#   to_port     = 65535
#   protocol    = "tcp"
#   self        = true
#   description = "Allow inter-container communication"
# }

#   ingress {
#     from_port       = 8000
#     to_port         = 8040
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb.id]
#     description     = "Allow traffic from ALB on ports 8000-8040"
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_iam_role" "ecs_instance_role" {
#   name = "${var.cluster_name}-ecs-instance-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
#   role       = aws_iam_role.ecs_instance_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# resource "aws_iam_instance_profile" "ecs" {
#   name = "${var.cluster_name}-ecs-instance-profile"
#   role = aws_iam_role.ecs_instance_role.name
# }

# # resource "aws_acm_certificate" "cert" {
# #   domain_name       = var.domain_name
# #   validation_method = "DNS"

# #   lifecycle {
# #     create_before_destroy = true
# #   }
# # }

# # resource "aws_route53_record" "cert_validation" {
# #   allow_overwrite = true
# #   name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
# #   type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
# #   zone_id = var.route53_zone_id
# #   records = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
# #   ttl     = 60
# # }

# # resource "aws_acm_certificate_validation" "cert" {
# #   certificate_arn         = aws_acm_certificate.cert.arn
# #   validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
# # }

# resource "aws_lb" "graphnode" {
#   name               = "${var.cluster_name}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = var.subnet_ids
# }

# resource "aws_lb_listener" "graphnode" {
#   load_balancer_arn = aws_lb.graphnode.arn

#   port              = 80
#   protocol          = "HTTP"
# #   port              = 443
# #   protocol          = "HTTPS"
# #   ssl_policy        = "ELBSecurityPolicy-2016-08"
# #   certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

#   default_action {
#     type = "fixed-response"
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "No route match"
#       status_code  = "404"
#     }
#   }

# #   depends_on = [aws_acm_certificate_validation.cert]
# }

# resource "aws_lb_target_group" "graphnode_8000" {
#   name        = "${var.cluster_name}-tg-8000"
#   port        = 8000
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "instance"

#   health_check {
#     path                = "/"
#     port                = 8030
#     protocol            = "HTTP"
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     interval            = 30
#     matcher             = "200-499"
#   }
# }

# resource "aws_lb_target_group" "graphnode_8001" {
#   name        = "${var.cluster_name}-tg-8001"
#   port        = 8001
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "instance"


#   health_check {
#     path                = "/"
#     port                = 8030
#     protocol            = "HTTP"
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     interval            = 30
#     matcher             = "200-499"
#   }
# }

# resource "aws_lb_listener_rule" "graphnode_8000" {
#   listener_arn = aws_lb_listener.graphnode.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.graphnode_8000.arn
#   }

#   condition {
#     query_string {
#       key   = "type"
#       value = "api"
#     }
#   }
# }

# resource "aws_lb_listener_rule" "graphnode_8001" {
#   listener_arn = aws_lb_listener.graphnode.arn
#   priority     = 200

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.graphnode_8001.arn
#   }

#   condition {
#     query_string {
#       key   = "type"
#       value = "ws"
#     }
#   }
# }

# resource "aws_security_group" "alb" {
#   name        = "${var.cluster_name}-alb-sg"
#   description = "Security group for ALB"
#   vpc_id      = var.vpc_id

# #   ingress {
# #     from_port   = 443
# #     to_port     = 443
# #     protocol    = "tcp"
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # resource "aws_route53_record" "graphnode" {
# #   zone_id = var.route53_zone_id
# #   name    = var.domain_name
# #   type    = "A"

# #   alias {
# #     name                   = aws_lb.graphnode.dns_name
# #     zone_id                = aws_lb.graphnode.zone_id
# #     evaluate_target_health = true
# #   }
# # }

# data "aws_region" "current" {}