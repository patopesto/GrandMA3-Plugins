# ScreenSwap

[![plugin version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FScreenSwap%2FScreenSwap.xml%3Fref_type%3Dheads&query=%2FGMA3%2FUserPlugin%2F%40Version&prefix=v&label=Plugin)](https://gitlab.com/patopest/grandma3-plugins/-/packages)
[![grandMA3 version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FScreenSwap%2FScreenSwap.xml%3Fref_type%3Dheads&query=%2FGMA3%2F%40DataVersion&prefix=v&label=grandMA3)](https://www.malighting.com/grandma3/)


Swap `ViewButtons` between 2 screens.

- Easily access a 2nd bank of ViewButtons for your screen in one-click.
- Access views stored on unavailable displays in your showfile. ex: Showfile was built on Full Console but currently running on Lite Console and missing Display 3.


![ScreenSwap Demo Video](../assets/ScreenSwap_demo.mov)


## Usage

Arguments:

- `/Screen X`: First screen (optional, default: 1)
- `/Screen Y`: Second screen (optional, default: 2)
- `/Buttons Z`: The number of `ViewButtons` to swap (optional, default: 10)

Example:

```lua
Plugin "ScreenSwap" "/Screen 1 /Screen 2 /Buttons 10"
```
