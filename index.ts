import * as pulumi from "@pulumi/pulumi";
import * as proxmox from "@muhlba91/pulumi-proxmoxve";

let endpoint = process.env.PROXMOX_VE_ENDPOINT;
let insecure = process.env.PROXMOX_VE_INSECURE;
let username = process.env.PROXMOX_VE_USERNAME;
let apiToken = process.env.PROXMOX_VE_TOKEN;

const provider = new proxmox.Provider("proxmoxve", {
  endpoint: endpoint,
  insecure: insecure == "true",
  username: username,
  apiToken: username + "@pve!" + username + "-token=" + apiToken,
});

// const user = new proxmox.permission.User(
//   "sinux",
//   {
//     comment: "Managed by Pulumi",
//     email: "sinux@pve",
//     enabled: false,
//     password: "tryme",
//     //expirationDate: new Date(Date.now() + 1 * 60 * 60 * 1000).toISOString(),
//     userId: "sinux@pve",
//   },
//   {
//     provider: provider,
//   },
// );
