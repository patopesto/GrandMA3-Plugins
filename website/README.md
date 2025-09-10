# Website

Built with [Astro](https://astro.build/) and [Starlight](https://starlight.astro.build/)

## Usage

Using [Taskfile](https://taskfile.dev/).

- Setup environment

```bash
task dev
```

- Run development server

```bash
task run
```

- Build production website

```bash
task build
task preview
```

## Notes on GrandMA3 reference documentation generation

- Running the [APIDump](../APIDump) LUA plugin in the grandMA3 `Simple_Show` demo showfile.  
- The Plugin will output a couple of `.json` files in `gma3_library` folder of the current installation:
    - macOS: `~/MALightingTechnology/gma3_library/...`
    - Windows: `C:\ProgramData\MALightingTechnology\gma3_library\...`
- These files are then copied in `src/content/docs/grandma3/<version>/data` folder for the appropriate version
- Run the `task generate` scripts to generate the `*.mdx` files for each version.


## Reference / Documentation

- Astro [docs](https://docs.astro.build)
- Starlight [docs](https://starlight.astro.build/)
