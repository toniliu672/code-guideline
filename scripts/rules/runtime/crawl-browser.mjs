import fs from 'node:fs';
import { applyDarkMode, auditContrast, clickVisibleTabs, runSteps } from './browser-audits.mjs';
import { discoverLinks, isIgnoredUrl, loadConfig, loadPlaywright, performLogin } from './browser-helpers.mjs';

const failOn4xx = process.env.RUNTIME_FAIL_ON_4XX === 'true';
const failOnConsole = process.env.RUNTIME_FAIL_ON_CONSOLE_ERROR !== 'false';
const clickTabs = process.env.RUNTIME_CLICK_TABS !== 'false';
const checkContrast = process.env.RUNTIME_CHECK_CONTRAST === 'true';
const checkDarkMode = process.env.RUNTIME_CHECK_DARK_MODE === 'true';
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
    const status = res.status(), url = res.url();
    if (!isIgnoredUrl(url, cfg.ignoreUrls) && (status >= 500 || (failOn4xx && bad4xx.has(status)))) record(`HTTP_${status}`, url);
  });

  let landedPath = null;
  const loginPath = role.login ? new URL(role.login.url || '/login', cfg.baseUrl).pathname : null;
  try { landedPath = await performLogin(page, cfg.baseUrl, role.login, cfg.timeoutMs); }
  catch (err) { currentRoute = loginPath || '/login'; record('LOGIN_FAIL', err.message); await context.close(); return { visited: 0, findings, landedPath }; }

  const queue = [...(role.routes?.length ? role.routes : ['/'])], visited = new Set();
  if (landedPath && landedPath !== loginPath && !queue.includes(landedPath)) queue.unshift(landedPath);
  const maxPages = role.maxPages || cfg.maxPages, discover = role.autoDiscover ?? cfg.autoDiscover;

  while (queue.length > 0 && visited.size < maxPages) {
    const route = queue.shift();
    if (!route || visited.has(route) || isIgnoredUrl(route, cfg.ignoreUrls)) continue;
    visited.add(route);
    currentRoute = route;
    const target = route.startsWith('http') ? route : `${cfg.baseUrl}${route.startsWith('/') ? '' : '/'}${route}`;
    try { await page.goto(target, { waitUntil: 'networkidle', timeout: cfg.timeoutMs }); }
    catch { await page.goto(target, { waitUntil: 'domcontentloaded', timeout: cfg.timeoutMs }).catch((e) => record('NAV_ERROR', e.message)); }
    const finalPath = new URL(page.url()).pathname;
    if (role.login && route !== loginPath && (finalPath === loginPath || /\/(login|signin)(\/|$)/i.test(finalPath))) {
      record('AUTH_BOUNCE', `Redirected to ${finalPath} (session unauthenticated)`);
      continue;
    }
    if (clickTabs) await clickVisibleTabs(page, cfg.timeoutMs);
    if (checkContrast) (await auditContrast(page, 'LIGHT')).forEach((i) => record(i.type, i.detail));
    if (checkDarkMode) {
      await applyDarkMode(page, true);
      if (checkContrast) (await auditContrast(page, 'DARK')).forEach((i) => record(i.type, i.detail));
      await applyDarkMode(page, false);
    }
    if (discover) for (const next of await discoverLinks(page, cfg.baseUrl)) if (!visited.has(next) && !queue.includes(next)) queue.push(next);
  }
  if (role.steps?.length) { currentRoute = 'steps'; await runSteps(page, cfg.baseUrl, role.steps, cfg.timeoutMs, record); }
  await context.close();
  return { visited: visited.size, findings, landedPath };
}

async function main() {
  const cfg = loadConfig();
  const browser = await launchBrowser(loadPlaywright().chromium);
  const allFindings = [];
  let totalVisited = 0;
  try {
    for (const role of cfg.roles) {
      const { visited, findings, landedPath } = await crawlRole(browser, cfg, role);
      totalVisited += visited;
      allFindings.push(...findings);
      const landInfo = landedPath ? ` (landed: ${landedPath})` : '';
      console.log(`  [${role.name}]${landInfo} visited ${visited} route(s) -> ${findings.length} error(s)`);
    }
  } finally { await browser.close(); }
  if (allFindings.length > 0) {
    console.error('\n[FAIL] Runtime & Browser Errors Detected:');
    for (const f of allFindings.slice(0, 50)) console.error(`  - [${f.role}] ${f.route} | ${f.type} | ${String(f.detail).slice(0, 180)}`);
    if (allFindings.length > 50) console.error(`  ... and ${allFindings.length - 50} more error(s).`);
    process.exit(1);
  }
  console.log(`[OK] Crawled ${totalVisited} route visit(s) across ${cfg.roles.length} role(s) with 0 errors.`);
}
main().catch((err) => { console.error(`[FAIL] Runtime crawler crashed: ${err.message}`); process.exit(1); });
