# flac2opus - Converts directory tree of flac files to [opus](https://www.opus-codec.org/)
This script rebuilds an entire flac music library with the opus codec.
The folder hierarchy of the output is identical with the input.
Encoding is multithreaded for good performance.

## Usage
```
./flac2opus.sh path/to/flac path/to/lossy
```

## Dependencies
Flac, opus-tools, bash, GNU find, GNU parallel.
