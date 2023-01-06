#!/bin/sh
set -ex

SCRIPT_DIR=`pwd`
export SCRIPT_DIR
echo $SCRIPT_DIR
ls $SCRIPT_DIR
# exit
TDIR=`mktemp -d`
trap "{ cd - ; rm -rf $TDIR; exit 255; }" SIGINT

cd $TDIR

git clone --depth 1 https://github.com/bitcoin-core/secp256k1.git src

CURRENTPATH=$PWD
export CURRENTPATH
ls $CURRENTPATH

IPHONE_SIMULATOR=iphonesimulator
IPHONEOS=iphoneos
mkdir -p $TDIR/$IPHONE_SIMULATOR
mkdir -p $TDIR/$IPHONEOS
export TARGETDIR_SIMULATOR

TARGETDIR_IPHONEOS="$SCRIPT_DIR/.build/$IPHONEOS"
mkdir -p "$TARGETDIR_IPHONEOS"
export TARGETDIR_IPHONEOS

TARGETDIR_SIMULATOR="$SCRIPT_DIR/.build/$IPHONE_SIMULATOR"
mkdir -p "$TARGETDIR_SIMULATOR"
export TARGETDIR_SIMULATOR

ls $SCRIPT_DIR
ls $CURRENTPATH
ls $TDIR

HOST_ARCH=$(uname -m)

xcrun -sdk iphoneos --show-sdk-path
alias autoreconf=/opt/homebrew/bin/autoreconf
(cd src && ./autogen.sh)

(cd src && ./configure --host=arm-apple-darwin \
    CC=`xcrun -find clang` \
    CFLAGS="-O3 -isysroot \
    `xcrun -sdk $IPHONE_SIMULATOR --show-sdk-path` -fembed-bitcode-marker -mios-simulator-version-min=8.0" \
    CXX=`xcrun -find clang++` \
    CXXFLAGS="-O3 -isysroot \
    `xcrun -sdk $IPHONE_SIMULATOR--show-sdk-path` -fembed-bitcode-marker -mios-simulator-version-min=8.0" --prefix="$TARGETDIR_SIMULATOR" \
    && make install)

mkdir -p "$SCRIPT_DIR/Libraries/$IPHONE_SIMULATOR/secp256k1/lib"
xcrun lipo -create "$TARGETDIR_SIMULATOR/lib/libsecp256k1.a" \
                   -o "$SCRIPT_DIR/Libraries/$IPHONE_SIMULATOR/secp256k1/lib/libsecp256k1.a"
cp -rf $TDIR/src/include "$SCRIPT_DIR/Libraries/$IPHONE_SIMULATOR/secp256k1"
exit
(cd src && ./configure --host=arm-apple-darwin \
     CC=`xcrun -find clang` CFLAGS="-O3 -isysroot \
     `xcrun -sdk $IPHONEOS --show-sdk-path` -fembed-bitcode -mios-version-min=8.0" \
     CXX=`xcrun -find clang++` \
     CXXFLAGS="-O3 -isysroot \
     `xcrun -sdk $IPHONEOS        --show-sdk-path` -fembed-bitcode -mios-version-min=8.0" --prefix="$TARGETDIR_IPHONEOS" \
     && make install)

cd -
mkdir -p "$SCRIPT_DIR/Libraries/$IPHONE_SIMULATOR/secp256k1/lib"
xcrun lipo -create "$TARGETDIR_SIMULATOR/lib/libsecp256k1.a" \
                   -o "$SCRIPT_DIR/Libraries/$IPHONE_SIMULATOR/secp256k1/lib/libsecp256k1.a"


rm -rf $TDIR

exit 0
