# Acore_BonusBuff

It's a Lua script made for [AzerothCore](https://github.com/azerothcore/azerothcore-wotlk) that lets a GM give server-wide buffs to every online player with one command: classic world buffs, class buffs per level range, or twink consumables per level range.

Based on [Acore_eventScripts](https://github.com/55Honey/Acore_eventScripts) by [55Honey](https://github.com/55Honey) ([bonusbuff.lua](https://github.com/55Honey/Acore_eventScripts/blob/main/bonusbuff.lua)).

> [!NOTE]
> Buffs are **applied as auras**, not cast. Range, targeting and zone restrictions of the original spell are skipped, so e.g. Warchief's Blessing works anywhere. Level limits that the core puts on the aura itself (Rallying Cry / Songflower above level 63) still apply, and the script checks that every buff really stayed on the player before counting it or telling them about it.

**Made for [ChromieCraft](https://www.chromiecraft.com/)**

## Requirements:

- Requires [mod-ale](https://github.com/azerothcore/mod-ale) (**A**zerothCore **L**ua **E**ngine) to work.

- If you're using the default `lua_scripts` folder then your `mod_ale.conf` should have `ALE.ScriptPath = "lua_scripts"`, otherwise adjust the path accordingly.

- Place the whole `Acore_BonusBuff` folder in `lua_scripts`. It contains three files that must stay together:
  - `BonusBuff.lua` - the script (no changes needed).
  - `BonusBuff_Config.lua` - all settings, groups and spells.
  - `BonusBuff_Locale.lua` - every player-facing text, in all 9 client languages.

- After changing the config or locale, run `.reload ale` to apply it.

## Administrator Usage:

All commands work in game (GM rank `Config.MinGMRank` or higher, default `3`) and from the worldserver console.

- `.bonusbuff` - Show the command usage.
- `.bonusbuff list` - List every group with its spells, level range and duration.
- `.bonusbuff list alias` - Same list, including every alias of each group.
- `.bonusbuff $group` - Apply all buffs of `$group` to every online player whose level fits each spell's level range.
- `.bonusbuff clear` - Remove **only** the buffs this script gave, from everyone.
- `.bonusbuff clear $group` - Remove only the buffs of `$group` that this script gave.

`$group` can be the group name or any of its aliases, for example:

- `.bonusbuff rend`, `.bonusbuff warchief` or `.bonusbuff blessing` - Warchief's Blessing.
- `.bonusbuff worldbuffs` or `.bonusbuff worldbuff` - All classic world buffs at once.
- `.bonusbuff level20` or `.bonusbuff 15` - Class buffs for levels 11 - 20 (any level number picks the level group that covers it).
- `.bonusbuff twink10` - Consumables + class buffs for levels 1 - 10.

> [!TIP]
> Not sure what a group gives? `.bonusbuff list` shows the real spell names (in your client language), the level range and the duration of every row.

## Default Groups

| Group | Aliases | Gives | Levels |
|---|---|---|---|
| `ony` | `rallying`, `dragonslayer` | Rallying Cry of the Dragonslayer | 1 - 63 |
| `rend` | `warchief`, `blessing` | Warchief's Blessing | 1 - 63 |
| `fengus` | `ferocity` | Fengus' Ferocity | 1 - 63 |
| `moldar` | `moxie` | Mol'dar's Moxie | 1 - 63 |
| `slipkik` | `savvy` | Slip'kik's Savvy | 1 - 63 |
| `zg` | `zandalar` | Spirit of Zandalar | 1 - 63 |
| `serenade` | `songflower` | Songflower Serenade | 1 - 63 |
| `worldbuffs` | `worldbuff` | All 7 world buffs above | 1 - 63 |
| `level10` ... `level80` | the level numbers in its range | Power Word: Fortitude, Mark of the Wild, Arcane Intellect, Blessing of Might (rank fitting the range) | 1 - 10, 11 - 20 ... 71 - 80 |
| `twink10` ... `twink80` | - | The same class buffs as the level group + elixirs (1 - 50) or a flask (51 - 80) | 1 - 10, 11 - 20 ... 71 - 80 |

World buffs last 2 hours, class buffs 1 hour, twink groups 2 hours.

## What the player sees

Every player who actually received at least one buff gets:

- The sound (`Config.SoundId`) and a short Spotlight visual (`Config.VisualSpellId`).
- A message in their own client language:

```
Happy Holidays from Chromie and her helpers!
You've been blessed with:
  Warchief's Blessing - 120 minutes
World buffs are removed when you enter a battleground or arena.
```

The last line is only shown for groups marked as `WorldBuff = true`. Players who got nothing (wrong level, inside a battleground, already have a longer copy of the buff...) see nothing.

## What it does:

- Applies the buffs of a group to every online player whose level fits each spell row.
- Uses the real time left: if a player already has the same buff with **more** time left (their own or an earlier `.bonusbuff`), it is left alone.
- Skips anything the core refuses or removes instantly, e.g. Rallying Cry / Songflower above level 63.
- Remembers every buff it gave (spell + exact end time) so it can:
  - **Preserve it through death** (`Config.PreserveOnDeath`): given back on resurrect with only the time that was left.
  - **Clear only its own buffs** (`.bonusbuff clear`): buffs from priests, real world buff events etc. are never touched.
- Forgets a buff as soon as the player loses it any other way (right-click cancel, expired, dispelled, replaced), so it is **not** given back after death.
- Keeps working across relogs (buff timers pause while offline, the script re-syncs on login).
- Dead players (`Config.SkipDeadPlayers = false`): buffs are queued and applied when they resurrect.
- Offline players during `.bonusbuff clear`: their buffs are removed at their next login.

## What it **NOT** does:

- Does not cast the spells, so there is no cast animation or "X casts Y on you" message.
- Does not remove buffs when a player enters a battleground or arena (the message only warns about it).
- Does not show a "From: ..." line in the buff tooltip. The tooltip comes from the client's `Spell.dbc` and the server can't add text to it.

> [!WARNING]
> The list of given buffs is kept **in memory only**. After a server restart or `.reload ale`, buffs given before that keep running until they expire, but they can no longer be cleared with `.bonusbuff clear` or given back after death.

## Configuration

All settings are in `BonusBuff_Config.lua`.

```lua
Config.MinGMRank = 3                  -- Minimum GM rank to use .bonusbuff (console is always allowed).
Config.SkipDeadPlayers = false        -- false = dead players get the buffs queued for when they resurrect.
Config.PreserveOnDeath = true         -- Give BonusBuff auras back on resurrect with the time they had left.

Config.ApplyBuffsToBattleground = {   -- { MinLevel, MaxLevel, Enabled } per battleground bracket.
    { 10, 19, false },                -- WSG
    { 20, 29, false },                -- WSG / AB
    ...
    { 80, 80, false },                -- WSG / AB / AV (80) / EotS / SotA / IoC
}
Config.ApplyBuffsToArena = {          -- { MinLevel, MaxLevel, Enabled } per arena bracket.
    { 70, 79, false },
    { 80, 80, false },
}
Config.PreserveInBattleground = false -- Give buffs back on resurrect inside battlegrounds (only AllowBG = true spells).
Config.PreserveInArena = false        -- Same for arenas.

Config.MatchLongestInGroup = true     -- Every buff in a group lasts as long as the longest one in that group.
Config.SoundId = 2847                 -- Sound played to buffed players. 0 = off.
Config.VisualSpellId = 50236          -- Spotlight visual on buffed players. 0 = off.
Config.VisualDurationSeconds = 5      -- How long the visual stays.
Config.AnnounceToPlayers = true       -- Send the chat message to buffed players.
```

> [!IMPORTANT]
> A player inside a battleground or arena only receives a spell when **all** of these are true: their level is in a bracket with `Enabled = true`, **and** the spell row has `AllowBG = true`. By default everything is off, so running a command never affects ongoing matches.

### Groups

Define a group first, then attach spells to it.

```lua
Config.Groups = {
    -- { GroupName, WorldBuff, "Comment", { "alias", ... } }
    { "rend", true, "Warchief's Blessing", { "warchief", "blessing" } },
}
```

- `GroupName` - What you type after `.bonusbuff` (not case sensitive, no spaces).
- `WorldBuff` - `true` adds the "World buffs are removed when you enter a battleground or arena." line to the player message.
- `"Comment"` - Shown in `.bonusbuff list`.
- `{ aliases }` - Optional extra names for the group. A clash with another name is reported in the console on load and ignored.

### Spells

```lua
Config.Spells = {
    -- { GroupName, SpellID, DurationSeconds, MinLevel, MaxLevel, AllowBG, "Comment" }
    { "rend", 16609, 7200, 1, 63, false, "Warchief's Blessing" }, -- +300 max health, +150 melee haste rating, +10 mana per 5 sec
}
```

- `GroupName` - Must exist in `Config.Groups` (a typo is reported in the console on load).
- `SpellID` - The spell whose aura is applied.
- `DurationSeconds` - In seconds (`3600` = 1 hour). `0` = the spell's own default.
- `MinLevel` / `MaxLevel` - Only players inside this range receive the row.
- `AllowBG` - `true` = may be applied / preserved inside battlegrounds and arenas.
- `"Comment"` - Fallback name if the spell name can't be read.

> [!TIP]
> To disable a spell or a whole group, put `--` in front of its line and run `.reload ale`.

> [!CAUTION]
> Some buffs replace each other in the core (`spell_group` / `spell_group_stack_rules`):
> - Only **one battle elixir** and **one guardian elixir** at a time. A **flask** counts as both.
> - Only **one scroll** at a time, and Scroll of Stamina / Intellect clash with Power Word: Fortitude / Arcane Intellect (the stronger one stays).
>
> If a group contains buffs that replace each other, players only keep the last one. The script only reports the buffs a player actually kept.

## Locale

`BonusBuff_Locale.lua` holds every text the script sends, for all 9 client languages (`0 = enUS` ... `8 = ruRU`). The enUS `[0]` entry is used when a translation is missing. Edit the texts there, including the "Happy Holidays from Chromie and her helpers!" announcement (`L.ANNOUNCE`).

---

> [!NOTE]
> This README was generated by Claude (Anthropic's AI assistant, via Claude Code) using the original [bonusbuff.lua](https://github.com/55Honey/Acore_eventScripts/blob/main/bonusbuff.lua) and the files in this repository. Read every command before running it, and treat any example values as placeholders to be replaced with your own.
