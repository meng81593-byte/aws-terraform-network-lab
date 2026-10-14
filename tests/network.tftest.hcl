mock_provider "aws" {}

run "network_boundaries" {
  command = plan

  assert {
    condition     = aws_vpc.main_vpc.enable_dns_support && aws_vpc.main_vpc.enable_dns_hostnames
    error_message = "VPC DNS must be enabled."
  }
  assert {
    condition     = aws_subnet.public_subnet_1.availability_zone != aws_subnet.public_subnet_2.availability_zone
    error_message = "Public subnets must span two Availability Zones."
  }
  assert {
    condition     = !aws_subnet.public_subnet_1.map_public_ip_on_launch && !aws_subnet.public_subnet_2.map_public_ip_on_launch
    error_message = "Public IPv4 assignment must be an explicit workload choice, not a subnet default."
  }
  assert {
    condition     = !aws_subnet.private_subnet_1.map_public_ip_on_launch && !aws_subnet.private_subnet_2.map_public_ip_on_launch
    error_message = "Private subnets must not auto-assign public IPv4 addresses."
  }
  assert {
    condition     = length(aws_route_table.private_rt_1.route) == 0 && length(aws_route_table.private_rt_2.route) == 0
    error_message = "Private route tables must not declare Internet routes."
  }
}

run "reject_duplicate_zones" {
  command = plan
  variables {
    availability_zones = ["eu-west-3a", "eu-west-3a"]
  }
  expect_failures = [var.availability_zones]
}

run "reject_overlapping_subnets" {
  command = plan
  variables { public_subnet_cidrs = ["10.0.1.0/24", "10.0.1.0/24"] }
  expect_failures = [aws_vpc.main_vpc]
}

run "reject_subnet_outside_vpc" {
  command = plan
  variables { private_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24"] }
  expect_failures = [aws_vpc.main_vpc]
}

run "reject_zones_in_another_region" {
  command = plan
  variables { availability_zones = ["us-east-1a", "us-east-1b"] }
  expect_failures = [aws_vpc.main_vpc]
}
