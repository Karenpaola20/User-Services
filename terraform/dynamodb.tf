resource "aws_dynamodb_table" "user_table" {
  
  name = "user-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "uuid"

  attribute {
    name = "uuid"
    type = "S"
  }
}