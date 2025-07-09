# Start with an official ROS 2 base image for the desired distribution
FROM ros:humble-ros-base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ROS_DISTRO=humble

ARG USER_UID=1001
ARG USER_GID=1001
ARG USERNAME=user

# Install essential packages and ROS development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash-completion \
        curl \
        gdb \
        git \
        nano \
        openssh-client \
        python3-colcon-argcomplete \
        python3-colcon-common-extensions \
        sudo \
        vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup user configuration
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/$USERNAME/.bashrc \
    && echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /home/$USERNAME/.bashrc
    

USER $USERNAME

# Need to install librealsense2-dkms librealsense2-utils in host system
WORKDIR /home/$USERNAME/libs
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
        apt-transport-https \
        lsb-release \
    && sudo mkdir -p /etc/apt/keyrings \
    && sudo curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | \
       sudo tee /etc/apt/sources.list.d/librealsense.list \
    && sudo apt-get update && sudo apt-get install -y --no-install-recommends \
        librealsense2-utils \
        librealsense2-dev \
        librealsense2-dbg

# RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
#         curl \
#     && sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' \
#     && curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo tee /etc/apt/trusted.gpg.d/ros.asc > /dev/null
# RUN sudo apt-get update && sudo apt install ros-humble-realsense2-*


RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
        unzip \
        wget \
    && wget -q --show-progress -O libtorch.zip https://download.pytorch.org/libtorch/cu128/libtorch-cxx11-abi-shared-with-deps-2.7.1%2Bcu128.zip \
    && unzip libtorch.zip \
    && sudo rm libtorch.zip  

WORKDIR /home/$USERNAME/tmp
# Install CUDA 12.8
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        gnupg \
        curl \
    && wget -q https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-wsl-ubuntu.pin \
    && sudo mv cuda-wsl-ubuntu.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
    && wget -q https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb \
    && sudo dpkg -i cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb \
    && sudo cp /var/cuda-repo-wsl-ubuntu-12-8-local/cuda-*-keyring.gpg /usr/share/keyrings/ \
    && sudo apt-get update \
    && sudo apt-get -y install cuda-toolkit-12-8 \
    && sudo apt-get clean \
    && sudo rm cuda-repo-wsl-ubuntu-12-8-local_12.8.0-1_amd64.deb \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*


# Set CUDA environment variables
ENV PATH="/usr/local/cuda/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

RUN echo 'export PATH=/usr/local/cuda/bin:$PATH' >> /home/$USERNAME/.bashrc && \
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> /home/$USERNAME/.bashrc

# Install cuDNN 9.10.2 (as non-root user using sudo)
RUN wget -q https://developer.download.nvidia.com/compute/cudnn/9.10.2/local_installers/cudnn-local-repo-ubuntu2204-9.10.2_1.0-1_amd64.deb \
    && sudo dpkg -i cudnn-local-repo-ubuntu2204-9.10.2_1.0-1_amd64.deb \
    && sudo cp /var/cudnn-local-repo-ubuntu2204-9.10.2/cudnn-*-keyring.gpg /usr/share/keyrings/ \
    && sudo apt-get update \
    && sudo apt-get -y install cudnn \
    && sudo apt-get clean \
    && sudo rm cudnn-local-repo-ubuntu2204-9.10.2_1.0-1_amd64.deb \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*
 
WORKDIR /home/$USERNAME/downloads
RUN sudo rm -r /home/$USERNAME/tmp


# Install some ROS 2 dependencies to create a cache layer
RUN sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
        ros-humble-ros-gz \
        ros-humble-sdformat-urdf \
        ros-humble-joint-state-publisher-gui \
        ros-humble-ros2controlcli \
        ros-humble-controller-interface \
        ros-humble-hardware-interface-testing \
        ros-humble-ament-cmake-clang-format \
        ros-humble-ament-cmake-clang-tidy \
        ros-humble-controller-manager \
        ros-humble-ros2-control-test-assets \
        libignition-gazebo6-dev \
        libignition-plugin-dev \
        ros-humble-hardware-interface \
        ros-humble-control-msgs \
        ros-humble-backward-ros \
        ros-humble-generate-parameter-library \
        ros-humble-realtime-tools \
        ros-humble-joint-state-publisher \
        ros-humble-joint-state-broadcaster \
        ros-humble-moveit-ros-move-group \
        ros-humble-moveit-kinematics \
        ros-humble-moveit-planners-ompl \
        ros-humble-moveit-ros-visualization \
        ros-humble-joint-trajectory-controller \
        ros-humble-moveit-simple-controller-manager \
        ros-humble-rviz2 \
        ros-humble-xacro \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

WORKDIR /ros2_ws

# Install the missing ROS 2 dependencies
COPY . /ros2_ws/src
RUN sudo chown -R $USERNAME:$USERNAME /ros2_ws \
    && vcs import src < src/franka.repos --recursive --skip-existing \
    && sudo apt-get update \
    && rosdep update \
    && rosdep install --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* \
    && rm -rf /home/$USERNAME/.ros \
    && rm -rf src \
    && mkdir -p src

COPY ./franka_entrypoint.sh /franka_entrypoint.sh
RUN sudo chmod +x /franka_entrypoint.sh



# Set the default shell to bash and the workdir to the source directory
SHELL [ "/bin/bash", "-c" ]
ENTRYPOINT [ "/franka_entrypoint.sh" ]
CMD [ "/bin/bash" ]
WORKDIR /ros2_ws