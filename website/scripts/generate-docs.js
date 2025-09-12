#!/usr/bin/env node
import path from 'node:path';
import fs from 'node:fs';
import { Command } from 'commander';

import { ParseFunctions, GenerateFunctionsMarkDown } from './generate-lua-functions.js';
import { ParseEnums, GenerateEnumsMarkDown } from './generate-lua-enums.js';
import { ParseTree, GenerateTreeMarkDown } from './generate-object-tree.js';
import { ProcessDiff, GenerateChangelogMarkDown } from './generate-changelog.js';


const VERSIONS = ["v2.0", "v2.1", "v2.2", "v2.3"];
const BASE_DIR = "src/content/docs/grandma3";
const FILENAMES = {
    fonctions: {
        raw: 'grandMA3_lua_functions.json',
        clean: 'functions.json',
        docs: 'api.mdx',
    },
    enums: {
        raw: 'grandMA3_lua_enums.json',
        clean: 'enums.json',
        docs: 'enums.mdx',
    },
    tree: {
        raw: 'grandMA3_object_tree.json',
        clean: 'tree.json',
        docs: 'tree.mdx',
    },
    changelog: {
        docs: 'changelog.mdx',
    }
};



function export_json(filename, data) {
    fs.writeFileSync(filename, JSON.stringify(data, null, 2), 'utf8');
    console.log(`✅ Output written at ${filename}`);
}


function import_json(filename) {
    if (!fs.existsSync(filename)) {
        console.error(`❌ Input file not found: ${filename}`);
        process.exit(1);
    }

    const raw = fs.readFileSync(filename, 'utf8');
    const json = JSON.parse(raw);
    return json;
}


async function ParseDocs(opts, cmd) {
    const options = cmd.optsWithGlobals();

    for (const version of options.version) {
        console.log("➡️  Parsing data for grandMA3", version);
        const dir = path.resolve(BASE_DIR, version, 'data');

        if (options.functions) {
            console.log(" 1. Parsing functions");
            const input_file = path.resolve(dir, FILENAMES.fonctions.raw);
            const output_file = path.resolve(dir, FILENAMES.fonctions.clean);
            const data = await ParseFunctions(version, input_file, output_file, options.functionsCheck);
            export_json(output_file, data);
        }
        if (options.enums) {
            console.log(" 2. Parsing enums");
            const input_file = path.resolve(dir, FILENAMES.enums.raw);
            const output_file = path.resolve(dir, FILENAMES.enums.clean);
            const data = ParseEnums(version, input_file, output_file);
            export_json(output_file, data);
        }
        if (options.tree) {
            console.log(" 3. Parsing tree");
            const input_file = path.resolve(dir, FILENAMES.tree.raw);
            const output_file = path.resolve(dir, FILENAMES.tree.clean);
            const data = ParseTree(version, input_file, output_file);
            export_json(output_file, data);
        }
    }

}



function GenerateDocs(opts, cmd) {
    const options = cmd.optsWithGlobals();
    const data = {};

    const load_version = (version) => {
        const dir = path.resolve(BASE_DIR, version);
        data[version] = {};

        if (options.functions) {
            const input_file = path.resolve(dir, 'data', FILENAMES.fonctions.clean);
            data[version].functions = import_json(input_file);
        }
        if (options.enums) {
            const input_file = path.resolve(dir, 'data', FILENAMES.enums.clean);
            data[version].enums = import_json(input_file);
        }
        if (options.tree) {
            const input_file = path.resolve(dir, 'data', FILENAMES.tree.clean);
            data[version].tree = import_json(input_file);
        }
    }

    for (const version of options.version) {
        console.log("➡️  Generating docs for grandMA3", version);
        const dir = path.resolve(BASE_DIR, version);
        load_version(version);

        if (options.diff) { // First compute diff and modify data object accordingly
            const idx = VERSIONS.indexOf(version);
            if (idx >= 1) {
                const prev_version = VERSIONS[idx - 1];
                load_version(prev_version); // always reload previous version to ensure clean data state
                data[version].diffs = ProcessDiff(version, prev_version, data, options);
            }
        }
        if (options.functions) {
            console.log(" 1. Generating functions");
            const output_file = path.resolve(dir, FILENAMES.fonctions.docs);
            GenerateFunctionsMarkDown(version, data[version].functions, output_file);
        }
        if (options.enums) {
            console.log(" 2. Generating enums");
            const output_file = path.resolve(dir, FILENAMES.enums.docs);
            GenerateEnumsMarkDown(version, data[version].enums, output_file);
        }
        if (options.tree) {
            console.log(" 3. Generating tree");
            const output_file = path.resolve(dir, FILENAMES.tree.docs);
            GenerateTreeMarkDown(version, data[version].tree, output_file);
        }
        if (options.diff) {
            const idx = VERSIONS.indexOf(version);
            if (idx >= 1) {
                console.log(" 4. Generating changelog");
                const output_file = path.resolve(dir, FILENAMES.changelog.docs);
                GenerateChangelogMarkDown(version, data[version].diffs, output_file)
            }
        }
    }
}




// Run Standalone
const program = new Command();
program.option('-v, --version <version...>', 'Run for versions "vX.Y"', VERSIONS)
       .option('--no-functions', 'Do not generate functions files')
       .option('--no-enums', 'Do not generate enums files')
       .option('--no-tree', 'Do not generate tree files')
       .option('--no-diff', 'Do not generate changelog files');

program.command('parse')
       .description('Parse the raw files and output clean json files')
       .option('--no-functions-check', 'Do not run functions checks')
       .action(ParseDocs);

program.command('generate')
       .description('Generate the markdown docs')
       .action(GenerateDocs);

program.parse();
