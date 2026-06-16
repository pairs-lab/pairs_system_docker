# PAIRS System — the whole CTU-MRS-derived UAV system on ROS Noetic, installed
# from the PAIRS apt repository (no source build, unlike upstream slide-slam
# which mounts and catkin-builds its source).
#
#   build:  ./build.sh                 # builds against a local copy of pairs-apt/docs
#           PAIRS_APT_SOURCE=live ./build.sh   # builds against the published repo
#   run:    ./run_pairs_system.sh
FROM osrf/ros:noetic-desktop-full

LABEL org.opencontainers.image.title="PAIRS System"
LABEL org.opencontainers.image.description="PAIRS UAV system (CTU-MRS port) on ROS Noetic, installed from the PAIRS apt repo"
LABEL maintainer="Thanh Nguyen Canh <canhthanh@vnu.edu.vn>"

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Where to get PAIRS packages from. Defaults to the public signed repo; build.sh
# overrides PAIRS_APT_BASE to a build-time local server when serving pairs-apt/docs.
ARG PAIRS_APT_BASE=https://thanhnguyencanh.github.io/apt
ARG PAIRS_APT_TRUSTED=0

# runtime tooling: tmux (the session scripts are plain tmux now), GUI/X helpers,
# editors and network tools for interactive use, catkin/rosdep for the overlay ws
RUN apt-get update && apt-get install -y --no-install-recommends \
      tmux curl gnupg2 ca-certificates sudo \
      nano vim less git \
      iproute2 iputils-ping net-tools \
      python3-catkin-tools python3-rosdep \
      xterm x11-utils wmctrl \
 && rm -rf /var/lib/apt/lists/*

# register the PAIRS apt repository (signed for the public repo; trusted=yes when
# building against a transient local server)
RUN set -e; \
    if [ "$PAIRS_APT_TRUSTED" = "1" ]; then \
      echo "deb [trusted=yes] ${PAIRS_APT_BASE} noetic main" > /etc/apt/sources.list.d/pairs.list; \
    else \
      curl -fsSL "${PAIRS_APT_BASE}/KEY.gpg" | gpg --dearmor -o /usr/share/keyrings/pairs.gpg; \
      echo "deb [signed-by=/usr/share/keyrings/pairs.gpg] ${PAIRS_APT_BASE} noetic main" > /etc/apt/sources.list.d/pairs.list; \
    fi

# install the FULL PAIRS UAV system (gazebo sim + all SLAM cores + control +
# estimation + drivers — the complete ~170-package closure).
# CACHEBUST (a changing value) forces this layer to re-run when the apt repo
# content changes even though the command text is identical.
ARG CACHEBUST=0
RUN echo "apt content build ${CACHEBUST}" && \
    apt-get update && apt-get install -y --no-install-recommends \
      ros-noetic-pairs-uav-system-full \
 && rm -rf /var/lib/apt/lists/*

# mavros needs the GeographicLib geoid dataset (egm96-5) to convert between
# ellipsoid and AMSL altitudes. Without it the mavros node dies on startup
# ("FATAL: File not readable .../geoids/egm96-5.pgm") and, with no MAVLink
# bridge, the PX4 API can't arm or switch to offboard.
RUN apt-get update && apt-get install -y --no-install-recommends geographiclib-tools wget \
 && geographiclib-get-geoids egm96-5 \
 && rm -rf /var/lib/apt/lists/*

# shell helpers (waitForRos / waitForControl / waitForHw / ...) used by the
# tmux session scripts' pane commands
COPY pairs_shell_additions.sh /opt/pairs/shell_additions.sh

# overlay catkin workspace for the user's own packages (mounted from the host)
RUN mkdir -p /opt/pairs_ws/src
WORKDIR /opt/pairs_ws

# every interactive shell sources ROS, the overlay (if built), the PAIRS helpers
RUN { \
      echo 'source /opt/ros/noetic/setup.bash'; \
      echo '[ -f /opt/pairs_ws/devel/setup.bash ] && source /opt/pairs_ws/devel/setup.bash'; \
      echo 'source /opt/pairs/shell_additions.sh'; \
    } >> /root/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
