import fs from 'node:fs';
import path from 'node:path';
import rdiff from 'recursive-diff';
import { slug } from 'github-slugger'

import { ParseJson } from './grandma3-json-parser.js'



export function ProcessDiff(version = "v2.1", prev_version = "v2.0", data, options) {

  const diffs = {}
  if (options.functions) {
      const result = rdiff.getDiff(data[prev_version].functions, data[version].functions);
      diffs.functions = result.filter((diff) => {
        if (diff.path.length == 3 && diff.path[2] == 'docs') return false; // remove diffs which are about docs url change
        return true;
      });

      // Edit main data object
      for (const diff of diffs.functions) {
        if (diff.op == 'delete') continue;

        const [section, name, other] = diff.path;
        if (other !== undefined) {
          data[version].functions[section][name].changelog = 'update'; // consider add/delete of parameters as an update
          continue;
        }
        data[version].functions[section][name].changelog = diff.op;
      }
  }
  if (options.enums) {
      diffs.enums = rdiff.getDiff(data[prev_version].enums, data[version].enums);

      // Edit main data object
      for (const diff of diffs.enums) {
        if (diff.op == 'delete') continue;

        const [name, key] = diff.path;
        if (key !== undefined) {
          data[version].enums[name].changelog = 'update'; // consider add/delete of items as an update
          continue;
        }
        data[version].enums[name].changelog = diff.op;
      }
  }
  if (options.tree) {
      diffs.tree = rdiff.getDiff(data[prev_version].tree, data[version].tree);
  }

  // console.log(diffs);
  return diffs;
}



export const BadgeVariants = {
  "add":    { text: "New", variant: "success" },
  "update": { text: "Changed", variant: "caution" },
  "delete": { text: "Removed", variant: "danger" },
};


export function GenerateChangelogMarkDown(version = "v2.0", diffs, output_file) {
  const version_short = version.replace(/^v/, '');
  const RELEASE_NOTES_URL = `https://help.malighting.com/grandMA3/${version_short}/HTML/key_releasenotes.html`;

  let markdown =
`---
title: Changelog
description: The changelog for grandMA3 version ${version}
version: ${version}
sidebar:
  order: 1
--- 
import { Aside, Badge } from '@astrojs/starlight/components';
import ReadMore from '@components/ReadMore.astro';

<Aside>
  <ReadMore>Read the <a href="${RELEASE_NOTES_URL}" target="_blank" rel="noopener noreferrer">Official Release Notes</a></ReadMore>
</Aside>

`;
  markdown = markdown.split('\n');

  if (diffs.functions !== undefined) {
    const sections = {
      objectfree: "Object-Free API",
      object: "Object API",
    };

    const functions = {};

    for (const diff of diffs.functions) {
      let op = diff.op;
      const [section, name, other] = diff.path;
      if (other !== undefined) op = 'update'; // consider add/delete of parameters as an update
      if (functions[section] === undefined) functions[section] = {}
      if (functions[section][op] === undefined) functions[section][op] = {}
      if (functions[section][op][name] === undefined) functions[section][op][name] = []
      functions[section][op][name].push(diff)
    }

    markdown.push('## Functions');
    markdown.push('');

    for (const section of Object.keys(functions).sort().reverse()) {

      markdown.push(`### ${sections[section]}`);
      markdown.push('');

      for (const op_type of ['add', 'update', 'delete']) {
        if (functions[section][op_type] === undefined) continue;

        for (const name of Object.keys(functions[section][op_type]).sort()) {
          const func = functions[section][op_type][name][0];
          const {text, variant} = BadgeVariants[op_type];
          if (op_type == 'add') markdown.push(`<Badge text="${text}" variant="${variant}"/> [${func.path[1]}](../api/#${slug(name)})`);
          if (op_type == 'update') markdown.push(`<Badge text="${text}" variant="${variant}"/> [${func.path[1]}](../api/#${slug(name)})`);
          if (op_type == 'delete') markdown.push(`<Badge text="${text}" variant="${variant}"/> ${func.path[1]}`);
          markdown.push('');
        }
      }
    }
  }

  if (diffs.enums !== undefined) {

    const enums = {};

    for (const diff of diffs.enums) {
      let op = diff.op;
      const [name, key] = diff.path;
      if (key !== undefined) op = 'update'; // consider add/delete of items as an update
      if (enums[op] === undefined) enums[op] = {}
      if (enums[op][name] === undefined) enums[op][name] = []
      enums[op][name].push(diff)
    }

    markdown.push('## Enums');
    markdown.push('');

    for (const op_type of ['add', 'update', 'delete']) {
      if (enums[op_type] === undefined) continue;

      for (const name of Object.keys(enums[op_type]).sort()) {
        const en = enums[op_type][name][0];
        const {text, variant} = BadgeVariants[op_type];
        if (op_type == 'add') markdown.push(`<Badge text="${text}" variant="${variant}"/> [${en.path[0]}](../enums/#${slug(name)})`);
        if (op_type == 'update') markdown.push(`<Badge text="${text}" variant="${variant}"/> [${en.path[0]}](../enums/#${slug(name)})`);
        if (op_type == 'delete') markdown.push(`<Badge text="${text}" variant="${variant}"/> ${en.path[0]}`);
        markdown.push('');
      }
    }

  }


  fs.writeFileSync(output_file, markdown.join('\n'), 'utf8');
  console.log(`✅ Markdown generated at ${output_file}`);

}
