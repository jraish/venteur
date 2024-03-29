resource "aws_vpc" "knights_path_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "lambda_subnet" {
  vpc_id            = aws_vpc.knights_path_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "lambda_subnet_2" {
  vpc_id            = aws_vpc.knights_path_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "example"
  subnet_ids = [aws_subnet.lambda_subnet.id, aws_subnet.lambda_subnet_2.id]
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Allow inbound traffic to lambda functions that will receive requests and return results"

  vpc_id = aws_vpc.knights_path_vpc.id

  lifecycle { create_before_destroy = true }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Restrict inbound traffic"

  vpc_id = aws_vpc.knights_path_vpc.id

  lifecycle { create_before_destroy = true }

  ingress {
    from_port   = 5432 
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_security_group_rule" "lambda_sg_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}