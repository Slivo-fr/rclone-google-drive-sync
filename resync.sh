#!/bin/bash

# --- CONFIGURATION ---
# Dynamically determine the script's location
BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Load configuration file
CONFIG_FILE="$BASE_DIR/config.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    echo "Please copy config.conf.template to config.conf and fill in your values."
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Validate required configuration variables
if [ -z "$LOCAL_PATH" ] || [ -z "$REMOTE_PATH" ]; then
    echo "ERROR: LOCAL_PATH and REMOTE_PATH must be set in config.conf"
    exit 1
fi

PATH1="$LOCAL_PATH"
PATH2="$REMOTE_PATH"

echo "=========================================================="
echo "PERFORMING DRY RUN"
echo "=========================================================="

# --- THE COMMAND (Flags listed for readability) ---
rclone bisync "$PATH1" "$PATH2" \
    --fast-list \
    --ignore-size \
    --check-access \
    --verbose \
    --resync \
    --resync-mode newer \
    --drive-acknowledge-abuse \
    --drive-export-formats desktop \
    --dry-run

echo ""
read -p "Do you want to proceed with the REAL RESYNC? (y/N): " confirm

if [[ "$confirm" == [yY] ]]; then
    echo "Proceeding..."
    # Running the same command without --dry-run
    rclone bisync "$PATH1" "$PATH2" \
        --fast-list \
        --ignore-size \
        --check-access \
        --verbose \
        --resync \
        --resync-mode newer \
        --drive-acknowledge-abuse \
        --drive-export-formats desktop \
        --exclude "/rclone-resync-backups/**"

    echo "Resync complete."
else
    echo "Cancelled."
fi
