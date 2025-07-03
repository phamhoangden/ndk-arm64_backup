#!/bin/bash

# Android SDK & NDK installer for Termux
install_dir=$HOME
sdk_dir=$install_dir/android-sdk
cmake_dir=$sdk_dir/cmake
ndk_base_dir=$sdk_dir/ndk
gradle_home=$HOME/.gradle

# Check Java
if ! command -v java >/dev/null 2>&1; then
    echo "Java not found."
    echo "You must install Java before continuing."
    echo "Would you like to install openjdk-17 now? [Y/n]"
    read -r install_java
    if [[ "$install_java" == "Y" || "$install_java" == "y" || "$install_java" == "" ]]; then
        pkg install openjdk-17 -y || { echo "Failed to install Java."; exit 1; }
    else
        echo "Java is required. Exiting."
        exit 1
    fi
fi

java_path=$(readlink -f "$(which java)")
java_home=$(dirname "$(dirname "$java_path")")

echo "Java installed: $java_home"

export JAVA_HOME="$java_home"
export PATH="$JAVA_HOME/bin:$PATH"

# NDK
echo "Select NDK version to install:"
select item in r27c r28b Quit; do
	case $item in
		r27c) ndk_ver="27.2.12479018"; ndk_ver_name="r27c"; break ;;
		r28b) ndk_ver="28.1.13356709"; ndk_ver_name="r28b"; break ;;
		Quit) echo "Exit."; exit ;;
		*) echo "Invalid selection." ;;
	esac
done

echo "Installing NDK $ndk_ver_name ($ndk_ver)..."

ndk_file="android-ndk-$ndk_ver_name-aarch64-linux-musl.tar.xz"
ndk_dir="$ndk_base_dir/$ndk_ver"

# Cleanup old NDK and cmake
rm -rf "$ndk_dir" "$cmake_dir"/*

# Download and extract NDK
wget -q --show-progress -N "https://github.com/phamhoangden/ndk-arm64_backup/releases/download/NDK/$ndk_file"
if [ -f "$ndk_file" ]; then
	tar --no-same-owner -xf "$ndk_file" --warning=no-unknown-keyword
	rm "$ndk_file"
	mkdir -p "$ndk_base_dir"
	mv android-ndk-$ndk_ver_name "$ndk_dir"
	cd "$ndk_dir/toolchains/llvm/prebuilt" && ln -sf linux-arm64 linux-aarch64
	cd "$ndk_dir/prebuilt" && ln -sf linux-arm64 linux-aarch64
	cd "$ndk_dir/shader-tools" && ln -sf linux-arm64 linux-aarch64
else
	echo "NDK archive not found!"
	exit 1
fi

# CMake
mkdir -p "$cmake_dir"
cd "$cmake_dir"
for ver in 3.10.2 3.18.1 3.22.1 3.25.1; do
	cmake_file="cmake-$ver-android-aarch64.zip"
	echo "Downloading CMake $ver..."
	wget -q --show-progress -N "https://github.com/phamhoangden/ndk-arm64_backup/releases/download/Cmake/$cmake_file"
	unzip -qq "$cmake_file" -d "$cmake_dir"
	chmod -R +x "$cmake_dir/$ver/bin"
	rm "$cmake_file"
done

# SDK tools
mkdir -p "$sdk_dir"
cd "$sdk_dir" || exit

echo "Setup platform-tools..."
wget -q --show-progress https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -qq platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

echo "Setup commandlinetools..."
wget -q --show-progress https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip
unzip -qq commandlinetools-linux-10406996_latest.zip -d cmdline-tools-tmp
mkdir -p cmdline-tools/latest
mv cmdline-tools-tmp/cmdline-tools/* cmdline-tools/latest/
rm -rf cmdline-tools-tmp commandlinetools-linux-*.zip

profile="$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] && profile="$HOME/.zshrc"

add_line_if_missing() {
  grep -qxF "$1" "$profile" || echo "$1" >> "$profile"
}

add_line_if_missing "export JAVA_HOME=$java_home"
add_line_if_missing 'export PATH=$JAVA_HOME/bin:$PATH'
add_line_if_missing 'export ANDROID_HOME=$HOME/android-sdk'
add_line_if_missing 'export ANDROID_SDK_ROOT=$ANDROID_HOME'
add_line_if_missing 'export PATH=$PATH:$ANDROID_HOME/platform-tools'

export ANDROID_HOME=$HOME/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/platform-tools

yes | "$sdk_dir"/cmdline-tools/latest/bin/sdkmanager --sdk_root="$sdk_dir" --licenses

mkdir -p "$gradle_home"
cd "$gradle_home"

wget -q --show-progress -N "https://github.com/phamhoangden/ndk-arm64_backup/releases/download/aapt2/aapt2"
chmod +x aapt2

echo 'sdk.dir=/data/data/com.termux/files/home/android-sdk' > gradle.properties
echo 'android.aapt2FromMavenOverride=/data/data/com.termux/files/home/.gradle/aapt2' > gradle.properties

echo "Install and setup done!"
