variable "db_password" {
 description = "Database administrator password"
 type = string
 sensitive = true
}

variable "aws_region" {
    description = "AWS account region"
    type        = string
    default     = "us-east-2"
}