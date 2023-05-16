resource "random_pet" "pet" {}

module "s3_bucket" {
  source = "./s3_bucket"

  bucket_name = "s3-aws-tf-lab-${random_pet.pet.id}"
}

module "static_website" {
  source = "./static_website"

  bucket_id = module.s3_bucket.bucket_id
}

resource "aws_s3_object" "files" {
  for_each = toset(["index.html", "error.html"])

  bucket       = module.s3_bucket.bucket_id
  key          = each.key
  source       = "../src/${each.key}"
  content_type = "text/html"
}
