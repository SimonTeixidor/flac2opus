# flac2opus.sh
flac2opus.sh recursively encodes a directory of flac format files to opus,
recreating the same directory structure in the output directory. It makes use
of all CPU cores (or as many as you would like). The tool does partial updates,
so that only new or modified files are (re-)encoded. Encodes are removed if the
original no longer exists. Album art is copied to the encoded directory if its
name matches {cover,folder}.{jpg,png}.

## Usage
```
Usage:
    ./flac2opus.sh [options] <FLAC_DIR> <LOSSY_DIR>

Options:
    -h          Print this help page
    -b <kbit/s> Set which bitrate to encode to
    -j <jobs>   Run up to <jobs> encoder processes in parallel.
```

## Dependencies
Flac, opus-tools, bash.
