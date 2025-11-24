#!/bin/bash
set -e

BUCKET_NAME=$1

if [ -z "$BUCKET_NAME" ]; then
    echo "Usage: $0 <bucket-name>"
    exit 1
fi

# Check if bucket exists
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME does not exist or is not accessible"
    exit 0
fi

echo "Emptying bucket: $BUCKET_NAME"

# Delete all object versions
aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json --query 'Versions[].{Key:Key,VersionId:VersionId}' | \
jq -r '.[] | "\(.Key)\t\(.VersionId)"' | \
while IFS=$'\t' read -r key versionId; do
    if [ -n "$key" ]; then
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$versionId" 2>/dev/null || true
    fi
done

# Delete all delete markers
aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' | \
jq -r '.[] | "\(.Key)\t\(.VersionId)"' | \
while IFS=$'\t' read -r key versionId; do
    if [ -n "$key" ]; then
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$versionId" 2>/dev/null || true
    fi
done

# Delete remaining objects (non-versioned)
aws s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null || true

echo "Bucket $BUCKET_NAME emptied successfully"
