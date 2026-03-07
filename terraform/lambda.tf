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
    }
  }
}

resource "aws_lambda_permission" "apigw" {

  statement_id  = "AllowAPIGatewayInvoke"

  action        = "lambda:InvokeFunction"

  function_name = aws_lambda_function.register_user.function_name

  principal     = "apigateway.amazonaws.com"

}

resource "aws_lambda_function" "login_user" {
  function_name = "login-user"

  handler = "index.handler"
  runtime = "nodejs20.x"

  role = aws_iam_role.lambda_exec.arn

  filename = "${path.module}/lambdas/user-service/login-user-lambda/login.zip"

  source_code_hash = filebase64sha256("${path.module}/lambdas/user-service/login-user-lambda/login.zip")
}

resource "aws_lambda_permission" "apigw_login" {

  statement_id = "AllowAPIGatewayInvokeLogin"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.login_user.function_name

  principal = "apigateway.amazonaws.com"

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
        Resource = "arn:aws:sqs:us-east-1:537236557851:create-request-card-sqs"
      }
    ]
  })
}