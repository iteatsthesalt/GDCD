// Boot the exported Web build in headless Chromium and take a screenshot.
// Needs Playwright with Chromium (preinstalled in Claude Code cloud sessions).
//
//   tools/export_web.sh && node tools/web_smoke.js [screenshot.png] [--wait=ms]
//
// Fails if the engine never starts, or if the page logs errors.
const http = require("http");
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

const ROOT = path.join(__dirname, "..", "build", "web");
const args = process.argv.slice(2);
const shot = args.find((a) => !a.startsWith("--")) || path.join(ROOT, "..", "web-smoke.png");
const waitMs = Number((args.find((a) => a.startsWith("--wait=")) || "--wait=3000").slice(7));
const TYPES = {
  ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png", ".json": "application/json",
};

const server = http.createServer((req, res) => {
  const file = path.join(ROOT, decodeURIComponent(req.url.split("?")[0]).replace(/^\/$/, "/index.html"));
  if (!file.startsWith(ROOT) || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
  fs.createReadStream(file).pipe(res);
});

(async () => {
  if (!fs.existsSync(path.join(ROOT, "index.html"))) throw new Error("No build/web; run tools/export_web.sh");
  await new Promise((r) => server.listen(0, "127.0.0.1", r));
  const url = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch({ args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const errors = [];
  page.on("console", (m) => {
    console.log(`[${m.type()}] ${m.text()}`);
    if (m.type() === "error" || /SCRIPT ERROR|^ERROR:/.test(m.text())) errors.push(m.text());
  });
  page.on("pageerror", (e) => errors.push(e.message));
  const started = page.waitForEvent("console", { predicate: (m) => m.text().startsWith("Godot Engine v"), timeout: 60000 });
  await page.goto(url);
  await started;
  await page.waitForTimeout(waitMs);
  await page.screenshot({ path: shot });
  await browser.close();
  server.close();
  console.log(`Screenshot: ${shot}`);
  if (errors.length) { console.error(`FAIL: ${errors.length} error(s) in the browser`); process.exit(1); }
  console.log("Web smoke test passed.");
})().catch((e) => { console.error(`FAIL: ${e.message}`); server.close(); process.exit(1); });
