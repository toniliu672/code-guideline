import fs from 'node:fs';
import { discoverLinks, isIgnoredUrl, loadConfig, loadPlaywright, performLogin } from './browser-helpers.mjs';

const failOn4xx = process.env.RUNTIME_FAIL_ON_4XX === 'true';
const failOnConsole = process.env.RUNTIME_FAIL_ON_CONSOLE_ERROR !== 'false';
const bad4xx = new Set([403, 404, 422]);

async function launchBrowser(chromium) {
  const bins = [process.env.RUNTIME_CHROMIUM_PATH, null, '/usr/local/bin/chromium', '/usr/bin/chromium', '/usr/bin/chromium-browser', '/usr/bin/google-chrome', '/usr/bin/google-chrome-stable'];
  let lastErr;
  for (const exe of bins) {
    if (exe && !fs.existsSync(exe)) continue;
    try { return await chromium.launch(exe ? { headless: true, executablePath: exe } : { headless: true }); }
    catch (err) { lastErr = err; }
  }
  throw lastErr;
}

async function crawlRole(browser, cfg, role) {
  const findings = [];
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();
  let currentRoute = '/';
  const record = (type, detail) => findings.push({ role: role.name, route: currentRoute, type, detail });

  page.on('pageerror', (err) => record('JS_ERROR', err.message));
  page.on('console', (msg) => failOnConsole && msg.type() === 'error' && record('CONSOLE', msg.text()));
  page.on('response', (res) => {
    const status = res.status();
    const url = res.url();
    if (isIgnoredUrl(url, cfg.ignoreUrls)) return;
    if (status >= 500 || (failOn4xx && bad4xx.has(status))) record(`HTTP_${status}`, url);
  });

  try {
    await performLogin(page, cfg.baseUrl, role.login, cfg.timeoutMs);
  } catch (err) {
    currentRoute = role.login?.url || '/login';
    record('LOGIN_FAIL', err.message);
    await context.close();
    return { visited: 0, findings };
  }

  const queue = [...(role.routes && role.routes.length ? role.routes : ['/'])];
  const visited = new Set();
  const maxPages = role.maxPages || cfg.maxPages;
  const discover = role.autoDiscover !== undefined ? role.autoDiscover : cfg.autoDiscover;

  while (queue.length > 0 && visited.size < maxPages) {
    const route = queue.shift();
    if (!route || visited.has(route) || isIgnoredUrl(route, cfg.ignoreUrls)) continue;
    visited.add(route);
    currentRoute = route;
    const target = route.startsWith('http') ? route : `${cfg.baseUrl}${route.startsWith('/') ? '' : '/'}${route}`;
    try {
      await page.goto(target, { waitUntil: 'networkidle', timeout: cfg.timeoutMs });
    } catch {
      await page.goto(target, { waitUntil: 'domcontentloaded', timeout: cfg.timeoutMs }).catch((e) => record('NAV_ERROR', e.message));
    }
    if (discover) {
      for (const next of await discoverLinks(page, cfg.baseUrl)) {
        if (!visited.has(next) && !queue.includes(next)) queue.push(next);
      }
    }
  }

  await context.close();
  return { visited: visited.size, findings };
}

async function main() {
  const cfg = loadConfig();
  const { chromium } = loadPlaywright();
  const browser = await launchBrowser(chromium);
  const allFindings = [];
  let totalVisited = 0;

  try {
    for (const role of cfg.roles) {
      const { visited, findings } = await crawlRole(browser, cfg, role);
      totalVisited += visited;
      allFindings.push(...findings);
      console.log(`  [${role.name}] visited ${visited} route(s) -> ${findings.length} error(s)`);
    }
  } finally {
    await browser.close();
  }

  if (allFindings.length > 0) {
    console.error('\n[FAIL] Runtime & Browser Errors Detected:');
    for (const f of allFindings.slice(0, 50)) console.error(`  - [${f.role}] ${f.route} | ${f.type} | ${String(f.detail).slice(0, 180)}`);
    if (allFindings.length > 50) console.error(`  ... and ${allFindings.length - 50} more error(s).`);
    process.exit(1);
  }
  console.log(`[OK] Crawled ${totalVisited} route visit(s) across ${cfg.roles.length} role(s) with 0 errors.`);
}

main().catch((err) => { console.error(`[FAIL] Runtime crawler crashed: ${err.message}`); process.exit(1); });
