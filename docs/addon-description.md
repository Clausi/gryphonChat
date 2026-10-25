# GryphonChat

**A better chat for World of Warcraft Classic Anniversary.**

GryphonChat extends the default chat instead of replacing it. Everything stays where you know it, with a few tools that make chatting easier.

## Features

### Clickable web links
Web addresses in chat (`https://...`, `www....`) become clickable links. One click opens a small window with the address selected: press **Ctrl+C** and paste it into your browser.

### Copy the chat
A new button next to every chat window, including whisper windows, shows the whole chat of that window as plain text. Everything is selected right away, so **Ctrl+C** copies it.

### Longer chat history
Chat windows normally keep only the last 128 lines. With `/gryphonchat lines <number>` you choose how many lines they keep for the current character, up to 5000.

### Short channel names
Turn long channel names into short ones: *[1. General - Elwynn Forest]* becomes *[1. G]*, *[4. LookingForGroup]* becomes *[4. LfG]*. Blizzard's channels come with short names, and you can give every channel your own, e.g. `/gryphonchat channels set Global G`. Off by default, turn it on with `/gryphonchat channels on`.

## Slash commands

| Command | Description |
|---|---|
| `/gryphonchat` | Show all commands |
| `/gryphonchat lines <50-5000>` | How many lines every chat window of this character keeps (default 128) |
| `/gryphonchat channels` | Show your channels and their short names |
| `/gryphonchat channels on\|off` | Short channel names for this character |
| `/gryphonchat channels set <channel> <short name>` | Your own short name for a channel |
| `/gryphonchat channels reset <channel>` | Remove your own short name |
| `/gryphonchat notify on\|off` | Turn the automatic messages of this character on or off |

## Good to know
- Made for **Classic Anniversary**. Support for **WoW Forever** follows later, more game versions
  are planned.
- Languages: English, German, French.

## Feedback & source code

Found a bug or have an idea? Please open an issue on GitHub:
**[github.com/Clausi/gryphonChat/issues](https://github.com/Clausi/gryphonChat/issues)**

Source code and changelog: [github.com/Clausi/gryphonChat](https://github.com/Clausi/gryphonChat)
