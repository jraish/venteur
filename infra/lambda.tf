resource "aws_lambda_function" "knightpath_lambda" {
  image_uri      = "${aws_ecr_repository.knightpath.repository_url}:latest"
  function_name  = "knightpath_lambda"
  role           = aws_iam_role.lambda_role.arn
  package_type   = "Image"
  timeout        = 60

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids     = [aws_subnet.lambda_subnet.id, aws_subnet.lambda_subnet_2.id]
  }

  environment {
    variables = {
      DB_USER = aws_db_instance.kp_pg_db.username
      DB_PASSWORD = aws_db_instance.kp_pg_db.password
      DB_HOST = aws_db_instance.kp_pg_db.endpoint
      DB_DATABASE = aws_db_instance.kp_pg_db.name
      SQS_NAME  = aws_sqs_queue.process_request_queue.name
    }
  }
}

resource "aws_lambda_function" "process_request_lambda" {
  image_uri      = "${aws_ecr_repository.process_request.repository_url}:latest"
  function_name  = "process_request_lambda"
  role           = aws_iam_role.lambda_role.arn
  package_type   = "Image"
  timeout        = 120

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids     = [aws_subnet.lambda_subnet.id, aws_subnet.lambda_subnet_2.id]
  }

  environment {
    variables = {
      DB_USER = aws_db_instance.kp_pg_db.username
      DB_PASSWORD = aws_db_instance.kp_pg_db.password
      DB_HOST = aws_db_instance.kp_pg_db.endpoint
      DB_DATABASE = aws_db_instance.kp_pg_db.name
    }
  }
}

resource "aws_lambda_function" "provision_db_lambda" {
  image_uri      = "${aws_ecr_repository.provision_db.repository_url}:latest"
  function_name  = "provision_db_lambda"
  role           = aws_iam_role.lambda_role.arn
  package_type   = "Image"
  timeout        = 45

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids     = [aws_subnet.lambda_subnet.id, aws_subnet.lambda_subnet_2.id]
  }

  environment {
    variables = {
      DB_USER = aws_db_instance.kp_pg_db.username
      DB_PASSWORD = aws_db_instance.kp_pg_db.password
      DB_HOST = aws_db_instance.kp_pg_db.endpoint
      DB_DATABASE = aws_db_instance.kp_pg_db.name
    }
  }
}

resource "aws_lambda_invocation" "provision_db" {
  function_name = aws_lambda_function.provision_db_lambda.function_name

  depends_on = [ aws_lambda_function.provision_db_lambda, aws_db_instance.kp_pg_db]

  input = jsonencode({
    test = "test"
  })
}

resource "aws_lambda_function" "knightpath_result_lambda" {
  image_uri      = "${aws_ecr_repository.knightpath_result.repository_url}:latest"
  function_name  = "knightpath_result_lambda"
  role           = aws_iam_role.lambda_role.arn
  package_type   = "Image"
  timeout        = 45

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids     = [aws_subnet.lambda_subnet.id, aws_subnet.lambda_subnet_2.id]
  }

  environment {
    variables = {
      DB_USER = aws_db_instance.kp_pg_db.username
      DB_PASSWORD = aws_db_instance.kp_pg_db.password
      DB_HOST = aws_db_instance.kp_pg_db.endpoint
      DB_DATABASE = aws_db_instance.kp_pg_db.name
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_db_policy" {
  name        = "lambda_db_policy"
  description = "IAM policy for Lambda functions to access the database"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect",
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource",
          "rds:DescribeDBLogFiles",
          "rds:DownloadDBLogFilePortion",
          "rds:ListTagsForResource"
        ]
        Resource = aws_db_instance.kp_pg_db.arn
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_deploy_policy" {
  name        = "lambda_deploy_policy"
  description = "IAM policy for Lambda functions to access the database"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:AttachNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda_sqs_policy"
  description = "IAM policy for Lambda functions to invoke other lambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.process_request_queue.arn
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_log_policy" {
  name        = "lambda_log_policy"
  description = "IAM policy for Lambda functions to write logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_db_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_db_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_deploy_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_deploy_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_log_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_log_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_ecr_repository" "process_request" {
  name = "process_request"
}

resource "aws_ecr_repository" "provision_db" {
  name = "provision_db"
}

resource "aws_ecr_repository" "knightpath" {
  name = "knightpath"
}

resource "aws_ecr_repository" "knightpath_result" {
  name = "knightpath_result"
}

resource "aws_cloudwatch_log_group" "lambda_knightpath_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.knightpath_lambda.function_name}"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "lambda_process_request_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.process_request_lambda.function_name}"
  retention_in_days = 3
}