resource "null_resource" "empty_data_lake_bucket" {
  triggers = {
    bucket_name = aws_s3_bucket.data_lake.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws s3 rm s3://${self.triggers.bucket_name} --recursive || true
      aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | jq -r '.[] | "--key \"\(.Key)\" --version-id \(.VersionId)"' | xargs -I {} aws s3api delete-object --bucket ${self.triggers.bucket_name} {} || true
      aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json | jq -r '.[] | "--key \"\(.Key)\" --version-id \(.VersionId)"' | xargs -I {} aws s3api delete-object --bucket ${self.triggers.bucket_name} {} || true
    EOT
  }

  depends_on = [aws_s3_bucket.data_lake]
}

resource "null_resource" "empty_athena_results_bucket" {
  count = var.enable_athena ? 1 : 0

  triggers = {
    bucket_name = aws_s3_bucket.athena_results[0].id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws s3 rm s3://${self.triggers.bucket_name} --recursive || true
      aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | jq -r '.[] | "--key \"\(.Key)\" --version-id \(.VersionId)"' | xargs -I {} aws s3api delete-object --bucket ${self.triggers.bucket_name} {} || true
      aws s3api list-object-versions --bucket ${self.triggers.bucket_name} --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json | jq -r '.[] | "--key \"\(.Key)\" --version-id \(.VersionId)"' | xargs -I {} aws s3api delete-object --bucket ${self.triggers.bucket_name} {} || true
    EOT
  }

  depends_on = [aws_s3_bucket.athena_results]
}
