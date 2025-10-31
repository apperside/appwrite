#!/bin/bash
# Build custom Appwrite image from source
# This runs in Coolify's build step

set -e

echo "🏗️  Building Appwrite from source..."

# Build the image
docker build \
  --build-arg DEBUG=false \
  --build-arg TESTING=false \
  --build-arg VERSION=1.8.0-custom \
  -t appwrite-custom:latest \
  -t appwrite-custom:$(git rev-parse --short HEAD) \
  .

echo "✅ Build complete!"
echo "   Image: appwrite-custom:latest"
echo "   Commit: $(git rev-parse --short HEAD)"

