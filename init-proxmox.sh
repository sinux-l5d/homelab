#!/bin/bash

# disable suspend on lid close (laptop only)
sed -i "s/^#HandleLidSwitch\([a-zA-Z]*\)=[a-z]*/HandleLidSwitch\1=ignore/" /etc/systemd/logind.conf

PROXMOX_USER_NAME="Pulumi"
PROXMOX_USER_ID="${PROXMOX_USER_NAME,,}@pve"
PROXMOX_USER_PASSWORD=$(cat /dev/urandom | tr -dc a-zA-Z0-9 | head -c 20)
echo "${PROXMOX_USER_NAME}'s password is \"${PROXMOX_USER_PASSWORD}\""

ROLES=(
    Datastore.Allocate
    Datastore.AllocateSpace
    Datastore.AllocateTemplate
    Datastore.Audit
    SDN.Use
    Sys.Audit
    Sys.Modify
    VM.Allocate
    VM.Audit
    VM.Clone
    VM.Config.CPU
    VM.Config.Cloudinit
    VM.Config.Disk
    VM.Config.HWType
    VM.Config.Memory
    VM.Config.Network
    VM.Config.Options
    VM.Monitor
    VM.PowerMgmt
)

pveum role add "${PROXMOX_USER_NAME}" -privs "${ROLES[*]}"
pveum user add "${PROXMOX_USER_ID}" -password "${PROXMOX_USER_PASSWORD}" -comment "${PROXMOX_USER_NAME} account"
pveum acl modify / -user "${PROXMOX_USER_ID}" -role "${PROXMOX_USER_NAME}"
pveum user token add "${PROXMOX_USER_ID}" "${PROXMOX_USER_NAME,,}-token" -expire 0 -privsep 0 -comment "${PROXMOX_USER_NAME} token" # privsep=0 means token has all privileged of user

# From https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pbs-install.sh
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

# This will set the correct sources to update and install Proxmox Backup Server.
cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian ${VERSION} main contrib
deb http://deb.debian.org/debian ${VERSION}-updates main contrib
deb http://security.debian.org/debian-security ${VERSION}-security main contrib
EOF
echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' >/etc/apt/apt.conf.d/no-${VERSION}-firmware.conf

# The 'pve-enterprise' repository is only available to users who have purchased a Proxmox VE subscription.
cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve ${VERSION} pve-enterprise
EOF

# The 'pve-no-subscription' repository provides access to all of the open-source components of Proxmox VE.
cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve ${VERSION} pve-no-subscription
EOF

# The 'Ceph Package Repositories' provides access to both the 'no-subscription' and 'enterprise' repositories. Correct ceph package sources.
cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb https://enterprise.proxmox.com/debian/ceph-quincy ${VERSION} enterprise
# deb http://download.proxmox.com/debian/ceph-quincy ${VERSION} no-subscription
# deb https://enterprise.proxmox.com/debian/ceph-reef ${VERSION} enterprise
# deb http://download.proxmox.com/debian/ceph-reef ${VERSION} no-subscription
EOF

# This will disable the nag message reminding you to purchase a subscription every time you log in to the web interface.
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/.*data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" >/etc/apt/apt.conf.d/no-nag-script
apt --reinstall install proxmox-widget-toolkit &>/dev/null

# Disable unnecessary (for my usage) high availability services.
systemctl disable -q --now pve-ha-lrm
systemctl disable -q --now pve-ha-crm
systemctl disable -q --now corosync

# Update
apt-get update
apt-get -y dist-upgrade

echo "Done. Please reboot now."
