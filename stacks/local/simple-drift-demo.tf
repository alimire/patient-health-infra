# Simple State Drift Demo (avoiding S3 performance issues)
# Focus on DynamoDB which works reliably in LocalStack

# Simple DynamoDB table for state drift practice
resource "aws_dynamodb_table" "drift_demo" {
  name           = "state-drift-demo-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "State Drift Demo"
    Environment = "local"
    ManagedBy   = "terraform"
    ManualTag   = "AddedByDeveloper"  # Accept the manual change
  }
}