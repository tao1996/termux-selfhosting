#!/data/data/com.termux/files/usr/bin/bash
set -e

PREFIX=/data/data/com.termux/files/usr

rm -rf out
mkdir -p out
mkdir -p out/lib
mkdir -p out/src

##############################################################################
# Install dependencies.
echo "Installing build-time dependencies..."
pkg upgrade -y
pkg install -y aapt apksigner clang dx ecj

##############################################################################
# Compile JNI.
echo "Downloading bootstrap archive..."

TERMUX_ARCH=$(uname -m)
case "$TERMUX_ARCH" in
aarch64) LIBDIR="arm64-v8a";;
armv7*|armv8*) TERMUX_ARCH="arm"; LIBDIR="armeabi-v7a";;
i686) LIBDIR="x86";;
x86_64) LIBDIR="x86_64";;
*) echo "Unknown arch '$TERMUX_ARCH'"; exit 1;;
esac

mkdir -p out/lib/${LIBDIR}

cd ./jni


echo "Compiling native libraries..."
clang -Os -shared -o ../out/lib/${LIBDIR}/libtermux-bootstrap.so termux-bootstrap.c termux-bootstrap-zip.S
clang -Os -shared -o ../out/lib/${LIBDIR}/libtermux.so termux.c

cd ..

##############################################################################
# Generate R.java.
echo "Generating R.java..."
aapt package --generate-dependencies --non-constant-id -f -m \
	-M deps/androidx-core/AndroidManifest.xml -S ./res -J ./src
aapt package --generate-dependencies --non-constant-id -f -m \
	-M deps/androidx-drawerlayout/AndroidManifest.xml -S ./res -J ./src
aapt package --generate-dependencies --non-constant-id -f -m \
	-M AndroidManifest.xml -S ./res -J ./src

##############################################################################
# Compile Java sources.
echo "Compiling Java sources..."
dalvikvm -Xmx512m -Xcompiler-option --compiler-filter=speed \
	-cp ${PREFIX}/share/dex/ecj.jar \
	org.eclipse.jdt.internal.compiler.batch.Main \
	-proc:none -source 1.8 -target 1.8 -nowarn \
	-cp ./deps/android-28.jar \
	-cp ./deps/annotation.jar \
	-cp ./deps/collection.jar \
	-cp ./deps/core-classes.jar \
	-cp ./deps/core-common.jar \
	-cp ./deps/customview-classes.jar \
	-cp ./deps/drawerlayout-classes.jar \
	-cp ./deps/lifecycle-common.jar \
	-cp ./deps/lifecycle-runtime-classes.jar \
	-cp ./deps/versionedparcelable-classes.jar \
	-cp ./deps/viewpager-classes.jar \
	-d ./out/src \
	./src

##############################################################################
# DEX Java classes.
echo "Dexing Java classes..."
dx --dex --output=out/classes.dex \
	deps/annotation.jar \
	deps/collection.jar \
	deps/core-classes.jar \
	deps/core-common.jar \
	deps/customview-classes.jar \
	deps/drawerlayout-classes.jar \
	deps/lifecycle-common.jar \
	deps/lifecycle-runtime-classes.jar \
	deps/versionedparcelable-classes.jar \
	deps/viewpager-classes.jar \
	out/src

##############################################################################
# Create Android package file.
echo "Creating a dummy APK..."
aapt package -f --min-sdk-version 24 --target-sdk-version 28 \
	-M AndroidManifest.xml -S res -F out/termux-unsigned.apk.tmp

cd out

echo "Adding native libraries into APK..."
aapt add -f termux-unsigned.apk.tmp lib/$LIBDIR/libtermux.so
aapt add -f termux-unsigned.apk.tmp lib/$LIBDIR/libtermux-bootstrap.so

echo "Adding classes.dex into APK..."
aapt add -f termux-unsigned.apk.tmp classes.dex

cd ..

##############################################################################
# Signing APK.
echo "Signing APK file..."
apksigner sign --ks ./termux_debug_shared.p12 --ks-type PKCS12 \
	--ks-pass "pass:xrj45yWGLbsO7W0v" --key-pass "pass:xrj45yWGLbsO7W0v" \
	--in out/termux-unsigned.apk.tmp --out ./termux-signed.apk
echo "Done: ./termux-signed.apk"
