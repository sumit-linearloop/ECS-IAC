# --- ECS Task Role ---

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "demo-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# --- Cloud Watch Logs ---

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 14
}

# --- ECS Task  ---

resource "aws_ecs_task_definition" "app" {
  family             = "demo-app"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "bridge"  # Changed from "awsvpc" to "bridge"
  cpu                = 2048
  memory             = 6144

  container_definitions = jsonencode([{
    name         = "app",
    image        = "sumit246/sumit:latest",
    essential    = true
          portMappings = [
        {
          containerPort = 1400
          hostPort      = 1400
        }
      ]
  
    cpu              = 2048  # Hard CPU limit (in units)
    memory           = 6144  # Hard memory limit (in MiB)
    memoryReservation = 3072  # Soft memory limit (in MiB)
 
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "ap-south-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "app"
      }
    },
  }])
}
