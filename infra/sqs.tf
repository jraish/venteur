resource "aws_sqs_queue" "process_request_queue" {
  name = "process_request_queue"
  visibility_timeout_seconds = 120
}

resource "aws_lambda_permission" "sqs_invoke_permission" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  source_arn = aws_sqs_queue.process_request_queue.arn
  principal     = "sqs.amazonaws.com"
  function_name    = aws_lambda_function.process_request_lambda.function_name
}


resource "aws_lambda_event_source_mapping" "process_request_queue_event_mapping" {
  event_source_arn = aws_sqs_queue.process_request_queue.arn
  batch_size       = 1
  enabled          = true
  function_name    = aws_lambda_function.process_request_lambda.arn
}

resource "aws_vpc_endpoint" "sqs_endpoint" {
  vpc_id            = aws_vpc.knights_path_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.sqs"
  security_group_ids    = [
      aws_security_group.lambda_sg.id, 
      aws_security_group.db_sg.id
      ]
  subnet_ids = [
      aws_subnet.lambda_subnet.id,
      aws_subnet.lambda_subnet_2.id 
  ]
  private_dns_enabled = true
  vpc_endpoint_type = "Interface"
}