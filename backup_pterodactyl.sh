#!/bin/bash

# ==========================================
# KONFIGURASI
# ==========================================
# Nama remote rclone yang sudah diatur (contoh: gdrive, s3, megadrive)
RCLONE_REMOTE="remote-kalian"

# Folder tujuan di remote rclone
REMOTE_FOLDER="pterodactyl-backups"

# Directory volume Pterodactyl (default Wings)
SOURCE_DIR="/var/lib/pterodactyl/volumes"

# Direktori penyimpanan sementara lokal
TMP_DIR="/tmp/pterodactyl_backups"

# Nama file backup berdasarkan tanggal
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="pterodactyl_volumes_${DATE}.tar.gz"

# Hapus backup lokal lama yang lebih dari X hari (Opsional)
RETENTION_DAYS=7

# ==========================================
# PROSES BACKUP
# ==========================================

mkdir -p "$TMP_DIR"

echo "[$(date)] Memulai kompresi volume Pterodactyl..."
tar -czf "${TMP_DIR}/${BACKUP_FILE}" -C "$SOURCE_DIR" .

if [ $? -eq 0 ]; then
    echo "[$(date)] Kompresi berhasil. Mengunggah ke rclone ($RCLONE_REMOTE)..."
    
    rclone copy "${TMP_DIR}/${BACKUP_FILE}" "${RCLONE_REMOTE}:${REMOTE_FOLDER}" --progress
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] Upload ke rclone berhasil!"
    else
        echo "[$(date)] GAGAL mengunggah ke rclone."
    fi
else
    echo "[$(date)] GAGAL membuat kompresi archive."
fi

# Membersihkan file sementara di server lokal
rm -rf "${TMP_DIR}/${BACKUP_FILE}"

# Membersihkan file lama di remote rclone (Opsional)
rclone delete --min-age "${RETENTION_DAYS}d" "${RCLONE_REMOTE}:${REMOTE_FOLDER}"

echo "[$(date)] Proses backup selesai."
