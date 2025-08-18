# ViewScaler

::include{file=PLUGIN.md}


## Usage

When called, the plugin will scale the content of the currently focused display.

> [!note]
> A display's content is not linked to the `Views` DataPool object which might have been called previously. This plugin will only affect the display's current content, not the original `View` object.


## Additionnal Information

### Screen Grid Sizes

The display grid sizes for the most common configurations

| Platform                       | Width | Height | Notes
| :----------------------------- | :---: | :----: | :----
| Compact (XT)                   | 18    | 7      |
| Lite / Full                    | 18    | 10     |
| External 24" (Display 5 and 6) | 18    | 10     | Scale x1
| onPC MBP 14"                   | 18    | 9      | Scale x0.75
| onPC MBP 16"                   | 21    | 11     | Scale x0.75