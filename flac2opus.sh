#!/bin/bash

export BITRATE=96

function usage
{
	echo
	echo "Usage:"
	echo "    $0 FLAC_DIR LOSSY_DIR"
}

function encode
{
	#only encode if the encode is older than the original file.
	if [ "$FLAC_DIR"/"$1" -nt "$LOSSY_DIR"/"$(echo "$1" | sed 's/.flac/.opus/')" ]; then
		ARTIST=`metaflac "$FLAC_DIR"/"$1" --show-tag=ARTIST | sed s/.*=//`
		TITLE=`metaflac "$FLAC_DIR"/"$1" --show-tag=TITLE | sed s/.*=//g`
		ALBUM=`metaflac "$FLAC_DIR"/"$1" --show-tag=ALBUM | sed s/.*=//g`
		TRACKNUMBER=`metaflac "$FLAC_DIR"/"$1" --show-tag=TRACKNUMBER | sed s/.*=//g`
		DISCNUMBER=`metaflac "$FLAC_DIR"/"$1" --show-tag=DISCNUMBER | sed s/.*=//g`
		
		echo "encoding $1"
		flac -s -c -d "$FLAC_DIR"/"$1"| opusenc --quiet --artist "$ARTIST" --bitrate "$BITRATE"\
			--title "$TITLE" --comment "TRACKNUMBER=$TRACKNUMBER" --comment "DISCNUMBER=$DISCNUMBER" --album "$ALBUM" \
			- "$LOSSY_DIR"/"$(echo "$1" | sed 's/.flac/.opus/')"
	fi
}
export -f encode

#If user didn't provide 2 arguments, quit.
if [ "$#" -ne 2 ]; then
	usage
	exit
fi

export FLAC_DIR="$1"
export LOSSY_DIR="$2"

#If first argument isn't a directory, quit.
if [ ! -d "$FLAC_DIR" ]; then
	usage
	exit
fi

#if LOSSY_DIR doesn't exist, create it
if [ ! -d "$LOSSY_DIR" ]; then
	mkdir "$LOSSY_DIR"
fi

#recreate the folder structure in lossy
echo "Creating the folder structure."
find "$FLAC_DIR" -mindepth 1 -name \*.flac -printf '%P\n'|while read fname; do
	if [ ! -d "$LOSSY_DIR/$(dirname "$fname")" ]; then
		mkdir -p "$LOSSY_DIR/$(dirname "$fname")"
	fi
done

echo "Encoding missing songs."
find "$FLAC_DIR" -mindepth 1 -name \*.flac -printf '%P\n' | parallel --no-notice encode
