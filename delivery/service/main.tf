terraform {
  required_version = ">= 1.7, < 2.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 6.0" } }
}
provider "aws" { region = var.aws_region }
variable "aws_region" {
  type    = string
  default = "eu-west-3"
}
variable "project_name" {
  type    = string
  default = "little-steps-portfolio"
}
variable "image_uri" {
  type        = string
  description = "ECR image reference pinned by sha256 digest."
  validation {
    condition     = can(regex("@sha256:[a-f0-9]{64}$", var.image_uri))
    error_message = "Supply an immutable image digest, not a mutable tag."
  }
}
variable "desired_count" {
  type    = number
  default = 1
  validation {
    condition     = contains([0, 1, 2], var.desired_count)
    error_message = "This cost-limited demo permits zero, one or two tasks."
  }
}
module "network" {
  source       = "../.."
  aws_region   = var.aws_region
  project_name = var.project_name
  # Dedicated experiment; it does not modify the original little-steps-vpc.
  vpc_cidr             = "10.42.0.0/16"
  public_subnet_cidrs  = ["10.42.1.0/24", "10.42.2.0/24"]
  private_subnet_cidrs = ["10.42.3.0/24", "10.42.4.0/24"]
}
data "aws_caller_identity" "current" {}
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = module.network.vpc_id
  description = "Public HTTP demonstration endpoint"
}
resource "aws_security_group" "tasks" {
  name_prefix = "${var.project_name}-task-"
  vpc_id      = module.network.vpc_id
  description = "Only the load balancer may reach the game"
}
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Public static game demo, no credentials or user data"
}
resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.tasks.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "game" {
  security_group_id            = aws_security_group.tasks.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
# ECR and CloudWatch have dynamic endpoints; this short-lived demo limits egress to TCP 443.
# trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "ECR image pull and CloudWatch Logs via public IPv4"
}
# An internet-facing ALB is the explicit entry point for a public static game.
# trivy:ignore:AVD-AWS-0053
resource "aws_lb" "game" {
  name                       = var.project_name
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.alb.id]
  subnets                    = module.network.public_subnet_ids
  drop_invalid_header_fields = true
}
resource "aws_lb_target_group" "game" {
  name                 = var.project_name
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = module.network.vpc_id
  deregistration_delay = 10
  health_check {
    path              = "/healthz"
    healthy_threshold = 2
    interval          = 15
  }
}
# Short-lived HTTP-only experiment without a supplied domain; no private data or authentication.
# Permanent hosting requires an HTTPS listener and certificate.
# trivy:ignore:AVD-AWS-0054
resource "aws_lb_listener" "game" {
  load_balancer_arn = aws_lb.game.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.game.arn
  }
}
resource "aws_cloudwatch_log_group" "game" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}
resource "aws_iam_role" "execution" {
  name = "${var.project_name}-execution"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ecs-tasks.amazonaws.com" },
    Condition = {
      StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id },
      ArnLike      = { "aws:SourceArn" = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*" }
    }
  }] })
}
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_cluster" "game" { name = var.project_name }
resource "aws_ecs_task_definition" "game" {
  family                   = var.project_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{
    name         = "game", image = var.image_uri, essential = true,
    portMappings = [{ containerPort = 8080, protocol = "tcp" }],
    healthCheck  = { command = ["CMD-SHELL", "wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1"], interval = 15, timeout = 3, retries = 3, startPeriod = 10 },
    logConfiguration = { logDriver = "awslogs", options = {
      "awslogs-group"         = aws_cloudwatch_log_group.game.name,
      "awslogs-region"        = var.aws_region,
      "awslogs-stream-prefix" = "game"
    } }
  }])
}
resource "aws_ecs_service" "game" {
  name                               = var.project_name
  cluster                            = aws_ecs_cluster.game.id
  task_definition                    = aws_ecs_task_definition.game.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  wait_for_steady_state              = true
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets          = module.network.public_subnet_ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.game.arn
    container_name   = "game"
    container_port   = 8080
  }
  depends_on = [aws_lb_listener.game, aws_iam_role_policy_attachment.execution]
}
output "url" { value = "http://${aws_lb.game.dns_name}" }
output "cluster_name" { value = aws_ecs_cluster.game.name }
output "service_name" { value = aws_ecs_service.game.name }
output "task_definition_arn" { value = aws_ecs_task_definition.game.arn }
