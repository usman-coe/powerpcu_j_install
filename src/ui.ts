const ESC = "\x1b[";
export const color = {
  reset: `${ESC}0m`,
  bold: `${ESC}1m`,
  dim: `${ESC}2m`,
  red: `${ESC}31m`,
  green: `${ESC}32m`,
  yellow: `${ESC}33m`,
  blue: `${ESC}34m`,
  magenta: `${ESC}35m`,
  cyan: `${ESC}36m`,
  white: `${ESC}37m`,
  gray: `${ESC}90m`,
};

export function banner(): void {
  const line = "═".repeat(64);
  console.log(`${color.cyan}${line}${color.reset}`);
  console.log(`${color.bold}${color.cyan}   PowerPCU - JHCIS Client Installer${color.reset}`);
  console.log(`${color.gray}   ติดตั้งโปรแกรม jhcis เฉพาะเครื่องลูก (Client)${color.reset}`);
  console.log(`${color.cyan}${line}${color.reset}`);
}

export function info(msg: string): void {
  console.log(`${color.blue}[i]${color.reset} ${msg}`);
}

export function ok(msg: string): void {
  console.log(`${color.green}[✓]${color.reset} ${msg}`);
}

export function warn(msg: string): void {
  console.log(`${color.yellow}[!]${color.reset} ${msg}`);
}

export function err(msg: string): void {
  console.log(`${color.red}[✗]${color.reset} ${msg}`);
}

export function step(n: number, total: number, label: string): void {
  console.log(
    `\n${color.bold}${color.magenta}► ขั้นตอน ${n}/${total}:${color.reset} ${color.bold}${label}${color.reset}`,
  );
}

export async function ask(question: string, def?: string): Promise<string> {
  const suffix = def ? ` ${color.gray}[${def}]${color.reset}` : "";
  process.stdout.write(`${color.yellow}? ${color.reset}${question}${suffix} `);
  const line = await readLine();
  const trimmed = line.trim();
  return trimmed === "" && def !== undefined ? def : trimmed;
}

export async function confirm(question: string, def = true): Promise<boolean> {
  const hint = def ? "Y/n" : "y/N";
  const ans = (await ask(`${question} (${hint})`)).toLowerCase();
  if (ans === "") return def;
  return ans === "y" || ans === "yes" || ans === "ใช่";
}

export async function pause(msg = "กด Enter เพื่อปิดหน้าต่าง..."): Promise<void> {
  process.stdout.write(`\n${color.gray}${msg}${color.reset} `);
  await readLine();
}

function readLine(): Promise<string> {
  return new Promise((resolve) => {
    let buf = "";
    const onData = (chunk: Buffer | string) => {
      const s = chunk.toString();
      buf += s;
      const nl = buf.indexOf("\n");
      if (nl !== -1) {
        process.stdin.removeListener("data", onData);
        process.stdin.pause();
        resolve(buf.slice(0, nl).replace(/\r$/, ""));
      }
    };
    process.stdin.resume();
    process.stdin.on("data", onData);
  });
}
