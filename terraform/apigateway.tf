resource "aws_api_gateway_rest_api" "pigbank_api" {
  name = "pigbank-api"
}

resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id
  parent_id = aws_api_gateway_rest_api.pigbank_api.root_resource_id
  path_part = "register"
}

resource "aws_api_gateway_method" "register_post" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_register" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.register_post.http_method

  integration_http_method   = "POST"
  type                      = "AWS_PROXY"
  uri                       = aws_lambda_function.register_user.invoke_arn
}

//Login
resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  parent_id = aws_api_gateway_rest_api.pigbank_api.root_resource_id

  path_part = "login"
}

resource "aws_api_gateway_method" "login_post" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  resource_id = aws_api_gateway_resource.login.id

  http_method = "POST"

  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_login" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  resource_id = aws_api_gateway_resource.login.id

  http_method = aws_api_gateway_method.login_post.http_method

  integration_http_method = "POST"

  type = "AWS_PROXY"

  uri = aws_lambda_function.login_user.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  depends_on = [
    aws_api_gateway_integration.lambda_register,
    aws_api_gateway_integration.lambda_login,
    aws_api_gateway_integration.get_profile_integration
  ]

}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.pigbank_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "dev"
}

//GET 

resource "aws_api_gateway_resource" "profile" {

  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  parent_id = aws_api_gateway_rest_api.pigbank_api.root_resource_id

  path_part = "profile"

}

resource "aws_api_gateway_resource" "profile_user" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  parent_id = aws_api_gateway_resource.profile.id

  path_part = "{user_id}"
}

resource "aws_api_gateway_method" "get_profile" {
  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  resource_id = aws_api_gateway_resource.profile_user.id

  http_method = "GET"

  authorization = "None"
}

resource "aws_api_gateway_integration" "get_profile_integration" {

  rest_api_id = aws_api_gateway_rest_api.pigbank_api.id

  resource_id = aws_api_gateway_resource.profile_user.id

  http_method = aws_api_gateway_method.get_profile.http_method

  integration_http_method = "POST"

  type = "AWS_PROXY"

  uri = aws_lambda_function.get_profile_user.invoke_arn

}