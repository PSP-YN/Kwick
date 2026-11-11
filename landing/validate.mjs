import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const directory = fileURLToPath(new URL('.', import.meta.url));
const html = readFileSync(resolve(directory, 'index.html'), 'utf8');
const css = readFileSync(resolve(directory, 'styles.css'), 'utf8');
const js = readFileSync(resolve(directory, 'app.js'), 'utf8');

const checks = [
  ['document language', /<html lang="en">/.test(html)],
  ['responsive viewport', /name="viewport"[^>]+width=device-width/.test(html)],
  ['description metadata', /name="description"/.test(html)],
  ['main landmark', /<main id="main">/.test(html)],
  ['skip navigation link', /class="skip-link" href="#main"/.test(html)],
  ['how it works section', /id="how-it-works"/.test(html)],
  ['trust and safety section', /id="trust"/.test(html)],
  ['professional workflow section', /id="for-professionals"/.test(html)],
  ['mobile navigation behavior', /aria-expanded/.test(js) && /is-open/.test(js)],
  ['mobile responsive breakpoint', /@media \(max-width: 640px\)/.test(css)],
  ['tablet responsive breakpoint', /@media \(max-width: 900px\)/.test(css)],
  ['reduced motion support', /prefers-reduced-motion: reduce/.test(css)],
  ['local stylesheet exists', existsSync(resolve(directory, 'styles.css'))],
  ['local script exists', existsSync(resolve(directory, 'app.js'))],
  ['favicon exists', existsSync(resolve(directory, 'favicon.svg'))],
];

const ids = new Set([...html.matchAll(/\bid="([^"]+)"/g)].map((match) => match[1]));
for (const match of html.matchAll(/href="#([^"]+)"/g)) {
  checks.push(['anchor target #' + match[1] + ' exists', ids.has(match[1])]);
}
for (const match of html.matchAll(/<a\b([^>]*)>/g)) {
  const attrs = match[1];
  if (/target="_blank"/.test(attrs)) {
    checks.push(['external new-tab link is protected', /rel="[^"]*noreferrer/.test(attrs)]);
  }
}

let failed = false;
for (const [name, passed] of checks) {
  process.stdout.write((passed ? 'PASS' : 'FAIL') + '  ' + name + '\n');
  if (!passed) failed = true;
}
if (failed) process.exit(1);
process.stdout.write('\nValidated ' + checks.length + ' landing-page checks.\n');
