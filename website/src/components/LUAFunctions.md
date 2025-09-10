---
import { Badge } from '@astrojs/starlight/components';
import AnchorHeading from '@astrojs/starlight/components/AnchorHeading.astro';

const { version, data } = Astro.props;
const CHECK_DOCS = true;

let rawText = null;
if (data) {
    rawText = data
}

// ------------------- Helpers -------------------
function splitSections(text: string) {
  const freeMarker = '==========================================\nObject-Free API';
  const objMarker = '==========================================\nObject API';
  const freeIdx = text.indexOf(freeMarker);
  const objIdx = text.indexOf(objMarker);
  const free = text.substring(freeIdx + freeMarker.length, objIdx).trim();
  const obj = text.substring(objIdx + objMarker.length).trim();
  return { free, obj };
}

// “name:type” → {name, type}
function splitArg(arg: string): { name: string; type: string } {
  const parts = arg.split(':');
  const name = parts.shift()?.trim() ?? '';
  const type = parts.join(':').trim(); // keep possible colons inside the type
  return { name, type };
}

// Parse a line like  Foo(bar:string, baz:integer): string:result
function parseLine(line: string) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('===') || trimmed.startsWith('#')) return null;

  const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*:\s*(.+)$/);
  if (!match) return null;

  const [, name, argsRaw, returnsRaw] = match;

  const args = argsRaw
    .split(',')
    .map((a) => a.trim())
    .filter(Boolean)
    .map(splitArg);

  const returns = returnsRaw
    .split(',')
    .map((r) => r.trim())
    .filter(Boolean)
    .map(splitArg);

  return { name, args, returns };
}

function parseSection(section: string) {
  const out: Array<{
    name: string;
    args: { name: string; type: string }[];
    returns: { name: string; type: string }[];
  }> = [];

  for (const line of section.split('\n')) {
    const parsed = parseLine(line);
    if (parsed) out.push(parsed);
  }
  return out;
}

// Base URL for the official docs
const version_short = version.replace(/^v/, "");
const BASE_URL = `https://help.malighting.com/grandMA3/${version_short}/HTML/`;

function makeDocUrl(section: 'objectfree' | 'object', funcName: string) {
  return `${BASE_URL}lua_${section}_${funcName.toLowerCase().trim()}.html`;
}

async function urlExists(url: string): Promise<boolean> {
  try {
    const res = await fetch(url, { method: 'HEAD' });
    return res.ok;
  } catch {
    return false;
  }
}

type FuncRecord = {
  name: string;
  args: { name: string; type: string }[];
  returns: { name: string; type: string }[];
  section: 'objectfree' | 'object';
  docUrl: string;
  hasDoc: boolean;
};

let allFuncs: FuncRecord[] = [];

if (rawText) {
  const { free, obj } = splitSections(rawText);
  const freeParsed = parseSection(free);
  const objParsed = parseSection(obj);

  // Combine both sections, tagging each entry with its origin.
  const combined = [
    ...freeParsed.map((f) => ({
      ...f,
      section: 'objectfree' as const,
    })),
    ...objParsed.map((f) => ({
      ...f,
      section: 'object' as const,
    })),
  ];

  // For every function compute the doc URL and test its existence.
  const checks = combined.map(async (fn) => {
    const url = makeDocUrl(fn.section, fn.name);
    let exists = false;
    if (CHECK_DOCS) {
      exists = await urlExists(url);
    }
    return {
      ...fn,
      docUrl: url,
      hasDoc: exists,
    };
  });

  // Await all HEAD requests before rendering.
  allFuncs = await Promise.all(checks);
}

---

{!rawText ? (
  <section>
    <h2>Unable to load <code>{FILE_NAME}</code></h2>
    <p>Make sure the file is placed next to this component.</p>
  </section>
) : (
  <>

    {/* ---------- Object‑Free API ---------- */}
    <section>
      <AnchorHeading level="2" id="objectfree">Object‑Free API</AnchorHeading>
      {allFuncs
        .filter((f) => f.section === 'objectfree')
        .map((fn) => (
          <article key={fn.name}>
            <AnchorHeading level="3" id={fn.name}>
              {fn.name}
              {/* Conditional link */}
              {fn.hasDoc && (
                <a href={fn.docUrl} target="_blank" rel="noopener">
                  <Badge text="Offical Docs" variant="note" style="margin-left:25px;"/>
                </a>
              )}
            </AnchorHeading>

            {/* Arguments */}
            <p><strong>Arguments:</strong></p>
            {fn.args.length ? (
              <ul>
                {fn.args.map((a, i) => (
                  <li key={i}>
                    <code>{a.name || '(unnamed)'}</code>: <code>{a.type}</code>
                  </li>
                ))}
              </ul>
            ) : (
              <p>(none)</p>
            )}

            {/* Returns */}
            <p><strong>Returns:</strong></p>
            {fn.returns.length ? (
              <ul>
                {fn.returns.map((r, i) => (
                  <li key={i}>
                    <code>{r.name || '(unnamed)'}</code>: <code>{r.type}</code>
                  </li>
                ))}
              </ul>
            ) : (
              <p>(none)</p>
            )}
          </article>
        ))}
    </section>

    {/* ---------- Object API ---------- */}
    <section>
      <AnchorHeading level="2" id="object">Object API</AnchorHeading>
      {allFuncs
        .filter((f) => f.section === 'object')
        .map((fn) => (
          <article key={fn.name}>
            <AnchorHeading level="3" id={fn.name}>
              {fn.name}
              {/* Conditional link */}
              {fn.hasDoc && (
                <a href={fn.docUrl} target="_blank" rel="noopener">
                  <Badge text="Offical Docs" variant="note" style="margin-left:25px;"/>
                </a>
              )}
            </AnchorHeading>

            {/* Conditional link */}
            {fn.hasDoc && (
              <p>
                Official docs:{' '}
                <a href={fn.docUrl} target="_blank" rel="noopener">
                  {fn.docUrl}
                </a>
              </p>
            )}

            {/* Arguments */}
            <p><strong>Arguments:</strong></p>
            {fn.args.length ? (
              <ul>
                {fn.args.map((a, i) => (
                  <li key={i}>
                    <code>{a.name || '(unnamed)'}</code>: <code>{a.type}</code>
                  </li>
                ))}
              </ul>
            ) : (
              <p>(none)</p>
            )}

            {/* Returns */}
            <p><strong>Returns:</strong></p>
            {fn.returns.length ? (
              <ul>
                {fn.returns.map((r, i) => (
                  <li key={i}>
                    <code>{r.name || '(unnamed)'}</code>: <code>{r.type}</code>
                  </li>
                ))}
              </ul>
            ) : (
              <p>(none)</p>
            )}
          </article>
        ))}
    </section>
  </>
)}