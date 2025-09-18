import fs from 'node:fs';
import path from 'node:path';
import GithubSlugger from 'github-slugger';

import { ParseJson } from './grandma3-json-parser.js';


const MAX_CHILDS = 30
let slugger = new GithubSlugger()


export function ParseTree(version = "v2.0", input_file) {

  if (!fs.existsSync(input_file)) {
    console.error(`❌ Input file not found: ${input_file}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(input_file, 'utf8');
  const tree = ParseJson(raw);
  if (tree == null) {
    process.exit(1);
  }

  return tree;
}



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
    markdown.push(`**Children** (${object.children.length}):`);

    let i = 1;
    for (const child of object.children) {
      markdown.push(`${child.index}. [\`${child.name}\`](#${slugger.slug(child.name)})`);
      
      if (i == MAX_CHILDS) {
        markdown.push(`${child.index}. \`...\` (list truncated for brevity)`);
        break;
      }
      i += 1;
    }

    i = 1;
    markdown.push('');
    for (const child of object.children) {
      if (i == MAX_CHILDS) break;

      object_to_markdown(child, markdown, level + 1)
      i += 1;
    }

  }
  markdown.push('');
}


function tree_to_markdown(object, markdown, level = 0) {

  if (level > 0) { // Skipping root object to keep all first child visible by default
    markdown.push(`${"    ".repeat(level)}- ${object.index} [\`${object.name}\`](#${slugger.slug(object.name)})`);
  }
  
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


export function GenerateTreeMarkDown(version = "v2.0", tree, output_file) {

  let markdown = 
`---
title: Data Tree
description: The Data Tree for grandMA3 ${version}
version: ${version}
tableOfContents:
  minHeadingLevel: 1
  maxHeadingLevel: 5
---
import { Aside } from '@astrojs/starlight/components';
import DataTree from '@components/DataTree.astro';

<Aside type="tip">
  This is a dump of the data tree from the \`Simple_show\` Demo Showfile.
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
  slugger = new GithubSlugger()
  markdown.push('# Interactive Tree');
  markdown.push('');
  markdown.push('<DataTree>');
  tree_to_markdown(tree, markdown);
  markdown.push('</DataTree>');

  // Traverse
  slugger = new GithubSlugger() // Reset heading slugs
  object_to_markdown(tree, markdown);

  fs.writeFileSync(output_file, markdown.join('\n'), 'utf8');
  console.log(`✅ Markdown generated at ${output_file}`);

  return tree;
}
