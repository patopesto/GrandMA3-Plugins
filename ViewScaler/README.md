# ViewScaler

[![plugin version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FViewScaler%2FViewScaler.xml%3Fref_type%3Dheads&query=%2FGMA3%2FUserPlugin%2F%40Version&prefix=v&label=Plugin)](https://gitlab.com/patopest/grandma3-plugins/-/packages)
[![grandMA3 version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%2FViewScaler%2FViewScaler.xml%3Fref_type%3Dheads&query=%2FGMA3%2F%40DataVersion&prefix=v&label=grandMA3)](https://www.malighting.com/grandma3/)


Scale a display's content to fit the available space.

This plugin came as a need to handle the views on different screen sizes when using multiple platforms: onPC, Compact(XT) or Lite/Full consoles.

![ViewScaler Demo Video](../assets/ViewScaler_demo.mov)



## Usage

When called, the plugin will scale the content of the currently focused display.


## Notes

> [!note]
> A display's content is not linked to the `Views` DataPool object which might have been called previously. This plugin will only affect the display's current content, not the original `View` object.

> [!note]
> This plugin does not affect the display width, height or scale settings. It rearranges the position and size of the widgets currently visible on screen.

### Screen Grid Sizes

The display grid sizes for the most common configurations

| Platform                       | Width | Height | Notes
| :----------------------------- | :---: | :----: | :----
| Compact (XT)                   | 18    | 7      |
| Lite / Full                    | 18    | 10     |
| External 24" (Display 5 and 6) | 18    | 10     | with scale x1
| onPC MacBookPro 14"            | 18    | 9      | with scale x0.75
| onPC MacBookPro 16"            | 21    | 11     | with scale x0.75