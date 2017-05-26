#!/bin/sh
x="\e[1;92m"
y="\e[39m"
RHOST=147.27.39.174
VERSION=2017.1

case $1 in
"reload")
	cp ../dma/dma.sdk/axidma_wrapper.hdf build/system.hdf
	cp ../dma/dma.runs/impl_1/axidma_wrapper.bit build/download.bit
	;;
"reconf")
	petalinux-config --get-hw-description build/
	[ `grep EXTRA_IMAGE_FEATURES ./build/conf/local.conf` ] || echo 'EXTRA_IMAGE_FEATURES="debug-tweaks"' >> ./build/conf/local.conf
	sed '/inherit extrausers/d;/EXTRA_USERS_PARAMS/d' -i ./project-spec/meta-plnx-generated/recipes-core/images/petalinux-user-image.bb
	;;
"ez")
	vim project-spec/meta-user/recipes-modules/zdma/zdma/zdma.c
	;;
"ezh")	
	vim project-spec/meta-user/recipes-modules/zdma/zdma/zdma.h
	;;
"ezi")
	vim project-spec/meta-user/recipes-modules/zdma/zdma/zdma_ioctl.h
	;;
"el")
	vim project-spec/meta-user/recipes-apps/libzdma/libzdma/libzdma.c
	;;
"cbuild")
	petalinux-build -c zdma || exit
	petalinux-build -c libzdma
	petalinux-build -c bench
	petalinux-build -x package
	petalinux-package --prebuilt --clean --fpga ./build/download.bit
	;;
"build")
	petalinux-build
	petalinux-package --prebuilt --clean --fpga ./build/download.bit
	;;
"remote")
	ssh -t $RHOST "cd work/zdma; source /opt/Xilinx/Vivado/$VERSION/settings64.sh; source /opt/Xilinx/PetaLinux/$VERSION/settings.sh ; ./go run && ./go con"
	;;
"run")
	xsdb project-spec/arm_reset.tcl
	petalinux-boot --jtag --prebuilt 3
	;;
"rcon")
	ssh -t $RHOST "picocom -b115200 /dev/ttyACM0"
	;;
"con"*)
	picocom -b115200 /dev/ttyACM0
	;;
"clean")
	rm *.log *.jou
	;;
"dt")
	vim project-spec/meta-user/recipes-dt/device-tree/files/system-top.dts
	;;
"dtpl")
	vim components/plnx_workspace/device-tree-generation/pl.dtsi
	;;
*)
	echo -e ""\
		"$x prep$y:   prepare shell environment\n"			\
		"$x reload$y: refresh hardware project files (HDF and BIT)\n"	\
		"$x reconf$y: reread HDF and run project configuration\n"	\
		"$x cbuild$y: build user components\n"				\
		"$x build$y:  build everything\n"				\
		"$x remote$y: boot and connect to target at remote host\n"	\
		"$x run$y:    boot the project to the connected board\n"	\
		"$x rcon$y:   launch serial terminal to target board at remote host\n" \
		"$x con$y:    launch serial terminal to target board.\n"	\
		"$x dt*$y:    edit device-tree nodes\n"
	;;
esac

