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
variable "github_repository" {
  type    = string
  default = "meng81593-byte/little-steps-devops"
}
variable "existing_oidc_provider_arn" {
  type    = string
  default = null
}
variable "trusted_branches" {
  type    = set(string)
  default = ["main"]
}
data "aws_caller_identity" "current" {}
resource "aws_ecr_repository" "game" {
  name                 = var.project_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  encryption_configuration { encryption_type = "AES256" }
  # Per-repository setting avoids changing unrelated registry-wide scan rules.
  image_scanning_configuration { scan_on_push = true }
  tags = { Project = var.project_name, ManagedBy = "Terraform", Purpose = "portfolio-lab" }
}
resource "aws_ecr_lifecycle_policy" "game" {
  repository = aws_ecr_repository.game.name
  policy = jsonencode({ rules = [{ rulePriority = 1, description = "Keep ten commit images", selection = {
    tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10
  }, action = { type = "expire" } }] })
}
resource "aws_iam_openid_connect_provider" "github" {
  count          = var.existing_oidc_provider_arn == null ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = { Project = var.project_name, ManagedBy = "Terraform" }
}
locals {
  oidc_arn = var.existing_oidc_provider_arn == null ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}
resource "aws_iam_role" "publisher" {
  name = "${var.project_name}-publisher"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Action = "sts:AssumeRoleWithWebIdentity", Principal = { Federated = local.oidc_arn },
    Condition = { StringEquals = {
      "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub" = [for branch in var.trusted_branches : "repo:${var.github_repository}:ref:refs/heads/${branch}"]
    } }
  }] })
}
resource "aws_iam_role_policy" "publisher" {
  role = aws_iam_role.publisher.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
    { Effect = "Allow", Action = ["ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:DescribeImages"], Resource = aws_ecr_repository.game.arn }
  ] })
}
output "repository_url" { value = aws_ecr_repository.game.repository_url }
output "repository_name" { value = aws_ecr_repository.game.name }
output "publisher_role_arn" { value = aws_iam_role.publisher.arn }
output "oidc_provider_arn" { value = local.oidc_arn }
