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

# Define log file path
LOG_FILE="$BASE_DIR/rclone-hourly-sync.log"

# --- LOGIN PROTECTION WITH RETRIES (3 tries, 5 min apart) ---
MAX_RETRIES=3
RETRY_DELAY=60*5
SUCCESS=false

for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Verifying connection to $PATH2 (Attempt $i/$MAX_RETRIES)..."
    
    # Check if we can talk to Google Drive
    if /usr/bin/rclone about "$PATH2" > /dev/null 2>&1; then
        SUCCESS=true
        echo "Connection verified."
        break
    fi

    if [ $i -lt $MAX_RETRIES ]; then
        echo "Connection failed (potential login/glitch). Retrying in $RETRY_DELAYs..."
        sleep $RETRY_DELAY
    fi
done

# If all retries failed, alert and exit safely
if [ "$SUCCESS" = false ]; then
    if [ -n "$NTFY_TOPIC" ]; then
        curl -H "Title: 🔑 Rclone Login Error" \
             -H "Priority: urgent" \
             -H "Tags: key,warning" \
             -d "Sync skipped on $(hostname). Google Drive is unreachable. 
The script exited safely to avoid a mandatory --resync." \
             ntfy.sh/$NTFY_TOPIC
    fi
    echo "ERROR: Unable to connect to $PATH2 after $MAX_RETRIES attempts. Exiting safely."
    exit 0
fi

# --- THE SYNC COMMAND ---
echo "Starting sync: $PATH1 <-> $PATH2"

# --- THE RCLONE COMMAND ---
/usr/bin/rclone bisync "$PATH1" "$PATH2" \
    --fast-list \
    --ignore-size \
    --check-access \
    --drive-acknowledge-abuse \
    --max-delete 100 \
    --conflict-resolve newer \
    --no-cleanup \
    --drive-export-formats desktop \
    --exclude "*.desktop" \
    --log-file="$LOG_FILE" \
    --log-level INFO

# --- ERROR CHECKING ---
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    # Get last 10 lines of log for context in the notification
    LOG_TAIL=$(tail -n 10 "$LOG_FILE")

    # Send ntfy notification if NTFY_TOPIC is configured
    if [ -n "$NTFY_TOPIC" ]; then
        curl -H "Title: 🚨 Rclone Sync Failed" \
             -H "Priority: urgent" \
             -H "Tags: warning,backup" \
             -d "Sync failed on $(hostname) at $(date '+%Y-%m-%d %H:%M')

Exit code: $EXIT_CODE

Last log entries:
$LOG_TAIL" \
             ntfy.sh/$NTFY_TOPIC
    fi

    echo "ERROR: Sync failed with exit code $EXIT_CODE"
    exit $EXIT_CODE
fi

echo "Sync completed successfully."
