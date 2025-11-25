#!/bin/bash
# Package Lambda function for secret rotation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Packaging Lambda function..."

# Create a temporary directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Copy the Lambda function
cp rotate_secret.py "$TMP_DIR/"

# Install psycopg2-binary (PostgreSQL driver)
pip install psycopg2-binary -t "$TMP_DIR/" --quiet

# Create the zip file
cd "$TMP_DIR"
zip -r "$SCRIPT_DIR/rotate_secret.zip" . > /dev/null

echo "✓ Lambda package created: rotate_secret.zip"
