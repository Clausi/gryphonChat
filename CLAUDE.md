# GryphonChat

World of Warcraft addon that extends the default chat.

## Target clients

- **For now only Anniversary** (20506, Classic UI, game folder `_anniversary_`) is supported and
  listed in `## Interface:`. Develop and verify against Anniversary only; do not add code for other
  clients yet.
- **WoW Forever (16001) is the next target:** the addon will be released for Forever later, so
  keep Forever in mind for every design decision (Mainline UI and API, "First Surname" names
  without realm, secret values). After that, the same package is meant to support Retail (120105),
  Classic Era (11509) and MoP Classic (50504) as well. To keep that easy:
  - Every client difference goes through `ns.Compat` (`Core/Compat.lua`). Detect APIs, methods or
    frame fields that exist instead of comparing version numbers, and do not branch on clients
    anywhere else.
  - Put Blizzard UI access that is likely to differ between clients (chat frame internals, sending
    messages, secret values) behind `ns.Compat` from the start, even if only the Anniversary
    variant exists yet.
- Reference for Blizzard UI code: the `classic_anniversary` branch of
  https://github.com/Gethe/wow-ui-source (chat frame code in the `Blizzard_ChatFrame*` folders). Read
  the actual Blizzard source before hooking or mirroring Blizzard behavior instead of relying on
  memory.
- Verify interface numbers in-game with `/dump select(4, GetBuildInfo())`.
- Character names differ per client. When a feature needs to build, compare or show names, take
  over `Core/Names.lua` and `Compat.HasRealmNames()` from GryphonMail (`D:\code\GryphonMail`) and
  always use `ns.Names`; never use `Ambiguate`. The rules:
  - **Forever:** names are "First Surname" (separator from
    `Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR`, a space) and carry no
    realm suffix. `UnitName(unit)` returns first name and **surname**, not name and realm. Each
    ruleset (PvE, PvP, RP) is its own realm, e.g. `GetRealmName()` = "Classic Beta PvE".
  - **Classic Era, Anniversary, MoP Classic, Retail:** names are "Name-Realm" with the realm from
    `GetNormalizedRealmName()` (no spaces). Chat events usually include the realm of the sender;
    other APIs leave it out for the own realm. `Names.Normalize` fills in the own realm for
    comparing; `Names.ToDisplay` gives the short name for the own realm.
- Lua 5.1 (WoW flavor): no `goto`, `//`, bitwise operators, `require`, `io` or `os`.

## Mandatory checks

- **luacheck must be green (0 warnings / 0 errors) after every change.** Run it from the repo root:

  ```
  ./.tools/luacheck.exe .
  ```

- Fix warnings in the code. Only change `.luacheckrc` when the warning is a false positive, e.g. a new
  WoW API global (add it to `read_globals`) or an intentional write to a Blizzard frame field.
  Never silence warnings globally or with inline `-- luacheck: ignore` without a reason in a comment.
- Code cannot be tested in-game from here. After a change, tell the user what to verify in-game.
- luacheck also runs in CI (`.github/workflows/luacheck.yml`) on pull requests and on `main`.

## Language

- Code, identifiers, comments, commit messages and docs are in **English**.
- Never hardcode user-facing text. Every string goes through `L["KEY"]`:
  1. Add the key to `Locales/enUS.lua` (base locale, must contain every key).
  2. Add the German translation to `Locales/deDE.lua` and the French one to `Locales/frFR.lua`.
  Missing translations fall back to English.
- `|` starts an escape sequence in WoW text (`|n` newline, `|c` color, `|H` hyperlink, ...). Write a
  literal pipe as `||` in user-facing strings. Chat messages contain links and color codes: never cut
  or rewrite a message in the middle of an escape sequence.

## Architecture

- All files share the addon namespace via `local addonName, ns = ...`. Do not create new globals;
  the only allowed globals are the ones listed under `globals` in `.luacheckrc`.
- Features live in `Modules/` and register with `ns:RegisterModule("Name")`:
  - `OnInitialize()` runs on `ADDON_LOADED` (saved variables are available).
  - `OnEnable()` runs on `PLAYER_LOGIN`.
- Use `ns:RegisterEvent`, `ns:Print`, `ns:Notify` and `ns:Debug` from `Core/` instead of own event
  frames or `print`.
- Slash subcommands are registered with `ns:RegisterCommand(name, handler, helpLines)`, never by
  extending the handler in `Core/Main.lua`.
- Saved variables (defaults in `Core/Init.lua`):
  - `GryphonChatDB` / `ns.db` (account-wide, `ns.defaults`): settings and data shared by all characters.
  - `GryphonChatCharDB` / `ns.charDb` (per character, `ns.charDefaults`): data only the logged-in
    character needs, e.g. a chat history. Prefer this for growing per-character data, so a login does
    not load the data of all characters.
- Every new file must be added to `GryphonChat.toc`. Locales first, `Core\Main.lua` last.

## Working with the Blizzard UI

- Prefer `hooksecurefunc`, `HookScript` and `ChatFrame_AddMessageEventFilter` over replacing
  Blizzard functions, methods or scripts (e.g. a chat frame's `AddMessage`), to avoid taint.
- Keep writes to Blizzard frames minimal and document why, in the code and in `.luacheckrc`.
- Values returned by the API and chat event arguments may be secret values (Forever, Retail), e.g.
  chat messages during encounters. Guard string or number operations on them with `issecretvalue`
  and pass secret values through unchanged.
- Sending chat messages differs per client (`C_ChatInfo.SendChatMessage` or the global
  `SendChatMessage`); go through `ns.Compat`.

## Housekeeping

- Record every user-visible change in `CHANGELOG.md` under `[Unreleased]`
  ([Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format: Added, Changed, Fixed, Removed).
  On a release, move the entries to a new version section and bump `## Version` in `GryphonChat.toc`.
  After that is merged, a pushed tag `vX.Y.Z` on `main` builds and uploads the release (see
  "Releasing" in `README.md`). Only tag when asked.
- Keep the structure section in `README.md` up to date when files are added or removed.
- Do not commit or push unless asked.

## Git workflow

- `main` is protected: no direct commits or pushes, every change goes through a pull request.
- Start each change on a new branch from an up-to-date `main`:
  `git checkout main`, `git pull`, `git checkout -b <type>/<short-name>`, using the commit types below
  (e.g. `feat/chat-history`, `fix/url-copy`, `docs/readme`).
- Split work into meaningful commits; each commit must pass luacheck on its own.
- Push with `git push -u origin <branch>`, then create the pull request with
  `gh pr create --base main` and give the user the PR link. The PR title follows the commit message
  format below; title and description are in English.
- After the merge: `git checkout main`, `git pull`, and delete the local branch. GitHub deletes the
  remote branch automatically. Pull requests are merged by rebase, so the commits get new hashes and
  `git branch -d` does not recognize them as merged: check the PR state with `gh pr view` and use
  `git branch -D`.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<scope>): <description>

<body>

<footer>
```

- **type** (required):
  - `feat`: new user-visible feature
  - `fix`: bug fix
  - `docs`: documentation only (README, CHANGELOG, CLAUDE.md, comments)
  - `refactor`: code change without behavior change
  - `perf`: performance improvement
  - `style`: formatting only
  - `test`: tests
  - `build`: TOC, packaging, deploy scripts
  - `ci`: CI configuration
  - `chore`: tooling and maintenance (e.g. `.luacheckrc`, `.gitignore`)
  - `revert`: reverts a previous commit
- **scope** (optional): the affected area in kebab-case, usually the module, e.g. `core`, `locales`,
  `toc`.
- **description**: imperative, lowercase start, no trailing period, at most 72 characters including
  type and scope, e.g. `fix(core): apply defaults to nested tables`.
- **body** (optional): explains what and why, not how; wrap at 72 characters.
- **footer**: `BREAKING CHANGE: <description>` (or `!` after the type/scope) for changes that break
  saved variables or slash commands; attribution trailers go here as well.
