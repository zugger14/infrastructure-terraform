# ==============================================================================
# ECS Cluster
# ==============================================================================
resource "aws_ecs_cluster" "main" {
  name = "multiapp-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "disabled" # Keep disabled to avoid extra CloudWatch costs
  }
}

# ==============================================================================
# IAM Roles for Fargate Tasks
# ==============================================================================
resource "aws_iam_role" "ecs_execution_role" {
  name = "multiapp-ecs-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==============================================================================
# Security Group for ECS Tasks (Receives traffic from ALB only)
# ==============================================================================
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "multiapp-ecs-tasks-sg-${var.environment}"
  description = "Allows incoming traffic from ALB to ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "multiapp-ecs-tasks-sg-${var.environment}"
  }
}

# ==============================================================================
# Target Groups & ALB Listener Rules (DRY loop per application)
# ==============================================================================
resource "aws_lb_target_group" "app_tg" {
  for_each = var.apps

  name        = "tg-${each.key}-${var.environment}"
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = coalesce(each.value.health_check_path, "/")
    interval            = 60
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
  }
}

resource "aws_lb_listener_rule" "app_rule" {
  for_each = var.apps

  listener_arn = var.alb_listener_arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg[each.key].arn
  }

  dynamic "condition" {
    for_each = each.value.path_pattern != null ? [1] : []
    content {
      path_pattern {
        values = [each.value.path_pattern]
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.host_header_pattern != null ? [1] : []
    content {
      host_header {
        values = each.value.host_header_pattern
      }
    }
  }
}

# ==============================================================================
# CloudWatch Log Groups (DRY loop per application)
# ==============================================================================
resource "aws_cloudwatch_log_group" "app_logs" {
  for_each = var.apps

  name              = "/ecs/${each.key}-${var.environment}"
  retention_in_days = 7
}

# ==============================================================================
# ECS Task Definitions & Services (Lowest compute options: 256 CPU, 512 MB RAM)
# ==============================================================================
resource "aws_ecs_task_definition" "app_task" {
  for_each = var.apps

  family                   = "${each.key}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = coalesce(each.value.container_image, try("${var.ecr_repository_urls[each.key]}:latest", "public.ecr.aws/docker/library/alpine:latest"))
      essential = true
      portMappings = [
        {
          containerPort = each.value.container_port
          hostPort      = each.value.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app_logs[each.key].name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  for_each = var.apps

  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg[each.key].arn
    container_name   = each.key
    container_port   = each.value.container_port
  }

  depends_on = [aws_lb_listener_rule.app_rule]
}
