#!/usr/bin/env bash
set -euo pipefail
# Template to upload a file to SourceForge via rsync or scp
# Fill SF_USER and SF_PATH or run with environment variables set.

FILE=${1:-}
if [ -z "$FILE" ]; then
  echo "Usage: $0 /path/to/file [remote_path]"
  exit 1
fi

SF_USER=${SF_USER:-"your_sf_username"}
SF_PATH=${2:-"/home/frs/project/stemweaver/"}

echo "Uploading $FILE to SourceForge..."
# Example rsync (replace host/path if needed)
rsync -avP "$FILE" "$SF_USER@frs.sourceforge.net:$SF_PATH"

echo "Upload complete. Verify on SourceForge Files page."

echo "Tip: if rsync fails, upload via SourceForge web UI or verify your SSH key is added to your SourceForge account."