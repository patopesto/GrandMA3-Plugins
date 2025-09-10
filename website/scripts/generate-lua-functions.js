#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { RateLimiter } from "limiter";
import { Agent } from "undici";


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



// Split a comma‑separated list ignoring commas that are inside {} or ().
function split_arguments(str) {
  const parts = [];
  let cur = '';
  let depth_sq = 0; // [] depth
  let depth_cu = 0; // {}/() depth

  for (let i = 0; i < str.length; i++) {
    const ch = str[i];
    if (ch === '[') depth_sq++;
    if (ch === ']') depth_sq = Math.max(depth_sq - 1, 0);
    if (ch === '{') depth_cu++;
    if (ch === '}') depth_cu = Math.max(depth_cu - 1, 0);
    if (ch === '(') depth_cu++;
    if (ch === ')') depth_cu = Math.max(depth_cu - 1, 0);

    if (ch === ',' && depth_cu === 0) {
      parts.push(cur.trim());
      cur = '';
    }
    else {
      cur += ch;
    }
  }

  if (cur.trim()) parts.push(cur.trim());
  return parts;
}


// Split on first ':' if not inside {},[] or ()
function split_arg_type(str) {
  let type = str;
  let name = "";
  let cur = '';
  let depth = 0;
  let found = false;

  for (let i = 0; i < str.length; i++) {
    const ch = str[i];
    if (ch === '[') depth++;
    if (ch === ']') depth = Math.max(depth - 1, 0);
    if (ch === '{') depth++;
    if (ch === '}') depth = Math.max(depth - 1, 0);
    if (ch === '(') depth++;
    if (ch === ')') depth = Math.max(depth - 1, 0);

    if (ch === ':' && depth === 0 && found == false) {
      type = cur.trim();
      cur = '';
      found = true;
    }
    else {
      cur += ch;
    }
  }

  if (found) name = cur.trim();
  return [type, name];
}


function parse_arguments(str) {
  const parts = split_arguments(str);
  const args = []

  let next_is_optional = false
  for (let part of parts) {
    let arg = part.trim();
    let optional = false;
    if (arg.endsWith(']') || next_is_optional) {
      next_is_optional = false
      optional = true
      arg = arg.replace(/]+$/, ''); // remove all ']' at the end
    }
    if (arg.endsWith('[')) {
      arg = arg.slice(0, -1);
      next_is_optional = true;
    }
    if (arg.startsWith('[')) {
      arg = arg.slice(1);
      optional = true;
    }

    const [type, name] = split_arg_type(arg);

    if (type !== "nothing") {
      args.push({
        raw: part,
        name: name.trim(),
        type: type.trim(),
        optional: optional,
      })
    }
  }

  return args;
}


function parse_function(name, data) {
  const { args, returns } = data;

  const signature = `${name}(${args}): ${returns}`;
  const parsed = {
    signature: signature,
    arguments: parse_arguments(args.trim()),
    returns: parse_arguments(returns.trim()),
    docs: false,
  }

  // console.log(name);
  // console.log(parsed);
  return parsed;
}


function function_to_markdown(name, func, markdown) {

  if (func.docs) {
    markdown.push(`### ${name} <a href="${func.docs}" target="_blank" rel="noopener noreferrer"><Badge text="Official Docs" variant="note" style="margin-left:25px;"/></a>`);
  }
  else {
    markdown.push(`### ${name}`);
  }
  markdown.push('');
  markdown.push('**Signature**');
  markdown.push('```lua');
  markdown.push(func.signature);
  markdown.push('```');
  markdown.push('');
  markdown.push('**Arguments**');
  markdown.push('');

  if (func.arguments.length) {
    for (let i = 0; i < func.arguments.length; i++) {
      const arg = func.arguments[i];
      const opt = arg.optional ? '**(optional)**' : '';
      const name = arg.name ? arg.name : '';
      markdown.push(`${i + 1}. **\`${arg.type}\`** ${opt}: ${name}`)
    }
  }
  else {
    markdown.push('No Arguments');
  }

  markdown.push('');
  markdown.push('**Returns**');
  markdown.push('');

  if (func.returns.length) {
    for (const arg of func.returns) {
      const name = arg.name ? arg.name : '';
      markdown.push(`- **\`${arg.type}\`**: ${name}`)
    }
  }
  else {
    markdown.push('No Return');
  }
  markdown.push('\n---\n');

}


// Main 
export async function GenerateFunctionsMarkDown(version = "v2.0", check_docs = true) {
  const DIR = `src/content/docs/grandma3/${version}`;
  const input_file = path.resolve(DIR, 'data', 'grandMA3_lua_functions.json');
  const output_file = path.resolve(DIR, 'api.mdx');
  const version_short = version.replace(/^v/, '');
  const DOCS_BASE_URL = `https://help.malighting.com/grandMA3/${version_short}/HTML/`;

  if (!fs.existsSync(input_file)) {
    console.error(`❌ Input file not found: ${input_file}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(input_file, 'utf8');
  const funcs = JSON.parse(raw);
  if (funcs == null) {
    process.exit(1);
  }

  const pretty = JSON.stringify(funcs, null, 2);
  console.log(pretty);

  const functions = {};
  for (const section of Object.keys(funcs)) {
    functions[section] = {};
    for (const [name, data] of Object.entries(funcs[section])) {
      functions[section][name] = parse_function(name, data);
    }
  }

  const make_doc_url = (section, func) => {
    const section_slug = section.toLowerCase().replace('-', '').split(' ')[0]; // "Object-Free API" becomes "objectfree"
    const url = `${DOCS_BASE_URL}lua_${section_slug}_${func.toLowerCase().trim()}.html`;
    return url;
  }

  // Check if official docs for each function exists.
  if (check_docs) {
    const doc_checks = Object.keys(functions).map(async (section) => {
      await Promise.all(Object.keys(functions[section]).map(async (fn_name) => {
        const url = make_doc_url(section, fn_name);
        const exists = await check_docs_exists(url);

        functions[section][fn_name].docs = exists ? url : false;
      }));
    });
    await Promise.all(doc_checks);
  }

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

  const sections = {
    objectfree: "Object-Free API",
    object: "Object API",
  }

  for (const section of Object.keys(functions)) {
    const sorted = Object.keys(functions[section]).sort((a, b) => a.localeCompare(b)); // sort alphabetically

    if (!sorted.length) continue;

    const title = sections[section];
    markdown.push(`## ${title}`);
    markdown.push('');

    for (const name of sorted) {
      const func = functions[section][name];

      function_to_markdown(name, func, markdown);
    }
  }


  fs.writeFileSync(output_file, markdown.join('\n'), 'utf8');
  console.log(`✅ Markdown generated at ${output_file}`);

}



// Run when called standalone (for debug)
GenerateFunctionsMarkDown("v2.0");
