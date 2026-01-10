# Rclone Google Drive Sync Scripts

A collection of bash scripts for synchronizing local directories with Google Drive using `rclone bisync`.

## Scripts

- **`sync.sh`** - Main synchronization script designed to be run via cron. Performs bidirectional sync between local and remote directories.
- **`resync.sh`** - Resync script for resolving sync conflicts. Performs a dry-run first, then prompts for confirmation before executing.

## Prerequisites

- [rclone](https://rclone.org/) installed and configured
- A configured rclone remote pointing to your Google Drive
- `curl` installed (for ntfy.sh notifications, optional)

## Setup

1. **Clone or download this repository**

2. **Create your configuration file**
   ```bash
   cp config.conf.template config.conf
   ```

3. **Edit `config.conf` with your personal values**
   ```bash
   nano config.conf  # or use your preferred editor
   ```
   
   Fill in:
   - `LOCAL_PATH`: Your local directory path (e.g., `/home/user/sync-drive/`)
   - `REMOTE_PATH`: Your rclone remote name and path (e.g., `gdrive:/`)
   - `NTFY_TOPIC`: Optional ntfy.sh topic for notifications (leave empty to disable)

4. **Make scripts executable**
   ```bash
   chmod +x sync.sh resync.sh
   ```

5. **Test the sync script manually**
   ```bash
   ./sync.sh
   ```

## Usage

### Regular Synchronization (Cron)

Add to your crontab for hourly synchronization:
```bash
crontab -e
```

Add this line (adjust the path as needed):
```
0 * * * * /path/to/google_drive_sync/sync.sh >> /path/to/google_drive_sync/cron.log 2>&1
```

### Resync (Conflict Resolution)

When you need to resolve sync conflicts:
```bash
./resync.sh
```

The script will:
1. Perform a dry-run to show what would be synced
2. Prompt for confirmation
3. Execute the resync if confirmed

## Configuration

The `config.conf` file contains all personal settings:
- **LOCAL_PATH**: Local directory to sync
- **REMOTE_PATH**: Rclone remote path (format: `remote_name:/`)
- **NTFY_TOPIC**: Optional ntfy.sh topic for error notifications

## Notifications

If `NTFY_TOPIC` is configured in `config.conf`, the sync script will send notifications via ntfy.sh when sync failures occur. To disable notifications, leave `NTFY_TOPIC` empty.

## Logs

Sync logs are written to `rclone-hourly-sync.log` in the script directory. Log files are gitignored.
