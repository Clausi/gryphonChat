# GryphonChat

World of Warcraft addon that extends the default chat.

**Load the `wow-lua` skill (`.claude/skills/wow-lua/`) before working on code.** It holds the rules
shared by all WoW addons (luacheck, locales, addon structure, Blizzard UI, secret values, names,
compatibility, changelog). The git workflow and commit messages are in the global `CLAUDE.md`. This
file only adds what is specific to GryphonChat.

## Target clients

- **For now only Anniversary** (20506, Classic UI, game folder `_anniversary_`) is supported and
  listed in `## Interface:`. Develop and verify against Anniversary only (`classic_anniversary`
  branch of wow-ui-source, chat frame code in the `Blizzard_ChatFrame*` folders); do not add code
  for other clients yet.
- **WoW Forever (16001) is the next target:** the addon will be released for Forever later, so
  keep Forever in mind for every design decision (Mainline UI and API, "First Surname" names
  without realm, secret values). After that, the same package is meant to support Retail, Classic
  Era and MoP Classic as well.
- Therefore every client difference already goes through `ns.Compat`, including chat frame
  internals and sending messages, even if only the Anniversary variant exists yet.
- `Core/Names.lua` does not exist yet. When a feature needs names, take over `Core/Names.lua` and
  `Compat.HasRealmNames()` from GryphonMail.

## Locales

`enUS` (base), `deDE`, `frFR`.

## Saved variables

`GryphonChatDB` (account-wide) and `GryphonChatCharDB` (per character, e.g. a chat history).
