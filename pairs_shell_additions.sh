#!/bin/bash
# PAIRS shell additions — the waitFor* helpers that the tmux session scripts call
# in their pane commands (waitForRos; roslaunch ...). These mirror the CTU-MRS
# shell helpers but key off the PAIRS topic names. Source this from ~/.bashrc.
#
# All helpers block until the relevant subsystem is up, so a pane that runs
# "waitForControl; roslaunch ..." starts its node only once the prerequisite
# (ros master / sim time / hw_api / control_manager) is available.

# default robot identity (override by exporting before sourcing)
export UAV_NAME="${UAV_NAME:-uav1}"
export UAV_TYPE="${UAV_TYPE:-x500}"
export RUN_TYPE="${RUN_TYPE:-simulation}"

# internal: block until topic "$1" has at least one publisher (timeout-guarded echo)
_pairs_wait_topic() {
  local topic="$1"
  until timeout 5 rostopic echo -n 1 --noarr "$topic" > /dev/null 2>&1; do
    sleep 1
  done
}

# block until the ROS master is reachable
waitForRos() {
  until rostopic list > /dev/null 2>&1; do
    sleep 1
  done
}
# alias kept for compatibility with MRS scripts
waitForRosMaster() { waitForRos; }

# block until simulated time is ticking (/clock); on real hardware /clock is
# absent and use_sim_time is false, so we return immediately in that case
waitForTime() {
  waitForRos
  if [ "$(rosparam get /use_sim_time 2>/dev/null)" = "true" ]; then
    _pairs_wait_topic "/clock"
  fi
}

# block until the Gazebo simulator is up and publishing model states
waitForGazebo() {
  waitForRos
  _pairs_wait_topic "/gazebo/model_states"
}

# block until the hardware API (px4/mavros bridge) is publishing status
waitForHw() {
  waitForRos
  _pairs_wait_topic "/$UAV_NAME/hw_api/status"
}
# alias
waitForHardware() { waitForHw; }

# block until the estimation manager is producing a UAV state estimate
waitForOdometry() {
  waitForRos
  _pairs_wait_topic "/$UAV_NAME/estimation_manager/odom_main"
}

# block until the control manager is running (publishing diagnostics)
waitForControl() {
  waitForRos
  _pairs_wait_topic "/$UAV_NAME/control_manager/diagnostics"
}

# block until the UAV is actually in OFFBOARD and being controlled. We read the
# control_manager diagnostics and wait for an active controller/tracker — a good
# proxy for "the UAV is flying and accepting commands". Refine the grep below if
# your diagnostics message field names differ.
waitForOffboard() {
  waitForControl
  until timeout 5 rostopic echo -n 1 "/$UAV_NAME/control_manager/diagnostics" 2>/dev/null \
        | grep -qiE "active_(controller|tracker): *[A-Za-z]"; do
    sleep 1
  done
}

# export so the helpers survive `exec` (entrypoint) and are available in
# login shells, non-interactive `bash -c`, and inherited tmux panes alike
export -f _pairs_wait_topic waitForRos waitForRosMaster waitForTime \
          waitForGazebo waitForHw waitForHardware waitForOdometry \
          waitForControl waitForOffboard
