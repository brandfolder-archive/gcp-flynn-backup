#!/usr/bin/env bash
set -e

# Setup Google Cloud Tools
echo "$GOOGLE_CREDENTIALS_ENCODED" | base64 -d | jq '.' > account.json
gcloud auth activate-service-account --key-file account.json --project `cat account.json | jq -r .project_id`

# Add Flynn Cluster
flynn cluster add -p $FLYNN_CERTIFICATE_PIN default $FLYNN_CLUSTER_DOMAIN $FLYNN_CONTROLLER_TOKEN

start-backups(){
  set -e

  # Backup filename
  filename="`date -Iseconds | sed -E "s/\+[0-9:]{0,}//"`-flynn-backup.tar"

  # Initiate Backup
  echo "initializing backup to '/tmp/$filename'"
  flynn cluster backup > "/tmp/$filename"

  # Create bucket if it doesnt exist
  gsutil mb gs://flynn-backups/ || true

  # Copy backup to bucket
  echo "uploading backup to google cloud bucket: '$GOOGLE_CLOUD_STORAGE_BUCKET'"
  gsutil cp "/tmp/$filename" gs://$FLYNN_BACKUP_DOMAIN/$GOOGLE_CLOUD_STORAGE_BUCKET/

  # Sleep until next
  echo "sleeping for $BACKUP_FREQUENCY seconds until next backup..."
  sleep $BACKUP_FREQUENCY
}

start-backups
