# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Addon skeleton for WoW Classic Anniversary: namespace, module registry, event dispatcher, saved variables (`GryphonChatDB`,
  `GryphonChatCharDB`) and `/gryphonchat` slash command.
- Localization with English base locale, German and French translation.
- `/gryphonchat debug` toggles debug output, `/gryphonchat notify on|off` the automatic messages of
  the current character.
- Web addresses in chat (`https://...`, `www....`) are clickable. A click opens a small dialog to
  copy the address with Ctrl+C.
- A button in the button bar of every chat window, including whisper windows, opens the whole
  content of that window as plain text to copy.
- `/gryphonchat lines <50-5000>` sets per character how many lines every chat window keeps
  (default 128, as in Blizzard's UI), which is also what the copy window can show.

[Unreleased]: https://github.com/Clausi/gryphonChat/commits/main
