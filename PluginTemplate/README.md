# PluginTemplate

[![plugin version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FPluginTemplate%2FPluginTemplate.xml%3Fref_type%3Dheads&query=%2FGMA3%2FUserPlugin%2F%40Version&prefix=v&label=Plugin)](https://gitlab.com/patopest/grandma3-plugins/-/packages)
[![grandMA3 version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FPluginTemplate%2FPluginTemplate.xml%3Fref_type%3Dheads&query=%2FGMA3%2F%40DataVersion&prefix=v&label=grandMA3)](https://www.malighting.com/grandma3/)


A simple plugin template to kickstart a new plugin

## Usage

- Copy this directory and rename it
- Rename both the `.xml` and `.lua` files to your plugin name
- In the `.xml` file, change the following:
    - `UserPlugin > Name` to your plugin name
    - `UserPlugin > Path` to your directory name
    - `UserPlugin > ComponentLua > FileName` to your `.lua` filename
