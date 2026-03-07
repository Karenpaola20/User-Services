resource "aws_lambda_function" "register_user" {
  function_name = "register-user-lambda"

  runtime = "nodejs20.x"
  handler = "index.handler"

  filename = "${path.module}/lambdas/user-service/register-user-lambda/register-user.zip"

  source_code_hash = filebase64sha256("${path.module}/lambdas/user-service/register-user-lambda/register-user.zip")

  role = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_permission" "apigw" {

  statement_id  = "AllowAPIGatewayInvoke"

  action        = "lambda:InvokeFunction"

  function_name = aws_lambda_function.register_user.function_name

  principal     = "apigateway.amazonaws.com"

}