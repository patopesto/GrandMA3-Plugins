import fs from 'node:fs';

import { ParseJson } from './grandma3-json-parser.js'
import { BadgeVariants } from './generate-changelog.js';



export function ParseEnums(version = "v2.0", input_file) {
  
  if (!fs.existsSync(input_file)) {
    console.error(`❌ Input file not found: ${input_file}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(input_file, 'utf8');
  const enums = ParseJson(raw);
  if (enums == null) {
    process.exit(1);
  }

  const parsed = {}
  for (const [key, value] of Object.entries(enums)) {
    const filtered = Object.fromEntries( // remove 'unnamed' keys
      Object.entries(value) .filter(([key]) => key !== 'unnamed')
    );
    parsed[key] = {
      items: filtered,
    }
  }

  return parsed;
}


function object_to_markdown(name, object, markdown) {

  let title = `### ${name} `;
  if (object.changelog) {
    const {text, variant} = BadgeVariants[object.changelog];
    title += ` :badge[${text}]{variant=${variant}}`;
  }
  markdown.push(title);
  markdown.push('');

  // Sort by values
  const sorted = Object.fromEntries(
    Object.entries(object.items).sort((a, b) => {
      const diff = a[1] - b[1];
      if (diff !== 0) return diff; // sort by value
      return a[0].localeCompare(b[0], undefined, { caseFirst: 'lower' }); // sort by key if same values
    })
  );

  markdown.push('| Name | Value | Usage');
  markdown.push('| ---- | ----- | -----');
  for (const [key, value] of Object.entries(sorted)) {
    markdown.push(`| \`${key}\` | ${value} | \`Enums.${name}.${key}\``);
  }

  markdown.push('');

}



export function GenerateEnumsMarkDown(version = "v2.0", enums, output_file) {

  let markdown =
`---
title: LUA Enums
description: The LUA Enums for grandMA3 ${version}
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

  const sorted = Object.keys(enums).sort() // Sort by keys

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
