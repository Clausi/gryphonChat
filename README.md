# GryphonChat

A World of Warcraft addon that extends the default chat.

## Features

- **Clickable web links:** web addresses in chat (`https://...`, `www....`) become links. A click
  opens a small dialog to copy the address.
- **Copy chat:** a button in the button bar of every chat window opens its whole content as plain
  text to copy.
- **Longer chat history:** the number of lines each chat window keeps is configurable (default 128).
- **Input history:** the arrow keys go through the lines entered before without Alt, and the last
  32 lines are kept across logouts and reloads.
- **Link tooltips:** item, spell, quest, achievement and similar links in chat show their tooltip
  on mouseover.
- **Mouse wheel:** with Shift to the first or last line, with Ctrl a page at a time; optionally back
  to the newest line some time after scrolling.
- **Whisper list:** while whisper windows are open, a button next to the chat lists them, newest first
  and with their unread messages. A click opens one, and they can be closed one by one, all read
  ones or all at once. Chat windows with unread messages from the chat alerts are listed as well.
- **Chat alerts:** per chat type (guild, officer, party, raid, instance, whispers) and for keywords:
  tab glow and unread count on a chat window in the background, a "New messages" line, a marker, the
  message in the middle of the screen and a sound (also from LibSharedMedia). Keywords and the own
  name are highlighted.
- **Short channel names:** optional, e.g. "[1. General - Elwynn Forest]" becomes "[1. G]". Blizzard's
  channels have default short names, every channel can get an own one.
- **Options:** all settings on an own page in the game options (the chat alerts and the short
  channel names on subpages), the short channel names also in the chat settings of every chat
  window.

The full description for CurseForge and Wago is in [docs/addon-description.md](docs/addon-description.md),
for WoWInterface (BBCode) in [docs/addon-description-wowinterface.txt](docs/addon-description-wowinterface.txt).

## Supported clients

| Client  | Interface | Status    |
| ------- | --------- | --------- |
| Forever | 16001     | Supported |
| Retail  | 120105    | Supported |

One package works on both clients, they use the same Mainline UI and API. Client differences are
handled in `Core/Compat.lua`. Version 1.4.0 is the last version for Classic Era, Anniversary and MoP
Classic.

## Installation

Install it from [CurseForge](https://www.curseforge.com/projects/1764734),
[Wago Addons](https://addons.wago.io/addons/gryphonchat) or
[WoWInterface](https://www.wowinterface.com/downloads/info27279), or copy (or symlink) the `GryphonChat` folder into the client's AddOns folder:

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
   ID from `X-Curse-Project-ID` in the TOC), Wago Addons (`X-Wago-ID`), WoWInterface
   (`X-WoWI-ID`) and as a GitHub release. Game versions come from `## Interface`. It needs the
   repository secrets `CF_API_KEY` (a CurseForge API token), `WAGO_API_TOKEN` (a Wago Addons API
   key) and `WOWI_API_TOKEN` (a WoWInterface API token). WoWInterface does not know every client
   (e.g. Forever); the packager warns and leaves those out.

## Structure

```
GryphonChat/
├── .github/workflows/
│   ├── luacheck.yml       # luacheck on pushes to main and on pull requests
│   └── release.yml        # Builds and uploads a release on version tags (BigWigs packager)
├── .pkgmeta               # Packager config: libraries, changelog and files left out of the package
├── GryphonChat.toc        # Addon manifest, defines load order
├── LICENSE                # MIT license
├── Libs/                  # Embedded libraries, not in the repo (fetched by the packager)
├── docs/
│   ├── addon-description.md  # Description text for CurseForge / Wago, Markdown (not shipped)
│   └── addon-description-wowinterface.txt  # Same text for WoWInterface, BBCode (not shipped)
├── Locales/
│   ├── enUS.lua           # Base locale (fallback, all keys)
│   ├── deDE.lua           # German translation
│   └── frFR.lua           # French translation
├── Core/
│   ├── Init.lua           # Namespace, module registry, event dispatcher
│   ├── Compat.lua         # Access to Blizzard chat frame internals and chat APIs
│   ├── Util.lua           # Print/Notify/Debug helpers, debug memory output, defaults
│   ├── OptionsPanel.lua   # Options page from own controls (checkboxes, sliders, buttons) on a canvas
│   ├── CopyFrame.lua      # Read-only dialogs to copy a line or a whole text with Ctrl+C
│   └── Main.lua           # Bootstrap: saved variables, module lifecycle, slash commands
└── Modules/
    ├── ChatLinks.lua      # Turns web addresses in chat into links that open the copy dialog
    ├── ChatCopy.lua       # Copy button in the button bar of every chat window
    ├── ChatHistory.lua    # Number of lines every chat window keeps ("/gryphonchat lines")
    ├── ChatInput.lua      # Input line: arrow keys without Alt, input history kept across sessions
    ├── LinkTooltips.lua   # Tooltips of item, spell, ... links in chat on mouseover
    ├── ChatScroll.lua     # Mouse wheel with Shift/Ctrl, scrolling back down after a while
    ├── WhisperList.lua    # List of the open whisper windows, opens and closes them through secure buttons
    ├── ChatAlerts.lua     # Alerts per chat type and for keywords: tab glow and count, line, sound, screen ("/gryphonchat keywords")
    ├── ChatAlertsEditor.lua  # Table of the chat types and their alerts with the keyword settings, used by Options
    ├── ChannelNames.lua   # Short channel names in front of channel messages ("/gryphonchat channels")
    ├── ChannelNamesEditor.lua  # Editor for the short channel names, used by Options and ChatConfig
    ├── Options.lua        # Options page in the game settings with own controls ("/gryphonchat options")
    └── ChatConfig.lua     # GryphonChat category in the chat settings of every chat window
```

## Libraries

The packager embeds these libraries from the externals in `.pkgmeta`; locally,
`.tools/fetch-libs.cmd` puts them into `Libs/`:

- [LibStub](https://www.wowace.com/projects/libstub) (public domain)
- [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler), needed by LibSharedMedia
- [LibSharedMedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0): the sounds other addons
  register are offered for the chat alerts. It stays under its own license, not under the MIT
  license of GryphonChat.

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
- `/gryphonchat channels language on|off` – language code after the short name, e.g.
  `T (EN)`, default on
- `/gryphonchat channels language round|dash|slash|square` – look of the language: `T (EN)` (default),
  `T-EN`, `T/EN` or `T [EN]`
- `/gryphonchat channels set <channel|number> <short name>` – own short name for a channel, e.g.
  `/gryphonchat channels set Global G`
- `/gryphonchat channels reset <channel|number>` – remove the own short name
- `/gryphonchat notify on|off` – automatic messages of the addon (e.g. on login) for the current
  character, default on
- `/gryphonchat debug` – toggle debug output (after a `/reload`, also the memory each module keeps)

Modules add subcommands with `ns:RegisterCommand(name, handler, helpLines)`.

## License

[MIT](LICENSE)
