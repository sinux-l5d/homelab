#!/bin/bash

[[ -z "$1" ]] && exit 1

# cd repo
cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1

sops --encrypt "$1" 2>/dev/null || ( [ "$?" -eq "203" ] && cat "$1" )
