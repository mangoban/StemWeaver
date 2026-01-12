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
    --dir) TARGET_DIR="$2"; shift 2 ;;
    --yes) FORCE_NO_PROMPT=1; shift ;;
    --help) echo "Usage: $0 [--all] [--model NAME] [--dir DIR] [--yes]"; exit 0 ;;
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
  local out="${TARGET_DIR}/${name}.pth"
  if [ -f "$out" ]; then
    echo "Model $name already exists at $out, skipping."
    return 0
  fi
  echo "Attempting to download $name from $url"
  if command -v curl >/dev/null 2>&1; then
    if curl -L --fail -o "$out" "$url"; then
      echo "Downloaded $name -> $out"
      return 0
    else
      rm -f "$out" || true
      echo "Failed to download $name from $url"
      return 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -O "$out" "$url"; then
      echo "Downloaded $name -> $out"
      return 0
    else
      rm -f "$out" || true
      echo "Failed to download $name from $url"
      return 1
    fi
  else
    echo "Error: neither curl nor wget available to download models" >&2
    return 2
  fi
}

run_for_model() {
  local model="$1"
  if [ -n "${MODEL_CANDIDATES[$model]:-}" ]; then
    download_one "$model" "${MODEL_CANDIDATES[$model]}" || return 1
  else
    echo "No known URL for model '$model'. Use --model URL or add an entry in scripts/download_models.sh" >&2
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
    read -p "Proceed to download recommended models? [y/N] " ans
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
else
  # Single model
  run_for_model "$MODE"
  exit $?
fi