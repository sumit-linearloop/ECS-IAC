# ECS Services
resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.my_vpc.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

    load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"  # Must match the container name in your task definition
    container_port   = 1400             # Must match the container's port exposed in the task definition
  }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.my_vpc.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}


