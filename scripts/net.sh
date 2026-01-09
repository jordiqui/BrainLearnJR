#!/bin/sh

downloader=""
if command -v curl > /dev/null 2>&1; then
  downloader="curl"
elif command -v wget > /dev/null 2>&1; then
  downloader="wget"
fi

sha256sum=$( (command -v shasum > /dev/null 2>&1 && echo "shasum -a 256") || \
             (command -v sha256sum > /dev/null 2>&1 && echo "sha256sum"))

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
NNUE_DIR="${NNUE_DIR:-$REPO_ROOT/nnue}"
NNUE_OUTPUT_DIR="${NNUE_OUTPUT_DIR:-$REPO_ROOT}"
SHASUMS_FILE="${NNUE_DIR}/SHASUMS.txt"
NNUE_BIG_EXTRA_URLS="${NNUE_BIG_EXTRA_URLS:-https://tests.stockfishchess.org/api/nn/nn-95a8d78bdb5e.nnue https://tests.stockfishchess.org/api/nn/nn-4ca89e4b3abf.nnue}"
MIN_NNUE_SIZE="${MIN_NNUE_SIZE:-1048576}"

get_nnue_filename() {
  grep "$1" "$REPO_ROOT/src/evaluate.h" | grep "#define" | sed "s/.*\(nn-[a-z0-9]\{12\}.nnue\).*/\1/"
}

file_size() {
  if command -v stat > /dev/null 2>&1; then
    stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null
  else
    wc -c < "$1"
  fi
}

update_shasums() {
  if [ -z "$sha256sum" ]; then
    return 0
  fi

  mkdir -p "$NNUE_DIR"

  {
    for file in "$NNUE_DIR"/nn-*.nnue; do
      [ -f "$file" ] || continue
      sha="$($sha256sum "$file" | awk '{print $1}')"
      size="$(file_size "$file")"
      printf "%s  %s  %s\n" "$sha" "$size" "$(basename "$file")"
    done
  } > "$SHASUMS_FILE"
}

validate_network() {
  [ -f "$1" ] || return 1
  size="$(file_size "$1")"
  [ "$size" -gt "$MIN_NNUE_SIZE" ] || return 1
  magic="$(dd if="$1" bs=1 count=4 2>/dev/null)"
  [ "$magic" = "NNUE" ] || return 1
  return 0
}

download_url() {
  _url="$1"
  _dest="$2"
  if [ "$downloader" = "curl" ]; then
    curl -L --fail --retry 3 --retry-delay 2 --connect-timeout 20 -o "$_dest" "$_url"
  elif [ "$downloader" = "wget" ]; then
    wget -qO "$_dest" "$_url"
  else
    return 1
  fi
}

fetch_network() {
  _filename="$(get_nnue_filename "$1")"
  _dest="${NNUE_DIR}/$_filename"
  _output="${NNUE_OUTPUT_DIR}/$_filename"

  if [ -z "$_filename" ]; then
    >&2 echo "NNUE file name not found for: $1"
    return 1
  fi

  mkdir -p "$NNUE_DIR"

  if [ -f "$_output" ]; then
    if validate_network "$_output"; then
      echo "Existing $_filename validated, skipping download"
      return
    else
      echo "Removing invalid NNUE file: $_filename"
    fi
  fi

  if [ -f "$_dest" ]; then
    if validate_network "$_dest"; then
      echo "Existing $_filename validated in NNUE directory, copying"
      cp -f "$_dest" "$_output"
      return
    else
      echo "Removing invalid NNUE file: $_filename"
    fi
  fi

  if [ -z "$downloader" ]; then
    >&2 printf "%s\n" "Neither curl nor wget is installed." \
          "Install one of these tools to download NNUE files automatically," \
          "or place $_filename next to the executable."
    return 0
  fi

  for url in \
    "https://raw.githubusercontent.com/official-stockfish/networks/master/$_filename" \
    "https://media.githubusercontent.com/media/official-stockfish/networks/master/$_filename" \
    "https://tests.stockfishchess.org/api/nn/$_filename"; do
    echo "Downloading from $url ..."
    tmpfile="${_dest}.tmp.$$"
    if download_url "$url" "$tmpfile"; then
      if validate_network "$tmpfile"; then
        mv -f "$tmpfile" "$_dest"
        echo "Successfully validated $_filename"
        update_shasums
        cp -f "$_dest" "$_output"
        return 0
      else
        echo "Downloaded $_filename is invalid"
        rm -f "$tmpfile"
      fi
    else
      echo "Failed to download from $url"
      rm -f "$tmpfile"
    fi
  done

  # Download was not successful in the loop, return false.
  >&2 echo "NNUE download failed; please place $_filename next to the executable or run make net"
  return 0
}

fetch_network_url() {
  _url="$1"
  _filename="$(basename "$_url")"
  _dest="${NNUE_DIR}/$_filename"
  _output="${NNUE_OUTPUT_DIR}/$_filename"

  if [ -z "$_filename" ]; then
    >&2 echo "NNUE file name not found for URL: $_url"
    return 1
  fi

  mkdir -p "$NNUE_DIR"

  if [ -f "$_output" ] && validate_network "$_output"; then
    echo "Existing $_filename validated, skipping download"
    return 0
  fi

  if [ -f "$_dest" ] && validate_network "$_dest"; then
    echo "Existing $_filename validated in NNUE directory, copying"
    cp -f "$_dest" "$_output"
    return 0
  fi

  echo "Downloading from $_url ..."
  tmpfile="${_dest}.tmp.$$"
  if download_url "$_url" "$tmpfile"; then
    if validate_network "$tmpfile"; then
      mv -f "$tmpfile" "$_dest"
      echo "Successfully validated $_filename"
    else
      echo "Downloaded $_filename is invalid"
      rm -f "$tmpfile"
      return 1
    fi
  else
    echo "Failed to download from $_url"
    rm -f "$tmpfile"
    return 1
  fi

  update_shasums
  cp -f "$_dest" "$_output"
}

fetch_extra_networks() {
  for url in $1; do
    fetch_network_url "$url" || true
  done
}

fetch_network EvalFileDefaultNameBig && \
fetch_network EvalFileDefaultNameSmall

fetch_extra_networks "$NNUE_BIG_EXTRA_URLS"

update_shasums
