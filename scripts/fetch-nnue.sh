#!/usr/bin/env sh

set -eu

downloader=""
if command -v curl >/dev/null 2>&1; then
  downloader="curl"
elif command -v wget >/dev/null 2>&1; then
  downloader="wget"
else
  echo "Error: curl or wget is required to download NNUE files." >&2
  exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
NETWORKS_DIR="${NNUE_DIR:-$REPO_ROOT/src/networks}"

NNUE_FILES="nn-2962dca31855.nnue nn-37f18f62d772.nnue"
BASE_URLS="https://raw.githubusercontent.com/official-stockfish/networks/master
https://media.githubusercontent.com/media/official-stockfish/networks/master
https://tests.stockfishchess.org/api/nn"

download_url() {
  _url="$1"
  _dest="$2"

  if [ "$downloader" = "curl" ]; then
    curl -L --fail --retry 3 --retry-delay 2 --connect-timeout 20 -o "$_dest" "$_url"
  else
    wget -qO "$_dest" "$_url"
  fi
}

is_valid_nnue() {
  [ -s "$1" ] || return 1
  magic="$(dd if="$1" bs=1 count=4 2>/dev/null || true)"
  [ "$magic" = "NNUE" ]
}

mkdir -p "$NETWORKS_DIR"

for file in $NNUE_FILES; do
  dest="$NETWORKS_DIR/$file"
  if is_valid_nnue "$dest"; then
    echo "Found $file in $NETWORKS_DIR"
    continue
  fi
  if [ -f "$dest" ]; then
    echo "Removing invalid $file from $NETWORKS_DIR"
    rm -f "$dest"
  fi

  success=0
  for base in $BASE_URLS; do
    url="$base/$file"
    tmp="${dest}.tmp.$$"
    echo "Downloading $file from $url ..."
    if download_url "$url" "$tmp"; then
      if is_valid_nnue "$tmp"; then
        mv -f "$tmp" "$dest"
        echo "Saved $file to $NETWORKS_DIR"
        success=1
        break
      else
        echo "Downloaded $file is invalid." >&2
        rm -f "$tmp"
      fi
    fi
    rm -f "$tmp"
  done

  if [ "$success" -ne 1 ]; then
    echo "Error: failed to download $file." >&2
    exit 1
  fi
done
