#! /bin/sh
set -e

cleanup() {
    osascript -e 'quit app "Playdate Simulator"' 2>/dev/null
}

trap cleanup EXIT

SWIFT=$(xcrun -f swift -toolchain "swift latest")

cd ..
"$SWIFT" package pdc

# Create a symbolic link to the compiled pdx in the Playdate Simulator Games dir
# This allows browsing the pdx as a sideloaded game, helpful for checking icons
if [ -L ~/Developer/PlaydateSDK/Disk/Games/$PRODUCT_NAME.pdx ]; then
    rm -rf ~/Developer/PlaydateSDK/Disk/Games/$PRODUCT_NAME.pdx
fi
ln -s "$(pwd)/.build/plugins/PDCPlugin/outputs/$PRODUCT_NAME.pdx" ~/Developer/PlaydateSDK/Disk/Games/$PRODUCT_NAME.pdx

~/Developer/PlaydateSDK/bin/Playdate\ Simulator.app/Contents/MacOS/Playdate\ Simulator ~/Developer/PlaydateSDK/Disk/Games/$PRODUCT_NAME.pdx
