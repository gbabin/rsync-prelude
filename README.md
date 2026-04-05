rsync-prelude
=============

Fix moved/renamed files before running rsync to avoid useless retransmissions.

Features
--------

- Respects rsync filters (uses rsync to get the list of candidate files)
- Works with remote hosts (using SSH)
- Plain Python 3
- Handles circular moves/renames (a -> b, b -> c, c -> a)
- Avoids computing hashsums if the filesize is unique in the set of files (then it cannot be a moved file)

Install
-------

- Manually: download and run `rsync-prelude`
- Using pip: `python -m pip install git+https://github.com/gbabin/rsync-prelude.git`

Prerequisites
-------------

- Python 3.7 or later

Usage
-----

```
rsync-prelude [-h] [--version] [-v] [-p [WIDTH]] [-q] [-s] [-e RSH] [-f FILTER_ARGS] [--hash-tool HASH_TOOL]
              [--mv-cmd MV_CMD] [--cp-cmd CP_CMD]
              SRC DEST

positional arguments:
  SRC                   source directory
  DEST                  destination directory

options:
  -h, --help            show this help message and exit
  --version             show program's version number and exit
  -v, --verbose         print internal actions and messages
  -p, --progress [WIDTH]
                        show current command (default width: 80)
  -q, --quiet           do not print actions taken
  -s, --script          just output script executing detected moves ('dry run')
  -e, --rsh RSH         rsync remote shell command to use (default: ssh)
  -f, --filter-args FILTER_ARGS
                        rsync args affecting file list
  --hash-tool HASH_TOOL
                        command to hash files. First word of the output must be the hash. It must
                        be available on both source and target host(s) (default: sha256sum)
  --mv-cmd MV_CMD       command used to move files (default: mv -n)
  --cp-cmd CP_CMD       command used to copy files (default: cp -n)
```

Example
-------

```shell
LOCAL_DATA_DIR=~/myfiles/
REMOTE_DATA_DIR=$BACKUP_HOST:~/mybackup/
RSH_CMD="ssh -p $BACKUP_PORT"
RSYNC_FILT_ARGS="-aup -FF"
RSYNC_ARGS="--info=progress2 --delete"

rsync-prelude -v -e "$RSH_CMD" -f " $RSYNC_FILT_ARGS" $LOCAL_DATA_DIR $REMOTE_DATA_DIR
rsync -v -e "$RSH_CMD" $RSYNC_ARGS $RSYNC_FILT_ARGS $LOCAL_DATA_DIR $REMOTE_DATA_DIR
```

License
-------

Distributed under the MIT License, see [LICENSE.md](LICENSE.md).

Acknowledgments
---------------

Derived from [rsync-prepare](https://gist.github.com/apirogov/c2253daf105d813349c6ae471e97a2d7).
