## Generate image

1. On the computer you're planning to install IncusOS onto, find the drive ID you wish to install with `ls -la /dev/disk/by-id`.
2. Generate the image for this computer : `./scripts/mkimg.sh nvme-eui.XXXXX`
3. Copy to a usb stick (replace /dev/sda with actual device) `dd if=incusos_custom.img of=/dev/sda status=progress`
