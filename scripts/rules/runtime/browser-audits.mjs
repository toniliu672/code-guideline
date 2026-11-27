import { resolveEnv } from './browser-helpers.mjs';

export async function clickVisibleTabs(page, timeoutMs) {
  const tabs = page.locator('[role="tab"]:visible');
  const count = Math.min(await tabs.count().catch(() => 0), 12);
  for (let i = 0; i < count; i++) {
    const tab = tabs.nth(i);
    const selected = await tab.getAttribute('aria-selected').catch(() => null);
    const disabled = await tab.isDisabled().catch(() => true);
    if (selected === 'true' || disabled) continue;
    await tab.click({ timeout: Math.min(timeoutMs, 3000) }).catch(() => {});
    await page.waitForTimeout(250);
  }
}

export async function applyDarkMode(page, enable) {
  await page.emulateMedia({ colorScheme: enable ? 'dark' : 'light' }).catch(() => {});
  await page.evaluate((on) => {
    document.documentElement.classList.toggle('dark', on);
    if (on) document.documentElement.setAttribute('data-theme', 'dark');
    else document.documentElement.removeAttribute('data-theme');
  }, enable).catch(() => {});
  await page.waitForTimeout(150);
}

export async function auditContrast(page, modeLabel) {
  return page.evaluate((mode) => {
    const parseRgba = (str) => {
      const m = str && str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
      return m ? [+m[1], +m[2], +m[3], m[4] === undefined ? 1 : parseFloat(m[4])] : null;
    };
    const lum = ([r, g, b]) => {
      const c = [r, g, b].map((v) => {
        const s = v / 255;
        return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
      });
      return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
    };
    const effectiveBg = (el) => {
      let cur = el;
      while (cur) {
        const bg = parseRgba(getComputedStyle(cur).backgroundColor);
        if (bg && bg[3] > 0.1) return bg;
        cur = cur.parentElement;
      }
      return mode === 'DARK' ? [15, 23, 42, 1] : [255, 255, 255, 1];
    };
    const issues = [];
    const els = document.querySelectorAll('button, a, h1, h2, h3, h4, p, label, [role="button"]');
    for (const el of els) {
      if (issues.length >= 10) break;
      const text = (el.innerText || '').trim().replace(/\s+/g, ' ').slice(0, 40);
      if (!text) continue;
      const st = getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      if (st.display === 'none' || st.visibility === 'hidden' || parseFloat(st.opacity) < 0.2 || rect.width < 2 || rect.height < 2) continue;
      const fg = parseRgba(st.color);
      if (!fg || fg[3] < 0.1) continue;
      const bg = effectiveBg(el);
      const [l1, l2] = [lum(fg), lum(bg)];
      const ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
      const size = parseFloat(st.fontSize) || 14;
      const weight = parseInt(st.fontWeight, 10) || 400;
      const minRatio = size >= 18.66 || (size >= 14 && weight >= 700) ? 3.0 : 4.5;
      if (ratio < minRatio) {
        issues.push({ type: `CONTRAST_${mode}`, detail: `${ratio.toFixed(2)}:1 (<${minRatio}:1) <${el.tagName.toLowerCase()}> "${text}" fg=${st.color} bg=rgb(${bg[0]},${bg[1]},${bg[2]})` });
      }
    }
    return issues;
  }, modeLabel).catch(() => []);
}

export async function runSteps(page, baseUrl, steps, timeoutMs, record) {
  for (const step of steps || []) {
    try {
      if (step.action === 'goto') await page.goto(step.url.startsWith('http') ? step.url : `${baseUrl}${step.url}`, { waitUntil: 'networkidle', timeout: timeoutMs });
      else if (step.action === 'click') await page.click(step.selector, { timeout: timeoutMs });
      else if (step.action === 'fill') await page.fill(step.selector, resolveEnv(step.value || ''), { timeout: timeoutMs });
      else if (step.action === 'reload') await page.reload({ waitUntil: 'networkidle', timeout: timeoutMs });
      else if (step.action === 'wait') await page.waitForTimeout(step.ms || 300);
      else if (step.action === 'expectVisible') await page.locator(step.selector).first().waitFor({ state: 'visible', timeout: timeoutMs });
      else if (step.action === 'expectText') {
        const txt = await page.locator(step.selector).first().innerText({ timeout: timeoutMs });
        if (!txt.includes(step.text)) throw new Error(`Expected "${step.text}" in "${txt.slice(0, 60)}"`);
      } else if (step.action === 'expectStorage') {
        const val = await page.evaluate((k) => localStorage.getItem(k), step.key);
        if (val !== step.value) throw new Error(`localStorage["${step.key}"] was "${val}", expected "${step.value}"`);
      }
    } catch (err) {
      record('E2E_STEP_FAIL', `${step.action}(${step.selector || step.url || step.key || ''}): ${err.message}`);
    }
  }
}
