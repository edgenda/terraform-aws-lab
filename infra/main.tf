resource "random_pet" "pet" {}

resource "aws_s3_bucket" "web" {
  bucket = "s3-aws-tf-lab-${random_pet.pet.id}"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.web.id
  key          = "index.html"
  source       = "../src/index.html"
  content_type = "text/html"
}
