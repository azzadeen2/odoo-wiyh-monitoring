#!/bin/bash
# Build Odoo Docker Image Script
# Usage: ./build-odoo-image.sh [image-tag]
#v1.0.0

set -e

IMAGE_TAG="${1:-odoo17-ssys:latest}"

echo "========================================="
echo "Building Odoo Docker Image"
echo "========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running or not accessible"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "./odoo/Dockerfile" ]; then
    echo "Error: Dockerfile not found at ./odoo/Dockerfile"
    exit 1
fi

echo "Image Tag: $IMAGE_TAG"
echo "Build Context: ./odoo"
echo ""

# Build the image
echo "Building Docker image..."
docker build -t "$IMAGE_TAG" -f ./odoo/Dockerfile ./odoo

if [ $? -ne 0 ]; then
    echo "Error: Docker build failed"
    exit 1
fi

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo ""
echo "Image built: $IMAGE_TAG"
echo ""

# Ask if user wants to update .env file
read -p "Do you want to update .env file with ODOO_IMAGE=$IMAGE_TAG? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ENV_FILE=".env"
    if [ -f "$ENV_FILE" ]; then
        # Check if ODOO_IMAGE already exists
        if grep -q "^ODOO_IMAGE=" "$ENV_FILE"; then
            # Update existing line
            sed -i "s|^ODOO_IMAGE=.*|ODOO_IMAGE=$IMAGE_TAG|" "$ENV_FILE"
        else
            # Append new line
            echo "ODOO_IMAGE=$IMAGE_TAG" >> "$ENV_FILE"
        fi
        echo ".env file updated with ODOO_IMAGE=$IMAGE_TAG"
    else
        echo "Creating .env file..."
        echo "ODOO_IMAGE=$IMAGE_TAG" > "$ENV_FILE"
        echo ".env file created with ODOO_IMAGE=$IMAGE_TAG"
    fi
else
    echo ""
    echo "To use this image, set in .env file:"
    echo "ODOO_IMAGE=$IMAGE_TAG"
    echo ""
    echo "Or export as environment variable:"
    echo "export ODOO_IMAGE=\"$IMAGE_TAG\""
fi

echo ""
echo "Next steps:"
echo "1. Restart services: docker-compose up -d --force-recreate odoo17-ssys"
echo "2. Or restart all: docker-compose up -d"

