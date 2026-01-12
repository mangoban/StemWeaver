#!/usr/bin/env bash
set -euo pipefail

# prepare_release.sh
# Generates SHA256 checksum and optional GPG signature, and prints SourceForge upload template.
# Usage: ./scripts/prepare_release.sh /path/to/StemWeaver-v1.1-x86_64.AppImage

APPIMAGE_PATH=${1:-"$(pwd)/StemWeaver-v1.1-x86_64.AppImage"}
APPIMAGE_NAME=$(basename "$APPIMAGE_PATH")
SHAFILE="$APPIMAGE_NAME.sha256"

if [ ! -f "$APPIMAGE_PATH" ]; then
  echo "ERROR: AppImage not found at: $APPIMAGE_PATH" >&2
  exit 2
fi

echo "Generating SHA256 for $APPIMAGE_NAME..."
sha256sum "$APPIMAGE_PATH" > "$SHAFILE"
echo "Wrote: $SHAFILE"

# Optional GPG signing
if command -v gpg >/dev/null 2>&1; then
  if [ -n "${GPG_KEY:-}" ]; then
    echo "Signing SHA file with GPG key: $GPG_KEY"
    gpg --default-key "$GPG_KEY" --armor --output "$SHAFILE.asc" --detach-sign "$SHAFILE"
    echo "Wrote: $SHAFILE.asc"
  else
    echo "gpg found but GPG_KEY env var not set; to sign set GPG_KEY and rerun." >&2
  fi
else
  echo "gpg not found; skipping signature creation." >&2
fi

cat <<'EOF'

SOURCEFORGE UPLOAD (example templates)

Manual web upload: Use your project's Files page on SourceForge and upload the AppImage and the .sha256 (and optionally .asc) file.

Rsync (example, replace placeholders):
  rsync -avP /path/to/StemWeaver-v1.1-x86_64.AppImage sf_user@frs.sourceforge.net:/home/frs/project/stemweaver/

SCP (example, replace placeholders):
  scp /path/to/StemWeaver-v1.1-x86_64.AppImage sf_user@upload.sourceforge.net:/home/project/web/htdocs/files/

Notes:
- SourceForge exact paths depend on your project settings; check SourceForge docs for the correct server/path or use the web UI.
- Use SSH keys for secure uploads. For automation, store credentials as CI secrets and use a runner or CI job.

EOF

echo "Release files ready:"
echo " - $APPIMAGE_PATH"
echo " - $SHAFILE"
[ -f "$SHAFILE.asc" ] && echo " - $SHAFILE.asc"

echo "Done."