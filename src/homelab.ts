import * as proxmox from "@muhlba91/pulumi-proxmoxve";
import * as pulumi from "@pulumi/pulumi";

import OpenWRT from "./services/openwrt";

export type Config = {
  ip: string;
  node_name: string;
  provider: proxmox.Provider;
  template_datastore: "local";
}

export class Homelab {
  private _provider: proxmox.Provider;
  private _node_name: string;
  private readonly config: Config;

  constructor(
    ip: string,
    username: string,
    token_uuid: string,
    node_name: string,
  ) {
    this._provider = new proxmox.Provider("proxmoxve", {
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
      template_datastore: "local",
    }
  }

  build() {
    const openwrt = new OpenWRT(this.config);
    openwrt.build();
  }
}
