# APIDump

[![plugin version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FAPIDump%2FAPIDump.xml%3Fref_type%3Dheads&query=%2FGMA3%2FUserPlugin%2F%40Version&prefix=v&label=Plugin)](https://gitlab.com/patopest/grandma3-plugins/-/packages)
[![grandMA3 version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FAPIDump%2FAPIDump.xml%3Fref_type%3Dheads&query=%2FGMA3%2F%40DataVersion&prefix=v&label=grandMA3)](https://www.malighting.com/grandma3/)


Export data from the current grandMA3 version used for the documentation generation.
Currently exports:
- LUA Functions
- LUA `Enums`
- The data tree
- Version and build information


## Usage


```lua
Plugin "APIDump"
```

### Notes

- Install in `Simple_Show` Demo showfile.
- Rename Station Hostname to `Laptop` and `Session` to `MySession` (To avoid having device-specific data in the tree dump).
- Run After a restart (to avoid having too much `Undo` history in the tree dump).