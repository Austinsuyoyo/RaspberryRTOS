#!/bin/sh

set -u
set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
CMDLINE="${BOARD_DIR}/cmdline-${BOARD_NAME}.cfg"

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
	grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

# Use custom cmdline.txt
if [ -e ${CMDLINE} ]; then
	install -D -m 0644 $CMDLINE \
		$BINARIES_DIR/rpi-firmware/cmdline.txt
fi

# Enable use password login with ssh
if [ -e ${TARGET_DIR}/etc/ssh/sshd_config ]; then
	sed -i '/^#PasswordAuthentication / s/#//' ${TARGET_DIR}/etc/ssh/sshd_config
fi

# Enable root use password login
if [ -e ${TARGET_DIR}/etc/ssh/sshd_config ]; then
	sed -i '/^#PermitRootLogin/ s/#//' ${TARGET_DIR}/etc/ssh/sshd_config
    sed -i '/^PermitRootLogin/ s/prohibit-password/yes/' ${TARGET_DIR}/etc/ssh/sshd_config
fi
