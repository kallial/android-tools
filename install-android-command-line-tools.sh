#!/bin/bash
set -e

if ! command -v javac &>/dev/null; then
  echo "Java not found. Installing Java..."
  sudo apt update
  sudo apt install -y default-jdk curl unzip
else
  echo "Java is already installed."
fi

JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"
echo "JAVA_HOME set to: $JAVA_HOME"

ANDROID_HOME="$HOME/Android"
CMDLINE_TOOLS="$ANDROID_HOME/cmdline-tools"
CMDLINE_LATEST="$CMDLINE_TOOLS/latest"
CMDLINE_BIN="$CMDLINE_LATEST/bin"

if [ ! -f "$CMDLINE_BIN/sdkmanager" ]; then
  mkdir -p "$CMDLINE_LATEST"
  cd "$CMDLINE_TOOLS"
  toolsDownloadUrl=$(curl -s https://developer.android.com/studio | grep -o "https:\/\/dl.google.com\/android\/repository\/commandlinetools\-linux\-[0-9]*_latest\.zip")
  curl -L -o cmdline.zip "$toolsDownloadUrl"
  unzip -q cmdline.zip -d tmp
  mv tmp/cmdline-tools/* "$CMDLINE_LATEST/"
  rmdir tmp/cmdline-tools tmp
  rm cmdline.zip
fi

export PATH="$CMDLINE_BIN:$PATH"
chmod +x "$CMDLINE_BIN/"*

yes | sdkmanager --licenses
sdkmanager --update
sdkmanager --install "platform-tools"

if ! grep -qxF 'export PATH="$HOME/Android/platform-tools:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/Android/platform-tools:$PATH"' >>"$HOME/.bashrc"
fi

echo "Android tools installed at: $ANDROID_HOME"
