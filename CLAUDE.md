# GryphonChat

World of Warcraft addon that extends the default chat.

**Load the `wow-lua` skill (`.claude/skills/wow-lua/`) before working on code.** It holds the rules
shared by all WoW addons (luacheck, locales, addon structure, Blizzard UI, secret values, names,
compatibility, changelog). The git workflow and commit messages are in the global `CLAUDE.md`. This
file only adds what is specific to GryphonChat.

## Target clients

- **WoW Forever** only (16001, `_forever_`, `forever` branch of wow-ui-source, Mainline UI and API,
  "First Surname" names without realm, secret values), tested in-game. Check the `forever` branch
  when hooking Blizzard code.
- Classic Era, Anniversary, MoP Classic and Retail are no longer supported: 1.4.0 was the last
  version for them. Do not add code for them.
- `Core/Compat.lua` still has branches for the Classic UI clients (e.g. the layout frame of the
  button bar next to a chat window, `VARIABLES_LOADED` in `HookChatMouseWheel`). They are left in
  for now; new code does not need a client check.
- `Core/Names.lua` does not exist yet. When a feature needs names, take over `Core/Names.lua` from
  GryphonMail.

## Locales

`enUS` (base), `deDE`, `frFR`.

## Saved variables

`GryphonChatDB` (account-wide) and `GryphonChatCharDB` (per character, e.g. a chat history).

## Commit scopes

`channel-names`, `chat-alerts`, `chat-config`, `chat-copy`, `chat-history`, `chat-input`, `chat-links`,
`chat-scroll`, `link-tooltips`, `copy-frame`, `options`, `whisper-list`, `core`, `locales`, `toc`.
