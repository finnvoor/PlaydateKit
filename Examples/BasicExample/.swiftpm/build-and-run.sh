#! /bin/sh
set -e
killall 'Playdate Simulator' || true
cd ..
PRODUCT=$(make product_path | tail -n1)
make 
~/Developer/PlaydateSDK/bin/Playdate\ Simulator.app/Contents/MacOS/Playdate\ Simulator $PRODUCT
