#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { ParseJson } from './grandma3-json-parser.js'



function object_to_markdown(title, object, markdown) {

  markdown.push(`### ${title}`);
  markdown.push('');

  // Sort by values
  const sorted = Object.fromEntries(
    Object.entries(object).sort(([,a],[,b]) => a - b)
  );

  markdown.push('| Name | Value | Usage');
  markdown.push('| ---- | ----- | -----');
  for (const [key, value] of Object.entries(sorted)) {
    markdown.push(`| \`${key}\` | ${value} | \`Enums.${title}.${key}\``);
  }

}


// Main 
export function GenerateEnumsMarkDown(version = "v2.0") {
  const DIR = `src/content/docs/grandma3/${version}`;
  const input_file = path.resolve(DIR, 'data', 'grandMA3_lua_enums.json');
  const output_file = path.resolve(DIR, 'enums.mdx');

  if (!fs.existsSync(input_file)) {
    console.error(`❌ Input file not found: ${input_file}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(input_file, 'utf8');
  const enums = ParseJson(raw);
  if (enums == null) {
    process.exit(1);
  }
  const sorted = Object.keys(enums).sort() // Sort by keys

  // const pretty = JSON.stringify(enums, null, 2);
  // console.log(enums);

  let markdown =
`---
title: LUA Enums
description: The LUA Enums for grandMA3 version ${version}
version: ${version}
---
import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">
  The following enums can be access from the global \`Enums\` object available
  in LUA.

  \`\`\`lua
  Printf(Enums.AgendaMode.Sunset)
  \`\`\`
  Also shown in the **Usage** column for each value
</Aside>   
`;
  markdown = markdown.split('\n');

  // // Main object
  // markdown.push(`## Enums`);
  // markdown.push('');
  // for (const key of sorted) {
  //   markdown.push(`- [\`${key}\`](#${key.toLowerCase()})`);
  // }

  // Sub Objects
  for (const key of sorted) {
    object_to_markdown(key, enums[key], markdown)
  }


  fs.writeFileSync(output_file, markdown.join('\n'), 'utf8');
  console.log(`✅ Markdown generated at ${output_file}`);

}



// Run when called standalone (for debug)
// GenerateEnumsMarkDown("v2.0");
