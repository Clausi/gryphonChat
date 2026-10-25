# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/Clausi/gryphonChat/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Clausi/gryphonChat/releases/tag/v0.1.0
