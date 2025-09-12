#!/usr/bin/env node
import { Command } from 'commander';
import { GenerateFunctionsMarkDown } from './generate-lua-functions.js'
import { GenerateEnumsMarkDown } from './generate-lua-enums.js'
import { GenerateTreeMarkDown } from './generate-object-tree.js'


const VERSIONS = ["v2.0", "v2.1"];


async function GenerateDocs() {
    const program = new Command();
    program.option('-v, --version <version...>', 'Run for versions "vX.Y"', VERSIONS)
           .option('--no-functions', 'Do not generate functions docs')
           .option('--no-functions-check', 'Do not run functions checks')
           .option('--no-enums', 'Do not generate enums docs')
           .option('--no-tree', 'Do not generate tree docs');

    program.parse();
    const options = program.opts();
    // console.log(options);

    for (const version of options.version) {
        console.log("➡️  Generating docs for grandMA3", version);
        if (options.functions) {
            console.log(" 1. Generating functions");
            await GenerateFunctionsMarkDown(version, options.functionsCheck);
        }
        if (options.enums) {
            console.log(" 2. Generating enums");
            GenerateEnumsMarkDown(version);
        }
        if (options.tree) {
            console.log(" 3. Generating tree");
            GenerateTreeMarkDown(version);
        }
    }
}




// Run Standalone
GenerateDocs();