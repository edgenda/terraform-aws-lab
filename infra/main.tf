resource "random_pet" "pet" {}

module "s3_bucket" {
  source = "./s3_bucket"

  bucket_name = "s3-aws-tf-lab-${random_pet.pet.id}"
}

module "static_website" {
  source = "./static_website"

  bucket_id = module.s3_bucket.bucket_id
}

resource "aws_s3_object" "index" {
  bucket       = module.s3_bucket.bucket_id
  key          = "index.html"
  source       = "../src/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = module.s3_bucket.bucket_id
  key          = "error.html"
  source       = "../src/error.html"
  content_type = "text/html"
}
