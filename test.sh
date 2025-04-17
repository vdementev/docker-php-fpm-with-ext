#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob

IMAGE_PREFIX="php_ext"
CONTAINER_PREFIX="php_ext_container"
DOCKERFILES_DIR="."

# 1) Build all Docker images
echo "Building all Docker images..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile.*; do
    base=$(basename "$dockerfile")          # e.g. Dockerfile.7.4-cli.builder
    temp=${base#Dockerfile.}                # → 7.4-cli.builder
    version=${temp%%-*}                     # → 7.4
    flavor=${temp#*-}                       # → cli.builder or fpm
    image_name="$IMAGE_PREFIX-$version-$flavor"

    echo "  ▶ Building image '$image_name' from '$dockerfile'..."
    docker build -f "$dockerfile" -t "$image_name" . \
        || { echo "✖ Failed to build $image_name"; exit 1; }
done
echo "✅ Build completed."

# 2) Run all containers
echo
echo "Running all containers..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile.*; do
    temp=${dockerfile##*/}                  # strip path
    temp=${temp#Dockerfile.}                # strip prefix
    version=${temp%%-*}
    flavor=${temp#*-}
    image_name="$IMAGE_PREFIX-$version-$flavor"
    container_name="$CONTAINER_PREFIX-$version-$flavor"

    echo "  ▶ Starting container '$container_name'..."
    docker run -d --name "$container_name" "$image_name" \
        || { echo "✖ Failed to run $container_name"; exit 1; }
done
echo "✅ Containers are up."

# 3) Check logs for errors
echo
echo "Checking container logs for errors..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile.*; do
    temp=${dockerfile##*/}
    temp=${temp#Dockerfile.}
    version=${temp%%-*}
    flavor=${temp#*-}
    container_name="$CONTAINER_PREFIX-$version-$flavor"

    echo "  ▶ Logs for '$container_name':"
    docker logs "$container_name" \
        || { echo "✖ Error fetching logs for $container_name"; exit 1; }
done
echo "✅ No errors in logs."

# 4) Tear down
echo
echo "Stopping and removing all containers..."
for dockerfile in "$DOCKERFILES_DIR"/Dockerfile.*; do
    temp=${dockerfile##*/}
    temp=${temp#Dockerfile.}
    version=${temp%%-*}
    flavor=${temp#*-}
    container_name="$CONTAINER_PREFIX-$version-$flavor"

    echo "  ▶ Stopping & removing '$container_name'..."
    docker stop "$container_name" && docker rm "$container_name" \
        || { echo "✖ Failed to remove $container_name"; exit 1; }
done
echo "✅ All containers stopped and removed."
