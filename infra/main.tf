resource "random_pet" "pet" {}

module "s3_bucket" {
  source = "./s3_bucket"

  bucket_name = "s3-aws-tf-lab-${random_pet.pet.id}"
}

resource "aws_s3_object" "index" {
  bucket       = module.s3_bucket.bucket_id
  key          = "index.html"
  source       = "../src/index.html"
  content_type = "text/html"
}