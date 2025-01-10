set dotenv-required

export PROXMOX_VE_ENDPOINT := 'https://' + env('ip') + ':8006/'
export PROXMOX_VE_TOKEN := 'pulumi@pve!pulumi=' + env('token')
export PROXMOX_VE_USERNAME := 'pulumi'
export PROXMOX_VE_INSECURE := 'true'

run:
    pulumi up
