#!/bin/bash

# --- CONFIGURATION ---
VERSION="v1.137.0"
PACKAGE_DIR="./package"
CONFIG_FILE="./vmagent-conf.yml"
REMOTE_WRITE_URL="http://localhost:8480/insert/0/prometheus/api/v1/write"

# --- 1. DOWNLOAD LOGIC ---
if [ ! -f "$PACKAGE_DIR/vmagent-prod" ]; then
    echo "vmagent-prod not found. Starting download..."
    mkdir -p "$PACKAGE_DIR"
    
    # Detect Architecture
    ARCH=$(uname -m)
    if [ "$ARCH" == "arm64" ]; then
        URL="https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/$VERSION/vmutils-darwin-arm64-$VERSION.tar.gz"
    else
        URL="https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/$VERSION/vmutils-darwin-amd64-$VERSION.tar.gz"
    fi

    echo "Downloading for $ARCH architecture..."
    curl -L "$URL" -o "$PACKAGE_DIR/vmutils.tar.gz"
    
    echo "Extracting package..."
    tar -xf "$PACKAGE_DIR/vmutils.tar.gz" -C "$PACKAGE_DIR"
    chmod +x "$PACKAGE_DIR/vmagent-prod"
    
    # Cleanup
    rm "$PACKAGE_DIR/vmutils.tar.gz"
    echo "Download and extraction complete."
else
    echo "vmagent-prod already exists in $PACKAGE_DIR."
fi

# --- 2. START NODE_EXPORTER ---
if ! pgrep -x "node_exporter" > /dev/null; then
    echo "Starting node_exporter via Homebrew..."
    brew services start node_exporter
else
    echo "node_exporter is already running."
fi

# --- 3. START VMAGENT ---
echo "Launching vmagent..."
"$PACKAGE_DIR/vmagent-prod" \
    -promscrape.config="$CONFIG_FILE" \
    -remoteWrite.url="$REMOTE_WRITE_URL" \
    -httpListenAddr=:8429