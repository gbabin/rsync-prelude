#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [ $# -eq 1 ] && [ "$1" = "--minimal" ]; then
    scope=minimal
else
    scope=all
fi

run() {
    test_id="$1"; shift
    test_script="$1"; shift
    test_all="$1"; shift
    test_dir="$1"; shift
    test_src="$1"; shift
    test_dst="$1"; shift

    echo ":: [${test_id}] ${test_src} -> ${test_dst}"

    if [ "${scope}" = "minimal" ] && [ "${test_all}" = "all" ]; then
        echo "Test ${test_id} SKIPPED"
        return
    fi

    if [ -e test-root-tmp/source ]; then
        chmod -R +w test-root-tmp/source
        rm -r test-root-tmp
    fi

    mkdir -p test-root-tmp/source/folder
    pushd test-root-tmp/source/folder > /dev/null
    echo a > file1     ; touch -ct 202211271401 file1
    echo ab > file2    ; touch -ct 202211271401 file2
    echo abc > file3a  ; touch -ct 202211271401 file3a
    echo 123 > file3b  ; touch -ct 202211271401 file3b
    echo abcd > file4  ; touch -ct 202211271401 file4
    echo abcde > file5 ; touch -ct 202211271401 file5
    # cycle with different sizes (but some files with same date)
    echo cycle1 > c1   ; touch -ct 202211271402 c1
    echo cycle22 > c2  ; touch -ct 202211271403 c2
    echo cycle333 > c3 ; touch -ct 202211271403 c3
    popd > /dev/null

    cp -r --preserve=timestamps test-root-tmp/source test-root-tmp/target

    pushd test-root-tmp/source/folder > /dev/null
    mv -n file1 file1-renamed
    mv -n file3a file3a-renamed
    mkdir moved
    mv -n file2 moved/file2
    touch -ct 202301011201 moved
    mkdir copy
    cp -n file4 copy/file4 ; touch -ct 202301011202 copy/file4
    touch -ct 202301011203 copy
    mv -n file4 file4-renamed
    mv -n c1 c0
    mv -n c2 c1
    mv -n c3 c2
    mv -n c0 c3
    popd > /dev/null

    chmod -R -w test-root-tmp/source

    pushd "${test_dir}" > /dev/null
    if [ "${test_script}" = "script" ]; then
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
        diff <(cd test-root-tmp/source; rhash -r -p '%c %s %{mtime} %p\n' . | sort) \
             <(cd test-root-tmp/target; rhash -r -p '%c %s %{mtime} %p\n' . | sort)
        echo "Test ${test_id} PASSED"
    else
        echo "== rsync diff =="
        echo "$remaining"
        echo "== rhash diff =="
        set +e
        diff <(cd test-root-tmp/source; rhash -r -p '%c %s %{mtime} %p\n' . | sort) \
             <(cd test-root-tmp/target; rhash -r -p '%c %s %{mtime} %p\n' . | sort)
        set -e
        echo "Test ${test_id} FAILED"
        exit 1
    fi
}

RSYNC_PRELUDE="$(pwd)/rsync-prelude"

run  1 direct min "."                  "test-root-tmp/source/folder"                  "test-root-tmp/target" -q
run  2 direct min "."                  "test-root-tmp/source/folder" "localhost:$(pwd)/test-root-tmp/target" -q
run  3 direct min "." "localhost:$(pwd)/test-root-tmp/source/folder"                  "test-root-tmp/target" -q

run  4 direct min "."                  "test-root-tmp/source/"                        "test-root-tmp/target" -q
run  5 direct min "."                  "test-root-tmp/source/"       "localhost:$(pwd)/test-root-tmp/target" -q
run  6 direct min "." "localhost:$(pwd)/test-root-tmp/source/"                        "test-root-tmp/target" -q

run  7 direct min "."                  "test-root-tmp/source/folder"                  "test-root-tmp/target/" -q
run  8 direct min "."                  "test-root-tmp/source/folder" "localhost:$(pwd)/test-root-tmp/target/" -q
run  9 direct min "." "localhost:$(pwd)/test-root-tmp/source/folder"                  "test-root-tmp/target/" -q

run 10 direct min "."                  "test-root-tmp/source/"                        "test-root-tmp/target/" -q
run 11 direct min "."                  "test-root-tmp/source/"       "localhost:$(pwd)/test-root-tmp/target/" -q
run 12 direct min "." "localhost:$(pwd)/test-root-tmp/source/"                        "test-root-tmp/target/" -q

run 13 direct min "test-root-tmp/source/folder" "./" "$(pwd)/test-root-tmp/target/folder/" -q
run 14 direct min "test-root-tmp/source/folder" "./" "$(pwd)/test-root-tmp/target/folder"  -q
run 15 direct min "test-root-tmp/source/folder" "."  "$(pwd)/test-root-tmp/target/folder/" -q
run 16 direct min "test-root-tmp/source/folder" "."  "$(pwd)/test-root-tmp/target/folder"  -q

run 17 direct min "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool md5sum
run 18 direct min "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool 'sha1sum -b'
run 19 direct all "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool 'openssl dgst -r -sha256'
run 20 direct min "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool sha512sum
run 21 direct min "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool b2sum
run 22 direct min "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool 'cksum -a sha224 --untagged'
run 23 direct all "." "test-root-tmp/source/" "test-root-tmp/target/" -q --hash-tool xxh128sum

run 24 direct min "." "test-root-tmp/source/" "test-root-tmp/target/" -q --mv-cmd mv
run 25 direct min "." "test-root-tmp/source/" "test-root-tmp/target/" -q --mv-cmd 'mv --no-clobber'

run 26 script min "." "test-root-tmp/source/" "test-root-tmp/target/" --script
