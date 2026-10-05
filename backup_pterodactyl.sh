#!/bin/bash
# ==========================================
# CONFIGURATION
# ==========================================
RCLONE_REMOTE="rclone_name" # Rclone remote name
REMOTE_FOLDER="pterodactyl-backups" # Destination folder on the rclone remote (optional)
SOURCE_DIR="/var/lib/pterodactyl/volumes" # Pterodactyl volume directory (default Wings)
TMP_DIR="/tmp/pterodactyl_backups" # Local temporary storage directory

# Backup file name based on date
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="pterodactyl_volumes_${DATE}.tar.gz"

# Delete old local backups older than X days (Optional)
RETENTION_DAYS=7

# ==========================================
# BACKUP PROCESS
# ==========================================

mkdir -p "$TMP_DIR"

echo "[$(date)] Starting Pterodactyl volume compression..."
tar -czf "${TMP_DIR}/${BACKUP_FILE}" -C "$SOURCE_DIR" .

if [ $? -eq 0 ]; then
    echo "[$(date)] Compression successful. Uploading to rclone ($RCLONE_REMOTE)..."
    
    rclone copy "${TMP_DIR}/${BACKUP_FILE}" "${RCLONE_REMOTE}:${REMOTE_FOLDER}" --progress
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] Upload to rclone successful!"
    else
        echo "[$(date)] FAILED to upload to rclone."
    fi
else
    echo "[$(date)] FAILED to create compressed archive."
fi

# Clean up temporary files on local server
rm -rf "${TMP_DIR}/${BACKUP_FILE}"

# Clean up old files on rclone remote (Optional)
rclone delete --min-age "${RETENTION_DAYS}d" "${RCLONE_REMOTE}:${REMOTE_FOLDER}"

echo "[$(date)] Backup process completed."
