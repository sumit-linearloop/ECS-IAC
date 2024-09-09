# security-group
resource "aws_security_group" "ecs_node_sg" {
  name_prefix = "demo-ecs-node-sg-"
  vpc_id      = aws_vpc.my_vpc.id

  dynamic "ingress" {
    for_each = [22, 80, 443, 6379, 1400]
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sumit-Terraform"
  }
}

# --- ECS Launch Template ---

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}


resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "demo-ecs-ec2"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t3a.large"
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]  # Corrected reference
  key_name               = "sumit"  # Add your AWS key pair name here

  iam_instance_profile { 
    arn = aws_iam_instance_profile.ecs_node.arn  # Corrected reference
  }
  
  monitoring { 
    enabled = true 
  }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.my_vpc.name} >> /etc/ecs/ecs.config;
    EOF
  )
}



# --- ECS ASG ---

resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "demo-ecs-asg-"
  vpc_zone_identifier       = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  min_size                  = 1
  max_size                  = 2
  


  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1    # Start with one instance

   # Attach to the ALB Target Group
  target_group_arns = [aws_lb_target_group.app.arn]  # Reference the Target Group


  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "demo-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

# --- ECS Capacity Provider ---

resource "aws_ecs_capacity_provider" "my_vpc" {
  name = "demo-ecs-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1      
      status                    = "ENABLED"
      target_capacity           = 70
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "my_vpc" {
  cluster_name       = aws_ecs_cluster.my_vpc.name  # Corrected reference
  capacity_providers = [aws_ecs_capacity_provider.my_vpc.name]  # Corrected reference

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.my_vpc.name  # Corrected reference
    base              = 1
    weight            = 100
  }
}


