# Database Module - RDS Primary + Cross-Region Replica

variable "project_name" {
  type = string
}

variable "db_name" {
  type    = string
  default = "drdb"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "primary_vpc_id" {
  type = string
}

variable "primary_private_subnets" {
  type = list(string)
}

variable "secondary_vpc_id" {
  type = string
}

variable "secondary_private_subnets" {
  type = list(string)
}

variable "primary_rds_sg_id" {
  type = string
}

variable "secondary_rds_sg_id" {
  type = string
}

variable "random_suffix" {
  type = string
}

# Subnet Groups
resource "aws_db_subnet_group" "primary" {
  name       = "${var.project_name}-primary-sng-${var.random_suffix}"
  subnet_ids = var.primary_private_subnets

  tags = {
    Name = "${var.project_name}-primary-sng"
  }
}

resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.project_name}-secondary-sng-${var.random_suffix}"
  subnet_ids = var.secondary_private_subnets

  tags = {
    Name = "${var.project_name}-secondary-sng"
  }
}

# RDS Primary
resource "aws_db_instance" "primary" {
  identifier           = "${var.project_name}-primary-${var.random_suffix}"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [var.primary_rds_sg_id]
  skip_final_snapshot  = true
  multi_az             = true
  backup_retention_period = 7
}

# RDS Replica in Secondary Region
resource "aws_db_instance" "secondary" {
  provider               = aws.secondary
  identifier             = "${var.project_name}-secondary-${var.random_suffix}"
  instance_class         = "db.t3.micro"
  replicate_source_db    = aws_db_instance.primary.arn
  db_subnet_group_name   = aws_db_subnet_group.secondary.name
  vpc_security_group_ids = [var.secondary_rds_sg_id]
  skip_final_snapshot    = true
  parameter_group_name   = "default.mysql8.0"
  
  # Replicas don't take backup retention settings from primary automatically in TF sometimes, 
  # but here it's managed by the replicate_source_db relationship.
}

output "primary_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "secondary_endpoint" {
  value = aws_db_instance.secondary.endpoint
}

output "primary_instance_id" {
  value = aws_db_instance.primary.id
}

output "secondary_instance_id" {
  value = aws_db_instance.secondary.id
}
