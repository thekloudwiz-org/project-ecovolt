#!/bin/bash
# Build Lambda Deployment Package
# Creates a deployment package with all dependencies

set -e

echo "========================================="
echo "Building Lambda Deployment Package"
echo "========================================="
echo ""

# Configuration
BACKEND_DIR="application/backend"
BUILD_DIR="build/lambda"
OUTPUT_ZIP="lambda-deployment.zip"

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR"
rm -f "$OUTPUT_ZIP"
mkdir -p "$BUILD_DIR"

# Copy application code
echo "Copying application code..."
cp -r "$BACKEND_DIR"/* "$BUILD_DIR/"

# Remove unnecessary files
echo "Removing unnecessary files..."
rm -rf "$BUILD_DIR/tests"
rm -rf "$BUILD_DIR/venv"
rm -rf "$BUILD_DIR/__pycache__"
rm -rf "$BUILD_DIR"/*/__pycache__
rm -f "$BUILD_DIR"/*.md
rm -f "$BUILD_DIR"/*.sh
rm -f "$BUILD_DIR"/pytest.ini

# Install dependencies
echo "Installing Python dependencies..."
pip3 install -r "$BACKEND_DIR/requirements.txt" -t "$BUILD_DIR" --quiet

# Create ZIP package
echo "Creating deployment package..."
cd "$BUILD_DIR"
zip -r "../../$OUTPUT_ZIP" . -q
cd ../..

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
echo "  aws lambda update-function-code \\"
echo "    --function-name ecovolt-dev-api-handler \\"
echo "    --zip-file fileb://$OUTPUT_ZIP"
echo ""
