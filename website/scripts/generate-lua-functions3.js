#!/usr/bin/env node

/* --------------------------------------------------------------
   grandMA3 Lua API → Markdown generator (v2.3)
   – Fixed nested‑optional‑argument parsing
   – All previous features (sections, sorting, tables, “or”, etc.)
   -------------------------------------------------------------- */

import fs from 'node:fs';
import path from 'node:path';
import { RateLimiter } from "limiter";
import { Agent } from "undici";


// ---------------------------------------------------------------------------
// Helper utilities
// ---------------------------------------------------------------------------

// Rate-limit requests to MA's docs to 10 requests every 100ms
const limiter = new RateLimiter({ tokensPerInterval: 10, interval: 100 });

async function check_docs_exists(url) {
    try {
      const remaining_tokens = await limiter.removeTokens(1);
      const res = await fetch(url, { method: 'HEAD', dispatcher: new Agent({ connectTimeout: 30 * 1000 }) });
      return res.ok;
    } catch (e) {
      console.log('Error for fetch: ', url, e)
      return false;
    }
  }


/**
 * Strip surrounding square brackets that mark an optional argument.
 */
function stripOptionalBrackets(str) {
  const trimmed = str.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    return { text: trimmed.slice(1, -1).trim(), optional: true };
  }
  return { text: trimmed, optional: false };
}

/**
 * Strip surrounding curly braces that may wrap a return list.
 */
function stripCurlyBraces(str) {
  const trimmed = str.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return trimmed.slice(1, -1).trim();
  }
  return trimmed;
}

/**
 * Split a comma‑separated list **ignoring commas that are inside
 * square brackets [] or curly braces {}**.
 */
function splitRespectingBrackets(str) {
  const parts = [];
  let cur = '';
  let depthSq = 0; // [] depth
  let depthCu = 0; // {} depth

  for (let i = 0; i < str.length; i++) {
    const ch = str[i];
    if (ch === '[') depthSq++;
    if (ch === ']') depthSq = Math.max(depthSq - 1, 0);
    if (ch === '{') depthCu++;
    if (ch === '}') depthCu = Math.max(depthCu - 1, 0);

    if (ch === ',' && depthSq === 0 && depthCu === 0) {
      parts.push(cur.trim());
      cur = '';
    } else {
      cur += ch;
    }
  }
  if (cur.trim()) parts.push(cur.trim());
  return parts;
}

/**
 * Split a token that may contain “or” alternatives.
 * Example:  "integer:foo or string:foo"
 */
function parseOrAlternatives(token) {
  const cleaned = token.trim();
  const alts = cleaned.split(/\s+or\s+/i).map(t => t.trim());

  return alts.map(alt => {
    const parts = alt.split(':');
    if (parts.length !== 2) return { type: alt, name: '' };
    return { type: parts[0].trim(), name: parts[1].trim() };
  });
}

/**
 * Parse a **single argument** token (no outer optional brackets).
 * Handles:
 *   – normal typed arguments (with “or”)
 *   – Lua table literals (starting with `{` and ending with `}`)
 */
function parseArgument(token) {
  // Table argument?
  if (token.startsWith('{') && token.endsWith('}')) {
    return {
      name: '',
      optional: false,
      types: [{ type: 'table', name: '' }],
      rawTable: token,
    };
  }
  if (token.startsWith('table of')) {
    return {
      name: '',
      types: [{ type: 'table', name: '' }],
      rawTable: token.replace('table of','').trim(),
    };
  }

  // Normal typed argument
  const nameIdx = token.lastIndexOf(':');
  if (nameIdx === -1) {
    return {
      name: '',
      optional: false,
      types: [{ type: token, name: '' }],
    };
  }

  const name = token.slice(nameIdx + 1).trim();
  const typePart = token.slice(0, nameIdx).trim();

  const types = parseOrAlternatives(typePart).map(o => ({
    type: o.type,
    name: '',
  }));

  return { name, optional: false, types };
}

// /**
//  * Parse a **single return** token.
//  * Handles:
//  *   – normal returns (with “or”)
//  *   – Lua table literals
//  */
// function parseArgument(token) {
//   const cleaned = stripCurlyBraces(token);

//   // Table return?
//   if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
//     return {
//       name: '',
//       types: [{ type: 'table', name: '' }],
//       rawTable: cleaned,
//     };
//   }
//   if (cleaned.startsWith('table of')) {
//     return {
//       name: '',
//       types: [{ type: 'table', name: '' }],
//       rawTable: cleaned.replace('table of','').trim(),
//     };
//   }

//   const nameIdx = cleaned.lastIndexOf(':');
//   if (nameIdx === -1) {
//     const types = parseOrAlternatives(cleaned).map(o => ({
//       type: o.type,
//       name: '',
//     }));
//     return { name: '', types };
//   }

//   const name = cleaned.slice(nameIdx + 1).trim();
//   const typePart = cleaned.slice(0, nameIdx).trim();

//   const types = parseOrAlternatives(typePart).map(o => ({
//     type: o.type,
//     name: '',
//   }));

//   return { name, types };
// }

/**
 * **Recursive extractor** that turns the raw argument string into an
 * array of fully‑parsed argument objects, correctly handling *nested*
 * optional brackets.
 *
 * Example input:
 *   "string:command[, light_userdata:undo[, light_userdata:target]]"
 * Returns three argument objects – the last two marked optional.
 */
function extractArguments(raw, forcedOptional = false) {
  raw = raw.trim();
  if (!raw) return [];

  // Whole chunk wrapped in optional brackets → mark everything inside as optional
  if (raw.startsWith('[') && raw.endsWith(']')) {
    const inner = raw.slice(1, -1).trim();               // drop outer [...]
    const pieces = splitRespectingBrackets(inner);       // split inner commas
    // Recurse, forcing optional = true for everything inside
    return pieces.flatMap(p => extractArguments(p, true));
  }

  // No outer brackets – split on commas that are *not* inside brackets
  const pieces = splitRespectingBrackets(raw);
  return pieces.flatMap(p => {
    // A piece may itself start with '[' (e.g. "light_userdata:undo[, light_userdata:target]")
    if (p.startsWith('[') && p.endsWith(']')) {
      // Treat the inner optional group separately
      return extractArguments(p, true);
    }

    // Normal argument – parse it and apply the forcedOptional flag if needed
    const parsed = parseArgument(p);
    if (forcedOptional) parsed.optional = true;
    return parsed;
  });
}

/**
 * Render arguments as a Markdown bullet list.
 */
function argsToMarkdown(args) {
  if (!args.length) return '_none_';
  if (args.length === 1 && args[0].types[0].type === 'nothing')
    return 'No Arguments';

  return args
    .map(arg => {
      const typeList = arg.types
        .map(t => `**\`${t.type}\`**`)
        .join(' **or** ');
      const opt = arg.optional ? '`optional`' : '`mandatory`';
      const name = arg.name ? arg.name : '';
      const extra = arg.rawTable ? ' – table definition' : '';
      return `- ${typeList} (${opt}): ${name} ${extra}`;
    })
    .join('\n');
}

/**
 * Render returns as a Markdown bullet list.
 */
function returnsToMarkdown(rets) {
  if (!rets.length) return '_none_';
  if (rets.length === 1 && rets[0].types[0].type === 'nothing')
    return 'No Returns';

  return rets
    .map(ret => {
      const typeList = ret.types
        .map(t => `**\`${t.type}\`**`)
        .join(' **or** ');
      const name = ret.name ? ret.name : '';
      const extra = ret.rawTable ? ` – table definition: \`\`\`${ret.rawTable}\`\`\`` : '';
      return `- ${typeList}: ${name} ${extra}`;
    })
    .join('\n');
}


// Main
export async function GenerateFunctionsMarkDown(version = 'v2.0') {
  const DIR = `src/content/docs/grandma3/${version}`;
  const input_file = path.resolve(DIR, 'data', 'grandMA3_lua_functions.txt');
  const output_file = path.resolve(DIR, 'api.mdx');
  const version_short = version.replace(/^v/, '');
  const DOCS_BASE_URL = `https://help.malighting.com/grandMA3/${version_short}/HTML/`;

  if (!fs.existsSync(input_file)) {
    console.error(`❌ Input file not found: ${input_file}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(input_file, 'utf8');

  // -----------------------------------------------------------------------
  // 1️⃣ Split into the two logical sections
  // -----------------------------------------------------------------------
  const sections = {
    'Object-Free API': [],
    'Object API': [],
  };

  let current_section = null;
  raw.split(/\r?\n/).forEach(line => {
    const trimmed = line.trim();
    if (trimmed === 'Object-Free API') current_section = 'Object-Free API';
    else if (trimmed === 'Object API') current_section = 'Object API';
    else if (
      current_section &&
      /^[A-Za-z_]\w*\s*\(.*\)\s*:/.test(trimmed)
    ) {
      sections[current_section].push(trimmed);
    }
  });

  // -----------------------------------------------------------------------
  // 2️⃣ Parse every function and store it in a nested object
  // -----------------------------------------------------------------------
  const make_doc_url = (section, func) => {
    const section_slug = section.toLowerCase().replace('-', '').split(' ')[0]; // "Object-Free API" becomes "objectfree"
    const url = `${DOCS_BASE_URL}lua_${section_slug}_${func.toLowerCase().trim()}.html`;
    return url;
  }

  const api = {};

  for (const [section, lines] of Object.entries(sections)) {
    api[section] = {};

    for (const line of lines) {
      const match = line.match(/^([A-Za-z_]\w*)\s*\(([^)]*)\)\s*:\s*(.*)$/);
      if (!match) continue; // safety

      const [, fn_name, args_raw, returns_raw] = match;

      // ----------- Arguments (fixed optional handling) --------------------
      const args = extractArguments(args_raw);

      // ----------- Returns ------------------------------------------------
      const rets = extractArguments(returns_raw);
      // const rets = [];
      // if (returns_raw.trim() !== '' && returns_raw.trim() !== 'nothing') {
      //   const retTokens = splitRespectingBrackets(returns_raw);
      //   for (const token of retTokens) {
      //     rets.push(parseReturn(token));
      //   }
      // }


      // Store the fully parsed representation
      api[section][fn_name] = {
        signature: line,
        arguments: args,
        returns: rets,
        docs: false,
      };
    }
  }

  // Check if official docs for each function exists.
  const doc_checks = Object.keys(api).map(async (section) => {
    await Promise.all(Object.keys(api[section]).map(async (fn_name) => {
      const url = make_doc_url(section, fn_name);
      const exists = await check_docs_exists(url);

      api[section][fn_name].docs = exists ? url : false;
    }));
  });
  await Promise.all(doc_checks);

  // -----------------------------------------------------------------------
  // 3️⃣ Build the markdown output (alphabetical order per section)
  // -----------------------------------------------------------------------
    let markdown = `
---
title: LUA Functions
description: The LUA API for grandMA3 version ${version}
version: ${version}
---
import { Aside, Badge } from '@astrojs/starlight/components';

<Aside type="tip">
  Only some functions have an entry in the official grandMA User Manual.
  If this is the case, a <Badge text="Official Docs" variant="note"/> badge will be present.
  You can click on the badge to open the corresponding page in the official User Manual.
</Aside>
`;
  markdown = markdown.split('\n');


  for (const section of ['Object-Free API', 'Object API']) {
    const funcNames = Object.keys(api[section] ?? {})
      .sort((a, b) => a.localeCompare(b));

    if (!funcNames.length) continue;

    markdown.push(`## ${section}`);
    markdown.push('');

    for (const fn_name of funcNames) {
      const fn = api[section][fn_name];

      if (fn.docs) {
        markdown.push(`### ${fn_name} <a href="${fn.docs}" target="_blank" rel="noopener noreferrer"><Badge text="Official Docs" variant="note" style="margin-left:25px;"/></a>`);
      }
      else {
        markdown.push(`### ${fn_name}`);
      }
      markdown.push('');
      markdown.push('**Signature**');
      markdown.push('```lua');
      markdown.push(fn.signature);
      markdown.push('```');
      markdown.push('');
      markdown.push('**Arguments**');
      markdown.push('');
      markdown.push(argsToMarkdown(fn.arguments));
      markdown.push('');
      markdown.push('**Returns**');
      markdown.push('');
      markdown.push(returnsToMarkdown(fn.returns));
      markdown.push('\n---\n');
    }
  }

  // -----------------------------------------------------------------------
  // 4️⃣ Write the markdown file
  // -----------------------------------------------------------------------
  fs.writeFileSync(output_file, markdown.join('\n'), 'utf8');
  console.log(`✅ Markdown generated at ${output_file}`);

}



// Run when called standalone (for debug)
// GenerateFunctionsMarkDown('v2.0');
