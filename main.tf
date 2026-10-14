# 1. Provider 配置：告诉 Terraform 我们要操作 AWS，并且把主阵地设在巴黎区 (eu-west-3)
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Purpose   = "portfolio-lab"
    }
  }
}

# 2. VPC 资源：这是我们在云上的一块隔离的虚拟地皮
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr # Private address space for this lab
  enable_dns_support   = true         # 开启内部 DNS 解析支持
  enable_dns_hostnames = true         # 允许 EC2 实例获取自动分配的 DNS 主机名

  tags = {
    Name = "${var.project_name}-vpc" # 贴个标签，以后在 AWS 控制台一眼就能认出它
  }
}

#3 public Subnet1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1"
  }
}

#4 public Subnet2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnet_cidrs[0]
  availability_zone       = var.availability_zones[0]

  tags = {
    Name = "${var.project_name}-private-1"
  }
}

#Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnet_cidrs[1]
  availability_zone       = var.availability_zones[1]

  tags = {
    Name = "${var.project_name}-private-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private subnets retain local VPC routing only. Egress must be designed separately.
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.main_vpc.id
  route  = []
  tags   = { Name = "${var.project_name}-private-rt-1" }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.main_vpc.id
  route  = []
  tags   = { Name = "${var.project_name}-private-rt-2" }
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}
