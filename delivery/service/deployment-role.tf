variable "github_subject_prefix" {
  type        = string
  description = "Exact subject prefix returned by the repository's Actions OIDC customization API."
  default     = "repo:meng81593-byte@252664009/little-steps-devops@1381492722"
}
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
resource "aws_iam_role" "deployer" {
  name = "${var.project_name}-deployer"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect    = "Allow", Action = "sts:AssumeRoleWithWebIdentity",
    Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn },
    Condition = { StringEquals = {
      "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub" = "${var.github_subject_prefix}:ref:refs/heads/main"
    } }
  }] })
}
resource "aws_iam_role_policy" "deployer" {
  role = aws_iam_role.deployer.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    # ECS registration requires '*'; this role can deploy only to the named service
    # and can pass only its execution role, never an arbitrary IAM role.
    { Effect = "Allow", Action = ["ecs:RegisterTaskDefinition"], Resource = "*" },
    { Effect = "Allow", Action = ["ecs:DescribeTaskDefinition"], Resource = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.project_name}:*" },
    { Effect = "Allow", Action = ["ecs:DescribeServices", "ecs:UpdateService"], Resource = aws_ecs_service.game.id },
    { Effect = "Allow", Action = ["ecr:DescribeImages"], Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}" },
    { Effect = "Allow", Action = ["iam:PassRole"], Resource = aws_iam_role.execution.arn, Condition = { StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" } } }
  ] })
}
output "deployer_role_arn" { value = aws_iam_role.deployer.arn }
