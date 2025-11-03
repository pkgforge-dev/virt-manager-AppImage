#!/bin/sh

set -eu
ARCH="$(uname -m)"
DEB_SOURCE="https://cursor.com/download"
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing dependencies..."
echo "---------------------------------------------------------------"
pacman -Sy --noconfirm --needed archlinux-keyring
pacman -Su --noconfirm
pacman -Syu --noconfirm \
	base-devel       \
	bridge-utils     \
	curl             \
	dnsmasq          \
	freetype2        \
	git              \
	libx11           \
	libxcb           \
	libxcursor       \
	libxi            \
	libxkbcommon-x11 \
	libxrandr        \
	libxss           \
	openbsd-netcat   \
	pipewire-audio   \
	pulseaudio       \
	pulseaudio-alsa  \
	qemu-desktop     \
	qemu-full        \
	swtpm            \
	virtiofsd        \
	virt-manager     \
	wget             \
	xorg-server-xvfb \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-common --prefer-nano

