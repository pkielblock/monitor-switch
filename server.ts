type Input = { id: string; label: string; port: string; value: string; icon?: string };
type Config = { monitor: string; vcp: string; i2cSourceAddr?: string; inputs: Input[] };

// Monitor-specific DDC/CI settings live in config.json (see README).
const CONFIG_PATH = process.env.CONFIG_PATH ?? new URL("./config.json", import.meta.url).pathname;
const config: Config = await Bun.file(CONFIG_PATH).json();
const inputs = new Map(config.inputs.map((i) => [i.id, i]));

const PORT = Number(process.env.PORT ?? 7580);
// Space-separated origins allowed to embed the page in an iframe (e.g. a dashboard).
const FRAME_ANCESTORS = process.env.FRAME_ANCESTORS ?? "'self'";

// ddcutil talks to a single I2C bus; run one command at a time.
let queue: Promise<unknown> = Promise.resolve();
function setInput(value: string): Promise<{ ok: boolean; output: string }> {
  const args = ["ddcutil"];
  if (config.i2cSourceAddr) args.push(`--i2c-source-addr=${config.i2cSourceAddr}`);
  args.push("setvcp", config.vcp, value);
  const run = async () => {
    try {
      const proc = Bun.spawn(args, { stdout: "pipe", stderr: "pipe" });
      const [out, err, code] = await Promise.all([
        new Response(proc.stdout).text(),
        new Response(proc.stderr).text(),
        proc.exited,
      ]);
      return { ok: code === 0, output: (out + err).trim() };
    } catch (e) {
      return { ok: false, output: String(e) };
    }
  };
  const result = queue.then(run, run);
  queue = result.catch(() => {});
  return result;
}

function audit(req: Request, server: Bun.Server, action: string, result: string) {
  const ip = req.headers.get("x-real-ip") ?? server.requestIP(req)?.address ?? "?";
  console.log(JSON.stringify({ time: new Date().toISOString(), ip, action, result }));
}

const securityHeaders = {
  "Strict-Transport-Security": "max-age=31536000",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
  "Content-Security-Policy": `default-src 'self'; style-src 'self' 'unsafe-inline'; frame-ancestors ${FRAME_ANCESTORS}`,
};

const json = (body: unknown, status = 200) =>
  Response.json(body, { status, headers: securityHeaders });

const publicDir = new URL("./public/", import.meta.url).pathname;

const server = Bun.serve({
  port: PORT,
  async fetch(req, server) {
    const url = new URL(req.url);

    if (url.pathname === "/api/health") return json({ ok: true });

    // Labels only (no DDC values).
    if (url.pathname === "/api/config" && req.method === "GET") {
      return json({
        monitor: config.monitor,
        inputs: config.inputs.map(({ id, label, port, icon }) => ({ id, label, port, icon })),
      });
    }

    const match = url.pathname.match(/^\/api\/input\/([\w-]+)$/);
    if (match && req.method === "POST") {
      const name = match[1];
      const input = inputs.get(name);
      if (!input) return json({ error: "unknown input" }, 404);
      const result = await setInput(input.value);
      audit(req, server, `input:${name}`, result.ok ? "ok" : `error: ${result.output}`);
      return result.ok ? json({ ok: true, input: name }) : json({ error: "ddcutil failed" }, 500);
    }

    if (req.method === "GET" || req.method === "HEAD") {
      const path = url.pathname === "/" ? "index.html" : url.pathname.slice(1);
      if (/^[\w.-]+$/.test(path)) {
        const file = Bun.file(publicDir + path);
        if (await file.exists()) return new Response(file, { headers: securityHeaders });
      }
    }

    return json({ error: "not found" }, 404);
  },
});

console.log(`monitor-switch listening on :${server.port} (${config.monitor})`);
