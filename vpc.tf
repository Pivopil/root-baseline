data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zone_names = data.aws_availability_zones.available.names
  az_number               = length(local.availability_zone_names)
  private_subnets_cidrs   = [for intex in range(local.az_number) : cidrsubnet(var.vpc_cidr, 4, intex)]
  public_subnets_cidrs    = [for intex in range(local.az_number) : cidrsubnet(var.vpc_cidr, 4, intex + local.az_number)]
}

variable "vpc_cidr" {
  type = string
}

resource "aws_vpc" "production_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prefix}-Production-VPC"
  }
}

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
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_elastic_ip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "${var.prefix}-Production-NAT-GW"
  }

  depends_on = [aws_eip.nat_gw_elastic_ip]
}

resource "aws_route" "nat_gw_route" {
  route_table_id         = aws_route_table.private_route_table.id
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  destination_cidr_block = "0.0.0.0/0"
}

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
