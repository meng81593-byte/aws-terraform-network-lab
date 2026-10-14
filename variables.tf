variable "aws_region" {
  description = "AWS region containing both Availability Zones."
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Resource name prefix. The default preserves the original resource names."
  type        = string
  default     = "little-steps"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.project_name))
    error_message = "Use 3-24 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC."
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Provide a valid IPv4 CIDR."
  }
}

variable "availability_zones" {
  description = "Two distinct Availability Zones in aws_region."
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "Provide exactly two distinct Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "Two non-overlapping IPv4 subnet CIDRs inside vpc_cidr, one per AZ."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.public_subnet_cidrs) == 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Provide exactly two valid IPv4 subnet CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Two non-overlapping IPv4 subnet CIDRs inside vpc_cidr, distinct from public subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  validation {
    condition     = length(var.private_subnet_cidrs) == 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Provide exactly two valid IPv4 subnet CIDRs."
  }
}
