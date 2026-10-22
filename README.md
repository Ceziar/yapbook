# Yapbook

NOTE: 100% Vibed with Claude Opus 5.5.

**A spellbook for your chat messages.** Yapbook is a World of Warcraft addon that stores the things you type over and over, such as trade ads, guild recruitment, dungeon callouts, song lyrics and running jokes, and sends them to chat with one click.

Built for the **World of Warcraft Forever** beta (client 1.60.1) on the Classic-era addon API. It's a single Lua file with no libraries or dependencies.

## Features

- **Spellbook-style interface:** parchment pages, chapter tabs, page turning and the game's own spellbook sounds.
- **Chapters:** General Chat, plus a Professions chapter with a tab for every Vanilla profession.
- **Multi-line messages:** each line is sent as its own chat message, with an adjustable delay and random jitter to stay friendly to spam filters.
- **A channel per message:** pull callouts go to Party while your recruiting ad goes to General, each with one click.
- **Automatic send mode:** Party, Raid and Guild can send on a timer. Say, Yell, Emote and public channels automatically send one line per click, which keeps the addon within Blizzard's hardware-event rules.
- **Mini bar:** your favorites on a floating, horizontal or vertical action bar, with a Next arrow for multi-line messages.
- **Organisation:** favorites, custom icons, colors, tags and search.
- **Safety:** per-entry cooldowns, a Preview mode that prints only to your own chat, and recovery that switches to manual sending instead of dropping a line the game refuses.
- **In-game guide:** a Guide tab explains everything without leaving the game.

## Installation

1. Download the latest release and extract it.
2. Place the `Yapbook` folder in `Interface/AddOns/`.
3. Start the game and type `/yap`, or click the book on the minimap.

If the addon list marks Yapbook as incompatible, run `/dump select(4, GetBuildInfo())` and put the result at the start of the `## Interface:` line in `Yapbook.toc`.

## Usage

Create an entry with **+ New message**, then click it to send. Star it to add it to the mini bar. `/yap guide` opens the in-game manual.

## Contributing

Bug reports and pull requests are welcome. Please include your client build and any Lua error text.

## Responsible use

Yapbook paces your messages, but what you send is your responsibility. Server and channel rules still apply.
