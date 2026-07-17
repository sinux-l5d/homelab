#!/bin/bash

[[ -z "$1" ]] && exit 1

# cd repo
cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1

sops --decrypt "$1" 2>/dev/null || cat "$1"
