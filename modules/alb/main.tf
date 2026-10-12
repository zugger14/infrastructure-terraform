resource "aws_security_group" "alb_sg" {
  name        = "multiapp-alb-sg-${var.environment}"
  description = "Security group for ECS Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP Public"
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

  tags = {
    Name = "multiapp-alb-sg-${var.environment}"
  }
}

resource "aws_lb" "main" {
  name               = "multiapp-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "multiapp-alb-${var.environment}"
  }
}

# Default HTTP Listener (returns 404 for unrouted traffic, rules will forward to apps)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "MultiApp ECS Load Balancer - Route Not Found"
      status_code  = "404"
    }
  }
}
