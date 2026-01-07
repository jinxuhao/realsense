# realsense

# ROS 环境
source /opt/ros/noetic/setup.bash
roscore &


# 如果开不开 ，X server 不允许当前容器里的 root 连接 ——就是 X11 访问控制（xauth / xhost）没放行。
xhost +SI:localuser:root

# RealSense 工具
realsense-viewer

# 驱动节点（APT 安装的话已包含）
roslaunch realsense2_camera rs_camera.launch


roslaunch realsense2_camera rs_camera.launch filters:=pointcloud
rviz

roslaunch realsense2_camera rs_camera.launch align_depth:=true

rosrun rqt_reconfigure rqt_reconfigure

rs-enumerate-devices | grep Serial

usb2 
roslaunch realsense2_camera rs_camera.launch filters:=pointcloud clip_distance:=0.5 depth_width:=640 depth_height:=480 depth_fps:=15 color_width:=640 color_height:=480 color_fps:=15

roslaunch realsense2_camera rs_camera.launch filters:=pointcloud clip_distance:=0.5 
                                            depth_width:=64 depth_height:=48 depth_fps:=15 color_width:=640 
                                            color_height:=480 color_fps:=15

rosservice call /camera/realsense2_camera/reset


## docker 运行完
# 检查脚本是否存在
ls -la /opt/init_catkin_ws.sh
# 执行初始化脚本
bash /opt/init_catkin_ws.sh

source /workspaces/realsense/catkin_ws/devel/setup.bash

# 查找 realsense2_camera 包 路径 
rospack find realsense2_camera
