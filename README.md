# GryphonChat

A World of Warcraft addon that extends the default chat.

## Features

- **Clickable web links:** web addresses in chat (`https://...`, `www....`) become links. A click
  opens a small dialog to copy the address.
- **Copy chat:** a button in the button bar of every chat window opens its whole content as plain
  text to copy.
- **Longer chat history:** the number of lines each chat window keeps is configurable (default 128).
- **Short channel names:** optional, e.g. "[1. General - Elwynn Forest]" becomes "[1. G]". Blizzard's
  channels have default short names, every channel can get an own one.
- **Options:** all settings on an own page in the game options, the short channel names also in the
  chat settings of every chat window.

The full description for CurseForge and Wago is in [docs/addon-description.md](docs/addon-description.md),
for WoWInterface (BBCode) in [docs/addon-description-wowinterface.txt](docs/addon-description-wowinterface.txt).

## Supported clients

| Client      | Interface | Status    |
| ----------- | --------- | --------- |
| Classic Era | 11509     | Supported |
| Anniversary | 20506     | Supported |
| MoP Classic | 50504     | Supported |
| Retail      | 120105    | Supported |
| Forever     | 16001     | Planned   |

One package works on all supported clients. WoW Forever follows once it is released.
Client differences are handled in `Core/Compat.lua`.

## Installation

Copy (or symlink) the `GryphonChat` folder into the client's AddOns folder:

```
World of Warcraft\<client folder>\Interface\AddOns\GryphonChat
```

## Releasing

1. Move the `[Unreleased]` entries in `CHANGELOG.md` to a new version section and bump
   `## Version` in `GryphonChat.toc`, then merge that into `main`.
2. Tag the merge commit on `main` and push the tag:

   ```
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. The `Release` workflow runs luacheck, builds the package with the
   [BigWigs packager](https://github.com/BigWigsMods/packager) and uploads it to CurseForge (project
   ID from `X-Curse-Project-ID` in the TOC), Wago Addons (`X-Wago-ID`) and as a GitHub release.
   Game versions come from `## Interface`. It needs the repository secrets `CF_API_KEY` (a
   CurseForge API token) and `WAGO_API_TOKEN` (a Wago Addons API key).

## Structure

```
GryphonChat/
├── .github/workflows/
│   ├── luacheck.yml       # luacheck on pushes to main and on pull requests
│   └── release.yml        # Builds and uploads a release on version tags (BigWigs packager)
├── .pkgmeta               # Packager config: changelog and files left out of the package
├── GryphonChat.toc        # Addon manifest, defines load order
├── LICENSE                # MIT license
├── docs/
│   ├── addon-description.md  # Description text for CurseForge / Wago, Markdown (not shipped)
│   └── addon-description-wowinterface.txt  # Same text for WoWInterface, BBCode (not shipped)
├── Locales/
│   ├── enUS.lua           # Base locale (fallback, all keys)
│   ├── deDE.lua           # German translation
│   └── frFR.lua           # French translation
├── Core/
│   ├── Init.lua           # Namespace, module registry, event dispatcher
│   ├── Compat.lua         # Client differences (Forever, Classic Era, Anniversary, MoP Classic, Retail) detected from the APIs
│   ├── Util.lua           # Print/Notify/Debug helpers, debug memory output, defaults
│   ├── CopyFrame.lua      # Read-only dialogs to copy a line or a whole text with Ctrl+C
│   └── Main.lua           # Bootstrap: saved variables, module lifecycle, slash commands
└── Modules/
    ├── ChatLinks.lua      # Turns web addresses in chat into links that open the copy dialog
    ├── ChatCopy.lua       # Copy button in the button bar of every chat window
    ├── ChatHistory.lua    # Number of lines every chat window keeps ("/gryphonchat lines")
    ├── ChannelNames.lua   # Short channel names in front of channel messages ("/gryphonchat channels")
    ├── ChannelNamesEditor.lua  # Editor for the short channel names, used by Options and ChatConfig
    ├── Options.lua        # Options page in the game settings ("/gryphonchat options")
    └── ChatConfig.lua     # GryphonChat category in the chat settings of every chat window
```

## Adding a module

1. Create `Modules/MyModule.lua`:

   ```lua
   local _, ns = ...
   local MyModule = ns:RegisterModule("MyModule")

   function MyModule:OnInitialize() end -- saved variables available
   function MyModule:OnEnable() end     -- PLAYER_LOGIN
   ```

2. Add it to `GryphonChat.toc` above `Core\Main.lua`.

## Localization

All strings live in `Locales/`. Add new keys to `enUS.lua` first; other locales
only override what they translate. Missing keys fall back to English.

## Development

Lint with [luacheck](https://github.com/lunarmodules/luacheck). Place `luacheck.exe` in `.tools/`
(ignored by git) and run from the repo root:

```
./.tools/luacheck.exe .
```

## Slash commands

- `/gryphonchat` – help
- `/gryphonchat version` – show version
- `/gryphonchat options` – open the options page
- `/gryphonchat lines <50-5000>` – lines every chat window of the current character keeps, and so
  what "Copy chat" can show (default 128 as in Blizzard's UI); without a number, shows the setting
- `/gryphonchat channels` – show the joined channels with their short names
- `/gryphonchat channels on|off` – short channel names for the current character, default off
- `/gryphonchat channels set <channel|number> <short name>` – own short name for a channel, e.g.
  `/gryphonchat channels set Global G`
- `/gryphonchat channels reset <channel|number>` – remove the own short name
- `/gryphonchat notify on|off` – automatic messages of the addon (e.g. on login) for the current
  character, default on
- `/gryphonchat debug` – toggle debug output (after a `/reload`, also the memory each module keeps)

Modules add subcommands with `ns:RegisterCommand(name, handler, helpLines)`.

## License

[MIT](LICENSE)
