# pairs_system — Docker image

The whole **PAIRS UAV system** (CTU-MRS port) on ROS Noetic.

This image **`apt install`s** the system from the signed PAIRS apt
repo, so the container is ready to run with no build step. Your own packages go
in a mounted overlay workspace.

## Contents
- `osrf/ros:noetic-desktop-full` base (rviz, gazebo11, rqt …)
- `ros-noetic-pairs-uav-system-full` — the complete ~170-package closure
  (gazebo simulation, all SLAM cores, control, estimation, drivers)
- `tmux` + the PAIRS `waitFor*` shell helpers the session scripts rely on
- an overlay catkin workspace at `/opt/pairs_ws` (mount your code here)

## Build

```bash
# 1) build against your LOCAL pairs-apt/docs (works today, before publishing)
./build.sh

# 2) or, once pairs-apt/docs is pushed to GitHub Pages, build against the live repo
PAIRS_APT_SOURCE=live ./build.sh
```

The image is tagged `thanhnc19/pairs_system:noetic` (and `:latest`) by default.
Override the account with `HUB_NAMESPACE=<your-dockerhub-namespace> ./build.sh`.

`build.sh` (local mode) serves `~/vin_dron_ws/pairs-apt/docs` over a throwaway
docker network and installs from it, so it does not depend on the GitHub Pages
push. Override the location with `APT_DOCS=/path/to/pairs-apt/docs`.

> **Note:** the published repo at `https://thanhnguyencanh.github.io/apt` must
> carry the current 102-deb index (incl. `ros-noetic-pairs-uav-system-full`) for
> `PAIRS_APT_SOURCE=live` and for end users to `apt install` directly. Push
> `pairs-apt/docs` first (see `pairs-apt/README.md`).

## Run

```bash
./run_pairs_system.sh
```

Edit the top of `run_pairs_system.sh` for your machine:
- `HUB_NAMESPACE` / `IMAGE` — which image to run
- `PAIRS_WS` — host overlay workspace (default `~/pairs_ws`, mounted at `/opt/pairs_ws`)
- `BAGS_DIR` — host rosbags/data (default `~/bags`, mounted at `/opt/bags`)

It forwards X11 (rviz/gazebo GUI), uses `--net host`, and attaches the NVIDIA GPU
if available.

## Try the simulation

Inside the container:

```bash
roscd pairs_uav_gazebo_simulation/tmux/one_drone
./start.sh        # plain-tmux session: gazebo + control + rviz, takeoff ready
# ./kill.sh       # stop everything
```

Detach with `Ctrl-b d`; re-attach with `tmux a -t simulation`.

## Push to Docker Hub

```bash
./push_docker.sh                 # docker login + push :noetic and :latest
TAG=v1.0 ./push_docker.sh        # also push a version tag (refreshes :latest)
```

`push_docker.sh` runs `docker login -u thanhnc19` if you are not already
authenticated, then pushes `thanhnc19/pairs_system:noetic` and `:latest`. After
it finishes the image appears at
<https://hub.docker.com/r/thanhnc19/pairs_system/tags>. Override the account with
`HUB_NAMESPACE=<your-dockerhub-namespace> ./push_docker.sh`.

On another machine: `docker pull thanhnc19/pairs_system:noetic`.

## Notes
- The gazebo session's final `layout` window calls `~/.i3/layout_manager.sh`
  (an i3 window-manager helper). Outside i3 that one window errors harmlessly;
  the rest of the session runs normally.
- Set `UAV_NAME` / `UAV_TYPE` / `RUN_TYPE` via the run script's env if you need
  something other than the `uav1` / `x500` / `simulation` defaults.
