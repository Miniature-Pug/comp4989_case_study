data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "lambda" {
  s3_bucket        = "bcit-cloudfront"
  s3_key           = "${var.s3_bucket_prefix}lambda/lambda_function.zip"
  function_name    = "comp4989_case_study"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.aws_s3_object.lambda.etag
  runtime          = "python3.10"
  depends_on       = [aws_s3_object.lambda]
}
