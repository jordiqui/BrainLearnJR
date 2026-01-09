#!/bin/sh

wget_or_curl=$( (command -v wget > /dev/null 2>&1 && echo "wget -qO-") || \
                (command -v curl > /dev/null 2>&1 && echo "curl -skL"))


sha256sum=$( (command -v shasum > /dev/null 2>&1 && echo "shasum -a 256") || \
             (command -v sha256sum > /dev/null 2>&1 && echo "sha256sum"))

if [ -z "$sha256sum" ]; then
  >&2 echo "sha256sum not found, NNUE files will be assumed valid."
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
NNUE_DIR="${NNUE_DIR:-$REPO_ROOT/nnue}"
NNUE_OUTPUT_DIR="${NNUE_OUTPUT_DIR:-$REPO_ROOT}"
SHASUMS_FILE="${NNUE_DIR}/SHASUMS.txt"
NNUE_BIG_EXTRA_URLS="${NNUE_BIG_EXTRA_URLS:-https://tests.stockfishchess.org/api/nn/nn-95a8d78bdb5e.nnue https://tests.stockfishchess.org/api/nn/nn-4ca89e4b3abf.nnue}"

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
  if [ -n "$sha256sum" ] && [ -f "$SHASUMS_FILE" ]; then
    line="$(grep " $(basename "$1")$" "$SHASUMS_FILE" | tail -n 1)"
    if [ -n "$line" ]; then
      expected_sha="$(echo "$line" | awk '{print $1}')"
      expected_size="$(echo "$line" | awk '{print $2}')"
      actual_sha="$($sha256sum "$1" | awk '{print $1}')"
      actual_size="$(file_size "$1")"
      [ "$expected_sha" = "$actual_sha" ] && [ "$expected_size" = "$actual_size" ] && return 0
      rm -f "$1"
      return 1
    fi
  fi

  # If no sha256sum command is available, assume the file is always valid.
  if [ -n "$sha256sum" ] && [ -f "$1" ]; then
    if [ "$1" != "nn-$($sha256sum "$1" | cut -c 1-12).nnue" ]; then
      rm -f "$1"
      return 1
    fi
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

  if [ -z "$wget_or_curl" ]; then
    >&2 printf "%s\n" "Neither wget or curl is installed." \
          "Install one of these tools to download NNUE files automatically."
    exit 1
  fi

  for url in \
    "https://tests.stockfishchess.org/api/nn/$_filename" \
    "https://media.githubusercontent.com/media/official-stockfish/networks/master/$_filename" \
    "https://raw.githubusercontent.com/official-stockfish/networks/master/$_filename" \
    "https://github.com/official-stockfish/networks/raw/master/$_filename"; do
    echo "Downloading from $url ..."
    if $wget_or_curl "$url" > "$_dest"; then
      if validate_network "$_dest"; then
        echo "Successfully validated $_filename"
      else
        echo "Downloaded $_filename is invalid"
        continue
      fi
    else
      echo "Failed to download from $url"
    fi
    if [ -f "$_dest" ]; then
      update_shasums
      cp -f "$_dest" "$_output"
      return
    fi
  done

  # Download was not successful in the loop, return false.
  >&2 echo "Failed to download $_filename"
  return 1
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
  if $wget_or_curl "$_url" > "$_dest"; then
    if validate_network "$_dest"; then
      echo "Successfully validated $_filename"
    else
      echo "Downloaded $_filename is invalid"
      rm -f "$_dest"
      return 1
    fi
  else
    echo "Failed to download from $_url"
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
