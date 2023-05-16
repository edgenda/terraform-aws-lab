resource "aws_s3_bucket_website_configuration" "web" {
  bucket = var.bucket_id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_get" {
  bucket = var.bucket_id

  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_s3_bucket" "web" {
  bucket = var.bucket_id
}

data "aws_iam_policy_document" "public_get" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${data.aws_s3_bucket.web.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "public_get" {
  depends_on = [aws_s3_bucket_public_access_block.public_get]

  bucket = var.bucket_id
  policy = data.aws_iam_policy_document.public_get.json
}
