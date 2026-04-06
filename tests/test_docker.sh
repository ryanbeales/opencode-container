#!/bin/bash
set -e

IMAGE_NAME=${1:-"opencode-container:test"}

echo "Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" .

echo "Testing tools in the image..."
docker run --rm "$IMAGE_NAME" node -v
docker run --rm "$IMAGE_NAME" npm -v
docker run --rm "$IMAGE_NAME" gh --version
docker run --rm "$IMAGE_NAME" kubectl version --client
docker run --rm "$IMAGE_NAME" jq --version
docker run --rm "$IMAGE_NAME" yq --version
docker run --rm "$IMAGE_NAME" dyff version
docker run --rm "$IMAGE_NAME" opencode --version
docker run --rm "$IMAGE_NAME" openchamber --version

echo "All tests passed for image: $IMAGE_NAME"