#!/usr/bin/env bash
set -euo pipefail

# download_models.sh
# Usage:
#   ./scripts/download_models.sh [--all] [--model NAME] [--dir DIR] [--yes]
# Downloads recommended models into $XDG_DATA_HOME/StemWeaver/models (or ~/.local/share/StemWeaver/models)

MODE=${1:-}
FORCE_NO_PROMPT=0
TARGET_DIR=${MODEL_DIR:-"${XDG_DATA_HOME:-$HOME/.local/share}/StemWeaver/models"}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all) MODE="all"; shift ;;
    --model) MODE="$2"; shift 2 ;;
    --url) MODE="url"; URL_VALUE="$2"; shift 2 ;;
    --dir) TARGET_DIR="$2"; shift 2 ;;
    --yes) FORCE_NO_PROMPT=1; shift ;;
    --help) echo "Usage: $0 [--all] [--model NAME] [--url URL] [--dir DIR] [--yes]"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

mkdir -p "$TARGET_DIR"
echo "Models will be stored in: $TARGET_DIR"

# Known model candidates (model name -> candidate URLs)
declare -A MODEL_CANDIDATES
MODEL_CANDIDATES[htdemucs_6s]="https://dl.fbaipublicfiles.com/demucs/htdemucs_6s.pth"
MODEL_CANDIDATES[htdemucs_ft]="https://dl.fbaipublicfiles.com/demucs/htdemucs_ft.pth"
# Add more as needed or allow users to pass explicit URLs

download_one() {
  local name="$1"
  local url="$2"
  # Choose output filename: if name has an extension, keep it; otherwise append .pth
  if [[ "$name" == *.* ]]; then
    local out="${TARGET_DIR}/${name}"
  else
    local out="${TARGET_DIR}/${name}.pth"
  fi
  local tmp="${out}.part"
  local logf="${TARGET_DIR}/download.log"

  if [ -f "$out" ]; then
    echo "Model $name already exists at $out, skipping." | tee -a "$logf"
    return 0
  fi
  echo "Attempting to download $name from $url" | tee -a "$logf"

  # Try curl with resume and retries first
  if command -v curl >/dev/null 2>&1; then
    if curl -L --fail --retry 5 --retry-delay 5 -C - -o "$tmp" "$url"; then
      mv "$tmp" "$out"
      echo "Downloaded $name -> $out" | tee -a "$logf"
      return 0
    else
      echo "curl failed to download $name from $url" | tee -a "$logf"
      rm -f "$tmp" || true
    fi
  fi

  # Fall back to wget with resume
  if command -v wget >/dev/null 2>&1; then
    if wget -c -O "$tmp" "$url"; then
      mv "$tmp" "$out"
      echo "Downloaded $name -> $out" | tee -a "$logf"
      return 0
    else
      echo "wget failed to download $name from $url" | tee -a "$logf"
      rm -f "$tmp" || true
    fi
  fi

  echo "Failed to download $name from $url (no suitable downloader or all retries failed)" | tee -a "$logf"
  return 1
}

run_for_model() {
  local model="$1"
  local url_arg="${2:-}"
  if [ -n "$url_arg" ]; then
    # Direct URL provided
    download_one "$model" "$url_arg" || return 1
  elif [ -n "${MODEL_CANDIDATES[$model]:-}" ]; then
    download_one "$model" "${MODEL_CANDIDATES[$model]}" || return 1
  else
    echo "No known URL for model '$model'. Use --url <URL> or add an entry in scripts/download_models.sh" >&2
    return 2
  fi
}

if [ "$MODE" = "" ]; then
  echo "No model specified. Use --all or --model NAME or --help"
  echo "Available models: ${!MODEL_CANDIDATES[*]}"
  exit 1
fi

if [ "$MODE" = "all" ]; then
  # Prompt user unless --yes
  echo "Models to download: ${!MODEL_CANDIDATES[*]}"
  if [ "$FORCE_NO_PROMPT" -eq 0 ]; then
    if [ -t 0 ]; then
      read -p "Proceed to download recommended models? [y/N] " ans
    else
      echo "Non-interactive session: use --yes to force downloads. Aborting." >&2
      exit 1
    fi
    case "$ans" in
      y|Y|yes|Yes) ;;
      *) echo "Aborted."; exit 0 ;;
    esac
  fi
  for m in "${!MODEL_CANDIDATES[@]}"; do
    run_for_model "$m" || echo "Warning: failed to download $m"
  done
  echo "Done. Models are in: $TARGET_DIR"
  exit 0
elif [ "$MODE" = "url" ]; then
  if [ -z "${URL_VALUE:-}" ]; then
    echo "Error: --url requires a URL value" >&2
    exit 2
  fi
  # derive name from URL
  NAME=$(basename "$URL_VALUE")
  run_for_model "$NAME" "$URL_VALUE" || exit 1
  exit $?
else
  # Single model name
  run_for_model "$MODE"
  exit $?
fi