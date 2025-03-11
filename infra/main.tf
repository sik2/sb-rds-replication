terraform {
  // aws 라이브러리 불러옴
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# AWS 설정 시작
provider "aws" {
  region = var.region
}
# AWS 설정 끝

# VPC 설정 시작
resource "aws_vpc" "vpc_1" {
  cidr_block = "10.0.0.0/16"

  # 무조건 켜세요.
  enable_dns_support   = true
  # 무조건 켜세요.
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc-1"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-subnet-2"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-subnet-3"
  }
}

resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.prefix}-igw-1"
  }
}

resource "aws_route_table" "rt_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }

  tags = {
    Name = "${var.prefix}-rt-1"
  }
}

resource "aws_route_table_association" "association_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rt_1.id
}

resource "aws_route_table_association" "association_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.rt_1.id
}

resource "aws_route_table_association" "association_3" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = aws_route_table.rt_1.id
}

resource "aws_security_group" "sg_1" {
  name = "${var.prefix}-sg-1"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.prefix}-sg-1"
  }
}

# EC2 설정 시작

# EC2 설정 끝

# RDS 설정 시작
resource "aws_db_subnet_group" "db_subnet_group_1" {
  name       = "${var.prefix}-db-subnet-group-1"
  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]

  tags = {
    Name = "${var.prefix}-db-subnet-group-1"
  }
}

resource "aws_db_parameter_group" "mariadb_parameter_group_1" {
  name   = "${var.prefix}-mariadb-parameter-group-1"
  family = "mariadb10.6"

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_filesystem"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_connection"
    value = "utf8mb4_general_ci"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_general_ci"
  }

  tags = {
    Name = "${var.prefix}-mariadb-parameter-group"
  }
}

resource "aws_db_instance" "db_1" {
  identifier              = "${var.prefix}-db-1"
  allocated_storage       = 20
  max_allocated_storage   = 1000
  engine                  = "mariadb"
  engine_version          = "10.6.13"
  instance_class          = "db.t3.micro"
  publicly_accessible     = true
  username                = "admin"
  password                = "lldd123414"
  parameter_group_name    = aws_db_parameter_group.mariadb_parameter_group_1.name
  backup_retention_period = 1
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.sg_1.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group_1.name
  availability_zone       = "${var.region}a"

  tags = {
    Name = "${var.prefix}-db-1"
  }
}

# db-2 생성
resource "aws_db_instance" "db_2" {
  identifier             = "${var.prefix}-db-2"
  engine                 = "mariadb"
  engine_version         = "10.6.13"
  instance_class         = "db.t3.micro"
  publicly_accessible    = true
  parameter_group_name   = aws_db_parameter_group.mariadb_parameter_group_1.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.sg_1.id]
  availability_zone      = "${var.region}c"  # different zone for high availability

  # replication configuration
  replicate_source_db = aws_db_instance.db_1.identifier  # specify the master DB instance identifier here

  tags = {
    Name = "${var.prefix}-db-2"
  }
}
# RDS 설정 끝