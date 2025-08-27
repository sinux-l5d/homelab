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
    VM.PowerMgmt
)

pveum role add "${PROXMOX_USER_NAME}" -privs "${ROLES[*]}"
pveum user add "${PROXMOX_USER_ID}" -password "${PROXMOX_USER_PASSWORD}" -comment "${PROXMOX_USER_NAME} account"
pveum acl modify / -user "${PROXMOX_USER_ID}" -role "${PROXMOX_USER_NAME}"
pveum user token add "${PROXMOX_USER_ID}" "${PROXMOX_USER_NAME,,}-token" -expire 0 -privsep 0 -comment "${PROXMOX_USER_NAME} token" # privsep=0 means token has all privileged of user

# From https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pbs-install.sh
VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"

# This will set the correct sources to update
cat >/etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: ${VERSION} ${VERSION}-updates
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: ${VERSION}-security
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# The 'pve-enterprise' repository is only available to users who have purchased a Proxmox VE subscription.
for file in /etc/apt/sources.list.d/*.sources; do
  if grep -q "Components:.*pve-enterprise" "$file"; then
    rm -f "$file"
  fi
done

# The 'pve-no-subscription' repository provides access to all of the open-source components of Proxmox VE.
cat >/etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: ${VERSION}
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# The 'Ceph Package Repositories' provides access to both the 'no-subscription' and 'enterprise' repositories. Correct ceph package sources.
for file in /etc/apt/sources.list.d/*.sources; do
  if grep -q "enterprise.proxmox.com.*ceph" "$file"; then
    rm -f "$file"
  fi
done
cat >/etc/apt/sources.list.d/ceph.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: ${VERSION}
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# This will disable the nag message reminding you to purchase a subscription every time you log in to the web interface.
echo "DPkg::Post-Invoke { \"if [ -s /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then echo 'Removing subscription nag from UI...'; sed -i '/data\.status/{s/\\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi\" };" >/etc/apt/apt.conf.d/no-nag-script
apt --reinstall install proxmox-widget-toolkit &>/dev/null

# Disable unnecessary (for my usage) high availability services.
systemctl disable -q --now pve-ha-lrm
systemctl disable -q --now pve-ha-crm
systemctl disable -q --now corosync

# Update
apt-get update
apt-get -y dist-upgrade

apt-get install -y dnsmasq
systemctl disable --now dnsmasq

echo "Done. Please reboot now."
