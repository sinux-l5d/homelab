#!/bin/bash

set -ueo pipefail

diskid="${1-}"
this_dir=$(dirname "$(readlink -f "$0")")
root_dir=$(dirname "$this_dir")
local_iso=$(find "$root_dir" -name "IncusOS_*.img" | sort | tail -n1)

if [ -z "$diskid" ]; then
    echo "Usage: $0 <disk_id>"
    echo "  disk_id: is the ID of the disk to install to, found with ls -la /dev/disk/by-id/. E.g. : nvme-eui.123456789"
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Error: Invalid number of arguments."
    exit 1
fi

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Error: $1 is not installed."
        exit 1
    }
}

require_cmd incus
require_cmd flasher-tool
require_cmd yq # github.com/mikefarah/yq

incus remote generate-certificate 2> /dev/null || true

CRT=$(cat ~/.config/incus/client.crt) yq eval '.preseed.certificates[]
    |= select(.name == "me")
    |= .certificate=strenv(CRT)' \
    "$root_dir/seed.tmpl.yaml" > "$root_dir/seed.yaml"

if [ -z "$local_iso" ]; then
    "$this_dir/mkimg.exp" "$diskid"
else
    "$this_dir/mkimg.exp" "$diskid" "$local_iso"
fi
