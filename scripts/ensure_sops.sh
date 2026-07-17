#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1

SHOULD_BE_ENCRYPTED=$(git diff --cached --name-only --diff-filter=ACM | xargs git check-attr filter 2>/dev/null| grep 'filter: sops' | cut -d: -f1)
EXIT_STATUS=0

if [ -n "$1" ]; then
    echo "RECEIVED: $1"
    echo "${SHOULD_BE_ENCRYPTED}" | grep "$1" > /dev/null || exit 0
    SHOULD_BE_ENCRYPTED="$1" # check the passed file only
fi

TEMP=$(mktemp -d)
trap "rm ${TEMP}" SIGKILL SIGTERM

while IFS= read -r file; do
    [ -z "${file}" ] && continue

    git show ":${file}" >> "${TEMP}/${file//\//-}"

    if ! sops --decrypt "${TEMP}/${file//\//-}" >/dev/null 2>&1; then
        echo "${file} is not sops-encrypted!"
        EXIT_STATUS=1
    fi
done <<< "${SHOULD_BE_ENCRYPTED}"

exit "$EXIT_STATUS"
