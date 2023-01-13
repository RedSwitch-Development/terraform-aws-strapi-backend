###############
# Application #
###############
module "ecr" {
  source = "lgallard/ecr/aws"
  name   = var.service_name

  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "service_definition" {
  family                   = var.service_name
  requires_compatibilities = [var.ecs_launch_type]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory

  container_definitions = jsonencode([
    {
      name      = "${var.service_name}"
      image     = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_image_name}:latest"
      essential = true
      portMappings = [
        {
          containerPort = "${var.container_port}"
          hostPort      = "${var.container_port}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.service_logs.name}"
          "awslogs-region"        = "${var.region}"
          "awslogs-stream-prefix" = "${var.service_name}"
        }
      }
      environment = var.environment_variables
    }
  ])

  task_role_arn      = var.task_role_arn
  execution_role_arn = aws_iam_role.service_execution_role.arn

  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.ecs_cluster_name
  task_definition = var.service_name
  desired_count   = var.instance_count
  depends_on      = [var.task_role_arn, aws_ecs_task_definition.service_definition]

  force_new_deployment = var.force_new_deployment

  launch_type = var.ecs_launch_type

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.security_group]
    assign_public_ip = true
  }

  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}



#######
# IAM #
#######
resource "aws_iam_role" "service_task_role" {
  name = "${var.service_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.service_name}-task-role-policy"

    policy = jsonencode({
      Version   = "2012-10-17"
      Statement = var.task_iam_permissions
    })
  }

  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_iam_role" "service_execution_role" {
  name = "${var.service_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.service_name}-execution-role-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ec2:*"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["ecr:*"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["logs:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

###########
# Network #
###########
resource "aws_lb_target_group" "back_end" {
  name        = var.service_name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/"
  }
}

resource "aws_alb_listener_rule" "back_end" {
  action {
    target_group_arn = aws_lb_target_group.back_end.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = [var.application_url]
    }
  }

  listener_arn = var.alb_listener_arn

  depends_on = [
    aws_lb_target_group.back_end
  ]
}

##############
# Monitoring #
##############
resource "aws_cloudwatch_log_group" "service_logs" {
  name = "/ecs/${var.service_name}"

  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

############
# Database #
############
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = local.service_name

  engine               = var.db_engine
  engine_version       = var.db_engine_version
  major_engine_version = var.db_major_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage

  name     = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [data.aws_security_group.default.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring
  monitoring_interval    = "30"
  monitoring_role_name   = "${var.service_name}-monitoring-role"
  create_monitoring_role = true

  # DB subnet group
  subnet_ids = var.subnets

  # DB parameter group
  create_db_parameter_group = false

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${var.service_name}-snapshot"

  # Database Deletion Protection
  deletion_protection = true

  # Public Access
  publicly_accessible = true

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

  options = []

  tags = {
    Service     = var.service_name
    Environment = var.environment
  }
}

