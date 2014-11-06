# flac2opus
This script rebuilds an entire flac music library with the opus codec.
The folder hierarchy is kept identical to the the original one.
Encoding is multithreaded for fast performance.

## Usage
```
./flac2opus.sh path/to/flac path/to/lossy
```

## Dependencies
Flac, opus-tools, bash, GNU find, GNU parallel.
