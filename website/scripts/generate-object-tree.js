#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import GithubSlugger from 'github-slugger';
import { ParseJson } from './grandma3-json-parser.js';


const MAX_CHILDS = 30
const slugger = new GithubSlugger()


function object_to_markdown(object, markdown, level = 1) {

  if (level >= 7) { // Markdown is not rendered after this
    level = 6;
  }
  markdown.push(`${"#".repeat(level)} \`${object.name}\``);
  markdown.push('');

  markdown.push(`**Class**: ${object.class}  `);
  markdown.push(`**Index**: ${object.index}  `);
  markdown.push(`**Addr**: \`${object.addr}\`  `);
  markdown.push(`**Path**: \`${object.path}\`  `);

  if (object.children !== undefined) {
    markdown.push('');
    markdown.push(`**Children**:`);

    let i = 1;
    for (const child of object.children) {
      markdown.push(`${child.index}. [\`${child.name}\`](#${slugger.slug(child.name)})`);
      
      if (i == MAX_CHILDS) {
        markdown.push(`${child.index}. \`...\` (list truncated for brevity)`);
        break;
      }
      i += 1;
    }

    if (object.children.length <= MAX_CHILDS) {
      markdown.push('');
      for (const child of object.children) {
        object_to_markdown(child, markdown, level + 1)
      }
    }
  }
  markdown.push('');
}


function tree_to_markdown(object, markdown, level = 0) {

  markdown.push(`${"    ".repeat(level)}- ${object.index} [\`${object.name}\`](#${slugger.slug(object.name)})`);
  
  if (object.children !== undefined) {
    let i = 1;
    for (const child of object.children) {
      tree_to_markdown(child, markdown, level + 1)
      if (i == MAX_CHILDS) {
        markdown.push(`${"    ".repeat(level + 1)}- ... (list truncated for brevity)`);
        break;
      }
      i += 1;
    }
  }
}


// Main 
export function GenerateTreeMarkDown(version = "v2.0") {
  const DIR = `src/content/docs/grandma3/${version}`;
  const input_file = path.resolve(DIR, 'data', 'grandMA3_object_tree.json');
  const output_file = path.resolve(DIR, 'tree.mdx');

  if (!fs.existsSync(input_file)) {
    console.error(`❌ Input file not found: ${input_file}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(input_file, 'utf8');
  const tree = ParseJson(raw);
  if (tree == null) {
    process.exit(1);
  }

  let markdown = 
`---
title: Data Tree
description: The Data Tree for grandMA3 version ${version}
version: ${version}
tableOfContents:
  minHeadingLevel: 1
  maxHeadingLevel: 5
---
import { Aside, FileTree } from '@astrojs/starlight/components';

<Aside type="tip">
  This is a dump of the data tree from a demo showfile.
  The **Addr** or **Path** can be used in CLI commands or LUA

  Usage in grandMA3 CLI:
  \`\`\`lua
  List <Addr>
  -- OR
  List <Path>
  \`\`\`

  Usage in LUA:
  \`\`\`lua
  local handle = FromAddr("<Addr>")
  \`\`\`

</Aside>   
`;
  markdown = markdown.split('\n');

  // Tree
  // markdown.push('# Tree');
  // markdown.push('');
  // markdown.push('<FileTree>');
  // tree_to_markdown(tree, markdown);
  // markdown.push('</FileTree>');

  // Traverse
  object_to_markdown(tree, markdown);

  fs.writeFileSync(output_file, markdown.join('\n'), 'utf8');
  console.log(`✅ Markdown generated at ${output_file}`);

}



// Run when called standalone (for debug)
// GenerateTreeMarkDown("v2.0");
