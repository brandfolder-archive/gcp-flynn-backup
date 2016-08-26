# gcp-flynn-backup
Automated backup of flynn

## Configuration
Configure the following environment variables.

* `BACKUP_TIMES=00:00` (comma delimited times to initiate a backup)
* `GOOGLE_CLOUD_STORAGE_BUCKET=flynn-backups`
* `FLYNN_CERTIFICATE_PIN=""``
* `FLYNN_CLUSTER_DOMAIN=""`
* `FLYNN_CONTROLLER_TOKEN=""`
* `GOOGLE_CREDENTIALS_ENCODED=""` (this value is the base64 encoded JSON account file)

## Deployment to a Flynn Cluster
To deploy to a flynn cluster run the following make command.

* `make push`
