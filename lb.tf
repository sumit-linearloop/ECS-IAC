# Load Balancer (ALB)

resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = aws_vpc.my_vpc.id

}

# Create an Application Load Balancer (ALB)
resource "aws_lb" "example_alb" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_node_sg.id] 
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  enable_deletion_protection = false

  tags = {
    Name = "example-alb"
  }
}

# Create a Target Group
resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 1400   # Must match the container port
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    interval            = 300
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "alb_url" {
  value = aws_lb.example_alb.dns_name
}







# --- ECS Service Auto Scaling ---


# --- ECS Service Auto Scaling ---

resource "aws_appautoscaling_target" "ecs_target" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.my_vpc.name}/${aws_ecs_service.app.name}"
  min_capacity       = 1
  max_capacity       = 2
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
