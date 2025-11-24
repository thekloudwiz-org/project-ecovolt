resource "null_resource" "empty_cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0

  triggers = {
    bucket_name = aws_s3_bucket.cloudtrail[0].id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "python3 ${path.root}/scripts/empty-s3-bucket.py ${self.triggers.bucket_name}"
  }

  depends_on = [aws_s3_bucket.cloudtrail]
}
