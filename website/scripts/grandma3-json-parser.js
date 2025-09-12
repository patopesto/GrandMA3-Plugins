import Hjson from 'hjson';


function sanitize(raw) {
  // Normalise line endings & trim
  let txt = raw.replace(/\r\n/g, '\n').trim();

  // Ensure a surrounding object exists
  if (!txt.startsWith('{')) txt = `{${txt}`;
  if (!txt.endsWith('}')) txt = `${txt}}`;

  // Insert missing commas between top‑level enum blocks
  //  Example:  "}ScrollType"  →  "},\nScrollType"
  txt = txt.replace(/}\s*(\w)/g, '},\n$1');

  // Quote any key
  txt = txt.replace(
    /^([\s]*)([A-Za-z0-9_<>()][^:]*?):/gm,
    (_, prefix, key) => `${prefix}"${key.replace('\n', ' ')}":` // Fix keys containing newline
  );

  // Quote numeric‑only keys (e.g.  "9":9)
  txt = txt.replace(
    /^([\s]*)([0-9]+):/gm,
    (_, prefix, key) => `${prefix}"${key}":`
  );

  // Remove newlines from string values
  txt = txt.replace(
    /^([^:]*?):("[^]*?")/gm,
    (_, key, value) => `${key}:${value.replace('\n', ' ')}`
  );

  // Remove stray trailing commas before a closing brace
  txt = txt.replace(/,\s*}/g, '}');

  // Handle completely empty keys (":value")
  txt = txt.replace(
    /^([\s]*):(.*)/gm,
    (_, prefix, value) => `${prefix}"unnamed":${value}`
  );

  // Collapse any accidental duplicate commas (",,")
  txt = txt.replace(/,,+/g, ',');

  return txt.trim();
}


export function ParseJson(raw) {

  const sanitized = sanitize(raw);

  let parsed;
  try {
    parsed = Hjson.parse(sanitized);
  } catch (e) {
    console.error('❌ Parsing failed after sanitisation', e.message);
    return null
  }

  return parsed
}