# TimecodeExporter

[![plugin version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%TimecodeExporter%TimecodeExporter.xml%3Fref_type%3Dheads&query=%2FGMA3%2FUserPlugin%2F%40Version&prefix=v&label=Plugin)](https://gitlab.com/patopest/grandma3-plugins/-/packages)
[![grandMA3 version](https://img.shields.io/badge/dynamic/xml?url=https%3A%2F%2Fgitlab.com%2Fpatopest%2Fgrandma3-plugins%2F-%2Fraw%2Fmaster%TimecodeExporter%TimecodeExporter.xml%3Fref_type%3Dheads&query=%2FGMA3%2F%40DataVersion&prefix=v&label=grandMA3)](https://www.malighting.com/grandma3/)


Export Timecode Pool objects to CSV.

- Support multiple objects in a single export






## Usage

```lua
Plugin "TimecodeExporter"
```

### Arguments:

- `Timecode X`: Timecode Pool object(s)
- `/File abc.csv`: The export filename (optional, default: `TimecodeExport.csv`)

### Examples:

- Export Timecode object by index:

    ```lua
    Plugin "TimecodeExporter" "Timecode 2"
    ```

- Export Timecode object by name and set exported file name:

    ```lua
    Plugin "TimecodeExporter" "Timecode MySong /File MySong.csv"
    ```

- Export multiple Timecode objects:

    ```lua
    Plugin "TimecodeExporter" "Timecode 1 thru 5"
    ```


## Notes

### Exported file format

The exported CSV file has the following format:

| Timecode    | Type | Track      | TrackGroup   | Pool
| :---------: | :--- | :--------- | :----------- | :---
| HH:MM:SS:FF | Go+  | MySequence | TrackGroup 1 | MyPoolObject
| HH:MM:SS:FF | Off  | MySequence | TrackGroup 1 | MyPoolObject
| HH:MM:SS:FF | Go+  | OtherSeq   | TrackGroup 2 | PoolObject2
| HH:MM:SS:FF | Off  | OtherSeq   | TrackGroup 2 | PoolObject2

