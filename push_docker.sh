#!/usr/bin/env bash
# =============================================================================
# push_docker.sh — push the pairs_system image to Docker Hub (thanhnc19/pairs_system).
#
#   ./push_docker.sh                  # push :noetic and :latest
#   TAG=v1.0 ./push_docker.sh         # also push a version tag (and refresh :latest)
#
# Requires `docker login` with your Docker Hub account (thanhnc19). The script
# logs you in if you are not already authenticated to docker.io.
# =============================================================================
set -euo pipefail

HUB_NAMESPACE="${HUB_NAMESPACE:-thanhnc19}"        # <<< your Docker Hub account/org
IMAGE="${IMAGE:-${HUB_NAMESPACE}/pairs_system}"
TAG="${TAG:-noetic}"                                # canonical ROS-distro tag
DOCKERHUB_USER="${DOCKERHUB_USER:-thanhnc19}"

if ! docker image inspect "${IMAGE}:${TAG}" >/dev/null 2>&1; then
  echo "ERROR: '${IMAGE}:${TAG}' not found locally. Run ./build.sh first." >&2
  exit 1
fi

# Ensure we are logged in to Docker Hub (docker.io).
if ! docker system info 2>/dev/null | grep -q "Username:"; then
  echo ">> Not logged in to Docker Hub. Running 'docker login' as ${DOCKERHUB_USER}..."
  docker login -u "${DOCKERHUB_USER}"
fi

echo ">> Pushing ${IMAGE}:${TAG} ..."
docker push "${IMAGE}:${TAG}"

# Always keep :latest current alongside the distro tag.
if [[ "$TAG" != "latest" ]]; then
  docker tag "${IMAGE}:${TAG}" "${IMAGE}:latest"
  echo ">> Pushing ${IMAGE}:latest ..."
  docker push "${IMAGE}:latest"
fi

echo ">> Pushed. View at: https://hub.docker.com/r/${IMAGE}/tags"
