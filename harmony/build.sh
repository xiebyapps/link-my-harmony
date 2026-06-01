#!/bin/bash
# HarmonyOS HAP build, install and launch script
# Usage: ./build.sh [--no-clean]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NODE="/Applications/DevEco-Studio.app/Contents/tools/node/bin/node"
HVIGOR="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js"
HDC="$HOME/Library/OpenHarmony/Sdk/12/toolchains/hdc"
PKG="app.xiebaiyuan.linkmyharmony"
HAP="$SCRIPT_DIR/entry/build/default/outputs/default/entry-default-signed.hap"

cd "$SCRIPT_DIR"

# Clean by default to avoid stale incremental builds
if [[ "$1" != "--no-clean" ]]; then
  "$NODE" "$HVIGOR" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone clean
fi

"$NODE" "$HVIGOR" \
  --mode module \
  -p product=default \
  assembleHap \
  --analyze=normal \
  --parallel \
  --incremental \
  --daemon

echo "✅ Build succeeded."

"$HDC" install "$HAP"
"$HDC" shell aa force-stop "$PKG"
"$HDC" shell aa start -a EntryAbility -b "$PKG" -m entry

echo "✅ Installed and launched."
