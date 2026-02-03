#!/bin/bash

set -ex

error() {
	echo "$@" >&2
	exit 1
}

usage() {
	error "USAGE: $0 <kernel version> <extlinux label>"
}

if [ $# -ne 2 ]; then
	usage
fi

kver="$1"
label="$2"

EXTLINUX="/boot/extlinux/extlinux.conf"
UNCOMPRESSED="/boot/uncompressed"

image_name="vmlinuz-$kver"
initrd_name="initrd.img-$kver"

if ! [ -f "/boot/$image_name" ]; then
	error "ERROR: Kernel image $image_name not found"
fi

if ! [ -f "/boot/$initrd_name" ]; then
	error "ERROR: Kernel initrd $initrd_name not found"
fi

if grep -q "^label $label" $EXTLINUX; then
	error "ERROR: Label $label already exists"
fi

if grep -q "LINUX .*${kver}$" $EXTLINUX; then
	error "ERROR: Entry for kernel $kver already exists"
fi

sudo mkdir -p $UNCOMPRESSED
sudo bash -c "zcat /boot/$image_name > $UNCOMPRESSED/$image_name"

sed -n '/^LABEL primary/,${p;/APPEND/q}' $EXTLINUX | sed -E \
	-e "s@(LABEL) .*@\1 ${label}@" \
	-e "s@(LINUX) .*@\1 /boot/uncompressed/${image_name}@" \
	-e "s@(INITRD) .*@\1 /boot/${initrd_name}@" \
	| sudo tee -a $EXTLINUX
echo | sudo tee -a $EXTLINUX # add newline padding

echo "Successfully added $kver to $EXTLINUX with label $label"

