import fs from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

export function loadPlaywright() {
  for (const base of [process.cwd(), ...((process.env.NODE_PATH || '').split(':').filter(Boolean))]) {
    try {
      return require(require.resolve('playwright', { paths: [base] }));
    } catch {}
  }
  return require('playwright');
}

export function loadConfig() {
  const cfgPath = process.env.RUNTIME_CONFIG || '.guidelines.runtime.json';
  const defaultRoutes = (process.env.RUNTIME_ROUTES || '/').split(',').map((s) => s.trim()).filter(Boolean);
  const fallback = {
    baseUrl: process.env.RUNTIME_BASE_URL,
    autoDiscover: true,
    maxPages: Number(process.env.RUNTIME_MAX_PAGES || 50),
    timeoutMs: Number(process.env.RUNTIME_TIMEOUT_MS || 15000),
    ignoreUrls: [],
    roles: [{ name: 'guest', routes: defaultRoutes }],
  };
  if (!fs.existsSync(cfgPath)) return fallback;
  const parsed = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  return {
    ...fallback,
    ...parsed,
    baseUrl: (process.env.RUNTIME_BASE_URL || parsed.baseUrl || '').replace(/\/$/, ''),
    roles: Array.isArray(parsed.roles) && parsed.roles.length ? parsed.roles : fallback.roles,
  };
}

export function resolveEnv(value) {
  if (typeof value !== 'string') return value;
  return value.replace(/\$\{([A-Z0-9_]+)\}/g, (_, key) => process.env[key] || '');
}

export function isIgnoredUrl(url, ignorePatterns) {
  return (ignorePatterns || []).some((p) => {
    try {
      return new RegExp(p).test(url);
    } catch {
      return url.includes(p);
    }
  });
}

export async function performLogin(page, baseUrl, login, timeoutMs) {
  if (!login) return;
  if (login.apiUrl) {
    const target = login.apiUrl.startsWith('http') ? login.apiUrl : `${baseUrl}${login.apiUrl}`;
    const payload = {};
    for (const [k, v] of Object.entries(login.payload || {})) payload[k] = resolveEnv(v);
    const res = await page.request.fetch(target, {
      method: login.method || 'POST',
      data: payload,
      headers: login.headers || { 'Content-Type': 'application/json' },
    });
    if (res.status() >= 400) {
      throw new Error(`API login failed (${res.status()}) at ${target}`);
    }
    return;
  }
  const loginUrl = login.url?.startsWith('http') ? login.url : `${baseUrl}${login.url || '/login'}`;
  await page.goto(loginUrl, { waitUntil: 'domcontentloaded', timeout: timeoutMs });
  if (login.emailSelector && login.email) {
    await page.fill(login.emailSelector, resolveEnv(login.email));
  }
  if (login.passwordSelector && login.password) {
    await page.fill(login.passwordSelector, resolveEnv(login.password));
  }
  if (login.submitSelector) {
    await Promise.all([
      page.waitForLoadState('networkidle', { timeout: timeoutMs }).catch(() => {}),
      page.click(login.submitSelector),
    ]);
  }
}

export async function discoverLinks(page, baseUrl) {
  const origin = new URL(baseUrl).origin;
  const hrefs = await page.evaluate(() =>
    Array.from(document.querySelectorAll('a[href]')).map((a) => a.getAttribute('href') || '')
  );
  const unsafe = /(\/logout|\/signout|\/delete|\/destroy|\/download|\.pdf$|\.csv$|\.xlsx$|\.zip$)/i;
  const found = [];
  for (const href of hrefs) {
    if (!href || href.startsWith('#') || href.startsWith('mailto:') || href.startsWith('javascript:')) continue;
    try {
      const u = new URL(href, baseUrl);
      if (u.origin === origin && !unsafe.test(u.pathname)) found.push(`${u.pathname}${u.search}`);
    } catch {}
  }
  return [...new Set(found)];
}
