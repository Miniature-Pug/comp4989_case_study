locals {
  base_directory = "../../src/fe/"
}

data "aws_s3_bucket" "cloudfront" {
  bucket = "bcit-cloudfront"
}

resource "aws_s3_object" "static_files" {
  for_each     = fileset("${local.base_directory}", "**/*")
  bucket       = data.aws_s3_bucket.cloudfront.id
  key          = "${var.s3_bucket_prefix}${each.key}"
  source       = "${local.base_directory}${each.key}"
  content_type = lookup(var.content_types, split(".", each.key)[1], "application/octet-stream")
  etag         = filemd5("${local.base_directory}${each.key}")
}

resource "null_resource" "cache-invaldiation" {

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${data.aws_cloudfront_distribution.static.id} --paths '/*'"
  }

  depends_on = [aws_s3_object.static_files]
}
