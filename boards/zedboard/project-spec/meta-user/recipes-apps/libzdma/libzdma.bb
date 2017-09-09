#
# This file is the libzdma recipe.
#

SUMMARY = "Simple libzdma application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://libzdma.c \
	   file://macro.h \
	   file://zdma_ioctl.h \
	   file://Makefile \
		  "

S = "${WORKDIR}"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}${bindir}
	     install --strip-program=/bin/true -m 0755 libzdma ${D}${bindir}
}