rsync-prepare
=============

Fix moved/renamed files before running rsync to avoid useless retransmissions.

Features
--------

- it respects the rsync filters (uses rsync to get the file list of candidate files)
- it works with remote hosts (unlike [rsync-sidekick](https://github.com/m-manu/rsync-sidekick))
- it's plain Python 3, which is available basically everywhere
- it can detect circular moves/renames (a -> b, b -> c, c -> a)
- it avoids computing hashsums if the filesize is unique in the set of files (then it cannot be a moved file)

Usage
-----

```shell
function updatebackup() {
  LOCAL_DATA_DIR=~/myfiles
  RSH_CMD="ssh -p $BACKUP_HOST"
  RSYNC_FILT_ARGS="-aup -FF"
  RSYNC_ARGS="--info=progress2 --delete"
  rsync-prepare -v -e "$RSH_CMD" -f "$RSYNC_FILT_ARGS" $LOCAL_DATA_DIR $REMOTE_DATA_DIR
  rsync -v -e "$RSH_CMD" $RSYNC_ARGS $RSYNC_FILT_ARGS  $LOCAL_DATA_DIR $REMOTE_DATA_DIR
}
```
