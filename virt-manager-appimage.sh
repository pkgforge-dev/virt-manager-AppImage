#!/bin/sh

set -eu

ARCH="$(uname -m)"
VERSION="$(cat ~/version)"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

export ADD_HOOKS="self-updater.bg.hook:fix-namespaces.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/virt-manager.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/virt-manager.png
export OUTNAME=virt-manager-"$VERSION"-anylinux-"$ARCH".AppImage
export DEPLOY_OPENGL=1
export DEPLOY_PIPEWIRE=1
export OPTIMIZE_LAUNCH=1

# this app is hardcoded to look into /usr/share/virt-manager in multiple places
export PATH_MAPPING='
	/usr/share/libvirt:${SHARUN_DIR}/share/libvirt
	/usr/share/virt-manager:${SHARUN_DIR}/share/virt-manager
	/usr/lib/libvirt:${SHARUN_DIR}/lib/libvirt
'

# DEPLOY ALL LIBS
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun \
	/usr/bin/virt-manager     \
	/usr/bin/python*          \
	/usr/bin/qemu*            \
	/usr/bin/virt*            \
	/usr/bin/libvirtd*        \
	/usr/lib/libvirt/*        \
	/usr/lib/libvirt/*/*      \
	/usr/lib/libosinfo*.so*   \
	/usr/lib/libgirepository*

cp -r /usr/lib/python3.* ./AppDir/lib
cp -r /usr/share/libvirt ./AppDir/share

# TODO upstream to sharun
echo 'VIRTD_PATH=${SHARUN_DIR}/bin'                 >> ./AppDir/.env
#echo 'LIBVIRT_DRIVER_DIR=${SHARUN_DIR}/lib/libvirt' >> ./AppDir/.env

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

mkdir -p ./dist
mv -v ./*.AppImage*  ./dist
mv -v ~/version      ./dist
echo "All Done!"
