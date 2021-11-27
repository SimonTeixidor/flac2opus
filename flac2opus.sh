#!/bin/bash
set -euo pipefail

credits="flac2opus.sh 0.1
Simon Persson <simon@flaskpost.me>

flac2opus.sh recursively encodes a directory of flac format files to opus,
recreating the same directory structure in the output directory. The tool does
partial updates, so that only new or modified files are (re-)encoded. Encodes
are removed if the original no longer exists. Album art is copied to the
encoded directory if its name matches {cover,folder}.{jpg,png}."

usage="Usage:
    $0 [options] <FLAC_DIR> <LOSSY_DIR>

Options:
    -h          Print this help page.
    -b <kbit/s> Set which bitrate to encode to.
    -f          Rename cover images to folder.{png,jpg} (these are recognized as album art on Android)
    -j <jobs>   Run up to <jobs> encoder processes in parallel."

COVER_REGEX='.*/\(cover\|folder\)\.\(jpg\|png\|gif\)$'
OPTIND=1
JOBS=$(nproc --all 2>/dev/null || echo 1)
export FOLDER_RENAME=0
export BITRATE=96

while getopts "hb:j:fs:" opt; do
	case "$opt" in
	h)
		printf "%s\n\n%s\n" "$credits" "$usage"
		exit 0
		;;
	b)
		BITRATE="$OPTARG"
		;;
	j)
		JOBS="$OPTARG"
		;;
	f)
		FOLDER_RENAME=1
		;;
	*) ;;

	esac
done
shift $((OPTIND - 1))

export FLAC_DIR="$1"
export LOSSY_DIR="$2"

ensure_dir() {
	if [ ! -d "$1" ]; then
		printf "Directory \"%s\" does not exist.\n\n%s\n" "$1" "$usage"
		exit 1
	fi
}

# Validate input
if [ "$#" -lt 2 ]; then
	printf "%s\n\n%s\n" "$credits" "$usage"
	exit 1
fi
ensure_dir "$FLAC_DIR"
ensure_dir "$LOSSY_DIR"

# Use parallelism, if requested
XARGS() {
	xargs -r0 -P "$JOBS" "$@"
}

# Encode a flac file at path relative to $FLAC_DIR.
encode() {
	FLAC="$FLAC_DIR/$1"
	OPUS="$LOSSY_DIR/${1%.*}.opus"
	if [ ! -f "$OPUS" ] || [ "$(stat -c '%Y' "$FLAC")" != "$(stat -c '%Y' "$OPUS")" ]; then
		opusenc --bitrate "$BITRATE" --quiet "$FLAC" "$OPUS" && touch -r "$FLAC" "$OPUS"
	fi
}
export -f encode

# Rename cover.{jpg,png} to folder.{jpg,png} if requested
folder_rename() {
	IN="$FLAC_DIR/$1"
	OUT="$LOSSY_DIR/$1"
	if [ "$FOLDER_RENAME" = "1" ]; then
		OUT="${OUT%cover.jpg}folder.jpg"
		OUT="${OUT%cover.png}folder.png"
	fi
	printf "%s\0%s\0" "$IN" "$OUT"
}
export -f folder_rename

# Create target folders.
find "$FLAC_DIR" -type d -printf "$LOSSY_DIR/%P\0" | XARGS mkdir -p

# Encode tracks
find "$FLAC_DIR" -type f -iname '*.flac' -printf "%P\0" | XARGS -I{} -n 1 bash -c 'encode "$@"' _ {}

# Copy covers
find "$FLAC_DIR" -type f -iregex "$COVER_REGEX" -printf "%P\0" |
	XARGS -I{} -n 1 bash -c 'folder_rename "$@"' _ {} |
	XARGS -n 2 cp --preserve -u

# Remove encodes if the original has been removed
comm -23 <(find "$LOSSY_DIR" -type f -iname '*.opus' -printf "%P\n" | sort) \
	<(find "$FLAC_DIR" -type f -iname '*.flac' -printf "%P\n" | sed 's/flac$/opus/' | sort) |
	XARGS -d '\n' -I{} rm "$LOSSY_DIR/{}"
