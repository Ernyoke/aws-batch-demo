resource "aws_vpc" "vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    "Name" = "${var.module_name}-vpc"
  }

  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.1.2.0/24"

  tags = {
    "Name" = "${var.module_name}-private-subnet"
  }
}

data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = data.aws_vpc_endpoint_service.s3.service_name
  route_table_ids = [aws_route_table.private_rt.id]
  policy          = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
}

data "aws_vpc_endpoint_service" "dynamodb" {
  service      = "dynamodb"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = data.aws_vpc_endpoint_service.dynamodb.service_name
  route_table_ids = [aws_route_table.private_rt.id]
  policy          = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
}

resource "aws_vpc_endpoint" "endpoints" {
  for_each = {
    "ecr" : "com.amazonaws.${var.aws_region}.ecr.dkr",
    "ecr-api" : "com.amazonaws.${var.aws_region}.ecr.api"
    "logs" : "com.amazonaws.${var.aws_region}.logs"
  }

  service_name        = each.value
  vpc_id              = aws_vpc.vpc.id
  subnet_ids          = [aws_subnet.private_subnet.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.tls.id]
  vpc_endpoint_type   = "Interface"
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.module_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "tls" {
  name        = "${var.module_name}-endpoint-sg"
  description = "Allow TLS for endpoints."
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
