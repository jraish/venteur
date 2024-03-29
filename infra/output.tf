output "knightpath_endpoint" {
  value = aws_apigatewayv2_api.knightpath_gw.api_endpoint
}

output "knightpath_result_endpoint" {
  value = aws_apigatewayv2_api.knightpath_result_gw.api_endpoint
}