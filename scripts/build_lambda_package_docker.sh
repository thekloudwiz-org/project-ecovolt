#!/bin/bash
# Build Lambda Package using Docker
# Ensures Linux-compatible binaries

set -e

echo "========================================="
echo "Building Lambda Package with Docker"
echo "========================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Configuration
BACKEND_DIR="application/backend"
OUTPUT_ZIP="lambda-deployment.zip"

# Clean previous build
echo "Cleaning previous build..."
rm -f "$OUTPUT_ZIP"

# Build package using Lambda Python runtime container
echo "Building package in Docker container..."
docker run --rm \
  -v "$(pwd)/$BACKEND_DIR":/var/task \
  -v "$(pwd)":/output \
  public.ecr.aws/lambda/python:3.11 \
  bash -c "
    echo 'Installing dependencies...' && \
    pip install -r /var/task/requirements.txt -t /tmp/package --no-cache-dir --quiet && \
    echo 'Copying application code...' && \
    cp -r /var/task/* /tmp/package/ && \
    echo 'Removing unnecessary files...' && \
    cd /tmp/package && \
    rm -rf tests venv __pycache__ */__pycache__ *.md *.sh pytest.ini && \
    echo 'Creating ZIP package...' && \
    zip -r /output/$OUTPUT_ZIP . -q && \
    echo 'Package created successfully!'
  "

# Get package size
SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)
echo ""
echo "========================================="
echo "Package built successfully!"
echo "========================================="
echo "Location: $OUTPUT_ZIP"
echo "Size: $SIZE"
echo ""
echo "To deploy:"
echo "  # API Handler"
echo "  aws lambda update-function-code \\"
echo "    --function-name ecovolt-dev-api-handler \\"
echo "    --zip-file fileb://$OUTPUT_ZIP"
echo ""
echo "  # IoT Processor"
echo "  aws lambda update-function-code \\"
echo "    --function-name ecovolt-dev-iot-processor \\"
echo "    --zip-file fileb://$OUTPUT_ZIP"
echo ""
