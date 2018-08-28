#!/usr/bin/env bash

# Fail on error, verbose output
set -exo pipefail

 port=1717
 if [[ ! -z $4 ]]; then
   port=$(($4))
 fi

adb -s $2 forward tcp:$port localabstract:minicap
# Build project
#ndk-build NDK_DEBUG=1 1>&2

toto=$2
# Figure out which ABI and SDK the device has
abi=$(adb -s $2 shell getprop ro.product.cpu.abi | tr -d '\r')
sdk=$(adb -s $2 shell getprop ro.build.version.sdk | tr -d '\r')
pre=$(adb -s $2 shell getprop ro.build.version.preview_sdk | tr -d '\r')
rel=$(adb -s $2 shell getprop ro.build.version.release | tr -d '\r')

if [[ -n "$pre" && "$pre" > "0" ]]; then
  sdk=$(($sdk + 1))
fi

# PIE is only supported since SDK 16
if (($sdk >= 16)); then
  bin=minicap
else
  bin=minicap-nopie
fi

args=
if [ "$1" = "autosize" ]; then
  set +o pipefail
  size=$(adb -s $2 shell dumpsys window | grep -Eo 'init=[0-9]+x[0-9]+' | head -1 | cut -d= -f 2)
  arraySize=(${size//x/ })
  virtualsize=${arraySize[1]}
  virtualsize="${virtualsize}x${arraySize[0]}"
  if [ "$size" = "" ]; then
    w=$(adb -s $2 shell dumpsys window | grep -Eo 'DisplayWidth=[0-9]+' | head -1 | cut -d= -f 2)
    h=$(adb -s $2 shell dumpsys window | grep -Eo 'DisplayHeight=[0-9]+' | head -1 | cut -d= -f 2)
    size="${w}x${h}"
    if [ "$3" -eq 90 ]; then
      virtualsize="${h}x${w}"
    fi
  fi
  # orientation=0
  # if [[ ! -z $3 ]]; then
  #   orientation=0
  # fi
  args="-P ${size}@${size}/0"
  if [ "$3" -eq 90 ]; then
      args="-P ${virtualsize}@${virtualsize}/0"
  fi
  set -o pipefail
  shift
fi

# Create a directory for our resources
dir=/data/local/tmp/minicap-devel
# Keep compatible with older devices that don't have `mkdir -p`.
adb -s $toto shell "mkdir $dir 2>/dev/null || true"

# Upload the binary
adb -s $toto push libs/$abi/$bin $dir

# Upload the shared library
if [ -e jni/minicap-shared/aosp/libs/android-$rel/$abi/minicap.so ]; then
  adb -s $toto push jni/minicap-shared/aosp/libs/android-$rel/$abi/minicap.so $dir
else
  adb -s $toto push jni/minicap-shared/aosp/libs/android-$sdk/$abi/minicap.so $dir
fi

# Run!
adb -s $toto shell LD_LIBRARY_PATH=$dir $dir/$bin $args

# Clean up
adb shell rm -r $dir
