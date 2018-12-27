#!/bin/bash

set -v

BSP_DIR="~/yocto"

while getopts ":d:" opt; do
  case $opt in
    d)BSP_DIR="$OPTARG"
      echo "BSP_DIR is $BSP_DIR" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift $((OPTIND-1))

BRANCH="thud"

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping -y

sudo apt-get install sysstat -y

VERSION=38

echo "SCRIPTPATH is $SCRIPTPATH"

if [ ! -d "poky" ]; then
	git clone -b $BRANCH git://git.yoctoproject.org/poky
fi

if [ ! -d "meta-openembedded" ]; then
	git clone -b $BRANCH git://git.openembedded.org/meta-openembedded
fi

if [ ! -d "meta-raspberrypi" ]; then
	git clone -b $BRANCH git://git.yoctoproject.org/meta-raspberrypi
	cd meta-raspberrypi
	# Fix missing firmware. Next commit changes handling of non-free firmware 
	# See: http://git.yoctoproject.org/cgit/cgit.cgi/meta-raspberrypi/commit/recipes-kernel/linux-firmware/linux-firmware_%25.bbappend?id=bfc35b773ff405394d066d7d8efb32ced3ac0410
	git checkout 0c14814f230e90dcb8323b5168ec881a284082d9
	cd ..
fi

if [ ! -d "openembedded-core" ]; then
	git clone -b $BRANCH https://github.com/openembedded/openembedded-core.git
fi

cd poky && git checkout $BRANCH && cd $SCRIPTPATH
cd meta-openembedded && git checkout $BRANCH && cd $SCRIPTPATH
cd meta-raspberrypi && git checkout $BRANCH && cd $SCRIPTPATH
cd openembedded-core && git checkout $BRANCH && cd $SCRIPTPATH
#cd meta-arago && git checkout $BRANCH && cd $SCRIPTPATH
#cd meta-sourcery && git checkout $BRANCH && cd $SCRIPTPATH
#cd meta-linaro && git checkout $BRANCH && cd $SCRIPTPATH

if [ ! -d "venv" ]; then
	virtualenv venv
fi

BSP_DIR_ABS=$(realpath "${BSP_DIR}")

source venv/bin/activate

pip install -r poky/bitbake/toaster-requirements.txt

BUILD_DIR=rpi-build-rebuild$VERSION

if [ -f $BUILD_DIR/conf/local.conf ];then
	rm $BUILD_DIR/conf/local.conf
fi

source poky/oe-init-build-env $BUILD_DIR


DOWNLOAD_CACHE="/mnt/external/yocto-downloads"
#DOWNLOAD_CACHE="/home/michael/yocto-downloads"

#SSTATE_MIRRORS=" file://.* file:///mnt/remotenfs/sstate-cachePATH "
#SSTATE_MIRRORS=/mnt/external/sstate-cache
SSTATE_CACHE=/mnt/external/sstate-cache
#SSTATE_CACHEi=/home/michael/yocto-build/sstate-cache$VERSION

TMP_CACHE=/home/michael/yocto-build/tmp$VERSION


echo "MACHINE = \"raspberrypi3\"" 			>> conf/local.conf
echo "PREFERRED_VERSION_linux-raspberrypi = \"4.14.%\""	>> conf/local.conf
#echo "PREFERRED_VERSION_linux-raspberrypi = \"4.16.%\""        >> conf/local.conf
#echo "PREFERRED_VERSION_linux-firmware-rpidistro = \"0.0+gitAUTOINC+b518de45ce\""	>> conf/local.conf
#echo "PREFERRED_VERSION_linux-firmware-rpidistro = \"0.0+gitAUTOINC+b518de45ce-r0\""       >> conf/local.conf
echo "DISTRO_FEATURES_remove = \"x11 wayland\""		>> conf/local.conf
#echo "DISTRO_FEATURES_append = \" systemd\"" 		>> conf/local.conf
echo "DISTRO_FEATURES_append = \" bluez5 bluetooth wifi\" "  >> conf/local.conf

#echo "IMAGE_INSTALL_append = \" kernel-modules crda rng-tools iw linux-firmware-bcm43455 bluez5 i2c-tools python-smbus bridge-utils hostapd dnsmasq dhcp-server iptables wpa-supplicant\""  >> conf/local.conf
# linux-firmware-bcm43430
# linux-firmware-rpidistro
#  bluez-firmware-rpidistro
#echo "VIRTUAL-RUNTIME_init_manager = \"systemd\"" 	>> conf/local.conf
echo "VIRTUAL-RUNTIME_init_manager = \"sysvinit\"" 	>> conf/local.conf
#echo "CORE_IMAGE_EXTRA_INSTALL += \"openssh gdbserver \"" >> conf/local.conf
echo "PACKAGE_CLASSES = \"package_rpm\"" 		>> conf/local.conf
echo "EXTRA_IMAGE_FEATURES += \" package-management \"" >> conf/local.conf


echo "ENABLE_UART = \"1\"" 				>> conf/local.conf
echo "DL_DIR ?= \"${DOWNLOAD_CACHE}\""		>> conf/local.conf
#echo "SSTATE_DIR ?= \"${SSTATE_CACHE}\""	>> conf/local.conf
echo "SSTATE_MIRRORS ?= \"${SSTATE_MIRRORS}\""	>> conf/local.conf
echo "TMPDIR = \"${TMP_CACHE}\""		>> conf/local.conf
echo "INHERIT += \"buildhistory\""			>> conf/local.conf
echo "BUILDHISTORY_COMMIT = \"1\""			>> conf/local.conf


#echo "TCLIBC = \"external-linaro-toolchain\""		>> conf/local.conf
#echo "TCLIBC = \"external-linaro-toolchain\""		>> conf/local.conf
#echo "TCMODE = \"external-linaro\""			>> conf/local.conf
#echo "EXTERNAL_TOOLCHAIN = \"/home/mdick/7.2.1-gcc-linaro/gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf/\""		>> conf/local.conf

#echo "ELT_TARGET_SYS ?= \"arm-linux-gnueabihf\""	>> conf/local.conf
#echo "TCMODE = \"external-arago\""			>> conf/local.conf
#echo "EXTERNAL_TOOLCHAIN = \"/home/mdick/arago-toolch/arago-2011.09/armv7a/\""		>> conf/local.conf
#echo "ELT_TARGET_SYS ?= \"arm-linux-gnueabihf\""	>> conf/local.conf

#echo "TARGET_PREFIX = \"arm-linux-gnueabihf-\""        	>> conf/local.conf
#echo "TCMODE = \"external-arago\""			>> conf/local.conf
#echo "EXTERNAL_TOOLCHAIN = \"/home/mdick/6.3-gcc-linaro/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf/\""              >> conf/local.conf
#echo "EXTERNAL_TOOLCHAIN = \"/home/mdick/6.1.1-gcc-linaro/gcc-linaro-6.1.1-2016.08-x86_64_arm-linux-gnueabihf/\""		>> conf/local.conf
#echo "EXTERNAL_TOOLCHAIN = \"/home/mdick/7.2.1-i686gcc-linaro/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf/\""		>> conf/local.conf
#echo "EXTERNAL_TOOLCHAIN = \"/home/mdick/7.3.1-gcc-linaro/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf\""		>> conf/local.conf

echo "SDK_EXT_TYPE = \"minimal\"" 			>> conf/local.conf
#echo "SDK_UPDATE_URL = \"http://my.server.com/path/to/esdk-update\""	>> conf/local.conf
#echo "SDK_INCLUDE_PKGDATA = \"1\""			>> conf/local.conf

mkdir -p 						"conf/distro"

echo "require conf/distro/include/yocto-uninative.inc"	>> conf/distro/poky.conf
echo "INHERIT += \"uninative\""				>> conf/distro/poky.conf



# LAYER_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
echo 'POKY_BBLAYERS_CONF_VERSION = "2"' 		>  conf/bblayers.conf

echo 'BBPATH = "${TOPDIR}"' 				>> conf/bblayers.conf
echo 'BBFILES ?= ""' 					>> conf/bblayers.conf

#echo 'BSPDIR := ' "\"${BSP_DIR_ABS}"\" 			>> conf/bblayers.conf


echo "BBLAYERS ?=  \"\\"				>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/poky/meta \\"			>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/poky/meta-poky \\"			>> conf/bblayers.conf
#echo "${BSP_DIR_ABS}/poky/meta-yocto-bsp \\"		>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/meta-openembedded/meta-oe \\"	>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/openembedded-core/meta \\"		>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/meta-openembedded/meta-python \\"	>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/meta-openembedded/meta-networking \\"	>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/meta-openembedded/meta-multimedia \\"	>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/meta-openembedded/meta-webserver	\\"     >> conf/bblayers.conf
#echo "${BSP_DIR_ABS}/meta-linaro/meta-linaro-toolchain \\"      >> conf/bblayers.conf
#echo "${BSP_DIR_ABS}/meta-arago/meta-arago-extras \\"      >> conf/bblayers.conf
#echo "${BSP_DIR_ABS}/meta-arago/meta-arago-distro \\"      >> conf/bblayers.conf

echo "${BSP_DIR_ABS}/meta-raspberrypi \\"			>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/meta-hgs \\"			>> conf/bblayers.conf
echo " \""						>> conf/bblayers.conf


echo "BBLAYERS_NON_REMOVABLE ?= \" \\"			>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/poky/meta \\"			>> conf/bblayers.conf
echo "${BSP_DIR_ABS}/poky/meta-poky \\"			>> conf/bblayers.conf
echo "\"" 						>> conf/bblayers.conf

bitbake-layers show-layers

# Measure CPU usage
rm /tmp/data
sar 2 10000 -o /tmp/data > /dev/null 2>&1 &
#bitbake core-image-minimal
#TOOLCHAIN_PATH=$HOME/gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf bitbake vci2-init-image
bitbake vci2-init-image
bitbake vci2-image
bitbake vci2-rescue-image
#bitbake meta-ide-support
#bitbake meta-toolchain adt-installer
#bitbake core-image-minimal -c populate-sdk
#bitbake vci2-image -c populate_sdk
bitbake vci2-image -c populate_sdk_ext

# Show CPU usage
killall -9 sar
sar -f /tmp/data | cat > yocto-sar-clean

# Offene Bitbaks töten
# ps ax | grep bitb | awk '{ print  $1 }' | xargs kill -9

#bitbake package-index
# Benötigt Paket python-twisted
#twistd -n web --path ${YOCTO_CACHE}/tmp7/deploy/rpm/ --port "tcp:port=8090"
