# ExtraStats for WoW Forever

ExtraStats extends the native Forever character window with configurable stat
categories, paper-doll resistances, and equipment-set specialization assignments.
This checkout and its release packages target WoW Forever (interface 16001).

- Group stats by General, Attributes, Melee, Ranged, Spell, and Defense.
- Choose role presets, filter stats, and drag category headers to reorder them.
- View resistances beside your equipment slots with native tooltips.
- Assign native equipment sets to specializations for automatic gear swaps.
- Configure the character window with mouse or controller navigation.

See [Forever features and validation](forever/README.md) for details.

## Installation

Extract a Forever release into your game's `Interface/AddOns` directory so that
`ExtraStats/ExtraStats.toc` is directly inside `Interface/AddOns/ExtraStats`.
For the Forever beta client, use `_classic_beta_/Interface/AddOns`.

## Development and releases

The addon loads from `ExtraStats.toc` and the `forever/` directory.
See [release instructions](RELEASING.md) for local checks, packaging, and publishing.

## Contributing

ExtraStats is open source and built with community support. Special thanks to
Crits and Giggles for helping create the addon.

- [Repository](https://github.com/wuild/extrastats)
- [Issue tracker](https://github.com/wuild/extrastats/issues)
- [Buy Me a Coffee](https://www.buymeacoffee.com/yuImx6KOY)
