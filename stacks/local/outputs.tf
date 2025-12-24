# Local Environment Outputs

# output "s3_bucket_name" {
#   description = "Name of the S3 bucket"
#   value       = aws_s3_bucket.example.bucket
# }

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.example.name
}

output "environment" {
  description = "Environment name"
  value       = "local"
}