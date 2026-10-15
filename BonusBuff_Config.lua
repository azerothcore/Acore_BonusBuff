
-- BonusBuff_Config.lua
-- Adjust settings here. No changes are needed in BonusBuff.lua.
--
-- USAGE (in game or from the worldserver console):
--   .bonusbuff <group>          Applies every spell aura of <group> to all online players
--                               whose level is inside that row's MinLevel / MaxLevel.
--   .bonusbuff list [alias]     Lists every group defined below (alias = also show the aliases).
--   .bonusbuff clear [group]    Removes only the buffs this script gave (all, or one group).
--   See README.md for everything else.
--
-- To disable a spell or a group, comment its line out with -- and run .reload ale

local Config = {}

-- Minimum GM rank required to use .bonusbuff (3 = Administrator). Console always allowed.
Config.MinGMRank = 3

-- Skip dead players / ghosts when applying buffs.
-- false = dead players get the buffs queued and applied when they resurrect (needs PreserveOnDeath = true).
Config.SkipDeadPlayers = false

-- Preserve BonusBuff auras through death: they are given back on resurrect with the time they had left.
-- (Time spent dead still counts down. Lost on a server restart / .reload ale.)
Config.PreserveOnDeath = true

-- ---------------------------------------------------------------------------
-- Battlegrounds / Arenas
-- A player inside a battleground or arena only receives a spell when ALL of these are true:
--   - the player's level falls in a bracket below that has Enabled = true
--   - the spell row has AllowBG = true (Config.Spells)
-- ---------------------------------------------------------------------------
-- Battleground brackets (WotLK):
--   WSG  = Warsong Gulch           AB   = Arathi Basin         AV  = Alterac Valley
--   EotS = Eye of the Storm        SotA = Strand of the Ancients
--   IoC  = Isle of Conquest
-- AV has its own brackets: 51-60, 61-70, 71-79 and 80 (shown in brackets below).
Config.ApplyBuffsToBattleground = {
    -- { MinLevel, MaxLevel, Enabled }
    { 10, 19, false },   -- WSG
    { 20, 29, false },   -- WSG / AB
    { 30, 39, false },   -- WSG / AB
    { 40, 49, false },   -- WSG / AB
    { 50, 59, false },   -- WSG / AB / AV (51-60)
    { 60, 69, false },   -- WSG / AB / AV (61-70) / EotS
    { 70, 79, false },   -- WSG / AB / AV (71-79) / EotS / SotA / IoC
    { 80, 80, false },   -- WSG / AB / AV (80) / EotS / SotA / IoC
}

-- Arena brackets
Config.ApplyBuffsToArena = {
    -- { MinLevel, MaxLevel, Enabled }
    { 70, 79, false },   -- Arenas (level 70 bracket)
    { 80, 80, false },   -- Arenas (level 80 bracket)
}

-- Override PreserveOnDeath inside battlegrounds / arenas.
-- false = buffs are NOT given back when resurrecting there.
-- true  = given back, but only spells with AllowBG = true.
Config.PreserveInBattleground = false
Config.PreserveInArena        = false

-- Every buff in a group lasts as long as the longest one in that group
-- (e.g. a 30 min scroll in a group with a 2 hour flask also lasts 2 hours).
Config.MatchLongestInGroup = true

-- Sound played to every buffed player. Set to 0 to disable.
Config.SoundId = 2847

-- Visual shown on every buffed player for a few seconds (only when they actually got a buff).
-- 50236 = Spotlight (Scaled to Creature), has its own sound. Set VisualSpellId to 0 to disable.
Config.VisualSpellId = 50236
Config.VisualDurationSeconds = 5

-- Send the ANNOUNCE + "You've been blessed with:" list (BonusBuff_Locale.lua) to every buffed player.
Config.AnnounceToPlayers = true

-- ---------------------------------------------------------------------------
-- Groups
-- Define a group here first, then attach spells to it in Config.Spells below.
-- The GroupName is what you type after .bonusbuff (not case sensitive, no spaces).
-- WorldBuff = true adds the WORLDBUFF_PVP_NOTE line (BonusBuff_Locale.lua) to the player message.
-- ---------------------------------------------------------------------------
Config.Groups = {
    -- { GroupName, WorldBuff, "Comment", { "alias", ... } }
    -- Aliases are optional extra names that also work after .bonusbuff
    -- Level groups: typing a level number picks the group that covers it (.bonusbuff 15 -> level20)
    { "ony",        true,  "Rallying Cry of the Dragonslayer", { "rallying", "dragonslayer" } },
    { "rend",       true,  "Warchief's Blessing",              { "warchief", "blessing" } },
    { "fengus",     true,  "Fengus' Ferocity",                 { "ferocity" } },
    { "moldar",     true,  "Mol'dar's Moxie",                  { "moxie" } },
    { "slipkik",    true,  "Slip'kik's Savvy",                 { "savvy" } },
    { "zg",         true,  "Spirit of Zandalar",               { "zandalar" } },
    { "serenade",   true,  "Songflower Serenade",              { "songflower" } },
    { "worldbuffs", true,  "All classic world buffs",          { "worldbuff" } },
    { "level10",   false, "Class buffs for levels 1 - 10",   { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" } },
    { "level20",   false, "Class buffs for levels 11 - 20",  { "11", "12", "13", "14", "15", "16", "17", "18", "19", "20" } },
    { "level30",   false, "Class buffs for levels 21 - 30",  { "21", "22", "23", "24", "25", "26", "27", "28", "29", "30" } },
    { "level40",   false, "Class buffs for levels 31 - 40",  { "31", "32", "33", "34", "35", "36", "37", "38", "39", "40" } },
    { "level50",   false, "Class buffs for levels 41 - 50",  { "41", "42", "43", "44", "45", "46", "47", "48", "49", "50" } },
    { "level60",   false, "Class buffs for levels 51 - 60",  { "51", "52", "53", "54", "55", "56", "57", "58", "59", "60" } },
    { "level70",   false, "Class buffs for levels 61 - 70",  { "61", "62", "63", "64", "65", "66", "67", "68", "69", "70" } },
    { "level80",   false, "Class buffs for levels 71 - 80",  { "71", "72", "73", "74", "75", "76", "77", "78", "79", "80" } },

    -- Twink groups: consumables + class buffs, same level ranges and ranks as the level groups above
    { "twink10",   false, "Twink: consumables + class buffs for levels 1 - 10" },
    { "twink20",   false, "Twink: consumables + class buffs for levels 11 - 20" },
    { "twink30",   false, "Twink: consumables + class buffs for levels 21 - 30" },
    { "twink40",   false, "Twink: consumables + class buffs for levels 31 - 40" },
    { "twink50",   false, "Twink: consumables + class buffs for levels 41 - 50" },
    { "twink60",   false, "Twink: consumables + class buffs for levels 51 - 60" },
    { "twink70",   false, "Twink: consumables + class buffs for levels 61 - 70" },
    { "twink80",   false, "Twink: consumables + class buffs for levels 71 - 80" },
}

-- ---------------------------------------------------------------------------
-- Spells
-- DurationSeconds: how long the buff lasts, in seconds (e.g. 3600 = 1 hour). 0 = the spell's own default.
-- If a player already has the buff with more time left, they keep the longer time.
-- A player only receives a row if MinLevel <= player level <= MaxLevel.
-- AllowBG: true = may be applied / preserved inside battlegrounds and arenas, false = never there.
-- The same SpellID may appear in several groups.
-- ---------------------------------------------------------------------------
Config.Spells = {
    -- { GroupName, SpellID, DurationSeconds, MinLevel, MaxLevel, AllowBG, "Comment" }

    -- Classic world buffs (2 hours, up to level 63). The comment on each row is what the buff gives (read from Spell.dbc).
    { "ony",      22888, 7200, 1, 63, false, "Rallying Cry of the Dragonslayer" }, -- +140 crit rating, +140 attack power
    { "rend",     16609, 7200, 1, 63, false, "Warchief's Blessing" }, -- +300 max health, +150 melee haste rating, +10 mana per 5 sec
    { "fengus",   22817, 7200, 1, 63, false, "Fengus' Ferocity" }, -- +200 attack power
    { "moldar",   22818, 7200, 1, 63, false, "Mol'dar's Moxie" }, -- +15% Stamina
    { "slipkik",  22820, 7200, 1, 63, false, "Slip'kik's Savvy" }, -- +42 spell crit rating
    { "zg",       24425, 7200, 1, 63, false, "Spirit of Zandalar" }, -- +50 all stats
    { "serenade", 15366, 7200, 1, 63, false, "Songflower Serenade" }, -- +70 crit rating, +15 all stats

    -- All of the above in one go
    { "worldbuffs", 22888, 7200, 1, 63, false, "Rallying Cry of the Dragonslayer" }, -- +140 crit rating, +140 attack power
    { "worldbuffs", 16609, 7200, 1, 63, false, "Warchief's Blessing" }, -- +300 max health, +150 melee haste rating, +10 mana per 5 sec
    { "worldbuffs", 22817, 7200, 1, 63, false, "Fengus' Ferocity" }, -- +200 attack power
    { "worldbuffs", 22818, 7200, 1, 63, false, "Mol'dar's Moxie" }, -- +15% Stamina
    { "worldbuffs", 22820, 7200, 1, 63, false, "Slip'kik's Savvy" }, -- +42 spell crit rating
    { "worldbuffs", 24425, 7200, 1, 63, false, "Spirit of Zandalar" }, -- +50 all stats
    { "worldbuffs", 15366, 7200, 1, 63, false, "Songflower Serenade" }, -- +70 crit rating, +15 all stats

    -- Class buffs (1 hour). The comment on each row is what the buff gives (read from Spell.dbc).
    { "level10", 1243,  3600, 1,  10, false, "Power Word: Fortitude (Rank 1)" }, -- +3 Stamina
    { "level10", 1126,  3600, 1,  10, false, "Mark of the Wild (Rank 1)" }, -- +25 armor
    { "level10", 1459,  3600, 1,  10, false, "Arcane Intellect (Rank 1)" }, -- +2 Intellect
    { "level10", 19740, 3600, 1,  10, false, "Blessing of Might (Rank 1)" }, -- +20 attack power

    { "level20", 1244,  3600, 11, 20, false, "Power Word: Fortitude (Rank 2)" }, -- +8 Stamina
    { "level20", 5232,  3600, 11, 20, false, "Mark of the Wild (Rank 2)" }, -- +65 armor, +2 all stats
    { "level20", 1460,  3600, 11, 20, false, "Arcane Intellect (Rank 2)" }, -- +7 Intellect
    { "level20", 19834, 3600, 11, 20, false, "Blessing of Might (Rank 2)" }, -- +35 attack power

    { "level30", 1245,  3600, 21, 30, false, "Power Word: Fortitude (Rank 3)" }, -- +20 Stamina
    { "level30", 5234,  3600, 21, 30, false, "Mark of the Wild (Rank 4)" }, -- +150 armor, +6 all stats, +5 all resistances
    { "level30", 1461,  3600, 21, 30, false, "Arcane Intellect (Rank 3)" }, -- +15 Intellect
    { "level30", 19835, 3600, 21, 30, false, "Blessing of Might (Rank 3)" }, -- +55 attack power

    { "level40", 2791,  3600, 31, 40, false, "Power Word: Fortitude (Rank 4)" }, -- +32 Stamina
    { "level40", 8907,  3600, 31, 40, false, "Mark of the Wild (Rank 5)" }, -- +195 armor, +8 all stats, +10 all resistances
    { "level40", 1461,  3600, 31, 40, false, "Arcane Intellect (Rank 3)" }, -- +15 Intellect
    { "level40", 19836, 3600, 31, 40, false, "Blessing of Might (Rank 4)" }, -- +85 attack power

    { "level50", 10937, 3600, 41, 50, false, "Power Word: Fortitude (Rank 5)" }, -- +43 Stamina
    { "level50", 9884,  3600, 41, 50, false, "Mark of the Wild (Rank 6)" }, -- +240 armor, +10 all stats, +15 all resistances
    { "level50", 10156, 3600, 41, 50, false, "Arcane Intellect (Rank 4)" }, -- +22 Intellect
    { "level50", 19837, 3600, 41, 50, false, "Blessing of Might (Rank 5)" }, -- +130 attack power

    { "level60", 10938, 3600, 51, 60, false, "Power Word: Fortitude (Rank 6)" }, -- +54 Stamina
    { "level60", 9885,  3600, 51, 60, false, "Mark of the Wild (Rank 7)" }, -- +285 armor, +12 all stats, +20 all resistances
    { "level60", 10157, 3600, 51, 60, false, "Arcane Intellect (Rank 5)" }, -- +31 Intellect
    { "level60", 25291, 3600, 51, 60, false, "Blessing of Might (Rank 7)" }, -- +232 attack power

    { "level70", 25389, 3600, 61, 70, false, "Power Word: Fortitude (Rank 7)" }, -- +79 Stamina
    { "level70", 26990, 3600, 61, 70, false, "Mark of the Wild (Rank 8)" }, -- +340 armor, +14 all stats, +25 all resistances
    { "level70", 27126, 3600, 61, 70, false, "Arcane Intellect (Rank 6)" }, -- +40 Intellect
    { "level70", 27140, 3600, 61, 70, false, "Blessing of Might (Rank 8)" }, -- +306 attack power

    { "level80", 48161, 3600, 71, 80, false, "Power Word: Fortitude (Rank 8)" }, -- +165 Stamina
    { "level80", 48469, 3600, 71, 80, false, "Mark of the Wild (Rank 9)" }, -- +750 armor, +37 all stats, +54 all resistances
    { "level80", 42995, 3600, 71, 80, false, "Arcane Intellect (Rank 7)" }, -- +60 Intellect
    { "level80", 48932, 3600, 71, 80, false, "Blessing of Might (Rank 10)" }, -- +550 attack power

    -- Twink: consumables (elixirs / flasks) + the same class buffs as the level groups.
    -- The comment on each row is what the buff gives (read from Spell.dbc).
    { "twink10", 2374,  7200, 1,  10, false, "Elixir of Minor Agility" }, -- +4 Agility
    { "twink10", 2378,  7200, 1,  10, false, "Elixir of Minor Fortitude" }, -- +27 max health
    { "twink10", 1243,  7200, 1,  10, false, "Power Word: Fortitude (Rank 1)" }, -- +3 Stamina
    { "twink10", 1126,  7200, 1,  10, false, "Mark of the Wild (Rank 1)" }, -- +25 armor
    { "twink10", 1459,  7200, 1,  10, false, "Arcane Intellect (Rank 1)" }, -- +2 Intellect
    { "twink10", 19740, 7200, 1,  10, false, "Blessing of Might (Rank 1)" }, -- +20 attack power

    { "twink20", 3160,  7200, 11, 20, false, "Elixir of Lesser Agility" }, -- +8 Agility
    { "twink20", 2378,  7200, 11, 20, false, "Elixir of Minor Fortitude" }, -- +27 max health
    { "twink20", 1244,  7200, 11, 20, false, "Power Word: Fortitude (Rank 2)" }, -- +8 Stamina
    { "twink20", 5232,  7200, 11, 20, false, "Mark of the Wild (Rank 2)" }, -- +65 armor, +2 all stats
    { "twink20", 1460,  7200, 11, 20, false, "Arcane Intellect (Rank 2)" }, -- +7 Intellect
    { "twink20", 19834, 7200, 11, 20, false, "Blessing of Might (Rank 2)" }, -- +35 attack power

    { "twink30", 11328, 7200, 21, 30, false, "Elixir of Agility" }, -- +15 Agility
    { "twink30", 3593,  7200, 21, 30, false, "Elixir of Fortitude" }, -- +120 max health
    { "twink30", 1245,  7200, 21, 30, false, "Power Word: Fortitude (Rank 3)" }, -- +20 Stamina
    { "twink30", 5234,  7200, 21, 30, false, "Mark of the Wild (Rank 4)" }, -- +150 armor, +6 all stats, +5 all resistances
    { "twink30", 1461,  7200, 21, 30, false, "Arcane Intellect (Rank 3)" }, -- +15 Intellect
    { "twink30", 19835, 7200, 21, 30, false, "Blessing of Might (Rank 3)" }, -- +55 attack power

    { "twink40", 11334, 7200, 31, 40, false, "Elixir of Greater Agility" }, -- +25 Agility
    { "twink40", 3593,  7200, 31, 40, false, "Elixir of Fortitude" }, -- +120 max health
    { "twink40", 2791,  7200, 31, 40, false, "Power Word: Fortitude (Rank 4)" }, -- +32 Stamina
    { "twink40", 8907,  7200, 31, 40, false, "Mark of the Wild (Rank 5)" }, -- +195 armor, +8 all stats, +10 all resistances
    { "twink40", 1461,  7200, 31, 40, false, "Arcane Intellect (Rank 3)" }, -- +15 Intellect
    { "twink40", 19836, 7200, 31, 40, false, "Blessing of Might (Rank 4)" }, -- +85 attack power

    { "twink50", 17538, 7200, 41, 50, false, "Elixir of the Mongoose" }, -- +25 Agility, +10 crit rating
    { "twink50", 3593,  7200, 41, 50, false, "Elixir of Fortitude" }, -- +120 max health
    { "twink50", 10937, 7200, 41, 50, false, "Power Word: Fortitude (Rank 5)" }, -- +43 Stamina
    { "twink50", 9884,  7200, 41, 50, false, "Mark of the Wild (Rank 6)" }, -- +240 armor, +10 all stats, +15 all resistances
    { "twink50", 10156, 7200, 41, 50, false, "Arcane Intellect (Rank 4)" }, -- +22 Intellect
    { "twink50", 19837, 7200, 41, 50, false, "Blessing of Might (Rank 5)" }, -- +130 attack power

    { "twink60", 17626, 7200, 51, 60, false, "Flask of the Titans" }, -- +400 max health
    { "twink60", 10938, 7200, 51, 60, false, "Power Word: Fortitude (Rank 6)" }, -- +54 Stamina
    { "twink60", 9885,  7200, 51, 60, false, "Mark of the Wild (Rank 7)" }, -- +285 armor, +12 all stats, +20 all resistances
    { "twink60", 10157, 7200, 51, 60, false, "Arcane Intellect (Rank 5)" }, -- +31 Intellect
    { "twink60", 25291, 7200, 51, 60, false, "Blessing of Might (Rank 7)" }, -- +232 attack power

    { "twink70", 28518, 7200, 61, 70, false, "Flask of Fortification" }, -- +500 max health, +10 defense rating
    { "twink70", 25389, 7200, 61, 70, false, "Power Word: Fortitude (Rank 7)" }, -- +79 Stamina
    { "twink70", 26990, 7200, 61, 70, false, "Mark of the Wild (Rank 8)" }, -- +340 armor, +14 all stats, +25 all resistances
    { "twink70", 27126, 7200, 61, 70, false, "Arcane Intellect (Rank 6)" }, -- +40 Intellect
    { "twink70", 27140, 7200, 61, 70, false, "Blessing of Might (Rank 8)" }, -- +306 attack power

    { "twink80", 53758, 7200, 71, 80, false, "Flask of Stoneblood" }, -- +1300 max health
    { "twink80", 48161, 7200, 71, 80, false, "Power Word: Fortitude (Rank 8)" }, -- +165 Stamina
    { "twink80", 48469, 7200, 71, 80, false, "Mark of the Wild (Rank 9)" }, -- +750 armor, +37 all stats, +54 all resistances
    { "twink80", 42995, 7200, 71, 80, false, "Arcane Intellect (Rank 7)" }, -- +60 Intellect
    { "twink80", 48932, 7200, 71, 80, false, "Blessing of Might (Rank 10)" }, -- +550 attack power
}

return Config
