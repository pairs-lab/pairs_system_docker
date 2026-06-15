#!/bin/bash
# Source the ROS + PAIRS environment for non-interactive `docker run ... <cmd>`
# invocations (interactive bash already sources these via ~/.bashrc).
set -e
source /opt/ros/noetic/setup.bash
[ -f /opt/pairs_ws/devel/setup.bash ] && source /opt/pairs_ws/devel/setup.bash
source /opt/pairs/shell_additions.sh
exec "$@"
