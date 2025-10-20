#!/bin/bash

# Build and Push Appwrite Image to Coolify's Registry
# This script builds a cross-platform image for AMD64 architecture

set -e

# Configuration - Update these with your Coolify instance details
COOLIFY_REGISTRY="docker.apperside.com"
IMAGE_NAME="appwrite-custom"
TAG="latest"
FULL_IMAGE_NAME="${COOLIFY_REGISTRY}/${IMAGE_NAME}:${TAG}"

# Registry credentials
REGISTRY_USER="apperside"
REGISTRY_PASSWORD="SecurePass2025"

echo "🔐 Logging in to Coolify registry..."
echo "${REGISTRY_PASSWORD}" | docker login ${COOLIFY_REGISTRY} -u ${REGISTRY_USER} --password-stdin

if [ $? -ne 0 ]; then
  echo "❌ Login failed! Check your credentials."
  exit 1
fi

echo "✅ Login successful"
echo ""

echo "🏗️  Building Appwrite image for AMD64/x86_64 architecture..."
echo "⚠️  Building for linux/amd64 platform (server architecture)"
echo "📦 This will build AND push in one step..."

docker buildx build --platform linux/amd64 \
  -t ${FULL_IMAGE_NAME} \
  --build-arg DEBUG="false" \
  --build-arg TESTING="false" \
  --build-arg VERSION="1.8.0" \
  --push \
  .

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Build and push complete! Image available at: ${FULL_IMAGE_NAME}"
  echo ""
  echo "🔧 Next steps:"
  echo "1. The image is now available in your registry"
  echo "2. Redeploy in Coolify to pull the new AMD64 image"
  echo "3. All containers should start successfully now!"
else
  echo "❌ Docker buildx failed!"
  echo "💡 Make sure Docker buildx is set up correctly"
  exit 1
fi
