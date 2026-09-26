# ExtraStats for WoW Forever

`ExtraStats.toc` targets Forever (interface 16001, Camelot) and loads the
runtime in `forever/`. Install the packaged addon as `Interface/AddOns/ExtraStats`,
not as a folder named `forever`. It uses the native character window and equipment
manager without bundled libraries or the legacy plugin system.

## Current behavior

- Addon-owned stats view inside the native pane with General, Attributes, Melee, Ranged, Spell and Defense
  groups. Native calculations/tooltips are reused; critical strike values are
  separated by attack type. Haste remains the native combined stat in General.
- Category headers have a collapse/expand button and drag-and-drop ordering.
  Drag a header to the gold insertion line; edges auto-scroll, and dropping
  outside the pane cancels. Clicking the header does not collapse it. The native role icons select a preset; right-click them or use the settings
  cog for Auto, Tank, Healer, Damage, and Off, plus
  per-role category and stat visibility. Auto reads the active talent configuration and chooses the highest-point
  tree using the original class-to-role mappings. Equal totals choose the first
  tree; an empty build defaults to Damage. Group/spec metadata is only a fallback
  when talent data is unavailable. Default filters match
  the old UI: Defense for tanks, Ranged for hunters or an equipped ranged weapon, Spell for spellcasting classes (including Paladin tanks). Attributes comes last by default.
  Overrides, ordering, and collapsed states persist per character. Reset affects
  stats controls only, preserving gear assignments.
- Five 32px resistance icons stacked beside the right equipment slots,
  with values on the left and native tooltips on hover or controller focus. The addon stats view has no resistance category; pet stats
  remain native. Headers use the original ExtraStats dark/gold template.
- Native gear-set **edit menu** gains an **Assign spec** section. Open a set's
  edit menu and choose a specialization (including its talent-tree name). Each talent group can
  have one set; assigning another replaces that group's previous assignment.
  Uncheck a group or use Clear assignments to remove it. Assignments are saved
  per character by set ID, so renaming a set preserves its assignment.
- A talent-group change equips its assigned set via `C_EquipmentSet`. Combat,
  casting, channeling and locked items defer the swap. The latest active group
  wins if another switch happens while waiting. Reload/login alone does not
  force a gear swap. Missing sets are cleared when encountered.

## UI source reference

Downloaded full shallow checkout: `.references/wow-ui-source-forever` (ignored).
Repository: https://github.com/Gethe/wow-ui-source/tree/forever
Commit: `bd2470aed543f72697a044e989285b6c83e63f73`
Client: `1.60.1.70009`

Key files under `Interface/AddOns/`:

- `Blizzard_UIPanels_Game/Camelot/CharacterFrame.lua`: native scrolling stats;
  resistances are appended separately from PAPERDOLL_STATCATEGORIES.
- `Blizzard_UIPanels_Game/Camelot/PaperDollFrameConstants.lua`: category table.
- `Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua`: attribute tooltips
  require the second category's five stats to stay in UNITSTAT order.
- `Blizzard_UIPanels_Game/Camelot/PaperDollFrame.lua` and `.xml`: equipment UI.
- `Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua`:
  primary/secondary specs use C_SpecializationInfo.GetActiveSpecGroup.

## Validation

Run `python tests/forever_smoke.py` with `lupa` installed (or in
`.references/python`). Tests use mocked WoW frames and APIs; they cannot validate
rendering, protected-action/taint behavior, or actual inventory swaps.

In-game checks still required: inspect all groups/tooltips, change gear and
resistance buffs, open pet view, select and rename sets, assign both specs,
switch specs normally and while blocked, and confirm bag-space/missing-item
errors. Check model overlap at different UI scales and gamepad mode.

## Taint isolation

The adapter copies native stat updater references into its own registry. It does
not change PAPERDOLL_STATINFO, PAPERDOLL_STATCATEGORIES, the native stats pane's
elementData, or its data provider. Rows and category controls belong to the addon.
A secure post-hook only queues a later addon refresh. Health and power values
are passed directly to font strings without numeric comparisons or conversion.
After upgrading from the earlier prototype, reload the UI to clear prior taint.
The mock tests verify state isolation but cannot prove in-client taint safety.

The modern overlay scrollbar uses addon-owned content height and scroll offset;
it does not query the engine scroll range or install ScrollUtil range callbacks.
