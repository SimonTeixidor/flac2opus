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
	if [ ! -f "$LOSSY_DIR"/"$(echo "$1" | sed 's/.flac/.opus/')" ]; then
		ARTIST=`metaflac "$FLAC_DIR"/"$1" --show-tag=ARTIST | sed s/.*=//`
		TITLE=`metaflac "$FLAC_DIR"/"$1" --show-tag=TITLE | sed s/.*=//g`
		ALBUM=`metaflac "$FLAC_DIR"/"$1" --show-tag=ALBUM | sed s/.*=//g`
		TRACKNUMBER=`metaflac "$FLAC_DIR"/"$1" --show-tag=TRACKNUMBER | sed s/.*=//g`
		DISCNUMBER=`metaflac "$FLAC_DIR"/"$1" --show-tag=DISCNUMBER | sed s/.*=//g`
		
		echo "encoding $1"
		flac -s -c -d "$FLAC_DIR"/"$1"| opusenc --quiet --artist "$ARTIST" --bitrate "$BITRATE"\
			--title "$TITLE" --comment "TRACKNUMBER=$TRACKNUMBER" --comment "DISCNUMBER=$DISCNUMBER" --album "$ALBUM" \
			- "$LOSSY_DIR"/"$(echo "$1" | sed 's/\.flac$/\.opus/')"
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
diff --new-line-format="" --unchanged-line-format="" \
  <(find $FLAC_DIR -mindepth 2 -maxdepth 2 -type d -printf '%P\n' | sort) \
  <(find $LOSSY_DIR -mindepth 2 -maxdepth 2 -type d -printf '%P\n' | sort) |while read fname; do
	mkdir -p "$LOSSY_DIR/$fname"
done

echo "Encoding missing songs."
diff --new-line-format="" --unchanged-line-format="" \
  <(find $FLAC_DIR -mindepth 1 -name \*.flac -printf '%P\n' | sort) \
  <(find $LOSSY_DIR -mindepth 1 -name \*.opus -printf '%P\n' | sed 's/\.opus$/\.flac/g' | sort) \
  | parallel --no-notice encode

echo "Copying cover.jpg and folder.jpg"
diff --new-line-format="" --unchanged-line-format="" \
  <(find $FLAC_DIR -mindepth 1 -name cover.jpg -o -name folder.jpg -printf '%P\n' | sort) \
  <(find $LOSSY_DIR -mindepth 1 -name cover.jpg -o -name folder.jpg -printf '%P\n' | sort) \
  | while read f; do
	cp "$FLAC_DIR/$f" "$LOSSY_DIR/$f"
done
