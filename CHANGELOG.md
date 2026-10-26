# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Support for WoW Retail, in the same package as the Classic clients. The "Copy chat" button sits
  at the bottom of the button bar next to the chat window there.

## [0.2.0] - 2026-10-25

Now for WoW Classic Era, Classic Anniversary and MoP Classic.

### Added

- Optional short channel names, e.g. "[1. General - Elwynn Forest]" becomes "[1. G]". Blizzard's
  channels have default short names (General G, Trade T, LocalDefense LD, WorldDefense WD,
  LookingForGroup LfG, GuildRecruitment GR), every channel can get an own one with
  `/gryphonchat channels set <channel|number> <short name>`. Turn it on per character with
  `/gryphonchat channels on`.
- Options page in the game settings (Esc > Options > AddOns > GryphonChat) for the automatic
  messages, the chat lines and the short channel names, also opened with `/gryphonchat options`.
  The short channel names can also be set in the chat settings (right click on a chat tab >
  Settings > GryphonChat).
- Support for WoW Classic Era and MoP Classic, in the same package as Anniversary.

## [0.1.0] - 2026-10-25

First release, for WoW Classic Anniversary.

### Added

- Web addresses in chat (`https://...`, `www....`) are clickable. A click opens a small dialog to
  copy the address with Ctrl+C.
- A button in the button bar of every chat window, including whisper windows, opens the whole
  content of that window as plain text to copy.
- `/gryphonchat lines <50-5000>` sets per character how many lines every chat window keeps
  (default 128, as in Blizzard's UI), which is also what the copy window can show.
- `/gryphonchat notify on|off` turns the automatic messages of the addon (e.g. on login) on or off
  for the current character.
- English, German and French translation.

[Unreleased]: https://github.com/Clausi/gryphonChat/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Clausi/gryphonChat/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Clausi/gryphonChat/releases/tag/v0.1.0
