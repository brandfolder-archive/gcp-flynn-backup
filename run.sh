#!/usr/bin/env bash
set -e

# Functions
backup-times() {
  set -e
  echo $BACKUP_TIMES | tr ',' "\n"
}

current-backup() {
  set -e
  backup-times | uniq | grep -o "^`date +%H:%M`$"
}

start-backups(){
  set -e

  # Sleep until next backup
  echo "Waiting for next backup..."
  until current-backup ; do sleep 1 ; done > /dev/null

  # Start next backup...
  echo "Starting `current-backup` scheduled backup..."

  # Backup filename
  filename="`date -Iseconds | sed -E "s/\+[0-9:]{0,}//"`-flynn-backup.tar"

  # Initiate Backup
  echo "Dumping backup to local file: '/tmp/$filename'..."
  flynn cluster backup > "/tmp/$filename"

  # Create bucket if it doesnt exist
  gsutil mb gs://$GOOGLE_CLOUD_STORAGE_BUCKET/ || true

  # Copy backup to bucket
  echo "Uploading backup to google cloud bucket: 'gs://$GOOGLE_CLOUD_STORAGE_BUCKET/$FLYNN_CLUSTER_DOMAIN'..."
  gsutil cp "/tmp/$filename" "gs://$GOOGLE_CLOUD_STORAGE_BUCKET/$FLYNN_CLUSTER_DOMAIN"

  # Clean up
  echo "Removing local file: '/tmp/$filename'..."
  rm -f "/tmp/$filename"

  start-backups
}

# Setup Google Cloud Tools
echo "$GOOGLE_CREDENTIALS_ENCODED" | base64 -d | jq '.' > account.json
gcloud auth activate-service-account --key-file account.json --project `cat account.json | jq -r .project_id`

# Add Flynn Cluster
flynn cluster add -p $FLYNN_CERTIFICATE_PIN default $FLYNN_CLUSTER_DOMAIN $FLYNN_CONTROLLER_TOKEN

# Start Backups
echo "Starting backup job!"
echo "Schduled backup times are:"
backup-times
start-backups
