--
-- BonusBuff_Locale.lua
-- Player-facing strings for BonusBuff, organised by locale.
--
-- Locale IDs come from player:GetDbcLocale():
--   0=enUS, 1=koKR, 2=frFR, 3=deDE, 4=zhCN, 5=zhTW, 6=esES, 7=esMX, 8=ruRU
--
-- Every key is a table {[locale_id] = "translated string", ...}.
-- The [0] (enUS) entry is the fallback used whenever no translation exists for a locale.
-- Use %d / %s for dynamic values.
--

local L = {}

-- ---------------------------------------------------------------------------
-- Sent to every player who actually received at least one aura
-- ---------------------------------------------------------------------------
L.ANNOUNCE = {
    [0] = "Happy Holidays from Chromie and her helpers!",
    [1] = "크로미와 그녀의 조력자들이 즐거운 휴일을 기원합니다!",
    [2] = "Joyeuses fêtes de la part de Chromie et de ses assistants !",
    [3] = "Frohe Feiertage von Chromie und ihren Helfern!",
    [4] = "克罗米和她的助手们祝你节日快乐！",
    [5] = "克羅米和她的助手們祝你節日快樂！",
    [6] = "¡Felices fiestas de parte de Cromi y sus ayudantes!",
    [7] = "¡Felices fiestas de parte de Cromi y sus ayudantes!",
    [8] = "Хрома и её помощники поздравляют вас с праздниками!",
}

L.BLESSED_HEADER = {
    [0] = "You've been blessed with:",
    [1] = "다음 효과를 받았습니다:",
    [2] = "Vous avez reçu :",
    [3] = "Du wurdest gesegnet mit:",
    [4] = "你获得了以下祝福：",
    [5] = "你獲得了以下祝福：",
    [6] = "Has recibido:",
    [7] = "Has recibido:",
    [8] = "Вы получили:",
}

-- %s = spell name, %d = duration in minutes
L.BLESSED_ENTRY = {
    [0] = "  %s - %d minutes",
    [1] = "  %s - %d분",
    [2] = "  %s - %d minutes",
    [3] = "  %s - %d Minuten",
    [4] = "  %s - %d 分钟",
    [5] = "  %s - %d 分鐘",
    [6] = "  %s - %d minutos",
    [7] = "  %s - %d minutos",
    [8] = "  %s - %d мин.",
}

-- %s = spell name (aura without an expiry time)
L.BLESSED_ENTRY_PERMANENT = {
    [0] = "  %s - until cancelled",
    [1] = "  %s - 취소할 때까지",
    [2] = "  %s - jusqu'à annulation",
    [3] = "  %s - bis zum Abbruch",
    [4] = "  %s - 直到取消",
    [5] = "  %s - 直到取消",
    [6] = "  %s - hasta que se cancele",
    [7] = "  %s - hasta que se cancele",
    [8] = "  %s - до отмены",
}

-- Extra line sent after the list when the group has WorldBuff = true
L.WORLDBUFF_PVP_NOTE = {
    [0] = "World buffs are removed when you enter a battleground or arena.",
    [1] = "전장 또는 투기장에 입장하면 월드 버프가 제거됩니다.",
    [2] = "Les bonus mondiaux sont retirés lorsque vous entrez dans un champ de bataille ou une arène.",
    [3] = "Weltbuffs werden entfernt, wenn du ein Schlachtfeld oder eine Arena betrittst.",
    [4] = "进入战场或竞技场时，世界增益会被移除。",
    [5] = "進入戰場或競技場時，世界增益會被移除。",
    [6] = "Los beneficios de mundo se eliminan al entrar en un campo de batalla o una arena.",
    [7] = "Los beneficios de mundo se eliminan al entrar en un campo de batalla o una arena.",
    [8] = "Мировые усиления снимаются при входе на поле боя или арену.",
}

-- Extra line for players who were dead when the buff was given
L.PENDING_RESURRECT = {
    [0] = "You are dead - these buffs will be applied when you resurrect.",
    [1] = "사망 상태입니다 - 부활하면 이 효과가 적용됩니다.",
    [2] = "Vous êtes mort - ces bonus seront appliqués à votre résurrection.",
    [3] = "Du bist tot - diese Buffs werden bei deiner Wiederbelebung angewendet.",
    [4] = "你已死亡——复活后将获得这些增益。",
    [5] = "你已死亡——復活後將獲得這些增益。",
    [6] = "Estás muerto: estos beneficios se aplicarán cuando resucites.",
    [7] = "Estás muerto: estos beneficios se aplicarán cuando resucites.",
    [8] = "Вы мертвы - эти усиления будут наложены после воскрешения.",
}

-- ---------------------------------------------------------------------------
-- GM feedback
-- ---------------------------------------------------------------------------
L.USAGE = {
    [0] = "Usage: .bonusbuff <group> | .bonusbuff clear [group] | .bonusbuff list [alias]",
    [1] = "사용법: .bonusbuff <그룹> | .bonusbuff clear [그룹] | .bonusbuff list [alias]",
    [2] = "Utilisation : .bonusbuff <groupe> | .bonusbuff clear [groupe] | .bonusbuff list [alias]",
    [3] = "Verwendung: .bonusbuff <Gruppe> | .bonusbuff clear [Gruppe] | .bonusbuff list [alias]",
    [4] = "用法：.bonusbuff <组> | .bonusbuff clear [组] | .bonusbuff list [alias]",
    [5] = "用法：.bonusbuff <組> | .bonusbuff clear [組] | .bonusbuff list [alias]",
    [6] = "Uso: .bonusbuff <grupo> | .bonusbuff clear [grupo] | .bonusbuff list [alias]",
    [7] = "Uso: .bonusbuff <grupo> | .bonusbuff clear [grupo] | .bonusbuff list [alias]",
    [8] = "Использование: .bonusbuff <группа> | .bonusbuff clear [группа] | .bonusbuff list [alias]",
}

L.LIST_HEADER = {
    [0] = "Available BonusBuff groups:",
    [1] = "사용 가능한 BonusBuff 그룹:",
    [2] = "Groupes BonusBuff disponibles :",
    [3] = "Verfügbare BonusBuff-Gruppen:",
    [4] = "可用的 BonusBuff 组：",
    [5] = "可用的 BonusBuff 組：",
    [6] = "Grupos de BonusBuff disponibles:",
    [7] = "Grupos de BonusBuff disponibles:",
    [8] = "Доступные группы BonusBuff:",
}

-- %s = alias (shown by .bonusbuff list alias)
L.LIST_ALIAS = {
    [0] = "  alias: %s",
    [1] = "  별칭: %s",
    [2] = "  alias : %s",
    [3] = "  Alias: %s",
    [4] = "  别名：%s",
    [5] = "  別名：%s",
    [6] = "  alias: %s",
    [7] = "  alias: %s",
    [8] = "  псевдоним: %s",
}

L.LIST_ALIAS_HINT = {
    [0] = "Use .bonusbuff list alias to show all aliases.",
    [1] = "모든 별칭을 보려면 .bonusbuff list alias 를 사용하세요.",
    [2] = "Utilisez .bonusbuff list alias pour afficher tous les alias.",
    [3] = "Nutze .bonusbuff list alias, um alle Aliase anzuzeigen.",
    [4] = "使用 .bonusbuff list alias 查看所有别名。",
    [5] = "使用 .bonusbuff list alias 查看所有別名。",
    [6] = "Usa .bonusbuff list alias para ver todos los alias.",
    [7] = "Usa .bonusbuff list alias para ver todos los alias.",
    [8] = "Используйте .bonusbuff list alias, чтобы увидеть все псевдонимы.",
}

L.ERR_UNKNOWN_GROUP = {
    [0] = "Unknown BonusBuff group: %s. Use .bonusbuff list",
    [1] = "알 수 없는 BonusBuff 그룹: %s. .bonusbuff list 를 사용하세요",
    [2] = "Groupe BonusBuff inconnu : %s. Utilisez .bonusbuff list",
    [3] = "Unbekannte BonusBuff-Gruppe: %s. Nutze .bonusbuff list",
    [4] = "未知的 BonusBuff 组：%s。请使用 .bonusbuff list",
    [5] = "未知的 BonusBuff 組：%s。請使用 .bonusbuff list",
    [6] = "Grupo de BonusBuff desconocido: %s. Usa .bonusbuff list",
    [7] = "Grupo de BonusBuff desconocido: %s. Usa .bonusbuff list",
    [8] = "Неизвестная группа BonusBuff: %s. Используйте .bonusbuff list",
}

-- %s = group name, %d = players buffed, %d = auras applied
L.APPLIED = {
    [0] = "BonusBuff '%s' applied to %d player(s) (%d aura(s) total).",
    [1] = "BonusBuff '%s' 이(가) 플레이어 %d명에게 적용되었습니다 (오라 %d개).",
    [2] = "BonusBuff '%s' appliqué à %d joueur(s) (%d aura(s) au total).",
    [3] = "BonusBuff '%s' auf %d Spieler angewendet (%d Aura(s) insgesamt).",
    [4] = "BonusBuff '%s' 已应用于 %d 名玩家（共 %d 个光环）。",
    [5] = "BonusBuff '%s' 已套用於 %d 名玩家（共 %d 個光環）。",
    [6] = "BonusBuff '%s' aplicado a %d jugador(es) (%d aura(s) en total).",
    [7] = "BonusBuff '%s' aplicado a %d jugador(es) (%d aura(s) en total).",
    [8] = "BonusBuff '%s' применён к %d игрок(ам) (всего аур: %d).",
}

-- %d = dead players who will get the buff on resurrect
L.QUEUED_DEAD = {
    [0] = "%d dead player(s) will receive it when they resurrect.",
    [1] = "사망한 플레이어 %d명은 부활 시 받게 됩니다.",
    [2] = "%d joueur(s) mort(s) le recevront à leur résurrection.",
    [3] = "%d tote(r) Spieler erhält/erhalten es bei der Wiederbelebung.",
    [4] = "%d 名死亡玩家将在复活后获得。",
    [5] = "%d 名死亡玩家將在復活後獲得。",
    [6] = "%d jugador(es) muerto(s) lo recibirán al resucitar.",
    [7] = "%d jugador(es) muerto(s) lo recibirán al resucitar.",
    [8] = "Мёртвые игроки (%d) получат его после воскрешения.",
}

-- %s = group name or "all", %d = auras removed, %d = players affected
L.CLEARED = {
    [0] = "BonusBuff clear (%s): removed %d aura(s) from %d online player(s). Offline players are cleared at next login.",
    [1] = "BonusBuff 제거 (%s): 오라 %d개 제거, 접속 중인 플레이어 %d명. 오프라인 플레이어는 다음 접속 시 제거됩니다.",
    [2] = "BonusBuff clear (%s) : %d aura(s) retirée(s) sur %d joueur(s) en ligne. Les joueurs hors ligne seront nettoyés à leur prochaine connexion.",
    [3] = "BonusBuff clear (%s): %d Aura(s) bei %d Online-Spieler(n) entfernt. Offline-Spieler werden beim nächsten Login bereinigt.",
    [4] = "BonusBuff 清除（%s）：已移除 %d 个光环，涉及 %d 名在线玩家。离线玩家将在下次登录时清除。",
    [5] = "BonusBuff 清除（%s）：已移除 %d 個光環，涉及 %d 名線上玩家。離線玩家將在下次登入時清除。",
    [6] = "BonusBuff clear (%s): %d aura(s) eliminada(s) de %d jugador(es) conectado(s). Los desconectados se limpiarán al volver a entrar.",
    [7] = "BonusBuff clear (%s): %d aura(s) eliminada(s) de %d jugador(es) conectado(s). Los desconectados se limpiarán al volver a entrar.",
    [8] = "BonusBuff clear (%s): снято аур: %d, у игроков онлайн: %d. Офлайн-игроки будут очищены при следующем входе.",
}

-- Sent to a player whose BonusBuff auras were removed
L.CLEARED_PLAYER = {
    [0] = "Your bonus buffs have been removed.",
    [1] = "보너스 버프가 제거되었습니다.",
    [2] = "Vos bonus ont été retirés.",
    [3] = "Deine Bonus-Buffs wurden entfernt.",
    [4] = "你的额外增益已被移除。",
    [5] = "你的額外增益已被移除。",
    [6] = "Tus bonificaciones han sido eliminadas.",
    [7] = "Tus bonificaciones han sido eliminadas.",
    [8] = "Ваши бонусные усиления сняты.",
}

return L
