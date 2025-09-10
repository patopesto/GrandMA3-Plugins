import type { Loader, LoaderContext } from 'astro/loaders';
import { z } from 'astro:content';


// ------------------------------------------------------------------
// Helper: read the original txt file and turn it into a flat array of
// objects that represent each function.
// ------------------------------------------------------------------
function parseGrandmaTxt(file): Array<{
    name: string;
    section: 'objectfree' | 'object';
    args: { name: string; type: string }[];
    returns: { name: string; type: string }[];
}> {

    if (!fs.existsSync(file)) {
        console.warn(`[grandma] Could not find ${file}`);
        return [];
    }

    const raw = fs.readFileSync(file, 'utf8');

    // ------- split the two sections ---------------------------------
    const freeMarker = '==========================================\nObject-Free API';
    const objMarker = '==========================================\nObject API';
    const freeIdx = raw.indexOf(freeMarker);
    const objIdx = raw.indexOf(objMarker);
    const freePart = raw.substring(freeIdx + freeMarker.length, objIdx).trim();
    const objPart = raw.substring(objIdx + objMarker.length).trim();

    // ------- generic line parser ------------------------------------
    const splitArg = (arg: string) => {
        const parts = arg.split(':');
        const name = parts.shift()?.trim() ?? '';
        const type = parts.join(':').trim();
        return { name, type };
    };

    const parseLine = (line: string) => {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('===') || trimmed.startsWith('#')) return null;
        const m = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*:\s*(.+)$/);
        if (!m) return null;
        const [, name, argsRaw, returnsRaw] = m;
        const args = argsRaw
            .split(',')
            .map((a) => a.trim())
            .filter(Boolean)
            .map(splitArg);
        const returns = returnsRaw
            .split(',')
            .map((r) => r.trim())
            .filter(Boolean)
            .map(splitArg);
        return { name, args, returns };
    };

    const walkSection = (text: string, sectionKey: 'objectfree' | 'object') => {
        const out: typeof results = [];
        for (const line of text.split('\n')) {
            const parsed = parseLine(line);
            if (parsed) out.push({ ...parsed, section: sectionKey });
        }
        return out;
    };

    const results = [...walkSection(freePart, 'objectfree'), ...walkSection(objPart, 'object')];
    return results;
}

// Define any options that the loader needs
export function LUAFunctionsLoader({ version }): Loader {
    // Configure the loader
    const version_short = version.replace(/^v/, "");
    const TXT_FILE_PATH = `src/content/docs/grandma3/${version}/grandMA3_lua_functions.txt`
    const BASE_DOC_URL = `https://help.malighting.com/grandMA3/${version_short}/HTML/`;
    // Return a loader object
    return {
        name: "lua-functions-loader",
        // Called when updating the collection.
        load: async (context: LoaderContext): Promise<void> => {
            // Load data and update the store
            const { store, logger, parseData, meta, renderMarkdown } = context
            
            logger.info("Loading functions");
            const funcs = parseGrandmaTxt(TXT_FILE_PATH);
            logger.info(funcs);
            store.clear();

            for (const fn of funcs) {
                const docUrl = `${BASE_DOC_URL}lua_${fn.section}_${fn.name.toLowerCase()}.html`;
                const markdownBody = `
### ${fn.name}
[Official documentation](${docUrl})

**Arguments**

| Name | Type |
| ---- | ---- |
${fn.args
  .map(
    (a) =>
      `| \`${a.name || '(unnamed)'}\` | \`${a.type}\` |`
  )
  .join('\n') || '*No arguments.*'}

**Returns**

| Name | Type |
| ---- | ---- |
${fn.returns
  .map(
    (r) =>
      `| \`${r.name || '(unnamed)'}\` | \`${r.type}\` |`
  )
  .join('\n') || '*No return value.*'}
`;
                const data = await parseData({
                    id: fn.name.toLowerCase(),
                    data: {
                        ...fn,
                        title: fn.name,
                        docUrl: docUrl,
                        content: markdownBody,
                    }
                });
                console.log(data)
                store.set({
                    id: fn.name.toLowerCase(),
                    data,
                    rendered: await renderMarkdown(data.content),
                });
            }
        },
        // Optionally, define the schema of an entry.
        // It will be overridden by user-defined schema.
        schema: async () => z.object({
            // Human readable title – we’ll use the function name.
            title: z.string(),
            // Which API section the function belongs to.
            section: z.enum(['objectfree', 'object']),
            // Argument list.
            args: z.array(
                z.object({
                    name: z.string(),
                    type: z.string(),
                })
            ),
            // Return list.
            returns: z.array(
                z.object({
                    name: z.string(),
                    type: z.string(),
                })
            ),
            // URL to the official doc page (may be dead – we don’t check here).
            docUrl: z.string().url(),
            content: z.string(),
        }),
    };
}