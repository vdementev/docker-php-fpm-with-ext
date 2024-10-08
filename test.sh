#!/bin/bash

# Set variables
IMAGE_PREFIX="php_ext"  # Prefix for your image names
CONTAINER_PREFIX="php_ext_container"  # Prefix for your container names
DOCKERFILES_DIR="."  # Directory where your Dockerfiles are located

# Step 1: Build all Docker images
echo "Building all Docker images..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile-*; do
    version=$(echo "$dockerfile" | sed -e 's/^.*-\([^-]*\)-fpm$/\1/')  # Extract the PHP version from the Dockerfile name
    image_name="$IMAGE_PREFIX:$version"
    echo "Building $image_name from $dockerfile..."

    docker build -f "$dockerfile" -t "$image_name" . || { echo "Failed to build $image_name"; exit 1; }
done

echo "Build completed successfully."

# Step 2: Run all containers
echo "Running all containers..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile-*; do
    version=$(echo "$dockerfile" | sed -e 's/^.*-\([^-]*\)-fpm$/\1/')  # Extract the PHP version from the Dockerfile name
    image_name="$IMAGE_PREFIX:$version"
    container_name="$CONTAINER_PREFIX-$version"

    echo "Running container $container_name from image $image_name..."

    docker run -d --name "$container_name" "$image_name" || { echo "Failed to run container $container_name"; exit 1; }
done

echo "All containers are running."

# Step 3: Check for errors in running containers
echo "Checking for errors in containers..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile-*; do
    version=$(echo "$dockerfile" | sed -e 's/^.*-\([^-]*\)-fpm$/\1/')  # Extract the PHP version from the Dockerfile name
    container_name="$CONTAINER_PREFIX-$version"

    echo "Checking logs for container $container_name..."
    docker logs "$container_name" || { echo "Error in container $container_name"; exit 1; }
done

echo "No errors found in container logs."

# Step 4: Stop all running containers
echo "Stopping all containers..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile-*; do
    version=$(echo "$dockerfile" | sed -e 's/^.*-\([^-]*\)-fpm$/\1/')  # Extract the PHP version from the Dockerfile name
    container_name="$CONTAINER_PREFIX-$version"

    echo "Stopping container $container_name..."
    docker stop "$container_name" || { echo "Failed to stop container $container_name"; exit 1; }
    docker rm "$container_name" || { echo "Failed to remove container $container_name"; exit 1; }
done

echo "All containers stopped and removed."
