## Prerequisites
A hardware that support :
- Secure boot support
- TPM 2.0 support

Check all dependencies are installed with [`just check-deps`](https://github.com/casey/just).

## Generating image

1. On the computer you're planning to install IncusOS onto, find the drive ID you wish to install with `ls -la /dev/disk/by-id`.
2. Generate the image for your computer : `./scripts/mkimg.sh nvme-eui.XXXXX`. This will :
  1. use `incus remote generate-certificate` to set up the initial key.
  2. use `seed.tmpl.yaml` as base seed, adding the initial key.
  3. use `github.com/lxc/incus-os/incus-osd/cmd/flasher-tool` to create the image, with options like wipe target disk, don't install Ceph nor Linstor and don't reboot automatically
3. Copy to a usb stick (replace /dev/sda with actual device) `dd if=incusos_custom.img of=/dev/sda status=progress`

## Installing the OS

Before installing, Secure Boot must be in setup mode in order to enrole IncusOS keys. When booting on the USB stick for the first time, it will add the keys before rebooting in installation mode.

## Setting up
Once installed, from local computer containing the initial key :
1. `incus remote add lab1 <ip>` to add the homelab to your remotes.
2. `incus remote switch lab1` to set it as the default. If not done, add `lab1:` in every command where `[remote:]` is needed.
3. Make sure an interface will provide access to the home network to instances by adding `.config.interfaces[n].roles = ["instances"]` in `incus admin os system network edit` as [described here](https://linuxcontainers.org/incus-os/docs/main/tutorials/network-direct-attach/). Also set the correct timezone in `.config.time.timezone`, e.g. `Europe/Paris`.
4. Get the recovery keys [as described in the documentation](https://linuxcontainers.org/incus-os/docs/main/getting-started/access/#fetching-the-encryption-recovery-key) with `incus admin os system security show > very-sensitive.yaml` and save this file some place safe.


## Deploying with OpenTofu
To deploy with a local file state, just use `tofu apply` from a directory containing `.tf` files, review, and say `yes`.

## Accessing the web UI

First generate the PKCS12 certificate :
```bash
openssl pkcs12 -export -inkey ~/.config/incus/client.key -in ~/.config/incus/client.crt -out ~/.config/incus/client.pfx
```

To see what's in the pfx file :
```bash
openssl pkcs12 -nodes -in ~/.config/incus/client.pfx # no password
```

Then add this `client.pfx` file to your browser's trusted certificates.
