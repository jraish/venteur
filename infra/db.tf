resource "aws_secretsmanager_secret" "db_password" {
  name = "db-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_db_instance" "kp_pg_db" {
  identifier           = "knights-path-pg-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "16.1"
  instance_class       = "db.t3.micro"
  name                 = "kp_pg_db"
  username             = "kp_user"
  password             = aws_secretsmanager_secret_version.db_password_version.secret_string
  parameter_group_name = "default.postgres16"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name

  vpc_security_group_ids = [aws_security_group.db_sg.id]
}