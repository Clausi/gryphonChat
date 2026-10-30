# GryphonChat

World of Warcraft addon that extends the default chat.

**Load the `wow-lua` skill (`.claude/skills/wow-lua/`) before working on code.** It holds the rules
shared by all WoW addons (luacheck, locales, addon structure, Blizzard UI, secret values, names,
compatibility, changelog). The git workflow and commit messages are in the global `CLAUDE.md`. This
file only adds what is specific to GryphonChat.

## Target clients

- **Supported: the Classic UI clients** Classic Era (11509, `_classic_era_`), Anniversary (20506,
  `_anniversary_`) and MoP Classic (50504, `_classic_`), all listed in `## Interface:`. Their chat
  frame code (`Blizzard_ChatFrame*` folders of the `classic_era`, `classic_anniversary` and `classic`
  branches of wow-ui-source) was identical when they were added. Check all three branches when
  hooking Blizzard code; Anniversary is the main test client.
- **Supported: Retail** (120105, `_retail_`, `live` branch of wow-ui-source), the first client with
  the Mainline UI and API. Its chat frame code differs from the Classic clients in the button bar
  next to a chat window (no layout frame, buttons are anchored) and in secret values (e.g. message
  filters are skipped for secret event arguments, whisper window names can be secret). The chat
  settings and the message filter API were the same when Retail was added. Check the `live` branch
  as well when hooking Blizzard code.
- **Listed: WoW Forever** (16001, `_forever_`, product `wowf` on Blizzard's version servers),
  released and listed in `## Interface:`, but not tested in-game yet; confirm the build with
  `/dump GetBuildInfo()`. Keep it in mind for every design decision (Mainline UI and API,
  "First Surname" names without realm, secret values).
- Therefore every client difference already goes through `ns.Compat`, including chat frame
  internals and sending messages, even if all clients use the same code there yet.
- `Core/Names.lua` does not exist yet. When a feature needs names, take over `Core/Names.lua` and
  `Compat.HasRealmNames()` from GryphonMail.

## Locales

`enUS` (base), `deDE`, `frFR`.

## Saved variables

`GryphonChatDB` (account-wide) and `GryphonChatCharDB` (per character, e.g. a chat history).
