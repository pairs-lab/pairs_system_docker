#!/usr/bin/env bash
# Run the pairs_system container with GUI (rviz/gazebo) and, if present, the GPU.
# Mirrors slide-slam's run script but for the PAIRS apt-installed image.
#
# Edit the three paths / the namespace below for your machine, then:
#   ./run_pairs_system.sh            # interactive shell in the container
# Inside, e.g.:
#   roscd pairs_uav_gazebo_simulation/tmux/one_drone && ./start.sh
set -euo pipefail

HUB_NAMESPACE="${HUB_NAMESPACE:-thanhnc19}"              # <<< your Docker Hub account/org
IMAGE="${IMAGE:-${HUB_NAMESPACE}/pairs_system:latest}"
PAIRS_WS="${PAIRS_WS:-$HOME/pairs_ws}"                    # host overlay workspace
BAGS_DIR="${BAGS_DIR:-$HOME/bags}"                        # host rosbags / data

mkdir -p "$PAIRS_WS/src" "$BAGS_DIR"

# --- let the container reach the host X server (rviz / gazebo GUI) ---
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch "$XAUTH"
xauth nlist "${DISPLAY:-:0}" 2>/dev/null | sed -e 's/^..../ffff/' \
  | xauth -f "$XAUTH" nmerge - 2>/dev/null || true
xhost +local:root >/dev/null 2>&1 || true

# --- attach the NVIDIA GPU only if the runtime is available ---
GPU_FLAG=""
if command -v nvidia-smi >/dev/null 2>&1 && docker info 2>/dev/null | grep -qi nvidia; then
  GPU_FLAG="--gpus all"
fi

docker run -it --rm \
  --name pairs_system \
  --net host \
  --privileged \
  $GPU_FLAG \
  --env DISPLAY="${DISPLAY:-:0}" \
  --env QT_X11_NO_MITSHM=1 \
  --env XAUTHORITY="$XAUTH" \
  --env UAV_NAME="${UAV_NAME:-uav1}" \
  --env UAV_TYPE="${UAV_TYPE:-x500}" \
  --env RUN_TYPE="${RUN_TYPE:-simulation}" \
  --volume "$XSOCK:$XSOCK:rw" \
  --volume "$XAUTH:$XAUTH:rw" \
  --volume "$PAIRS_WS:/opt/pairs_ws:rw" \
  --volume "$BAGS_DIR:/opt/bags:rw" \
  "$IMAGE" \
  bash
