import * as proxmox from "@muhlba91/pulumi-proxmoxve";
import { Config } from "../homelab";
import { Service } from ".";

class OpenWRT implements Service {
  // TODO: find replacement, supposed to be deprecated
  private readonly _URL = "https://fra1lxdmirror01.do.letsbuildthe.cloud/images/openwrt/23.05/amd64/default/20250112_11%3A57/rootfs.tar.xz";
  private readonly filename = /.*\/(\d+\.\d+)\/.*\/(\d{8}_\d\d%3A\d\d)\/.*/;
  private readonly config: Config;

  constructor(config: Config) {
    this.config = config;
  }

  build() {
    const internalNetwork = new proxmox.network.NetworkBridge(
      "vmbr1",
      {
        nodeName: this.config.node_name,
        name: "vmbr1",
        vlanAware: false,
      },
      { provider: this.config.provider },
    );

    let [_, version, builddate] = this.filename.exec(this._URL)!;
    let match = this.filename.exec(this._URL)!;
    builddate = builddate.replace("%3A", "").replace("_", "-");

    const rootfs = new proxmox.download.File(
      `openwrt_${version}_${builddate}`,
      {
        url: this._URL,
        checksumAlgorithm: "sha256",
        checksum:
          "e8b047e41fc22ddce48a0386616f45089fcd32b3043fad9f828876211b6f51bc",
        contentType: "vztmpl",
        datastoreId: this.config.template_datastore,
        nodeName: this.config.node_name,
      },
      { provider: this.config.provider },
    );
  }
}

export default OpenWRT;
