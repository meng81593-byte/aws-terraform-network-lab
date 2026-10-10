# 1. Provider 配置：告诉 Terraform 我们要操作 AWS，并且把主阵地设在巴黎区 (eu-west-3)
provider "aws" {
  region = "eu-west-3"
}

# 2. VPC 资源：这是我们在云上的一块隔离的虚拟地皮
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"   # 划分一个大网段，包含 65536 个内部 IP 地址
  enable_dns_support   = true            # 开启内部 DNS 解析支持
  enable_dns_hostnames = true            # 允许 EC2 实例获取自动分配的 DNS 主机名

  tags = {
    Name = "little-steps-vpc"            # 贴个标签，以后在 AWS 控制台一眼就能认出它
  }
}

#3 public Subnet1
resource "aws_subnet" "public_subnet_1"{
    vpc_id      = aws_vpc.main_vpc.id
    cidr_block  = "10.0.1.0/24"
    availability_zone = "eu-west-3a"
    map_public_ip_on_launch = true

    tags = {
        Name = "little-steps-public-1"
    }
}

#4 public Subnet2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"         
  availability_zone       = "eu-west-3b"         
  map_public_ip_on_launch = true

  tags = {
    Name = "little-steps-public-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "little-steps-private-1"
  }
}

#Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-3b"

  tags = {
    Name = "little-steps-private-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "little-steps-igw"
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
    Name = "little-steps-public-rt"
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