rsync-prelude
=============

Fix moved/renamed files before running rsync to avoid useless retransmissions.

Features
--------

- it respects the rsync filters (uses rsync to get the file list of candidate files)
- it works with remote hosts (unlike [rsync-sidekick](https://github.com/m-manu/rsync-sidekick))
- it's plain Python 3, which is available basically everywhere
- it can detect circular moves/renames (a -> b, b -> c, c -> a)
- it avoids computing hashsums if the filesize is unique in the set of files (then it cannot be a moved file)

Prerequisites
-------------

- Python 3.7 or later

Usage
-----

```
rsync-prelude [-h] [-v] [-q] [-s] [-e RSH] [-f FILTER_ARGS] [--hash-tool HASH_TOOL]
              [--mv-cmd MV_CMD] [--cp-cmd CP_CMD]
              SRC DEST

options:
  -h, --help            show this help message and exit
  -v, --verbose
  -q, --quiet           Do not print actions taken (default: False)
  -s, --script          Just output script executing detected moves ('dry run') (default: False)
  -e RSH, --rsh RSH     rsync remote shell command to use (default: ssh)
  -f FILTER_ARGS, --filter-args FILTER_ARGS
                        rsync args affecting file list
  --hash-tool HASH_TOOL
                        Command to hash files. First word of the output must be the hash. It must
                        be available on both source and target host(s) (default: sha256sum)
  --mv-cmd MV_CMD       Command used to move files (default: mv -n)
  --cp-cmd CP_CMD       Command used to copy files (default: cp -n)
```

Example
-------

```shell
function updatebackup() {
  LOCAL_DATA_DIR=~/myfiles
  RSH_CMD="ssh -p $BACKUP_HOST"
  RSYNC_FILT_ARGS="-aup -FF"
  RSYNC_ARGS="--info=progress2 --delete"
  rsync-prelude -v -e "$RSH_CMD" -f "$RSYNC_FILT_ARGS" $LOCAL_DATA_DIR $REMOTE_DATA_DIR
  rsync -v -e "$RSH_CMD" $RSYNC_ARGS $RSYNC_FILT_ARGS  $LOCAL_DATA_DIR $REMOTE_DATA_DIR
}
```

License
-------

Distributed under the MIT License, see [LICENSE.md](LICENSE.md).

Acknowledgments
---------------

Derived from [rsync-prepare](https://gist.github.com/apirogov/c2253daf105d813349c6ae471e97a2d7).
