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

  archive_info() {
    let [_, version, builddate] = this.filename.exec(this._URL)!;
    let match = this.filename.exec(this._URL)!;
    builddate = builddate.replace("%3A", "").replace("_", "-");

    const sha256file_url = this._URL.replace("rootfs.tar.xz", "SHA256SUMS");
    const rootfs_sum = fetch(sha256file_url).then(async res => {
      const body = await res.text();
      const cs = body.split("\n")
        .map((l) => l.split(" "))
        .filter(([_, file]) => file == "rootfs.tar.xz")
        .at(0)
        ?.at(0);
      if (!cs) return Promise.reject("Can't retrieve checksum");
      return cs;
    });

    return {
      version,
      builddate,
      checksum: rootfs_sum,
    }
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

    let { version, builddate, checksum } = this.archive_info();
    const rootfs = new proxmox.download.File(
      `openwrt_${version}_${builddate}`,
      {
        url: this._URL,
        fileName: "openwrt.tar.xz",
        checksumAlgorithm: "sha256",
        checksum,
        contentType: "vztmpl",
        datastoreId: this.config.template_datastore,
        nodeName: this.config.node_name,
      },
      { provider: this.config.provider },
    );

    const container = new proxmox.ct.Container(
      "openwrt-container",
      {
        nodeName: this.config.node_name,
        started: false,
        operatingSystem: {
          templateFileId: rootfs.id,
          type: "unmanaged",
        },
        unprivileged: true,
        initialization: {
          hostname: "openwrt",
        },
        networkInterfaces: [
          {
            name: "eth0",
            bridge: "vmbr0",
          },
          { name: "eth1", bridge: internalNetwork.name },
        ],
        disk: {
          datastoreId: this.config.data_datastore,
        },
      },
      { provider: this.config.provider },
    );
  }
}

export default OpenWRT;
