#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

run() {
    test_id="$1"
    test_script="$2"
    test_dir="$3"
    test_src="$4"
    test_dst="$5"
    shift
    shift
    shift
    shift
    shift

    echo ":: [${test_id}] ${test_src} -> ${test_dst}"

    if [ -e test-root-tmp/source ]; then
        chmod -R +w test-root-tmp/source
        rm -r test-root-tmp
    fi

    mkdir -p test-root-tmp/source/folder
    pushd test-root-tmp/source/folder > /dev/null
    echo a > file1     ; touch -t 202211271401 file1
    echo ab > file2    ; touch -t 202211271401 file2
    echo abc > file3a  ; touch -t 202211271401 file3a
    echo 123 > file3b  ; touch -t 202211271401 file3b
    echo abcd > file4  ; touch -t 202211271401 file4
    echo abcde > file5 ; touch -t 202211271401 file5
    # cycle with different sizes (but some files with same date)
    echo cycle1 > c1   ; touch -t 202211271402 c1
    echo cycle22 > c2  ; touch -t 202211271403 c2
    echo cycle333 > c3 ; touch -t 202211271403 c3
    popd > /dev/null

    cp -r --preserve=timestamps test-root-tmp/source test-root-tmp/target

    sleep 2

    pushd test-root-tmp/source/folder > /dev/null
    mv -n file1 file1-renamed
    mv -n file3a file3a-renamed
    mkdir moved
    mv -n file2 moved/file2
    mkdir copy
    cp -n file4 copy/file4
    mv -n file4 file4-renamed
    mv -n c1 c0
    mv -n c2 c1
    mv -n c3 c2
    mv -n c0 c3
    popd > /dev/null

    chmod -R -w test-root-tmp/source

    sleep 2

    pushd "${test_dir}" > /dev/null
    if [ "${test_script}" = "y" ]; then
        "${RSYNC_PRELUDE}" -f ' --recursive' "$@" "${test_src}" "${test_dst}" | bash
    else
        "${RSYNC_PRELUDE}" -f ' --recursive' "$@" "${test_src}" "${test_dst}"
    fi
    set +e # because of grep
    remaining=$(rsync --dry-run --itemize-changes --recursive "${test_src}" "${test_dst}" | grep '^.f')
    rem_count=$(printf '%s' "$remaining" | grep -c '^')
    set -e
    popd > /dev/null

    if [ "$rem_count" -eq 0 ]
    then
        diff <(cd test-root-tmp/source; rhash -r -p '%c %s %{mtime} %p\n' .) \
             <(cd test-root-tmp/target; rhash -r -p '%c %s %{mtime} %p\n' .)
        echo "Test ${test_id} PASSED"
    else
        echo "== rsync diff =="
        echo "$remaining"
        echo "== rhash diff =="
        set +e
        diff <(cd test-root-tmp/source; rhash -r -p '%c %s %{mtime} %p\n' .) \
             <(cd test-root-tmp/target; rhash -r -p '%c %s %{mtime} %p\n' .)
        set -e
        echo "Test ${test_id} FAILED"
        exit 1
    fi
}

RSYNC_PRELUDE="$(pwd)/rsync-prelude"

run  1 n "."                  "test-root-tmp/source/folder"                  "test-root-tmp/target" -q
run  2 n "."                  "test-root-tmp/source/folder" "localhost:$(pwd)/test-root-tmp/target" -q
run  3 n "." "localhost:$(pwd)/test-root-tmp/source/folder"                  "test-root-tmp/target" -q

run  4 n "."                  "test-root-tmp/source/"                        "test-root-tmp/target" -q
run  5 n "."                  "test-root-tmp/source/"       "localhost:$(pwd)/test-root-tmp/target" -q
run  6 n "." "localhost:$(pwd)/test-root-tmp/source/"                        "test-root-tmp/target" -q

run  7 n "."                  "test-root-tmp/source/folder"                  "test-root-tmp/target/" -q
run  8 n "."                  "test-root-tmp/source/folder" "localhost:$(pwd)/test-root-tmp/target/" -q
run  9 n "." "localhost:$(pwd)/test-root-tmp/source/folder"                  "test-root-tmp/target/" -q

run 10 n "."                  "test-root-tmp/source/"                        "test-root-tmp/target/" -q
run 11 n "."                  "test-root-tmp/source/"       "localhost:$(pwd)/test-root-tmp/target/" -q
run 12 n "." "localhost:$(pwd)/test-root-tmp/source/"                        "test-root-tmp/target/" -q

run 13 n "test-root-tmp/source/folder" "./" "$(pwd)/test-root-tmp/target/folder/" -q
run 14 n "test-root-tmp/source/folder" "./" "$(pwd)/test-root-tmp/target/folder"  -q
run 15 n "test-root-tmp/source/folder" "."  "$(pwd)/test-root-tmp/target/folder/" -q
run 16 n "test-root-tmp/source/folder" "."  "$(pwd)/test-root-tmp/target/folder"  -q

run 17 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool md5sum
run 18 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool sha1sum
run 19 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool sha256sum
run 20 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool sha512sum
run 21 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool b2sum
run 22 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool 'cksum -a sha224 --untagged'
run 23 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool xxh128sum

run 24 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --mv-cmd mv
run 25 n "." "test-root-tmp/source/" "test-root-tmp/target/" -q --mv-cmd 'mv --no-clobber'

run 26 y "." "test-root-tmp/source/" "test-root-tmp/target/" --script
