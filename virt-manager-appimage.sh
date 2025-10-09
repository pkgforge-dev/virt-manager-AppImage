#!/usr/bin/env bash

set -eux

export ARCH="$(uname -m)"
export DESKTOP=https://raw.githubusercontent.com/virt-manager/virt-manager/refs/heads/main/data/virt-manager.desktop.in
export ICON=https://github.com/virt-manager/virt-manager/blob/main/data/icons/256x256/apps/virt-manager.png?raw=true
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*-$ARCH.AppImage.zsync"
export RIM_ALLOW_ROOT=1
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"

echo '== download base RunImage'
curl -o runimage -L "https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$ARCH"
chmod +x runimage

run_install() {
	set -e

	EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"
	INSTALL_PKGS=(
		virt-manager
		freetype2
		libxcb
		libxcursor
		libxi
		libxkbcommon-x11
		pipewire-audio
		pulseaudio
		pulseaudio-alsa
		qemu-desktop
		wget
	)

	rim-update
	pac --needed --noconfirm -S "${INSTALL_PKGS[@]}"

	wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
	chmod +x ./get-debloated-pkgs.sh
	./get-debloated-pkgs.sh --add-opengl opus-mini gdk-pixbuf2-mini

	# remove llvm-libs but don't force it just in case something else depends on it
	pac -Rsn --noconfirm llvm-libs || true
	# same for glycin
	pac -Rsn --noconfirm glycin || true

	echo '== shrink (optionally)'
	pac -Rsndd --noconfirm wget gocryptfs jq gnupg
	rim-shrink --all
	pac -Rsndd --noconfirm binutils perl

	pac -Qi | awk -F': ' '/Name/ {name=$2}
		/Installed Size/ {size=$2}
		name && size {print name, size; name=size=""}' \
			| column -t | grep MiB | sort -nk 2

	VERSION=$(pacman -Q virt-manager | awk '{print $2; exit}')
	echo "$VERSION" > ~/version

	echo '== create RunImage config for app (optionally)'
	cat <<- 'EOF' > "$RUNDIR/config/Run.rcfg"
	RIM_CMPRS_LVL="${RIM_CMPRS_LVL:=22}"
	RIM_CMPRS_BSIZE="${RIM_CMPRS_BSIZE:=25}"
	RIM_SYS_NVLIBS="${RIM_SYS_NVLIBS:=1}"
	RIM_NVIDIA_DRIVERS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/runimage_nvidia"
	RIM_SHARE_ICONS="${RIM_SHARE_ICONS:=1}"
	RIM_SHARE_FONTS="${RIM_SHARE_FONTS:=1}"
	RIM_SHARE_THEMES="${RIM_SHARE_THEMES:=1}"
	RIM_HOST_XDG_OPEN="${RIM_HOST_XDG_OPEN:=1}"
	RIM_BIND="/usr/share/locale:/usr/share/locale,/usr/lib/locale:/usr/lib/locale"
	RIM_AUTORUN=virt-manager
	EOF

	rim-build -s temp.RunImage
}
export -f run_install
RIM_OVERFS_MODE=1 RIM_NO_NVIDIA_CHECK=1 ./runimage bash -c run_install
./temp.RunImage --runtime-extract
rm -f ./temp.RunImage
mv ./RunDir ./AppDir
mv ./AppDir/Run ./AppDir/AppRun

# debloat
rm -rfv ./AppDir/sharun/bin/chisel \
	./AppDir/rootfs/usr/lib/libgo.so* \
	./AppDir/rootfs/usr/lib/libgphobos.so* \
	./AppDir/rootfs/usr/lib/libgfortran.so* \
	./AppDir/rootfs/usr/bin/rav1e \
	./AppDir/rootfs/usr/*/*pacman* \
	./AppDir/rootfs/var/lib/pacman \
	./AppDir/rootfs/etc/pacman* \
	./AppDir/rootfs/usr/share/licenses \
	./AppDir/rootfs/usr/lib/udev/hwdb.bin

# Make AppImage with uruntime
export VERSION="$(cat ~/version)"
export OUTNAME=virt-manager-"$VERSION"-anylinux-"$ARCH".AppImage
export OPTIMIZE_LAUNCH=1
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

mkdir -p ./dist
mv -v ./*.AppImage* ./dist
mv -v ~/version     ./dist

echo "All done!"
