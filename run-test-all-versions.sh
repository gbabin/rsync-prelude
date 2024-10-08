#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

for py_ver_min in {7..13}
do
    cat <<EOF > Dockerfile
FROM python:3.${py_ver_min}-alpine
RUN apk update \
 && apk upgrade \
 && apk add bash coreutils rhash rsync \
 && rm -rf /var/cache/apk/*
COPY --chmod=555 mock-ssh /usr/bin/ssh
EOF
    docker build --tag rsync-prelude-test:3.${py_ver_min} .
    rm Dockerfile
    docker run --rm -v $(pwd):/rsync-prelude --workdir /rsync-prelude rsync-prelude-test:3.${py_ver_min} ./test.sh --minimal
done
