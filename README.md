## Prerequisites

You must install Java before running this script.  
Example:

```bash
apt install openjdk-17
```

## Installation

run install script:

```bash
apt update && apt upgrade -y && apt install which wget -y && \
wget https://github.com/phamhoangden/ndk-arm64_backup/raw/main/install.sh \
--no-verbose --show-progress -N && chmod +x install.sh && bash install.sh
```

The script will automatically download and configure:

- Android SDK (command-line tools)
- Android NDK (arm64 custom build)
- Required environment variables and paths
