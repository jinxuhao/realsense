# 基于 ROS Noetic 桌面完整版（含 RViz 等），系统层是 Ubuntu 20.04
FROM osrf/ros:noetic-desktop-full
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# 基础工具（添加了 python3-catkin-tools）
RUN apt-get update && apt-get install -y \
    sudo curl wget git lsb-release gnupg2 ca-certificates nano vim \
    python3-pip python3-venv python3-dev build-essential \
    python3-catkin-tools \
    ros-noetic-ddynamic-reconfigure \
    && rm -rf /var/lib/apt/lists/*

# 1) 设置 ROS 环境
RUN echo "source /opt/ros/noetic/setup.bash" >> /root/.bashrc

# 2) 安装 librealsense2（官方仓库，含 udev 规则/DKMS）
RUN apt-get update && apt-get install -y ca-certificates && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://librealsense.intel.com/Debian/librealsense.pgp \
      | gpg --dearmor -o /etc/apt/keyrings/librealsense-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/librealsense-keyring.gpg] https://librealsense.intel.com/Debian/apt-repo focal main" \
      > /etc/apt/sources.list.d/librealsense.list && \
    apt-get update && apt-get install -y \
      librealsense2-utils librealsense2-dev librealsense2-dkms && \
    rm -rf /var/lib/apt/lists/*

# 3) 安装 realsense2_camera（ROS 包）
RUN apt-get update && apt-get install -y \
    ros-noetic-realsense2-camera ros-noetic-realsense2-description \
    ros-noetic-ddynamic-reconfigure && \
    rm -rf /var/lib/apt/lists/*

# 4) 可选：Python 层的 SDK
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir pyrealsense2

# 5) 创建便捷初始化脚本（首次构建catkin_ws用）
RUN cat >/opt/init_catkin_ws.sh <<'EOS'
#!/usr/bin/env bash
set -e

WORKSPACE=${1:-/workspaces/realsense/catkin_ws}

echo "Initializing catkin workspace at: $WORKSPACE"

# 创建工作空间
mkdir -p $WORKSPACE/src
cd $WORKSPACE

# 初始化
source /opt/ros/noetic/setup.bash
catkin init

# 配置构建选项
catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release -DCATKIN_ENABLE_TESTING=False

# Clone源码
if [ ! -d "$WORKSPACE/src/realsense-ros" ]; then
    cd src
    git clone -b ros1-legacy https://github.com/IntelRealSense/realsense-ros.git
    cd ..
fi

# 安装依赖
rosdep install --from-paths src --ignore-src --skip-keys=librealsense2 -r -y

# 构建
catkin build

# 添加到bashrc（如果还没有）
if ! grep -q "source $WORKSPACE/devel/setup.bash" ~/.bashrc; then
    echo "source $WORKSPACE/devel/setup.bash" >> ~/.bashrc
fi

echo "✅ Workspace initialized at: $WORKSPACE"
echo "Run: source ~/.bashrc or source $WORKSPACE/devel/setup.bash"
EOS
RUN chmod +x /opt/init_catkin_ws.sh

# 6) 进入容器后执行的一次性设置脚本
RUN cat >/opt/setup_devcontainer_post.sh <<'EOS'
#!/usr/bin/env bash
set -e
apt-get update && apt-get install -y locales && \
  locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*
rosdep init 2>/dev/null || true
rosdep update || true
echo "[OK] postCreate done."
EOS
RUN chmod +x /opt/setup_devcontainer_post.sh

RUN apt-get update && apt-get install -y \
    usbutils v4l-utils udev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root
