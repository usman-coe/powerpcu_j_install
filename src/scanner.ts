import net from "node:net";
import os from "node:os";
import { color, info, ok, warn } from "./ui";

export interface MysqlServer {
  host: string;
  port: number;
  versionHint?: string;
}

interface Subnet {
  iface: string;
  localIp: string;
  base: string;
  size: number;
}

const DEFAULT_TIMEOUT_MS = 800;
const HANDSHAKE_TIMEOUT_MS = 1500;

export function discoverSubnets(): Subnet[] {
  const result: Subnet[] = [];
  const ifaces = os.networkInterfaces();
  for (const [name, addrs] of Object.entries(ifaces)) {
    for (const a of addrs ?? []) {
      if (a.family !== "IPv4" || a.internal) continue;
      const parts = a.address.split(".");
      if (parts.length !== 4) continue;
      result.push({
        iface: name,
        localIp: a.address,
        base: `${parts[0]}.${parts[1]}.${parts[2]}.`,
        size: 254,
      });
    }
  }
  return result;
}

function probeMysql(host: string, port: number): Promise<MysqlServer | null> {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    let settled = false;
    const finish = (val: MysqlServer | null) => {
      if (settled) return;
      settled = true;
      socket.removeAllListeners();
      socket.destroy();
      resolve(val);
    };

    let connected = false;
    socket.setTimeout(DEFAULT_TIMEOUT_MS);
    socket.once("connect", () => {
      connected = true;
      socket.setTimeout(HANDSHAKE_TIMEOUT_MS);
    });
    socket.once("data", (chunk: Buffer | string) => {
      const buf = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
      // MySQL v10 handshake: [3 bytes len][1 byte seq][1 byte protocol=10][version null-terminated]
      if (!connected || buf.length < 6 || buf[4] !== 0x0a) {
        finish(null);
        return;
      }
      const end = buf.indexOf(0x00, 5);
      const versionHint = end > 5 ? buf.subarray(5, end).toString("utf8") : undefined;
      finish({ host, port, versionHint });
    });
    socket.once("timeout", () => finish(null));
    socket.once("error", () => finish(null));
    socket.connect(port, host);
  });
}

export async function scanLan(port: number): Promise<MysqlServer[]> {
  const subnets = discoverSubnets();
  if (subnets.length === 0) {
    warn("ไม่พบ network interface แบบ IPv4");
    return [];
  }

  const found = new Map<string, MysqlServer>();
  for (const sub of subnets) {
    info(
      `สแกน subnet ${color.cyan}${sub.base}0/24${color.reset} ผ่าน ${color.cyan}${sub.iface}${color.reset} (local=${sub.localIp})`,
    );
    const tasks: Promise<MysqlServer | null>[] = [];
    for (let i = 1; i <= sub.size; i++) {
      const host = `${sub.base}${i}`;
      if (host === sub.localIp) continue;
      tasks.push(probeMysql(host, port));
    }
    const results = await Promise.all(tasks);
    for (const r of results) {
      if (r && !found.has(r.host)) {
        found.set(r.host, r);
        ok(
          `พบ MySQL ที่ ${color.bold}${r.host}:${r.port}${color.reset}` +
            (r.versionHint ? ` (version: ${r.versionHint})` : ""),
        );
      }
    }
  }
  return [...found.values()];
}
