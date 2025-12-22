default:
    @just -l

tag VERSION:
    git tag -a -m "v${VERSION}" "v${VERSION}"

check-deps:
    -@command -v tofu >/dev/null || echo "opentofu not installed: deployment"
    -@command -v prek >/dev/null || echo "prek not installed: pre-commit hooks engine"
    -@command -v jq >/dev/null || echo "jq not installed: json parser"
    -@command -v incus >/dev/null || echo "incus not installed: cli client for IncusOS"
    -@command -v expect >/dev/null || echo "expect not installed: scripting interractive commands"
    -@command -v flasher-tool >/dev/null || echo "flasher-tool not installed: IncusOS tool to generate disk image"
    -@command -v yq >/dev/null || echo "yq not installed: yaml parser"

    -@yq --version | grep mikefarah/yq >/dev/null || echo "yq must be from github.com/mikefarah/yq"
    -@{{ justfile_dir() }}/scripts/semver_le.sh v1.10.7 $(tofu version | grep -oPm 1 'v\d+\.\d+\.\d+') || echo "opentofu must be >1.10.7"
    -@{{ justfile_dir() }}/scripts/semver_le.sh 6.19.1 $(incus --version) || echo "incus must be >6.19.1"

alias shutdown := poweroff

poweroff:
    echo "yes" | incus admin os system poweroff

reboot:
    echo "yes" | incus admin os system reboot

init-private:
    @git clone git@github.com:sinux-l5d/homelab-private.git '{{ justfile_dir() }}/infra-private' 2> /dev/null && test -d '{{ justfile_dir() }}/infra-private' || echo "failed to clone homelab-private"
