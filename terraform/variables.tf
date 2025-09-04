# --------------------------
# AWS Region
# --------------------------
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# --------------------------
# DynamoDB Table
# --------------------------
variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

# --------------------------
# Lambda Function
# --------------------------
variable "lambda_role_name" {
  description = "IAM Role name for Lambda"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_source_file" {
  description = "Path to the Lambda source file (Python)"
  type        = string
}

# --------------------------
# API Gateway
# --------------------------
variable "api_gateway_name" {
  description = "API Gateway name"
  type        = string
}

# --------------------------
# DynamoDB seed files
# --------------------------
variable "records_files" {
  description = "List of DynamoDB JSON seed files relative to Terraform module"
  type        = list(string)
}
