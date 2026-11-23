# GryphonChat

World of Warcraft addon that extends the default chat.

**Load the `wow-lua` skill (`.claude/skills/wow-lua/`) before working on code.** It holds the rules
shared by all WoW addons (luacheck, locales, addon structure, Blizzard UI, secret values, names,
compatibility, changelog). The git workflow and commit messages are in the global `CLAUDE.md`. This
file only adds what is specific to GryphonChat.

## Target clients

- **Supported: WoW Forever** (16001, `_forever_`, `forever` branch of wow-ui-source), tested
  in-game. "First Surname" names without realm.
- **Supported: Retail** (120105, `_retail_`, `live` branch of wow-ui-source). "Name-Realm" names.
- Both use the Mainline UI and API with secret values (e.g. message filters are skipped for secret
  event arguments, whisper window names can be secret). Their chat frame code was the same when
  the Classic clients were dropped. Check the `forever` and `live` branches when hooking Blizzard
  code.
- Classic Era, Anniversary and MoP Classic are no longer supported: 1.4.0 was the last version for
  them. Do not add code for them.
- Every client difference goes through `ns.Compat`, including chat frame internals and sending
  messages, even if both clients use the same code there yet.
- `Core/Names.lua` does not exist yet. When a feature needs names, take over `Core/Names.lua` and
  `Compat.HasRealmNames()` from GryphonMail.

## Locales

`enUS` (base), `deDE`, `frFR`.

## Saved variables

`GryphonChatDB` (account-wide) and `GryphonChatCharDB` (per character, e.g. a chat history).

## Commit scopes

`channel-names`, `chat-alerts`, `chat-config`, `chat-copy`, `chat-history`, `chat-input`, `chat-links`,
`chat-scroll`, `link-tooltips`, `copy-frame`, `options`, `whisper-list`, `core`, `locales`, `toc`.
