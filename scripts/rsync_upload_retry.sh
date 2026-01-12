#!/usr/bin/env bash
set -euo pipefail

# rsync_upload_retry.sh
# Usage: ./scripts/rsync_upload_retry.sh /path/to/file [remote_user] [remote_path] [retries]
# Example:
#   ./scripts/rsync_upload_retry.sh StemWeaver-v1.1-x86_64.AppImage bendebcreations /home/frs/project/stemweaver/release1 6

FILE=${1:-}
REMOTE_USER=${2:-bendebcreations}
REMOTE_PATH=${3:-/home/frs/project/stemweaver/release1/}
RETRIES=${4:-6}
SLEEP_BASE=${SLEEP_BASE:-10} # seconds, backoff multiplier
SSH_ARGS=${SSH_ARGS:-"-o ServerAliveInterval=60 -o ServerAliveCountMax=5"}
RSYNC_OPTS=(--archive --verbose --partial --append-verify --progress)
RSYNC_SSH_OPTS=( -e "ssh $SSH_ARGS" )

if [ -z "$FILE" ]; then
  echo "Usage: $0 /path/to/file [remote_user] [remote_path] [retries]" >&2
  exit 2
fi

if [ ! -f "$FILE" ]; then
  echo "ERROR: File not found: $FILE" >&2
  exit 3
fi

BASENAME=$(basename "$FILE")
SHAFILE="$BASENAME.sha256"

# Generate sha256 locally if missing
if [ ! -f "$SHAFILE" ]; then
  echo "Generating local SHA256: $SHAFILE"
  sha256sum "$FILE" > "$SHAFILE"
else
  echo "Using existing SHA file: $SHAFILE"
fi

# Ensure remote dir exists (attempt via ssh)
echo "Ensuring remote directory exists: $REMOTE_USER@frs.sourceforge.net:$REMOTE_PATH"
ssh $SSH_ARGS "$REMOTE_USER@frs.sourceforge.net" "mkdir -p '$REMOTE_PATH'" || {
  echo "Warning: Could not create remote directory. You may need to create it via SourceForge web UI." >&2
}

attempt=1
while [ $attempt -le $RETRIES ]; do
  echo "\nAttempt $attempt/$RETRIES: rsync --append-verify"
  if rsync "${RSYNC_OPTS[@]}" -e "ssh $SSH_ARGS" "$FILE" "$REMOTE_USER@frs.sourceforge.net:$REMOTE_PATH"; then
    echo "File uploaded successfully (attempt $attempt)"
    # Upload sha file
    if rsync -av --progress -e "ssh $SSH_ARGS" "$SHAFILE" "$REMOTE_USER@frs.sourceforge.net:$REMOTE_PATH"; then
      echo "SHA file uploaded successfully"
    else
      echo "WARNING: SHA upload failed" >&2
    fi

    # Verify remote checksum
    echo "Verifying remote checksum..."
    VERIFY_CMD="cd '$REMOTE_PATH' && sha256sum -c '$SHAFILE'"
    if ssh $SSH_ARGS "$REMOTE_USER@frs.sourceforge.net" "$VERIFY_CMD"; then
      echo "Remote checksum verification succeeded. Upload complete."
      exit 0
    else
      echo "Remote checksum verification failed. Will retry (or check remote environment)." >&2
      # fall through to retry
    fi
  else
    echo "rsync attempt $attempt failed (connection or IO error)." >&2
  fi

  # Backoff before retry
  sleep_time=$((SLEEP_BASE * attempt))
  echo "Sleeping for $sleep_time seconds before retry..."
  sleep $sleep_time
  attempt=$((attempt + 1))
done

echo "ERROR: All $RETRIES upload attempts failed." >&2
exit 10
