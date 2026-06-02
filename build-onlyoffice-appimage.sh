#!/bin/bash
set -e

APP="OnlyOffice"
ARCH="x86_64"
APPDIR="${APP}.AppDir"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

wget -q "https://github.com/pkgforge-dev/appimagetool/releases/latest/download/appimagetool-x86_64-linux" -O appimagetool
chmod +x appimagetool

DOWNLOAD_URL=$(curl -s https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest | grep "browser_download_url.*-x86_64\.AppImage" | cut -d '"' -f 4 | head -n 1)
wget -q "$DOWNLOAD_URL" -O onlyoffice.AppImage
chmod +x onlyoffice.AppImage

./onlyoffice.AppImage --appimage-extract
mv squashfs-root ./"$APPDIR"

rm -f ./"$APPDIR"/.DirIcon
cp ./"$APPDIR"/onlyoffice-desktopeditors.png ./"$APPDIR"/.DirIcon

rm -f ./"$APPDIR"/AppRun
cat <<'EOF' > ./"$APPDIR"/AppRun
#!/bin/sh
export APPDIR="$(dirname "$(readlink -f "${0}")")"
exec "$APPDIR/usr/bin/desktopeditors" "$@"
EOF
chmod +x ./"$APPDIR"/AppRun

sed -i 's|^Exec=.*|Exec=AppRun %F|g' ./"$APPDIR"/onlyoffice-desktopeditors.desktop

VERSION=$(curl -s https://api.github.com/repos/ONLYOFFICE/DesktopEditors/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
APPIMAGE_NAME="$APP-$VERSION-$ARCH.AppImage"

export OPTIMIZE_LAUNCH=1
export OUTNAME="$APPIMAGE_NAME"

./appimagetool ./"$APPDIR" -o ./dist

mv ./dist/"$APPIMAGE_NAME" "$OLDPWD"

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "appimage_name=$APPIMAGE_NAME" >> "$GITHUB_OUTPUT"
