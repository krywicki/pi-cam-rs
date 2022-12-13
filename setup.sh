#!/bin/bash
#
# Useful raspi-config cli non-interactive commands docs
#   - raspi-config shell functions
#     - https://github.com/RPi-Distro/raspi-config/blob/master/raspi-config
#   - raspi-config ui references to raspi-config nonint commands
#     - https://github.com/raspberrypi-ui/rc_gui/blob/89c774e7fa2621a7a13efd82ccd204d01daafabc/src/rc_gui.c#L52
#   - Blog about raspi-config nonint commands
#     - https://loganmarchione.com/2021/07/raspi-configs-mostly-undocumented-non-interactive-mode/

# Colored output.
RED="\e[1;31m"
YELLOW="\e[1;33m"
GREEN="\e[1;32m"
CYAN="\e[1;36m"
NORM="\e[0m"
LIGHT_GRAY="\e[0;37m"
BLUE="\e[0;34m"

# Swap file path on RaspberryPi OS.
SWAP_FILE=/etc/dphys-swapfile

# Platform Info
ARCH=$(uname -m)
CUR_GPU_MEM=$(sudo raspi-config nonint get_config_var gpu_mem /boot/config.txt)
REQ_GPU_MEM=256

OPENCV_VER="4.6.0"

do_print_welcome=true
do_update=false
do_ask_reboot=true
reboot_required=false

usage()
{
  printf "Usage: $0 [OPTIONS]\n\n"
  printf "OPTIONS:\n"
  printf "  -h  Print help information\n"
  printf "  -m  Mute welcome message\n"
  printf "  -u  Prevent script from updating the system\n"
  printf "  -r  Prevent script from asking for reboot\n"
}

ask_reboot()
{
  printf $GREEN"Please reboot your system before continung. Reboot now? [N/y]\n"
  printf $GREEN"==> "$NORM

  read selection # Read standard input.
  case $selection in
    Y|y)
      systemctl reboot
      ;;
    *)
      printf $YELLOW"==> Warning:$NORM changes will only be applied at next reboot\n"
      ;;
  esac
}

greet ()
{
  printf "$CYAN\n#######################################################\n"
  printf        "## pi-cam-rs successfully setup!                     ##\n"
  printf        "#######################################################\n$NORM"
}

# Print error message and exit.
exit_msg()
{
  printf $RED"==> Error:$NORM $1.\n"
  exit 1
}

welcome_msg()
{
  local COLOR1="$RED"
  local COLOR2="$RED"
  local COLOR3="$YELLOW"
  local COLOR4="$BLUE"
  local COLOR5="$BLUE"
  local COLOR6="$BLUE"

  printf "$COLOR1██████╗ ██╗       ██████╗ █████╗ ███╗   ███╗      ██████╗ ███████╗\n"
  printf "$COLOR2██╔══██╗██║      ██╔════╝██╔══██╗████╗ ████║      ██╔══██╗██╔════╝\n"
  printf "$COLOR3██████╔╝██║█████╗██║     ███████║██╔████╔██║█████╗██████╔╝███████╗\n"
  printf "$COLOR4██╔═══╝ ██║╚════╝██║     ██╔══██║██║╚██╔╝██║╚════╝██╔══██╗╚════██║\n"
  printf "$COLOR5██║     ██║      ╚██████╗██║  ██║██║ ╚═╝ ██║      ██║  ██║███████║\n"
  printf "$COLOR6╚═╝     ╚═╝       ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝      ╚═╝  ╚═╝╚══════╝\n\n$NORM"

  printf "$CYAN#####################################################################\n"
  printf      "## Installation helper script for pi-cam-rs                        ##\n"
  printf      "## Borrowed heavily from:                                          ##\n"
  printf      "##   Marco Radocchia                                               ##\n"
  printf      "##   https://github.com/marcoradocchia/bombuscv-rs                 ##\n"
  printf      "##                                                                 ##\n"
  printf      "## Warning: the installation process may take a while (>1h)...     ##\n"
  printf      "#####################################################################\n\n$NORM"
}

# deny root execution
[ $(whoami) = "root" ] && exit_msg "please don't run the script as root, run as normal user"

# validate platform architecture
case $ARCH in
    "aarch64"|"armv7l");;
    *)
        exit_msg "$ARCH not supported\n"
esac

# Get CLI options/arguments.
while getopts "m?h?u?r?" opt; do
  case $opt in
    m) # Mute welcome message.
      do_print_welcome=false
      ;;
    u) # Prevent script from updating the system.
      do_update=false
      ;;
    r) # Prevent script from asking for reboot.
      do_ask_reboot=false
      ;;
    h) # Print help information.
      usage && exit 0
      ;;
  esac
done

# Print welcome message unless -m option specified.
[ $do_print_welcome = true ] && welcome_msg

# Check if Raspberry is at least 4GB RAM.
[ $(free --mebi | awk '/^Mem:/ {print $2}') -lt 3000 ] && \
  exit_msg "required at least 4GB of RAM"

# Update the system.
[ $do_update = true ] && {
  printf "$GREEN==> Updating the system...$NORM\n"
  sudo apt-get -y update && sudo apt-get -y upgrade
}

# Update bootloader.
if [ "$(rpi-eeprom-update | grep 'BOOTLOADER: up to date')" = "" ]; then
  printf "$GREEN==> Updating bootloader...$NORM\n"
  sudo rpi-eeprom-update -a || exit_msg "Failed rpi-eeprom-update"
  reboot_required=true
else
  printf "$GREEN==> Bootloader up to date!$NORM\n"
fi

# Bring gpu memory up to 256MB.
if [ $CUR_GPU_MEM != $REQ_GPU_MEM ]; then
  printf "$GREEN==> Increasing gpu memory to $REQ_GPU_MEM...$NORM\n"
  sudo raspi-config nonint do_memory_split $REQ_GPU_MEM || exit_msg "Failed raspi-config do_memory_split"
  reboot_required=true
else
  printf "$GREEN==> Gpu memory already set at ${REQ_GPU_MEM}!$NORM\n"
fi

# Increasing swap size.
printf "$GREEN==> Increasing swap size...$NORM\n"
# storing the original swap size for later restore
orig_swap=$(awk -F'=' '/CONF_SWAPSIZE=/ {print $2}' $SWAP_FILE)
sudo sed -i $SWAP_FILE -e s'/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=4096/' || exit_msg "Failed to edit $SWAP_FILE"
sudo /etc/init.d/dphys-swapfile restart

# Enable legacy camera support with raspi-config in non-interactive mode.
if [ "$(sudo raspi-config nonint get_legacy)" != 0 ];
then
  printf "$GREEN==> Setting raspi-config legacy mode$NORM\n"
  sudo raspi-config nonint do_legacy 0 || exit_msg "Failed setting raspi-config legacy mode"
  reboot_required=true
else
    printf "$GREEN==> raspi-config legacy mode already set!$NORM\n"
fi

# Install all dependencies with apt-get.
printf "$GREEN==> Installing dependencies...$NORM\n"
sudo apt-get install -y \
  clang \
  libclang-dev \
  build-essential \
  cmake \
  git \
  ffmpeg \
  unzip \
  pkg-config \
  libjpeg-dev  \
  libpng-dev \
  libavcodec-dev \
  libavformat-dev \
  libswscale-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-gl \
  libxvidcore-dev \
  libx264-dev \
  libtbb2 \
  libtbb-dev \
  libdc1394-22-dev \
  libv4l-dev \
  v4l-utils \
  libopenblas-dev \
  libatlas-base-dev \
  libblas-dev \
  liblapack-dev \
  gfortran \
  libhdf5-dev \
  libprotobuf-dev \
  libgoogle-glog-dev \
  libgflags-dev \
  protobuf-compiler \
  libtiff-dev \
  libtiffxx5 \
  gstreamer1.0-tools

# Download OpenCV
if [ ! -d "opencv" ]; then
  printf "$GREEN==> Downloading OpenCV $OPENCV_VER...$NORM\n"
  wget -O opencv.zip https://github.com/opencv/opencv/archive/$OPENCV_VER.zip
  unzip opencv.zip
  mv opencv-$OPENCV_VER opencv
  rm opencv.zip
else
  printf "$GREEN==> OpenCV $OPENCV_VER already downloaded! Skipping.$NORM\n"
fi

# Dowload OpenCV Contrib
if [ ! -d "opencv_contrib" ]; then
  printf "$GREEN==> Downloading OpenCV Contrib $OPENCV_VER...$NORM\n"
  wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/$OPENCV_VER.zip
  unzip opencv_contrib.zip
  mv opencv_contrib-$OPENCV_VER opencv_contrib
  rm opencv_contrib.zip
else
  printf "$GREEN==> OpenCV Contrib $OPENCV_VER already downloaded! Skipping.$NORM\n"
fi

# create the build directory
CWD=$(pwd)
cd opencv && mkdir -p build && cd build

# Compile OpenCV 4.6.0.
printf "$GREEN==> Compiling OpenCV v$OPENCV_VER...$NORM\n"
# run cmake
cmake \
-DCMAKE_BUILD_TYPE=RELEASE \
-DCMAKE_INSTALL_PREFIX=/usr/local \
-DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
-DCPU_BASELINE=NEON \
-DENABLE_NEON=ON \
-DENABLE_VFPV3=$([ $ARCH = aarch64 ] && echo OFF || echo ON) \
-DWITH_OPENMP=ON \
-DWITH_OPENCL=OFF \
-DBUILD_TIFF=ON \
-DWITH_FFMPEG=ON \
-DWITH_TBB=ON \
-DBUILD_TBB=ON \
-DWITH_GSTREAMER=ON \
-DBUILD_TESTS=OFF \
-DWITH_EIGEN=OFF \
-DWITH_V4L=ON \
-DWITH_VTK=OFF \
-DWITH_QT=OFF \
-DWITH_GTK=OFF \
-DHIGHGUI_ENABLE_PLUGINS=OFF \
-DWITH_WIN32UI=OFF \
-DWITH_DSHOW=OFF \
-DWITH_AVFOUNDATION=OFF \
-DWITH_MSMF=OFF \
-DWITH_TESTs=OFF \
-DOPENCV_ENABLE_NONFREE=ON \
-DINSTALL_C_EXAMPLES=OFF \
-DINSTALL_PYTHON_EXAMPLES=OFF \
-DINSTALL_ANDROID_EXAMPLES=OFF \
-DWITH_ANDROID_MEDIANDK=OFF \
-DINSTALL_BIN_EXAMPLES=OFF \
-DOPENCV_GENERATE_PKGCONFIG=ON \
-DBUILD_EXAMPLES=OFF \
-DBUILD_JAVA=OFF \
-DBUILD_FAT_JAVA_LIB=OFF \
-DBUILD_JAVA=OFF \
-DBUILD_opencv_python2=OFF \
-DBUILD_opencv_python3=OFF \
-DENABLE_PYLINT=OFF \
-DENABLE_FLAKE8=OFF \
-DENABLE_ZLIB=ON \
-DWITH_PROTOBUF=ON \
..
[ "$?" != 0 ] && exit_msg "Failed cmake"

# Run make (compile) using num cores
make -j2 || exit_msg "Failed make"

# Install OpenCV 4.6.0
printf "$GREEN==> Installing OpenCV v4.6.0...$NORM\n"
sudo make install || exit_msg "Failed make install"
sudo ldconfig || exit_msg "Failed ldconfig"

# changing cwd back to $HOME
cd $CWD

# Install rustup if cargo isn't on system.
command -v cargo > /dev/null || {
  printf "$GREEN==> Installing rustup...$NORM\n"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

# Restoring swap size
printf "$GREEN==> Restoring swap size...$NORM\n"
sudo sed -i $SWAP_FILE -e s"/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=$orig_swap/" || exit_msg "Failed to restore swap size in $SWAP_FILE"
sudo /etc/init.d/dphys-swapfile restart

# Check if binary is installed successfully & greet if so.
greet


if [ -d /var/run/reboot-required ] || [ "$reboot_required" = true ]; then
  [ $do ask_reboot ] && ask_reboot || systemctl reboot
fi
