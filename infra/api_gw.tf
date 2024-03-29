resource "aws_apigatewayv2_api" "knightpath_gw" {
  name          = "kp_api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.knightpath_lambda.invoke_arn
}

resource "aws_apigatewayv2_api" "knightpath_result_gw" {
  name          = "kp_result_api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.knightpath_result_lambda.invoke_arn
}

resource "aws_apigatewayv2_api" "knightpath_process_gw" {
  name          = "kp_processing_api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.process_request_lambda.invoke_arn
}

resource "aws_lambda_permission" "knightpath_perm" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.knightpath_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "knightpath_result_perm" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.knightpath_result_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "knightpath_process_perm" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_request_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_apigatewayv2_integration" "knightpath_integration" {
  api_id               = aws_apigatewayv2_api.knightpath_gw.id
  integration_type     = "AWS_PROXY"
  integration_uri      = aws_lambda_function.knightpath_lambda.invoke_arn
  integration_method   = "POST"
}

resource "aws_apigatewayv2_integration" "knightpath_result_integration" {
  api_id               = aws_apigatewayv2_api.knightpath_result_gw.id
  integration_type     = "AWS_PROXY"
  integration_uri      = aws_lambda_function.knightpath_result_lambda.invoke_arn
  integration_method   = "POST"
}

resource "aws_apigatewayv2_integration" "knightpath_process_integration" {
  api_id               = aws_apigatewayv2_api.knightpath_process_gw.id
  integration_type     = "AWS_PROXY"
  integration_uri      = aws_lambda_function.process_request_lambda.invoke_arn
  integration_method   = "POST"
}

resource "aws_apigatewayv2_route" "knightpath_route" {
  api_id    = aws_apigatewayv2_api.knightpath_gw.id
  route_key = "POST /knightpath"
  target    = "integrations/${aws_apigatewayv2_integration.knightpath_integration.id}"
}

resource "aws_apigatewayv2_route" "knightpath_result_route" {
  api_id    = aws_apigatewayv2_api.knightpath_result_gw.id
  route_key = "POST /knightpath_result"
  target    = "integrations/${aws_apigatewayv2_integration.knightpath_result_integration.id}"
}

resource "aws_apigatewayv2_route" "knightpath_process_route" {
  api_id    = aws_apigatewayv2_api.knightpath_process_gw.id
  route_key = "POST /knightpath_result"
  target    = "integrations/${aws_apigatewayv2_integration.knightpath_process_integration.id}"
}

resource "aws_apigatewayv2_stage" "knightpath_gw_stage" {
  api_id      = aws_apigatewayv2_api.knightpath_gw.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_apigatewayv2_stage" "knightpath_result_gw_stage" {
  api_id      = aws_apigatewayv2_api.knightpath_result_gw.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_apigatewayv2_stage" "knightpath_process_gw_stage" {
  api_id      = aws_apigatewayv2_api.knightpath_process_gw.id
  name        = "prod"
  auto_deploy = true
}