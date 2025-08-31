import * as dotenv from 'dotenv';
import { Homelab } from './homelab';
import * as path from 'path';

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const ip = process.env.IP;
const username = 'pulumi';
const token_uuid = process.env.TOKEN;
const node_name = 'homelab';

if (!ip || !token_uuid) {
  console.error('Missing required environment variables');
  process.exit(1);
}

const homelab = new Homelab(ip, username, token_uuid, node_name);

homelab.build();
