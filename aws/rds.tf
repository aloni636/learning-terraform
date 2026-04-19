resource "aws_db_subnet_group" "rds" {
  name = "rds_subnet_group"
  subnet_ids = values(aws_subnet.rds)[*].id
}

# TODO: Explore KMS as top level of the encryption chain (1$ per month)
# resource "aws_secretsmanager_secret" "name" { }

# TODO: Enable cloudwatch with enhanced monitoring (IAM role and RDS config)
# resource "aws_iam_role" "rds_enhanced_monitoring" {
#   assume_role_policy = 
# }
# enabled_cloudwatch_logs_exports = ["postgresql"]
# resource "aws_cloudwatch_log_group" "rds" { }

# NOTE: RDS is a managed database service, meaning we have a restricted access
# to PostgreSQL features. For example: limited set of extensions,
# no access to the filesystem or shell, limited access to raw logs, etc.
resource "aws_db_instance" "db" {
  db_name = "${var.project_name}-db"
  # Engine
  engine                     = "postgres"
  engine_version             = "18.3"
  auto_minor_version_upgrade = true

  # Storage
  allocated_storage   = 32
  skip_final_snapshot = true
  deletion_protection = false
  delete_automated_backups = true

  # TODO: Add automated backups and snapshots config

  # Compute
  instance_class = var.rds_instance_type

  # Security
  username                    = "rds_user"
  db_subnet_group_name        = aws_db_subnet_group.rds.name
  vpc_security_group_ids      = [aws_security_group.inbound_rds.id]
  manage_master_user_password = true
  publicly_accessible         = false
  # NOTE: A lambda function is required to auto rotate the password
  # password_wo = 
  # password_wo_version = 

  # High availability / Fault tolerance
  multi_az = false # this is not production

  # Monitoring
  # monitoring_interval = 60
}
