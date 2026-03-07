output "register_endpoint" {
  value = "https://${aws_api_gateway_rest_api.pigbank_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/register"
}

output "login_endpoint" {
  value = "https://${aws_api_gateway_rest_api.pigbank_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/login"
}