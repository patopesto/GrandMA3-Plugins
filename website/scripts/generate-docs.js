#!/usr/bin/env node

import { GenerateFunctionsMarkDown } from './generate-lua-functions.js'
import { GenerateEnumsMarkDown } from './generate-lua-enums.js'
import { GenerateTreeMarkDown } from './generate-object-tree.js'


async function GenerateDocs(version = "v2.0") {
    console.log("➡️  Generating docs for grandMA3", version);
    console.log(" 1. Generating functions");
    await GenerateFunctionsMarkDown(version);

    console.log(" 2. Generating enums");
    GenerateEnumsMarkDown(version);

    console.log(" 3. Generating tree");
    GenerateTreeMarkDown(version);
}




// Run Standalone
GenerateDocs("v2.0");