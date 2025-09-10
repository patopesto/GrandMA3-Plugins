#!/usr/bin/env node

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';

/* --------------------------------------------------------------
   1️⃣  HELPERS
   -------------------------------------------------------------- */

/** Slugify a string for use as an HTML id attribute. */
function slugify(str) {
  return str
    .toLowerCase()
    .replace(/[^\w]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/** Escape a literal pipe character so Markdown tables stay intact (kept for badge URLs). */
function escapePipe(txt) {
  return String(txt).replace(/\|/g, '&#124;');
}

/**
 * Split a comma‑separated list **respecting square brackets**.
 *
 * Example:
 *   "string:cmd[, light_userdata:undo[, light_userdata:target]]"
 * becomes three tokens:
 *   ["string:cmd", "light_userdata:undo", "light_userdata:target"]
 * with the second and third marked as optional.
 */
function splitRespectingBrackets(raw) {
  const tokens = [];
  let cur = '';
  let depth = 0; // square‑bracket nesting level

  for (let i = 0; i < raw.length; i++) {
    const ch = raw[i];

    if (ch === '[') {
      depth++;
      cur += ch;
    } else if (ch === ']') {
      depth--;
      cur += ch;
    } else if (ch === ',' && depth === 0) {
      tokens.push(cur.trim());
      cur = '';
    } else {
      cur += ch;
    }
  }
  if (cur.trim()) tokens.push(cur.trim());

  // Turn each token into {text, optional}
  return tokens.map(tok => {
    const optional = /^\[.*\]$/.test(tok);
    const clean = optional ? tok.replace(/^\[|\]$/g, '').trim() : tok;
    return { text: clean, optional };
  });
}
/* --------------------------------------------------------------
   PATCH END
   -------------------------------------------------------------- */

/**
 * Parse a single parameter fragment (already stripped of outer brackets).
 *
 * Returns an object with:
 *   name, rawType, union (array of alternatives), optional, isVariadic, defaultValue
 */
function parseParamFragment(fragment, optionalFlag) {
  let frag = fragment.trim();

  // ------------------------------------------------------------
  // NEW: Clean up a possible leading comma that appears when the
  // optional argument is written as "[, type:name]".
  // Example: ", boolean:return_as_handles" → "boolean:return_as_handles"
  // ------------------------------------------------------------
  frag = frag.replace(/^,\s*/, '');

  // ---------- Variadic ----------
  const isVariadic = frag.endsWith('...') || frag.endsWith('…');
  if (isVariadic) {
    frag = frag.replace(/\.\.\.$|\u2026/g, '').trim();
  }

  // ---------- Split name / type ----------
  const colonIdx = frag.indexOf(':');
  let namePart = '';
  let typePart = '';
  if (colonIdx >= 0) {
    namePart = frag.slice(0, colonIdx).trim();
    typePart = frag.slice(colonIdx + 1).trim();
  } else {
    typePart = frag; // unnamed param, only a type
  }

  // ---------- Default value (before colon) ----------
  let defaultValue;
  if (namePart.includes('=')) {
    const [n, def] = namePart.split('=');
    namePart = n.trim();
    defaultValue = def.trim();
  }

  // ---------- Default value (after colon) ----------
  if (typePart.includes('=')) {
    const [t, def] = typePart.split('=');
    typePart = t.trim();
    defaultValue = def.trim();
  }

  const name = namePart || (isVariadic ? '...' : '(unnamed)');

  // ------------------------------------------------------------
  // UNION HANDLING (OR / or) – unchanged from the previous patch
  // ------------------------------------------------------------
  const unionParts = typePart.split(/\s+(?:OR|or)\s+/i).map(p => p.trim());

  const processed = unionParts.map(part => {
    const arrMatch = part.match(/^(.+?)\s*\[\]$/);
    const isArray = !!arrMatch;
    const base = isArray ? arrMatch[1].trim() : part;
    return {
      raw: part,
      isArray,
      baseType: base,
    };
  });

  return {
    name,
    rawType: typePart,
    union: processed,
    optional: optionalFlag,
    isVariadic,
    defaultValue,
  };
}

/**
 * Parse a full signature line.
 *
 * Expected loosely: Func(arg1, arg2,…): ret1, ret2,…
 *
 * Returns { name, args[], returns[] } or null if the line cannot be parsed.
 */
function parseSignature(line) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('===') || trimmed.startsWith('#')) return null;

  const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*:\s*(.+)$/);
  if (!match) return null;

  const [, name, argsRaw, returnsRaw] = match;

  // ----- Arguments -----
  const argTokens = splitRespectingBrackets(argsRaw); // uses patched splitter
  const args = argTokens.map(tok => parseParamFragment(tok.text, tok.optional));

  // ----- Return values -----
  // Return values do **not** use the bracket‑optional syntax, so we can split on commas directly.
  const returns = returnsRaw
    .split(',')
    .map(s => s.trim())
    .filter(Boolean)
    .map(ret => parseParamFragment(ret, false)); // returns are never optional in this sense

  return { name, args, returns };
}

/**
 * Split the huge txt file into the two logical sections.
 */
function splitSections(text) {
  const freeMarker = '==========================================\nObject-Free API';
  const objMarker = '==========================================\nObject API';

  const freeIdx = text.indexOf(freeMarker);
  const objIdx = text.indexOf(objMarker);

  const freePart = text.substring(freeIdx + freeMarker.length, objIdx).trim();
  const objPart = text.substring(objIdx + objMarker.length).trim();

  return { free: freePart, object: objPart };
}

/**
 * Turn a parsed *union* (array of alternatives) into a readable string.
 *
 * Example output: `integer OR string[] OR On|Off`
 */
function formatType(union) {
  const parts = union.map(u => {
    let txt = u.baseType;
    if (u.isArray && !txt.endsWith('[]')) txt += '[]';
    if (u.isEnum) txt = u.enumValues.join('|');
    return txt;
  });
  return parts.join(' OR ');
}

/**
 * Render a single function as MDX (HTML + Markdown lists).
 *
 * `section` is either `"objectfree"` or `"object"` – it determines the URL.
 */
function renderFunction(fn, section, baseDocUrl) {
  const docUrl = `${baseDocUrl}lua_${section}_${fn.name.toLowerCase()}.html`;

  /**
   * Render a list of parameters (arguments **or** return values).
   *
   * `isReturn` tells us whether we are rendering return values – in that case we
   * omit the `required/optional` flag because returns are never optional.
   */
  const renderList = (items, isReturn = false) => {
    // Filter out any entry whose type resolves to “nothing”
    const filtered = items.filter(p => {
      // If any union member is exactly "nothing", discard the whole param.
      return !p.union.some(u => u.baseType.toLowerCase() === 'nothing');
    });

    if (filtered.length === 0) {
      return isReturn ? '*No return values.*' : '*No arguments.*';
    }

    return filtered
      .map(p => {
        const typeStr = formatType(p.union);
        const optFlag = !isReturn ? (p.optional ? '`optional`' : '`required`') : '';
        const def = p.defaultValue ? `default: \`${p.defaultValue}\`` : '';

        // Assemble a compact description, skipping empty parts
        const parts = [];
        if (optFlag) parts.push(optFlag);
        parts.push(`type: \`${typeStr}\``);
        if (def) parts.push(def);

        return `- **${p.name}** – ${parts.join(', ')}`;
      })
      .join('\n');
  };

  return `
### ${fn.name} <a href="${docUrl}" target="_blank" rel="noopener noreferrer"><Badge text="Official Docs" variant="note" style="margin-left:25px;"/></a>

<details open>
  <summary>Arguments (${fn.args.length})</summary>

  ${renderList(fn.args, false)}
</details>

<details open>
  <summary>Return values (${fn.returns.length})</summary>

  ${renderList(fn.returns, true)}
</details>
`;
}

/* --------------------------------------------------------------
   2️⃣  MAIN GENERATOR
   -------------------------------------------------------------- */
function generate(version = 'v2.0') {
  const versionShort = version.replace(/^v/, '');
  const DIR = `src/content/docs/grandma3/${version}`;
  const BASE_DOC_URL = `https://help.malighting.com/grandMA3/${versionShort}/HTML/`;

  const inputFile = path.resolve(DIR, 'grandMA3_lua_functions.txt');
  const outputFile = path.resolve(DIR, 'api.mdx');

  if (!existsSync(inputFile)) {
    console.error(`❌ Input file not found: ${inputFile}`);
    process.exit(1);
  }

  const rawText = readFileSync(inputFile, 'utf8');
  const { free, object } = splitSections(rawText);

  // Helper to render a whole section (Object‑Free / Object)
  const renderSection = (title, key, body) => {
    const functions = body
      .split('\n')
      .map(parseSignature)
      .filter(Boolean);

    const renderedFns = functions.map(fn => renderFunction(fn, key, BASE_DOC_URL)).join('\n');

    return renderedFns;
  };

  // Assemble final MDX document
  const mdxContent = `
---
title: LUA functions
description: The LUA API for grandMA3 version ${version}
version: ${version}
---
import { Aside, Badge } from '@astrojs/starlight/components';

<Aside type="tip">
  Only some functions have an entry in the official grandMA User Manual.
  If this is the case, a <Badge text="Official Docs" variant="note"/> badge will be present.
  You can click on the badge to open the corresponding page in the official User Manual.
</Aside>

## Object‑Free API
${renderSection('Object‑Free API', 'objectfree', free)}

## Object API
${renderSection('Object API', 'object', object)}
`;

  // Write output
  writeFileSync(outputFile, mdxContent.trimStart(), 'utf8');
  console.log(`✅ MDX generated at ${outputFile}`);
}

/* --------------------------------------------------------------
   3️⃣  RUN
   -------------------------------------------------------------- */
generate('v2.0');