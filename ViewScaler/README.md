# ViewScaler

::include{file=PLUGIN.md}


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