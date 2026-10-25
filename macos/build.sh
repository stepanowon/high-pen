#!/bin/zsh
# Builds dist/HighPen.app (universal, ad-hoc signed) from src/ with the Command Line Tools' swiftc (no Xcode project).
#   ./build.sh            build
#   ./build.sh test       build, then run the self-check
#   ./build.sh dmg        build, then package dist/HighPen-<version>.dmg (drag the app onto Applications)
set -e
VERSION=1.2.0
cd "${0:A:h}"
APP=dist/HighPen.app
rm -rf $APP dist/obj
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources dist/obj

for arch in arm64 x86_64; do
    swiftc -O -swift-version 5 -target $arch-apple-macos14 -o dist/obj/HighPen-$arch src/HighPen/*.swift
done
lipo -create -output $APP/Contents/MacOS/HighPen dist/obj/HighPen-arm64 dist/obj/HighPen-x86_64

# app icon, drawn at every size
swiftc -O -swift-version 5 -o dist/obj/make-icon src/make-icon.swift
dist/obj/make-icon dist/obj/HighPen.iconset
iconutil -c icns dist/obj/HighPen.iconset -o $APP/Contents/Resources/HighPen.icns

cat > $APP/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>HighPen</string>
    <key>CFBundleIdentifier</key><string>com.stepanowon.HighPen</string>
    <key>CFBundleName</key><string>HighPen</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>CFBundleIconFile</key><string>HighPen</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.education</string>
    <key>LSMultipleInstancesProhibited</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Copyright (c) 2026 StephenWon. MIT License.</string>
</dict>
</plist>
EOF

rm -rf dist/obj
# Ad-hoc signatures are identified by their hash, which changes on every build and makes macOS forget the
# screen recording permission. Requiring only the bundle id keeps the permission across rebuilds.
codesign --force --sign - --identifier com.stepanowon.HighPen -r='designated => identifier "com.stepanowon.HighPen"' $APP
echo "Built $APP ($VERSION)"
[[ "$1" == test ]] && $APP/Contents/MacOS/HighPen --selftest

if [[ "$1" == dmg ]]; then
    DMG=dist/HighPen-$VERSION.dmg
    rm -rf dist/dmg $DMG
    mkdir dist/dmg
    cp -R $APP dist/dmg/
    ln -s /Applications dist/dmg/Applications
    hdiutil create -volname "HighPen $VERSION" -srcfolder dist/dmg -fs HFS+ -format UDZO -quiet $DMG
    rm -rf dist/dmg
    echo "Built $DMG"
fi
exit 0
