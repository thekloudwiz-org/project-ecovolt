#!/bin/bash
# Script to consolidate EcoVolt documentation

echo "📚 Consolidating EcoVolt Documentation..."

# Create backup directory
mkdir -p docs/archive
timestamp=$(date +%Y%m%d_%H%M%S)
backup_dir="docs/archive/backup_$timestamp"
mkdir -p "$backup_dir"

# Backup existing docs
echo "📦 Backing up existing documentation..."
cp docs/*.md "$backup_dir/" 2>/dev/null || true

# List of files to keep
keep_files=(
    "ARCHITECTURE.md"
    "INFRASTRUCTURE.md"
    "BACKEND.md"
    "FRONTEND.md"
    "COST_ESTIMATION.md"
)

# Move files to archive that aren't in keep list
echo "🗂️  Archiving old documentation..."
for file in docs/*.md; do
    filename=$(basename "$file")
    if [[ ! " ${keep_files[@]} " =~ " ${filename} " ]]; then
        echo "  Archiving: $filename"
        mv "$file" "$backup_dir/"
    fi
done

# Clean up non-markdown files in docs
echo "🧹 Cleaning up non-documentation files..."
rm -f docs/*.tf 2>/dev/null || true

echo "✅ Documentation consolidation complete!"
echo ""
echo "📋 Current documentation structure:"
echo "  - README.md (main project overview)"
echo "  - docs/ARCHITECTURE.md"
echo "  - docs/INFRASTRUCTURE.md"
echo "  - docs/BACKEND.md"
echo "  - docs/FRONTEND.md"
echo "  - docs/COST_ESTIMATION.md"
echo "  - docs/architecture.jpeg (to be added)"
echo ""
echo "📦 Backup location: $backup_dir"
