import * as proxmox from '@muhlba91/pulumi-proxmoxve';

import OpenWRT from './services/openwrt';

export type Config = {
  ip: string;
  node_name: string;
  provider: proxmox.Provider;
  template_datastore: 'local';
  data_datastore: 'local-lvm';
};

export class Homelab {
  private _provider: proxmox.Provider;
  private _node_name: string;
  private readonly config: Config;

  constructor(
    ip: string,
    username: string,
    token_uuid: string,
    node_name: string
  ) {
    this._provider = new proxmox.Provider('proxmoxve', {
      endpoint: `https://${ip}:8006/`,
      insecure: true,
      username: username,
      apiToken: `${username}@pve!${username}-token=${token_uuid}`,
    });

    this._node_name = node_name;

    this.config = {
      ip,
      node_name,
      provider: this._provider,
      template_datastore: 'local',
      data_datastore: 'local-lvm',
    };
  }

  build_interfaces() {
    const interfaces = [
      new proxmox.network.NetworkBridge(
        'vmbr0',
        {
          nodeName: this.config.node_name,
          name: 'vmbr0',
          comment: 'Management',
          autostart: true,
          ports: ['enx00e04c680216'],
          address: '192.168.1.199/24',
          gateway: '192.168.1.254',
        },
        { provider: this.config.provider }
      ),
    ];
  }

  build() {
    this.build_interfaces();

    const openwrt = new OpenWRT(this.config);
    openwrt.build();

    // const talos = new TalosCluster(this.config);
    // talos.build();
  }
}
