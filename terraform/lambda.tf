resource "aws_lambda_function" "register_user" {
  function_name = "register-user-lambda"

  runtime = "nodejs20.x"
  handler = "index.handler"

  timeout = 10
  memory_size = 256

  filename = "${path.module}/lambdas/user-service/register-user-lambda/register-user.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/user-service/register-user-lambda/register-user.zip")

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      CARD_REQUEST_QUEUE = "https://sqs.us-east-1.amazonaws.com/537236557851/create-request-card-sqs"
      NOTIFICATION_QUEUE = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvokeRegister"

  action        = "lambda:InvokeFunction"

  function_name = aws_lambda_function.register_user.function_name

  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.pigbank_api.execution_arn}/*/*"
}

//Login
resource "aws_lambda_function" "login_user" {
  function_name = "login-user"

  runtime = "nodejs20.x"
  handler = "index.handler"

  timeout = 10
  memory_size = 256

  role = aws_iam_role.lambda_exec.arn

  filename = "${path.module}/lambdas/user-service/login-user-lambda/login.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/user-service/login-user-lambda/login.zip")

  environment {
    variables = {
      NOTIFICATION_QUEUE = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_lambda_permission" "apigw_login" {

  statement_id = "AllowAPIGatewayInvokeLogin"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.login_user.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.pigbank_api.execution_arn}/*/*"
}

resource "aws_iam_role_policy" "lambda_sqs_send" {
  name = "lambda-send-sqs"

  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = [
          "arn:aws:sqs:us-east-1:537236557851:create-request-card-sqs",
          "arn:aws:sqs:us-east-1:537236557851:notification-email-sqs"
        ]
      }
    ]
  })
}

//Get
resource "aws_lambda_function" "get_profile_user" {
  function_name = "get-profile-user-lambda"

  handler = "index.handler"
  runtime = "nodejs20.x"

  filename = "${path.module}/lambdas/user-service/get-profile-user-lambda/get-profile.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/user-service/get-profile-user-lambda/get-profile.zip")

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_permission" "api_get_profile" {
  statement_id = "AllowAPIGatewayInvoke"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.get_profile_user.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.pigbank_api.execution_arn}/*/*"
}

//Update
resource "aws_lambda_function" "update_user_lambda" {
  function_name     = "update-user-lambda"

  filename          = "${path.module}/lambdas/user-service/update-user-lambda/update-user-lambda.zip"
  source_code_hash  = filebase64sha256("${path.module}/lambdas/user-service/update-user-lambda/update-user-lambda.zip")

  handler           = "index.handler"
  runtime           = "nodejs20.x"

  role              = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.user_table.name
      NOTIFICATION_QUEUE = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_lambda_permission" "allow_apigw_update_user" {
  statement_id    = "AllowAPIGatewayInvokeUpdateUser"
  action          = "lambda:InvokeFunction"
  function_name   = aws_lambda_function.update_user_lambda.function_name
  principal       = "apigateway.amazonaws.com"

  source_arn      = "${aws_api_gateway_rest_api.pigbank_api.execution_arn}/*/*"
}