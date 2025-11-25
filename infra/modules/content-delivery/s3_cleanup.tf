resource "null_resource" "empty_static_assets_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.static_assets.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws s3 rm s3://${self.triggers.bucket_name} --recursive || true
      aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | jq -r '.[] | "--key \"\(.Key)\" --version-id \(.VersionId)"' | xargs -I {} aws s3api delete-object --bucket ${self.triggers.bucket_name} {} || true
      aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json | jq -r '.[] | "--key \"\(.Key)\" --version-id \(.VersionId)"' | xargs -I {} aws s3api delete-object --bucket ${self.triggers.bucket_name} {} || true
    EOT
  }

  depends_on = [aws_s3_bucket.static_assets]
}
