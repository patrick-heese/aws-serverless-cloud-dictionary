# --------------------------
# DynamoDB Table
# --------------------------
resource "aws_dynamodb_table" "cloud_dictionary" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "term"

  attribute {
    name = "term"
    type = "S"
  }
}

# --------------------------
# IAM Role + Policies for Lambda
# --------------------------
resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamodb_readonly" {
  name        = "${var.lambda_role_name}-DynamoDBReadOnly"
  description = "Read-only access to DynamoDB table ${var.table_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan"]
        Resource = aws_dynamodb_table.cloud_dictionary.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_readonly" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_readonly.arn
}

# --------------------------
# Lambda Function
# --------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.lambda_source_file
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "fetch_term" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "dictionary_lambda.lambda_handler"
  runtime       = "python3.12"
  architectures = ["x86_64"]
  filename      = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
}

# --------------------------
# API Gateway
# --------------------------
resource "aws_api_gateway_rest_api" "cloud_dictionary_api" {
  name        = var.api_gateway_name
  description = "API for fetching cloud term definitions"
}

resource "aws_api_gateway_resource" "get_definition" {
  rest_api_id = aws_api_gateway_rest_api.cloud_dictionary_api.id
  parent_id   = aws_api_gateway_rest_api.cloud_dictionary_api.root_resource_id
  path_part   = "get-definition"
}

resource "aws_api_gateway_method" "get_definition_get" {
  rest_api_id   = aws_api_gateway_rest_api.cloud_dictionary_api.id
  resource_id   = aws_api_gateway_resource.get_definition.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cloud_dictionary_api.id
  resource_id             = aws_api_gateway_resource.get_definition.id
  http_method             = aws_api_gateway_method.get_definition_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.fetch_term.invoke_arn
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fetch_term.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cloud_dictionary_api.execution_arn}/*/*"
}

# --------------------------
# API Gateway Stage
# --------------------------
resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.cloud_dictionary_api.id
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.cloud_dictionary_api.id
  stage_name    = "dev"
}

# --------------------------
# Seed DynamoDB Table
# --------------------------
resource "null_resource" "seed_records" {
  for_each   = toset(var.records_files)
  depends_on = [aws_dynamodb_table.cloud_dictionary]

  provisioner "local-exec" {
    command = "aws dynamodb batch-write-item --region ${var.region} --request-items file://${path.module}/${each.value}"
  }
}
