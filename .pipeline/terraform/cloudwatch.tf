resource "aws_cloudwatch_log_group" "api_gw_v2" {
  name              = "/aws/api_gw_v2/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 5
}