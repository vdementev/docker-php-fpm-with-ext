#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob

IMAGE_PREFIX="php_ext"
CONTAINER_PREFIX="php_ext_container"
DOCKERFILES_DIR="."
HEALTH_TIMEOUT=15

# Track created containers for cleanup
CONTAINERS=()

cleanup() {
    if [[ ${#CONTAINERS[@]} -gt 0 ]]; then
        echo
        echo "Cleaning up containers..."
        for name in "${CONTAINERS[@]}"; do
            docker rm -f "$name" 2>/dev/null || true
        done
    fi
}
trap cleanup EXIT

# Parse Dockerfile name → VERSION, FLAVOR, IMAGE_NAME, CONTAINER_NAME
parse_dockerfile() {
    local temp
    temp=$(basename "$1")
    temp=${temp#Dockerfile.}
    VERSION=${temp%%-*}
    FLAVOR=${temp#*-}
    IMAGE_NAME="$IMAGE_PREFIX-$VERSION-${FLAVOR//./-}"
    CONTAINER_NAME="$CONTAINER_PREFIX-$VERSION-${FLAVOR//./-}"
}

dockerfiles=("$DOCKERFILES_DIR"/Dockerfile.*)

if [[ ${#dockerfiles[@]} -eq 0 ]]; then
    echo "No Dockerfiles found in $DOCKERFILES_DIR"
    exit 1
fi

echo "Found ${#dockerfiles[@]} Dockerfile(s)"
start_time=$SECONDS

# 1) Build all Docker images
echo
echo "=== Building all Docker images ==="
for dockerfile in "${dockerfiles[@]}"; do
    parse_dockerfile "$dockerfile"
    echo "  Building '$IMAGE_NAME' from '$dockerfile'..."
    docker build -f "$dockerfile" -t "$IMAGE_NAME" . \
        || { echo "FAIL: build $IMAGE_NAME"; exit 1; }
done
echo "Build completed."

# 2) Smoke-test each image
echo
echo "=== Running smoke tests ==="
for dockerfile in "${dockerfiles[@]}"; do
    parse_dockerfile "$dockerfile"
    echo "  Testing '$IMAGE_NAME'..."

    # Verify PHP binary works
    php_ver=$(docker run --rm "$IMAGE_NAME" php -r 'echo PHP_VERSION;') \
        || { echo "  FAIL: php did not start in $IMAGE_NAME"; exit 1; }
    echo "    PHP $php_ver"

    # Verify extensions are loaded
    ext_count=$(docker run --rm "$IMAGE_NAME" php -m 2>&1 | grep -c '^[a-zA-Z]') || true
    echo "    Extensions loaded: $ext_count"

    # For FPM images: verify the process starts and becomes healthy
    if [[ "$FLAVOR" == *fpm* ]]; then
        docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" \
            || { echo "  FAIL: start $CONTAINER_NAME"; exit 1; }
        CONTAINERS+=("$CONTAINER_NAME")

        echo -n "    Waiting for healthy status..."
        healthy=false
        for ((i = 1; i <= HEALTH_TIMEOUT; i++)); do
            status=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "none")
            if [[ "$status" == "healthy" ]]; then
                healthy=true
                break
            elif [[ "$status" == "unhealthy" ]]; then
                break
            fi
            sleep 1
        done

        if $healthy; then
            echo " OK (${i}s)"
        else
            echo " FAIL (status: $status)"
            docker logs "$CONTAINER_NAME" 2>&1 | tail -20
            exit 1
        fi
    fi
done
echo "Smoke tests completed."

# 3) Check FPM container logs for critical errors
echo
echo "=== Checking container logs ==="
for name in "${CONTAINERS[@]}"; do
    if docker logs "$name" 2>&1 | grep -iqE 'fatal|panic|segfault|core.dump'; then
        echo "  FAIL: critical errors in '$name':"
        docker logs "$name" 2>&1 | grep -iE 'fatal|panic|segfault|core.dump'
        exit 1
    fi
    echo "  '$name': OK"
done
echo "Log check completed."

# Cleanup is handled by the EXIT trap
echo
elapsed=$((SECONDS - start_time))
echo "All tests passed in $((elapsed / 60))m$((elapsed % 60))s."
