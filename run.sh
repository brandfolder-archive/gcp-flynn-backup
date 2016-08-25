#!/usr/bin/env bash
set -e

# Functions
backup-times() {
  set -e
  echo $BACKUP_TIMES | tr ',' "\n" | uniq | sort
}

current-time() {
  date +%H:%M
}

current-backup() {
  set -e
  backup-times | grep -o "^`current-time`$"
}

is-ten-min-mark() {
  set -e
  date +%M:%S | grep -oE "0:00$" > /dev/null
}

wait-for-backup() {
  set -e
  is-ten-min-mark || print-info "Waiting for next backup..."
  until current-backup > /dev/null ; do
    if is-ten-min-mark ; then print-info "Waiting for next backup..." ; fi
    sleep 0.75
  done
}

print-info() {
  echo '---------------------------------'
  if [ -n "$1" ] ; then
    echo "$1"
  fi
  echo "Current time: `current-time`"
  echo "Scheduled backup times are:"
  backup-times | sed "s/^/• /"
}

start-backups(){
  set -e

  wait-for-backup

  # Start next backup...
  echo '---------------------------------'
  echo "Starting `current-backup` scheduled backup..."

  # Backup filename
  filename="`date -Iminutes | sed -E "s/\+[0-9:]{0,}//"`-flynn-backup.tar"

  # Initiate Backup
  echo "Dumping backup to local file: '$filename'..."
  flynn cluster backup > "$filename"

  # Create bucket if it doesnt exist
  gsutil mb gs://$GOOGLE_CLOUD_STORAGE_BUCKET/ || true

  # Copy backup to bucket
  echo "Uploading backup to google cloud bucket: 'gs://$GOOGLE_CLOUD_STORAGE_BUCKET/$FLYNN_CLUSTER_DOMAIN'..."
  gsutil cp "$filename" "gs://$GOOGLE_CLOUD_STORAGE_BUCKET/$FLYNN_CLUSTER_DOMAIN/$filename"
  ln -s "./$filename" latest
  gsutil cp latest "gs://$GOOGLE_CLOUD_STORAGE_BUCKET/$FLYNN_CLUSTER_DOMAIN/latest"

  # Clean up
  echo "Removing local file: '$filename'..."
  rm -f "$filename"

  start-backups
}

# Setup Google Cloud Tools
echo "$GOOGLE_CREDENTIALS_ENCODED" | base64 -d | jq '.' > account.json
gcloud auth activate-service-account --key-file account.json --project `cat account.json | jq -r .project_id`

# Add Flynn Cluster
flynn cluster add -p $FLYNN_CERTIFICATE_PIN default $FLYNN_CLUSTER_DOMAIN $FLYNN_CONTROLLER_TOKEN

# Start Backups
start-backups
