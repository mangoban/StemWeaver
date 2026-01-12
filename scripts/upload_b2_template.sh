#!/usr/bin/env bash
# Template script for uploading a file to Backblaze B2 using aws cli (s3-compatible)
# Requires: aws cli configured with B2 endpoint or rclone configured
# Usage: ./scripts/upload_b2_template.sh /path/to/StemWeaver-v1.1-x86_64.AppImage my-bucket-name

set -euo pipefail
FILE=${1:-}
BUCKET=${2:-}
DEST=${3:-}

if [ -z "$FILE" ] || [ -z "$BUCKET" ]; then
  echo "Usage: $0 /path/to/file bucket-name [dest-path]"
  exit 1
fi

# Example using rclone (recommended):
# rclone copy "$FILE" remote:bucket-name/path/

# Example using aws cli with B2 S3 endpoint (configure AWS env variables first):
# AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... AWS_REGION=us-west-000 aws --endpoint-url https://s3.us-west-000.backblazeb2.com s3 cp "$FILE" s3://$BUCKET/${DEST:-$(basename "$FILE")}

echo "Upload template complete. Replace placeholders with your credentials and run."