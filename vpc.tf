// // Default VPC

resource "aws_default_vpc" "default" {}

data "aws_subnet_ids" "default_subtets" {
  vpc_id = aws_default_vpc.default.id
}

data "aws_security_group" "default" {
  vpc_id = aws_default_vpc.default.id
  name   = "default"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "alb_sg" {
  name   = "${var.prefix}-alb_sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Custom VPC
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zone_names = data.aws_availability_zones.available.names
  az_number               = length(local.availability_zone_names)
  //  https://www.terraform.io/docs/language/functions/cidrsubnet.html
  private_subnets_cidrs = [for intex in range(local.az_number) : cidrsubnet(var.vpc_cidr, 4, intex)]
  public_subnets_cidrs  = [for intex in range(local.az_number) : cidrsubnet(var.vpc_cidr, 4, intex + local.az_number)]
}

//https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "production_vpc" {
  //  https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html
  cidr_block = var.vpc_cidr
  //  https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prefix}-Production-VPC"
  }
}

//https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
//https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-subnet-basics
resource "aws_subnet" "public_subnet" {
  count             = length(local.public_subnets_cidrs)
  cidr_block        = local.public_subnets_cidrs[count.index]
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone = local.availability_zone_names[count.index]

  tags = {
    Name = "${var.prefix}-Public-Subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(local.private_subnets_cidrs)
  cidr_block        = local.private_subnets_cidrs[count.index]
  vpc_id            = aws_vpc.production_vpc.id
  availability_zone = local.availability_zone_names[count.index]

  tags = {
    Name = "${var.prefix}-Privat-Subnet-${count.index}"
  }
}

//https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
//https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.production_vpc.id
  tags = {
    Name = "${var.prefix}-Public-Route-Table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.production_vpc.id
  tags = {
    Name = "${var.prefix}-Private-Route-Table"
  }
}


//https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#route-table-assocation
//https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "public_route_association" {
  count          = length(local.public_subnets_cidrs)
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

resource "aws_route_table_association" "private_route_association" {
  count          = length(local.private_subnets_cidrs)
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}

// https://docs.aws.amazon.com/vpc/latest/userguide/vpc-eips.html
resource "aws_eip" "nat_gw_elastic_ip" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"

  tags = {
    Name = "${var.prefix}-Production-EIP"
  }

  depends_on = [aws_internet_gateway.production_igw]
}

// https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
//network address translation
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_elastic_ip.id
  subnet_id     = aws_subnet.private_subnet[0].id

  tags = {
    Name = "${var.prefix}-Production-NAT-GW"
  }

  depends_on = [aws_eip.nat_gw_elastic_ip]
}

//https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "nat_gw_route" {
  route_table_id         = aws_route_table.private_route_table.id
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  destination_cidr_block = "0.0.0.0/0"
}

//https://medium.com/awesome-cloud/aws-vpc-difference-between-internet-gateway-and-nat-gateway-c9177e710af6
resource "aws_internet_gateway" "production_igw" {
  vpc_id = aws_vpc.production_vpc.id
  tags = {
    Name = "${var.prefix}-Production-IGW"
  }
}

resource "aws_route" "public_internet_igw_route" {
  route_table_id         = aws_route_table.public_route_table.id
  gateway_id             = aws_internet_gateway.production_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

variable "vpc_cidr" {
  type = string
}
