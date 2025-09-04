# AWS region
region = "us-east-1"

# DynamoDB Table
table_name = "CloudDictionary"

# Lambda
lambda_role_name      = "LambdaDynamoDBAccessRole"
lambda_function_name  = "FetchTermFromDynamoDB"
lambda_source_file    = "../src/dictionary_function/dictionary_lambda.py"

# API Gateway
api_gateway_name = "CloudDictionaryAPIGateway"

# DynamoDB seed files (relative to terraform module)
records_files = [
  "records/records-1.json",
  "records/records-2.json",
  "records/records-3.json",
  "records/records-4.json"
]
