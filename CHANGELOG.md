# Simple Raid Frames

## 1.12.1 (2026-05-02)

- Added a UIDropDownMenu taint guard so settings dropdowns no longer block Blizzard community avatar textures.
- Stopped reapplying raid-frame hooks and settings when unrelated Blizzard addons load.
- Replaced the Reset All Settings StaticPopup with an addon-owned dialog to avoid tainting protected Blizzard confirmations.

## 1.12 (2026-05-02)

- Added support for WoW 12.0.5 (interface 120005).
- Removed the unused Private Auras settings tab.
- Restored the default health background color when the override is disabled, so leftover class coloring no longer sticks.
- Added an option to tint role icons with the unit's class color.
- Added separate options to tint leader/assist icons and status icons with the unit's class color.
- Added a Role Icon Style dropdown (Pixels / Blizzard); Blizzard icons are never class-tinted.
- Removed the Hide Realm Names toggle; realm suffixes are now always stripped.
- Refreshed default settings for new installs (no outline name font, class-tinted role icons with a 3,-3 offset, dark class health colors at 90%, class-colored health background, slim aura bars anchored top-right with the Flat texture).
- Enlarged the settings window, wrapped each tab in a scroll frame so content no longer hides behind the bottom bar, and added a Reset All Settings button beside Close.
- Removed the Auras settings tab and the standalone Hide Native Buff Icons toggle; native buff icons are now hidden iff aura bars are enabled.
- Removed all private aura handling; Blizzard now anchors and shows them with default behavior.

## 1.10 (2026-05-02)

- Updated heal absorb coloring to follow the active dark class color mode.
- Clamped heal prediction visuals inside the raid frame without relying on Blizzard's overflow ratio path.
- Kept dispel overlays above heal absorb visuals.
- Removed the range alpha setting and its related update hooks.
- Cleaned unused exports, outdated fallbacks, and duplicated refresh logic.
