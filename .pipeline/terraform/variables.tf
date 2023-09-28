variable "content_types" {
  description = "Mapping of file extensions to content types (MIME types)"
  type        = map(string)
  default = {
    "html" = "text/html"
    "js"   = "application/javascript"
    "css"  = "text/css"
  }
}
variable "s3_bucket_prefix" {}