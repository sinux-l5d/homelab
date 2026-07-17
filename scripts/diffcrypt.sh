#!/bin/bash

[[ -z "$1" ]] && exit 1

# cd repo
cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1

echo "[THE FOLLOWING IS AUTOMAGICALLY ENTRYPTED]"
echo "[CHEK WITH \`git show ':$1'\`]"
./scripts/decrypt.sh "$1"
