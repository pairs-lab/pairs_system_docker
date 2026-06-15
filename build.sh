#!/usr/bin/env bash
# Build the pairs_system Docker image.
#
#   ./build.sh                       # build against a LOCAL copy of pairs-apt/docs
#                                    # (works today, before the apt repo is pushed)
#   PAIRS_APT_SOURCE=live ./build.sh # build against the PUBLISHED signed repo
#                                    # (use once pairs-apt/docs has been pushed live)
#
# Set HUB_NAMESPACE to your Docker Hub account/org.
set -euo pipefail

HUB_NAMESPACE="${HUB_NAMESPACE:-thanhnc19}"     # <<< your Docker Hub account/org
IMAGE="${HUB_NAMESPACE}/pairs_system"
TAG="${TAG:-noetic}"
SOURCE="${PAIRS_APT_SOURCE:-local}"             # local | live
APT_DOCS="${APT_DOCS:-$HOME/vin_dron_ws/pairs-apt/docs}"

cd "$(dirname "$0")"

if [ "$SOURCE" = "live" ]; then
  echo ">> building against the published repo https://thanhnguyencanh.github.io/apt"
  docker build -t "${IMAGE}:${TAG}" -t "${IMAGE}:latest" .
else
  # serve the local pairs-apt/docs over a throwaway docker network so the build
  # can apt-install from it without depending on the GitHub Pages push
  [ -f "$APT_DOCS/dists/noetic/main/binary-amd64/Packages" ] || {
    echo "!! local apt index not found at $APT_DOCS — set APT_DOCS or run pairs-apt/tools/build.sh" >&2
    exit 1
  }
  # serve the docs on a host loopback port; build with --network host so the
  # BuildKit builder can reach it (BuildKit rejects custom docker networks)
  SRV=pairsapt_build_srv
  PORT="${APT_PORT:-8910}"
  echo ">> serving $APT_DOCS on 127.0.0.1:${PORT} for the build"
  docker rm -f "$SRV" >/dev/null 2>&1 || true
  docker run -d --name "$SRV" -p "127.0.0.1:${PORT}:8000" \
    -v "$APT_DOCS":/srv:ro -w /srv python:3-slim \
    python3 -m http.server 8000 >/dev/null
  cleanup() { docker rm -f "$SRV" >/dev/null 2>&1 || true; }
  trap cleanup EXIT
  sleep 2

  docker build --network host \
    --build-arg PAIRS_APT_BASE="http://127.0.0.1:${PORT}" \
    --build-arg PAIRS_APT_TRUSTED=1 \
    -t "${IMAGE}:${TAG}" -t "${IMAGE}:latest" .
fi

echo
echo "built: ${IMAGE}:${TAG}  (also tagged :latest)"
echo "run:   ./run_pairs_system.sh"
echo "push:  ./push_docker.sh"
