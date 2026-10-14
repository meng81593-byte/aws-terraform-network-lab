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
    condition     = aws_subnet.public_subnet_1.map_public_ip_on_launch && aws_subnet.public_subnet_2.map_public_ip_on_launch
    error_message = "Demo public subnets must support public IPv4 assignment."
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
