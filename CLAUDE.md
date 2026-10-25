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
- **Retail (120105) is the next target**, the first client with the Mainline UI and API (other
  chat button bar and chat settings layout, secret values). Do not add Mainline code before work on
  Retail starts.
- **WoW Forever (16001) follows** once it is released; it cannot be tested before that. Keep it in
  mind for every design decision (Mainline UI and API, "First Surname" names without realm, secret
  values).
- Therefore every client difference already goes through `ns.Compat`, including chat frame
  internals and sending messages, even if only the Classic variant exists yet.
- `Core/Names.lua` does not exist yet. When a feature needs names, take over `Core/Names.lua` and
  `Compat.HasRealmNames()` from GryphonMail.

## Locales

`enUS` (base), `deDE`, `frFR`.

## Saved variables

`GryphonChatDB` (account-wide) and `GryphonChatCharDB` (per character, e.g. a chat history).
