#!/bin/sh

# Download appimagetool
if [ ! -f ./appimagetool ]; then
	echo "-----------------------------------------------------------------------------"
	echo "◆ Downloading \"appimagetool\" from https://github.com/AppImage/appimagetool"
	echo "-----------------------------------------------------------------------------"
	curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage && chmod a+x appimagetool
fi

# Determine appname and branch
if [ "$branch" = candidate ]; then
	APPNAME="Blender Release Candidate"
elif [ "$branch" = beta ]; then
	APPNAME="Blender Beta"
elif [ "$branch" = alpha ]; then
	APPNAME="Blender Alpha"
else
	branch="stable"
	APPNAME="Blender"
fi

# Download and extract the archive
download=$(curl -Ls "https://builder.blender.org/download/daily/archive/" | tr '"' '\n' | grep "^https" | grep -i "tar.xz$" | grep -w -v sha256 | grep "$branch" | head -1)

if ! test -f *.tar.xz; then
	wget "$download" || exit 1
fi
tar fx *.tar.xz
dirname=$(ls . | grep tar.xz | sed 's/.tar.xz$//g')
mv ./"$dirname" ./blender.AppDir

mv blender.AppDir/blender-launcher blender.AppDir/AppRun

# Launcher and icon
cp -r ./blender.desktop blender.AppDir/blender.desktop
cp -r ./blender.png blender.AppDir/blender.png
sed -i "s/Name=BLENDER/Name=$APPNAME/g" blender.AppDir/blender.desktop || exit 1

# Export to AppImage
APPNAME=$(echo "$APPNAME" | sed 's/ /_/g')
REPO="$APPNAME-appimage"
TAG="continuous-$branch"
VERSION=$(echo "$download" | tr '-' '\n' | grep "^[0-9]")
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*x86_64.AppImage.zsync"

ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "$UPINFO" \
	./blender.AppDir "$APPNAME"-"$VERSION"-x86_64.AppImage

if ! test -f ./*AppImage; then
	exit 0
fi
