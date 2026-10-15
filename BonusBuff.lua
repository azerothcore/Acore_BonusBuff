--Copyright (C) 2021-2022  https://github.com/55Honey
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License
--along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 23/12/2021
-- Originally created by Honey for Azerothcore
-- requires ALE (Eluna) module

------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with the ALE module
--               -  adjust config in Acore_BonusBuff/BonusBuff_Config.lua
--               -  adjust texts in Acore_BonusBuff/BonusBuff_Locale.lua
--               -  place the Acore_BonusBuff folder in ../lua_scripts/
--
-- COMMANDS:     .bonusbuff <group>          apply the auras of <group> to all online players
--               .bonusbuff clear [group]    remove only the buffs this script gave (all, or one group)
--               .bonusbuff list             list all configured groups
------------------------------------------------------------------------------------------------

local Config = require("BonusBuff_Config")
local L = require("BonusBuff_Locale")

------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

local TEAM_NEUTRAL = 2                      -- GetPlayersInWorld(TEAM_NEUTRAL) = both factions
local PLAYER_EVENT_ON_COMMAND = 42          -- (event, player, command) - player is nil if command used from console
local PLAYER_EVENT_ON_RESURRECT = 36        -- (event, player)
local PLAYER_EVENT_ON_LOGIN = 3             -- (event, player)
local PLAYER_EVENT_ON_LOGOUT = 4            -- (event, player)
local PLAYER_EVENT_ON_AURA_REMOVE = 67      -- (event, player, aura, remove_mode)
local AURA_REMOVE_BY_DEATH = 5              -- AuraRemoveMode in the core

-- Every buff handed out by this script (used by PreserveOnDeath and .bonusbuff clear):
-- bb_given[playerGuidLow][spellId] = { spell = <spell row>, expires = os.time() end, -1 = permanent, 0 = queued (spell default) }
-- Kept in memory only: a server restart or .reload ale forgets it.
local bb_given = {}

-- Players who were offline during .bonusbuff clear: bb_pendingClear[guidLow][spellId] = entry
local bb_pendingClear = {}

-- Players currently logging out: the core strips all auras then (they are saved with the
-- character first), which must not count as "removed".
local bb_loggingOut = {}

-- Locale helper: picks the player's locale string from a table, falls back to enUS [0].
local function bb_t(player, key, ...)
    local locale = player and player:GetDbcLocale() or 0
    local entry = L[key]
    local str = (type(entry) == "table" and (entry[locale] or entry[0])) or entry or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

-- Replies to the GM in game, or prints to the console when used from there.
local function bb_reply(player, key, ...)
    local text = bb_t(player, key, ...)
    if player then
        player:SendBroadcastMessage(text)
    else
        print(text)
    end
end

-- Build the group index from the config: groups[lowercase name] = { name, worldBuff, comment, spells = {...} }
local groups = {}
local groupOrder = {}

for _, row in ipairs(Config.Groups or {}) do
    local name, worldBuff, comment, aliases = row[1], row[2] == true, row[3] or "", row[4] or {}
    local key = string.lower(name)
    if groups[key] then
        print("[BonusBuff] Duplicate group '"..name.."' in BonusBuff_Config.lua - ignored.")
    else
        local group = { name = name, worldBuff = worldBuff, comment = comment, aliases = aliases, spells = {} }
        groups[key] = group
        table.insert(groupOrder, key)
        for _, alias in ipairs(aliases) do
            local aliasKey = string.lower(alias)
            if groups[aliasKey] then
                print("[BonusBuff] Alias '"..alias.."' of group '"..name.."' is already in use - ignored.")
            else
                groups[aliasKey] = group
            end
        end
    end
end

for _, row in ipairs(Config.Spells or {}) do
    local groupName, spellId, duration, minLevel, maxLevel, allowBG, comment = row[1], row[2], row[3], row[4], row[5], row[6], row[7]
    if type(allowBG) == "string" then               -- old 6-column row without AllowBG
        comment, allowBG = allowBG, false
    end
    local group = groups[string.lower(groupName or "")]
    if not group then
        print("[BonusBuff] Spell "..tostring(spellId).." uses undefined group '"..tostring(groupName).."' - add it to Config.Groups. Ignored.")
    else
        table.insert(group.spells, {
            id       = spellId,
            duration = (duration or 0) * 1000,   -- seconds -> milliseconds
            minLevel = minLevel or 1,
            maxLevel = maxLevel or 255,
            comment  = comment or "",
            allowBG  = allowBG == true,
        })
    end
end

-- Config.MatchLongestInGroup: every spell in a group lasts as long as the longest one in that group.
if Config.MatchLongestInGroup then
    for _, key in ipairs(groupOrder) do
        local g = groups[key]
        local longest = 0
        for _, spell in ipairs(g.spells) do
            if spell.duration > longest then
                longest = spell.duration
            end
        end
        if longest > 0 then
            for _, spell in ipairs(g.spells) do
                spell.duration = longest
            end
        end
    end
end

-- "arena", "bg" or "world". InBattleground() is also true inside arenas, so arena is checked first.
local function bb_zone(target)
    if target:InArena() then
        return "arena"
    elseif target:InBattleground() then
        return "bg"
    end
    return "world"
end

-- May this spell be applied to this player where they are right now?
local function bb_allowedHere(target, spell, level)
    local zone = bb_zone(target)
    if zone == "world" then
        return true
    end
    if not spell.allowBG then
        return false
    end
    local brackets = (zone == "arena") and Config.ApplyBuffsToArena or Config.ApplyBuffsToBattleground
    for _, bracket in ipairs(brackets or {}) do
        local minLevel, maxLevel, enabled = bracket[1], bracket[2], bracket[3]
        if level >= minLevel and level <= maxLevel then
            return enabled == true
        end
    end
    return false                                    -- level not in any bracket
end

-- Applies one spell's aura and checks the player really kept it.
-- Returns the Aura on success, nil if it was refused or instantly expired
-- (e.g. Rallying Cry / Songflower above level 63 get a 1 ms duration from the core).
local function bb_tryAura(target, spell)
    -- The player already has this buff with more time left (their own, or an earlier .bonusbuff):
    -- leave it alone so it is never taken over and never removed by .bonusbuff clear.
    local existing = target:GetAura(spell.id)
    if existing and spell.duration > 0 then
        local existingRemaining = existing:GetDuration()            -- ms, -1 = permanent
        if existingRemaining == -1 or existingRemaining >= spell.duration then
            return nil
        end
    end

    local aura = target:AddAura(spell.id, target)
    if not aura or not target:HasAura(spell.id) then
        return nil
    end

    local remaining = aura:GetDuration()            -- -1 = permanent
    if remaining >= 0 and remaining <= 1000 then
        target:RemoveAura(spell.id)                 -- dead on arrival, don't revive it with SetDuration
        return nil
    end

    if spell.duration > 0 then
        aura:SetMaxDuration(spell.duration)
        aura:SetDuration(spell.duration)
    end

    local guid = target:GetGUIDLow()
    local remaining = aura:GetDuration()
    bb_given[guid] = bb_given[guid] or {}
    bb_given[guid][spell.id] = {
        spell   = spell,
        expires = remaining == -1 and -1 or (os.time() + math.ceil(remaining / 1000)),
    }
    return aura
end

-- Is the aura this player has right now the one this script gave? Compares the time left
-- with what was recorded, so a buff from another source (priest, real world buff event) is not touched.
local function bb_auraMatches(aura, entry)
    local remaining = aura:GetDuration()
    if entry.expires == -1 then
        return remaining == -1
    elseif remaining == -1 or entry.expires == 0 then
        return false
    end
    return math.abs((os.time() + remaining / 1000) - entry.expires) <= 5
end

local function bb_isOurs(target, spellId, entry)
    local aura = target:GetAura(spellId)
    return aura ~= nil and bb_auraMatches(aura, entry)
end

-- Our aura went away for any reason other than death (right-click cancel, expired, dispelled,
-- replaced by someone else's buff, removed by a GM...): forget it, so it is NOT given back on resurrect.
local function bb_onAuraRemove(event, player, aura, mode)
    local guid = player:GetGUIDLow()
    if bb_loggingOut[guid] then
        return
    end
    if mode == AURA_REMOVE_BY_DEATH and Config.PreserveOnDeath then
        return                                      -- given back on resurrect
    end
    local list = bb_given[guid]
    if not list then
        return
    end
    local spellId = aura:GetAuraId()
    local entry = list[spellId]
    if entry and entry.expires ~= 0 and bb_auraMatches(aura, entry) then
        list[spellId] = nil
        if next(list) == nil then
            bb_given[guid] = nil
        end
    end
end

-- Removes the tracked buffs of one player. onlySpells = set of spell ids, or nil for all.
-- Returns how many auras were removed.
local function bb_clearPlayer(target, guid, list, onlySpells)
    local removed = 0
    for spellId, entry in pairs(list) do
        if not onlySpells or onlySpells[spellId] then
            if target and bb_isOurs(target, spellId, entry) then
                target:RemoveAura(spellId)
                removed = removed + 1
            end
            list[spellId] = nil                     -- also drops buffs queued for resurrect
        end
    end
    if next(list) == nil then
        bb_given[guid] = nil
    end
    return removed
end

-- Dead player: remember the buff so bb_onResurrect hands it out.
-- Returns the duration in ms for the message (0 = spell default), or nil if nothing was queued.
local function bb_queueForResurrect(target, spell)
    local guid = target:GetGUIDLow()
    bb_given[guid] = bb_given[guid] or {}
    local old = bb_given[guid][spell.id]
    local now = os.time()
    local expires = spell.duration > 0 and (now + spell.duration / 1000) or 0   -- 0 = spell default

    -- Keep whichever lasts longer
    if old and (old.expires == -1 or (expires ~= 0 and old.expires > expires)) then
        return old.expires == -1 and -1 or (old.expires - now) * 1000
    end

    bb_given[guid][spell.id] = { spell = spell, expires = expires }
    return spell.duration
end

-- Short visual (e.g. Spotlight) on the player. Applied as an aura so the duration can be cut short;
-- falls back to a triggered cast if the spell has no aura.
local function bb_playVisual(target)
    local id = Config.VisualSpellId
    if not id or id == 0 then
        return
    end
    local aura = target:AddAura(id, target)
    if aura then
        local ms = (Config.VisualDurationSeconds or 5) * 1000
        aura:SetMaxDuration(ms)
        aura:SetDuration(ms)
    else
        target:CastSpell(target, id, true)
    end
end

local function bb_spellName(spell, locale)
    local info = GetSpellInfo(spell.id)
    local name = info and info:GetName(locale)
    if (name == nil or name == "") and info then
        name = info:GetName(0)
    end
    if name == nil or name == "" then
        name = spell.comment ~= "" and spell.comment or ("Spell "..spell.id)
    end
    return name
end

local function bb_formatDuration(seconds)
    seconds = math.floor(seconds)
    if seconds <= 0 then
        return "default"
    elseif seconds % 3600 == 0 then
        return string.format("%dh", seconds / 3600)
    elseif seconds % 60 == 0 then
        return string.format("%d min", seconds / 60)
    end
    return string.format("%d sec", seconds)
end

-- .bonusbuff list [alias]
local function bb_list(player, showAliases)
    local locale = player and player:GetDbcLocale() or 0
    local function line(text)
        if player then player:SendBroadcastMessage(text) else print(text) end
    end

    bb_reply(player, "LIST_HEADER")
    for _, key in ipairs(groupOrder) do
        local g = groups[key]
        line(g.name)
        if showAliases then
            for _, alias in ipairs(g.aliases) do
                line(bb_t(player, "LIST_ALIAS", alias))
            end
        end
        for _, spell in ipairs(g.spells) do
            line(string.format("  %s - %d - %d (%s)", bb_spellName(spell, locale),
                spell.minLevel, spell.maxLevel, bb_formatDuration(spell.duration / 1000)))
        end
        line(" ")
    end
    if not showAliases then
        bb_reply(player, "LIST_ALIAS_HINT")
    end
end

local function bb_apply(player, group)
    local playersBuffed, aurasApplied, deadQueued = 0, 0, 0

    for _, target in ipairs(GetPlayersInWorld(TEAM_NEUTRAL)) do
        if target:IsAlive() or (not Config.SkipDeadPlayers and Config.PreserveOnDeath) then
            local level = target:GetLevel()
            local received = {}

            local isDead = not target:IsAlive()

            for _, spell in ipairs(group.spells) do
                if level >= spell.minLevel and level <= spell.maxLevel and bb_allowedHere(target, spell, level) then
                    if isDead then
                        -- The core refuses auras on dead players: queue it for resurrect instead
                        local ms = bb_queueForResurrect(target, spell)
                        if ms then
                            table.insert(received, { spell = spell, ms = ms })
                        end
                    else
                        local aura = bb_tryAura(target, spell)
                        if aura then
                            table.insert(received, { spell = spell, ms = aura:GetDuration() })
                        end
                    end
                end
            end

            -- Some buffs replace each other (two battle elixirs, a flask and an elixir...):
            -- only keep the ones the player still has.
            if not isDead and #received > 1 then
                local tracked = bb_given[target:GetGUIDLow()] or {}
                local kept = {}
                for _, r in ipairs(received) do
                    if tracked[r.spell.id] and target:HasAura(r.spell.id) then
                        table.insert(kept, r)
                    end
                end
                received = kept
            end

            if #received > 0 then
                if isDead then
                    deadQueued = deadQueued + 1
                else
                    playersBuffed = playersBuffed + 1
                    aurasApplied = aurasApplied + #received
                end

                if Config.SoundId and Config.SoundId > 0 then
                    target:PlayDirectSound(Config.SoundId, target)
                end

                if not isDead then
                    bb_playVisual(target)
                end

                if Config.AnnounceToPlayers then
                    local locale = target:GetDbcLocale()
                    target:SendBroadcastMessage(bb_t(target, "ANNOUNCE"))
                    target:SendBroadcastMessage(bb_t(target, "BLESSED_HEADER"))
                    for _, r in ipairs(received) do
                        local name = bb_spellName(r.spell, locale)
                        if r.ms == 0 then
                            target:SendBroadcastMessage("  "..name)                -- spell default, applied on resurrect
                        elseif r.ms and r.ms > 0 then
                            target:SendBroadcastMessage(bb_t(target, "BLESSED_ENTRY", name, math.ceil(r.ms / 60000)))
                        else
                            target:SendBroadcastMessage(bb_t(target, "BLESSED_ENTRY_PERMANENT", name))
                        end
                    end
                    if group.worldBuff then
                        target:SendBroadcastMessage(bb_t(target, "WORLDBUFF_PVP_NOTE"))
                    end
                    if isDead then
                        target:SendBroadcastMessage(bb_t(target, "PENDING_RESURRECT"))
                    end
                end
            end
        end
    end

    bb_reply(player, "APPLIED", group.name, playersBuffed, aurasApplied)
    if deadQueued > 0 then
        bb_reply(player, "QUEUED_DEAD", deadQueued)
    end
end

-- .bonusbuff clear [group]: removes only buffs given by this script.
local function bb_clear(player, group)
    local onlySpells
    if group then
        onlySpells = {}
        for _, spell in ipairs(group.spells) do
            onlySpells[spell.id] = true
        end
    end

    local online = {}
    for _, target in ipairs(GetPlayersInWorld(TEAM_NEUTRAL)) do
        online[target:GetGUIDLow()] = target
    end

    local aurasRemoved, playersAffected = 0, 0
    for guid, list in pairs(bb_given) do
        local target = online[guid]
        if target then
            local removed = bb_clearPlayer(target, guid, list, onlySpells)
            if removed > 0 then
                aurasRemoved = aurasRemoved + removed
                playersAffected = playersAffected + 1
                if Config.AnnounceToPlayers then
                    target:SendBroadcastMessage(bb_t(target, "CLEARED_PLAYER"))
                end
            end
        else
            -- Offline: their auras are saved with the character, remove them at next login
            bb_pendingClear[guid] = bb_pendingClear[guid] or {}
            for spellId, entry in pairs(list) do
                if not onlySpells or onlySpells[spellId] then
                    bb_pendingClear[guid][spellId] = entry
                end
            end
            bb_clearPlayer(nil, guid, list, onlySpells)
        end
    end

    bb_reply(player, "CLEARED", group and group.name or "all", aurasRemoved, playersAffected)
end

-- Positive buffs do not tick while a player is offline, so the recorded end times would be wrong
-- after a relog. Snapshot the time left at logout and re-sync it at login.
local function bb_snapshot(player, list)
    if not list then
        return
    end
    local now = os.time()
    for spellId, entry in pairs(list) do
        local aura = player:GetAura(spellId)
        if aura and bb_auraMatches(aura, entry) then
            entry.pausedRemaining = aura:GetDuration()     -- ms, -1 = permanent
        elseif player:IsAlive() then
            list[spellId] = nil                            -- not ours any more
        end
        entry.logoutAt = now
    end
end

local function bb_resync(player, list)
    if not list then
        return
    end
    local now = os.time()
    for spellId, entry in pairs(list) do
        if entry.pausedRemaining then
            local aura = player:GetAura(spellId)
            if aura and math.abs(aura:GetDuration() - entry.pausedRemaining) <= 5000 then
                local d = aura:GetDuration()
                entry.expires = d == -1 and -1 or (now + math.ceil(d / 1000))
            else
                list[spellId] = nil
            end
        elseif entry.logoutAt and entry.expires > 0 then
            entry.expires = entry.expires + (now - entry.logoutAt)   -- logged out while dead: pause too
        end
        entry.pausedRemaining, entry.logoutAt = nil, nil
    end
end

local function bb_onLogout(event, player)
    local guid = player:GetGUIDLow()
    bb_snapshot(player, bb_given[guid])
    bb_loggingOut[guid] = true
end

local function bb_onLogin(event, player)
    local guid = player:GetGUIDLow()
    bb_loggingOut[guid] = nil
    bb_resync(player, bb_given[guid])
    if bb_given[guid] and next(bb_given[guid]) == nil then
        bb_given[guid] = nil
    end

    local list = bb_pendingClear[guid]
    if not list then
        return
    end
    bb_pendingClear[guid] = nil
    bb_resync(player, list)
    local removed = 0
    for spellId, entry in pairs(list) do
        if bb_isOurs(player, spellId, entry) then
            player:RemoveAura(spellId)
            removed = removed + 1
        end
    end
    if removed > 0 and Config.AnnounceToPlayers then
        player:SendBroadcastMessage(bb_t(player, "CLEARED_PLAYER"))
    end
end

local function bb_onCommand(event, player, command)
    local args = {}
    for word in string.gmatch(command, "%S+") do
        table.insert(args, string.lower(word))
    end

    if args[1] ~= "bonusbuff" then
        return
    end

    if player and player:GetGMRank() < Config.MinGMRank then
        return   -- let the core answer with its normal "no such command"
    end

    if args[2] == nil then
        bb_reply(player, "USAGE")
    elseif args[2] == "list" then
        bb_list(player, args[3] == "alias" or args[3] == "aliases")
    elseif args[2] == "clear" then
        if args[3] == nil or args[3] == "all" then
            bb_clear(player, nil)
        elseif groups[args[3]] then
            bb_clear(player, groups[args[3]])
        else
            bb_reply(player, "ERR_UNKNOWN_GROUP", args[3])
        end
    else
        local group = groups[args[2]]
        if group then
            bb_apply(player, group)
        else
            bb_reply(player, "ERR_UNKNOWN_GROUP", args[2])
        end
    end

    return false
end

-- Death removes every aura in the core. On resurrect, give back what this script handed out,
-- with only the time that was left (time spent dead still counts down).
local function bb_onResurrect(event, player)
    local guid = player:GetGUIDLow()
    local list = bb_given[guid]
    if not list then
        return
    end

    -- Battleground / arena override: keep the list (it may be used after the next death
    -- outside), but don't give anything back here unless allowed.
    local zone = bb_zone(player)
    if zone == "bg" and not Config.PreserveInBattleground then
        return
    elseif zone == "arena" and not Config.PreserveInArena then
        return
    end

    local now = os.time()
    for spellId, entry in pairs(list) do
        local remainingMs
        if entry.expires == -1 then
            remainingMs = -1
        elseif entry.expires == 0 then
            remainingMs = 0                             -- queued while dead, use spell default
        else
            remainingMs = (entry.expires - now) * 1000
        end
        if remainingMs == -1 or remainingMs == 0 or remainingMs > 1000 then
            if zone ~= "world" and not entry.spell.allowBG then
                -- not allowed inside battlegrounds / arenas, keep it for later
            elseif player:HasAura(spellId) then
                list[spellId] = nil                     -- already has it from another source
            else
                local aura = player:AddAura(spellId, player)
                if aura then
                    local d = aura:GetDuration()
                    if d >= 0 and d <= 1000 then
                        player:RemoveAura(spellId)      -- disabled for this level by the core
                        list[spellId] = nil
                    elseif remainingMs ~= 0 then
                        aura:SetMaxDuration(remainingMs)
                        aura:SetDuration(remainingMs)
                    end
                    -- From now on track the real end time
                    if list[spellId] then
                        local d2 = aura:GetDuration()
                        list[spellId].expires = d2 == -1 and -1 or (now + math.ceil(d2 / 1000))
                    end
                end
            end
        else
            list[spellId] = nil                         -- expired
        end
    end

    if next(list) == nil then
        bb_given[guid] = nil
    end
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, bb_onCommand)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, bb_onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, bb_onLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_AURA_REMOVE, bb_onAuraRemove)
if Config.PreserveOnDeath then
    RegisterPlayerEvent(PLAYER_EVENT_ON_RESURRECT, bb_onResurrect)
end
