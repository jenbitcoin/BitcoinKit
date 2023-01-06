#! /bin/sh

#
# Build for iOS 64bit-ARM variants and iOS Simulator
# - Place the script at project root
# - Customize MIN_IOS_VERSION and other flags as needed
#
# Test Environment
# - macOS 10.14.6
# - iOS 13.1
# - Xcode 11.1
#

Build() {
    # Ensure -fembed-bitcode builds, as workaround for libtool macOS bug
    export MACOSX_DEPLOYMENT_TARGET="10.4"
    # Get the correct toolchain for target platforms
    export CC=$(xcrun --find --sdk "${SDK}" clang)
    export CXX=$(xcrun --find --sdk "${SDK}" clang++)
    export CPP=$(xcrun --find --sdk "${SDK}" cpp)
    export CFLAGS="${HOST_FLAGS} ${OPT_FLAGS}"
    export CXXFLAGS="${HOST_FLAGS} ${OPT_FLAGS}"
    export LDFLAGS="${HOST_FLAGS}"

    EXEC_PREFIX="${PLATFORMS}/${PLATFORM}"
    ./autogen.sh
    ./configure \
        --host="${CHOST}" \
        --prefix="${PREFIX}" \
        --exec-prefix="${EXEC_PREFIX}" \
        --enable-static \
        --disable-shared  # Avoid Xcode loading dylibs even when staticlibs exist

    make clean
    mkdir -p "${PLATFORMS}" &> /dev/null
    make V=1 -j"${MAKE_JOBS}" --debug=j
    make install
}

echo "HI"

# Locations
ScriptDir="$( cd "$( dirname "$0" )" && pwd )"
export ScriptDir
echo $ScriptDir
echo $ScriptDir/Libraries/platforms/arm/lib
if [ ! -d "$ScriptDir/Libraries/platforms/arm/lib" ]; then
git clone https://github.com/bitcoin-core/secp256k1.git || true
fi
cd secp256k1 &> /dev/null
mkdir -p _build/platforms/arm/lib
PREFIX="${ScriptDir}"/Libraries
PLATFORMS="${PREFIX}"/platforms
UNIVERSAL="${PREFIX}"/universal

# Compiler options
OPT_FLAGS="-O3 -g3 -fembed-bitcode"
MAKE_JOBS=8
MIN_IOS_VERSION=8.0

# Build for platforms
SDK="iphoneos"
PLATFORM="arm"
PLATFORM_ARM=${PLATFORM}
ARCH_FLAGS="-arch arm64 -arch arm64e"  # -arch armv7 -arch armv7s
HOST_FLAGS="${ARCH_FLAGS} -miphoneos-version-min=${MIN_IOS_VERSION} -isysroot $(xcrun --sdk ${SDK} --show-sdk-path)"
CHOST="arm-apple-darwin"
Build

SDK="iphonesimulator"
PLATFORM="x86_64-sim"
PLATFORM_ISIM=${PLATFORM}
ARCH_FLAGS="-arch x86_64"
HOST_FLAGS="${ARCH_FLAGS} -mios-simulator-version-min=${MIN_IOS_VERSION} -isysroot $(xcrun --sdk ${SDK} --show-sdk-path)"
CHOST="x86_64-apple-darwin"
Build

# Create universal binary
cd "${PLATFORMS}/${PLATFORM_ARM}/lib"
LIB_NAME=`find . -iname *.a`
cd -
mkdir -p "${UNIVERSAL}" &> /dev/null
lipo -create -output "${UNIVERSAL}/${LIB_NAME}" "${PLATFORMS}/${PLATFORM_ARM}/lib/${LIB_NAME}" "${PLATFORMS}/${PLATFORM_ISIM}/lib/${LIB_NAME}"
lipo -info "${UNIVERSAL}/${LIB_NAME}" "${PLATFORMS}/${PLATFORM_ARM}/lib/${LIB_NAME}" "${PLATFORMS}/${PLATFORM_ISIM}/lib/${LIB_NAME}"
echo "BYE"
