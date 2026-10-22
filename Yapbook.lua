-- Yapbook 1.3
-- A spellbook for your chat messages. Chapters, a Professions chapter with
-- every Vanilla profession, favorites, custom icons, colors, tags,
-- per-entry cooldowns and paced multi-line sending.
-- Left-click an entry to send it. Shift-click ignores its cooldown.
-- Right-click an entry to edit it.

local ADDON_NAME = ...

local FONT_TITLE = "Fonts\\MORPHEUS.TTF"
local FONT_BODY = "Fonts\\FRIZQT__.TTF"
local INK = { 0.22, 0.12, 0.04 }
local INK_SOFT = { 0.42, 0.30, 0.16 }

local ICON = "Interface\\Icons\\"
local MINIMAP_ICON = ICON .. "INV_Misc_Book_09"
local STAR = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"

local CATEGORIES = {
    { key = "general", name = "General Chat", icon = ICON .. "INV_Misc_Note_01" },
    { key = "professions", name = "Professions", icon = ICON .. "Trade_Engineering", subs = {
        { key = "alchemy",        name = "Alchemy",        icon = ICON .. "Trade_Alchemy" },
        { key = "blacksmithing",  name = "Blacksmithing",  icon = ICON .. "Trade_BlackSmithing" },
        { key = "enchanting",     name = "Enchanting",     icon = ICON .. "Trade_Engraving" },
        { key = "engineering",    name = "Engineering",    icon = ICON .. "Trade_Engineering" },
        { key = "herbalism",      name = "Herbalism",      icon = ICON .. "Trade_Herbalism" },
        { key = "leatherworking", name = "Leatherworking", icon = ICON .. "Trade_LeatherWorking" },
        { key = "mining",         name = "Mining",         icon = ICON .. "Trade_Mining" },
        { key = "skinning",       name = "Skinning",       icon = ICON .. "INV_Misc_Pelt_Wolf_01" },
        { key = "tailoring",      name = "Tailoring",      icon = ICON .. "Trade_Tailoring" },
        { key = "cooking",        name = "Cooking",        icon = ICON .. "INV_Misc_Food_15" },
        { key = "firstaid",       name = "First Aid",      icon = ICON .. "Spell_Holy_SealOfSacrifice" },
        { key = "fishing",        name = "Fishing",        icon = ICON .. "Trade_Fishing" },
    } },
}

local COLORS = {
    { key = "none",   name = "No color" },
    { key = "red",    name = "Red",    r = 0.72, g = 0.12, b = 0.10 },
    { key = "orange", name = "Orange", r = 0.86, g = 0.45, b = 0.06 },
    { key = "yellow", name = "Yellow", r = 0.85, g = 0.68, b = 0.05 },
    { key = "green",  name = "Green",  r = 0.18, g = 0.55, b = 0.16 },
    { key = "blue",   name = "Blue",   r = 0.16, g = 0.36, b = 0.76 },
    { key = "purple", name = "Purple", r = 0.50, g = 0.22, b = 0.70 },
    { key = "grey",   name = "Grey",   r = 0.42, g = 0.42, b = 0.42 },
}
local COLOR_BY_KEY = {}
for _, c in ipairs(COLORS) do COLOR_BY_KEY[c.key] = c end

-- Icons offered in the picker. Missing ones are filtered out at runtime
-- where the client allows it; you can also type any icon name by hand.
local ICON_CHOICES = {
    "INV_Misc_Note_01", "INV_Misc_Note_06", "INV_Misc_Book_09", "INV_Misc_Book_11",
    "INV_Scroll_03", "INV_Scroll_05", "INV_Misc_QuestionMark", "INV_Misc_Map_01",
    "INV_Misc_Coin_01", "INV_Misc_Coin_02", "INV_Misc_Coin_03", "INV_Misc_Bag_10",
    "INV_Box_01", "INV_Misc_Gift_01", "INV_Misc_Key_03", "INV_Misc_Horn_01",
    "INV_Misc_Spyglass_02", "INV_Misc_Rune_01", "INV_Misc_Head_Dragon_01", "INV_Misc_Bone_HumanSkull_01",
    "INV_Misc_Head_Murloc_01", "INV_Misc_Gem_Ruby_02", "INV_Misc_Gem_Emerald_02", "INV_Misc_Gem_Sapphire_02",
    "INV_Sword_04", "INV_Sword_27", "INV_Axe_01", "INV_Mace_01",
    "INV_Staff_08", "INV_Weapon_Bow_02", "INV_Shield_06", "INV_Helmet_03",
    "INV_Chest_Chain", "INV_Potion_51", "INV_Potion_54", "INV_Drink_05",
    "INV_Misc_Food_15", "INV_Misc_Fish_02", "INV_Misc_Bandage_15", "INV_Ingot_03",
    "INV_Ore_Copper_01", "INV_Fabric_Linen_01", "INV_Misc_Pelt_Wolf_01", "INV_Misc_Herb_10",
    "INV_Enchant_DustArcane", "Spell_Holy_Heal", "Spell_Holy_PowerWordShield", "Spell_Holy_Resurrection",
    "Spell_Holy_SealOfMight", "Spell_Fire_Fireball02", "Spell_Fire_SelfDestruct", "Spell_Frost_FrostBolt02",
    "Spell_Nature_Lightning", "Spell_Nature_Polymorph", "Spell_Nature_Regeneration", "Spell_Shadow_ShadowBolt",
    "Spell_Shadow_RaiseDead", "Spell_Arcane_TeleportStormWind", "Ability_Warrior_BattleShout", "Ability_Rogue_Sprint",
    "Ability_Mount_RidingHorse", "Ability_Racial_BloodRage", "Ability_Ambush", "Ability_Stealth",
}

local STATIC_CHANNELS = { "PREVIEW", "PARTY", "RAID", "GUILD", "INSTANCE_CHAT", "EMOTE", "SAY", "YELL" }
local MAX_LEN = 240
local MIN_DELAY = 2.0
local JITTER = 0.8

local COLS, ROWS = 3, 4
local PER_PAGE = COLS * ROWS
local CELL_W, CELL_H, ROW_H = 232, 60, 66
local MAX_FAVS = 16
local PICK_COLS, PICK_ROWS = 6, 6

local defaults = {
    channel = "PARTY",
    delay = 3.5,
    manual = false,
    cooldown = 60,
    minimapAngle = 215,
    hideMinimap = false,
    entries = {},
}

local DB
local ui = { cells = {}, tabs = {}, subtabs = {}, favs = {} }
local curTop, curSub, page = 1, 1, 1
local queue, index, running, nextAt = {}, 0, false, 0
local runLabel, runEntry, doneLabel = "", nil, nil
local runManual = false -- the mode the current run uses
local sent -- the most recent send, so a block from the game can rewind it
local Refresh, RefreshCooldowns -- forward declarations

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Yapbook:|r " .. tostring(msg))
end

local function Snd(name)
    if SOUNDKIT and SOUNDKIT[name] then PlaySound(SOUNDKIT[name]) end
end

local function Trim(s)
    return ((s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

---------------------------------------------------------------------
-- Text -> chat lines
---------------------------------------------------------------------
local function SplitLong(line, out)
    while #line > MAX_LEN do
        local cut = line:sub(1, MAX_LEN):match("^.*()%s") or MAX_LEN
        out[#out + 1] = Trim(line:sub(1, cut))
        line = Trim(line:sub(cut + 1))
    end
    if line ~= "" then out[#out + 1] = line end
end

local function BuildQueue(text)
    local out = {}
    for raw in (text or ""):gmatch("[^\r\n]+") do
        local line = Trim(raw)
        if line ~= "" then SplitLong(line, out) end
    end
    return out
end

local function ParseTags(s)
    local out = {}
    for raw in (s or ""):gmatch("[^,%s]+") do
        local t = raw:gsub("^#+", ""):lower()
        if t ~= "" then out[#out + 1] = t end
    end
    return out
end

local function TagLine(e)
    local tags = ParseTags(e.tags)
    if #tags == 0 then return nil end
    return "#" .. table.concat(tags, " #")
end

---------------------------------------------------------------------
-- Channels
---------------------------------------------------------------------
local function JoinedChannels()
    local list = {}
    local t = { GetChannelList() }
    local i = 1
    while i <= #t do
        if type(t[i]) == "number" and type(t[i + 1]) == "string" then
            local step = (type(t[i + 2]) == "boolean") and 3 or 2
            if not (step == 3 and t[i + 2] == true) then
                list[#list + 1] = "CH:" .. t[i + 1]
            end
            i = i + step
        else
            i = i + 1
        end
    end
    return list
end

local function ChannelList()
    local l = {}
    for _, c in ipairs(STATIC_CHANNELS) do l[#l + 1] = c end
    for _, c in ipairs(JoinedChannels()) do l[#l + 1] = c end
    return l
end

local function ChannelLabel(ch)
    if ch:sub(1, 3) == "CH:" then
        return (ch:sub(4):gsub(" %- .*$", ""))
    end
    return ch
end

local function ChannelUsable(ch)
    if ch == "PREVIEW" or ch == "SAY" or ch == "YELL" or ch == "EMOTE" then return true end
    if ch == "PARTY" then return IsInGroup() end
    if ch == "RAID" then return IsInRaid() end
    if ch == "GUILD" then return IsInGuild() end
    if ch == "INSTANCE_CHAT" then return IsInGroup(LE_PARTY_CATEGORY_INSTANCE or 2) end
    if ch:sub(1, 3) == "CH:" then
        local id = GetChannelName(ch:sub(4))
        return id and id > 0
    end
    return false
end

-- Channels where the game only allows a send right after a click or key press.
local function NeedsManual(ch)
    return ch == "SAY" or ch == "YELL" or ch == "EMOTE" or ch:sub(1, 3) == "CH:"
end

-- The mode the current channel will actually use.
local function EffectiveManual()
    return NeedsManual(DB.channel) or DB.manual
end

local function ModeMessage()
    local pref = "Mode for Party, Raid, Guild, Instance and Preview: " .. (DB.manual and "Manual" or "Auto") .. "."
    if NeedsManual(DB.channel) then
        return pref .. " " .. ChannelLabel(DB.channel) .. " always uses Manual."
    end
    return pref
end

local function SendLine(line)
    local ch = DB.channel
    if ch == "PREVIEW" then
        Print(line)
    elseif ch:sub(1, 3) == "CH:" then
        SendChatMessage(line, "CHANNEL", nil, (GetChannelName(ch:sub(4))))
    else
        SendChatMessage(line, ch)
    end
end

---------------------------------------------------------------------
-- Cooldowns
---------------------------------------------------------------------
local function CooldownLeft(e)
    if not e or not e.last or (DB.cooldown or 0) <= 0 then return 0 end
    local left = e.last + DB.cooldown - time()
    if left > 0 then return left end
    return 0
end

local function ApplyCooldown(cd, e)
    if not cd then return end
    local left = CooldownLeft(e)
    if left > 0 then
        cd:SetCooldown(GetTime() - (DB.cooldown - left), DB.cooldown)
    else
        cd:SetCooldown(0, 0)
    end
end

local function NewCooldown(parent, anchor)
    local ok, cd = pcall(CreateFrame, "Cooldown", nil, parent, "CooldownFrameTemplate")
    if not ok then cd = CreateFrame("Cooldown", nil, parent) end
    cd:SetAllPoints(anchor)
    return cd
end

---------------------------------------------------------------------
-- Sending engine
---------------------------------------------------------------------
local function UpdateControls()
    if not ui.frame then return end
    if NeedsManual(DB.channel) then
        ui.mode:SetText("Mode: Manual (required)")
        ui.mode:Disable()
    else
        ui.mode:SetText("Mode: " .. (DB.manual and "Manual" or "Auto"))
        ui.mode:Enable()
    end
    if running then
        ui.next:SetShown(runManual)
    else
        ui.next:SetShown(EffectiveManual())
    end
    ui.channel:SetText("Channel: " .. ChannelLabel(DB.channel))
    if running then
        ui.status:SetText(("Sending: %s   %d / %d"):format(runLabel, index, #queue))
        ui.bar:SetMinMaxValues(0, math.max(1, #queue))
        ui.bar:SetValue(index)
    elseif doneLabel then
        ui.status:SetText("Done: " .. doneLabel)
        ui.bar:SetMinMaxValues(0, 1)
        ui.bar:SetValue(1)
    else
        ui.status:SetText("Idle")
        ui.bar:SetMinMaxValues(0, 1)
        ui.bar:SetValue(0)
    end
    for _, c in ipairs(ui.cells) do
        local on = running and c.item ~= nil and c.item.e ~= nil and c.item.e == runEntry
        if on then
            c.run:Show()
            if not c.runAnim:IsPlaying() then c.runAnim:Play() end
        else
            c.runAnim:Stop()
            c.run:Hide()
        end
    end
    if ui.mm and ui.mm.pulse then
        if running then
            ui.mm.pulseTex:Show()
            ui.mm.pulse:Play()
        else
            ui.mm.pulse:Stop()
            ui.mm.pulseTex:Hide()
        end
    end
end

local function Stop(reason)
    running = false
    runEntry = nil
    doneLabel = nil
    if reason then Print(reason) end
    UpdateControls()
end

local function Step(fromClick)
    if not running then
        if fromClick then Print("Nothing is running. Click an entry first.") end
        return
    end
    if GetTime() < nextAt then
        if fromClick then Print("Too soon - wait a moment (spam protection).") end
        return
    end
    index = index + 1
    if index > #queue then
        Stop("Finished.")
        return
    end
    if not ChannelUsable(DB.channel) then
        Stop("Channel no longer available, stopped.")
        return
    end
    -- remember this send so a block from the game can rewind it
    sent = { at = GetTime(), idx = index, entry = runEntry, prevLast = runEntry and runEntry.last }
    local ok, err = pcall(SendLine, queue[index])
    if not ok then
        Stop("Send failed: " .. tostring(err))
        return
    end
    if index == 1 and runEntry and DB.channel ~= "PREVIEW" then
        runEntry.last = time()
        if RefreshCooldowns then RefreshCooldowns() end
    end
    nextAt = GetTime() + math.max(MIN_DELAY, DB.delay) + math.random() * JITTER
    if index >= #queue then
        running = false
        runEntry = nil
        doneLabel = ("%s (%d %s)"):format(runLabel, #queue, #queue == 1 and "line" or "lines")
        Print("Finished.")
    end
    UpdateControls()
end

local function StartEntry(entry, force)
    local left = CooldownLeft(entry)
    if left > 0 and not force and DB.channel ~= "PREVIEW" then
        Print(("'%s' is on cooldown (%ds left). Shift-click to send anyway."):format(entry.name, math.ceil(left)))
        return
    end
    queue = BuildQueue(entry.text)
    if #queue == 0 then
        Print("That entry is empty. Right-click it to edit.")
        return
    end
    if not ChannelUsable(DB.channel) then
        Print("Channel " .. ChannelLabel(DB.channel) .. " is not available right now.")
        return
    end
    index = 0
    running = true
    runLabel = entry.name
    runEntry = entry
    doneLabel = nil
    nextAt = GetTime()
    runManual = EffectiveManual()
    -- Line 1 always goes out on this click, which the game counts as a key press.
    Step(true)
    if running then
        if runManual then
            Print("Press Next line (or /yap next) for each following line.")
        else
            Print(("Sending %d lines to %s."):format(#queue, ChannelLabel(DB.channel)))
        end
    end
    UpdateControls()
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_ACTION_BLOCKED")
driver:SetScript("OnEvent", function(_, _, addon)
    if addon ~= ADDON_NAME then return end
    -- Only react to a block caused by the send we just made in this frame.
    if not (sent and sent.at == GetTime()) then return end
    -- The game refused that line: rewind it and continue in Manual for this run.
    if sent.idx == 1 and sent.entry then sent.entry.last = sent.prevLast end
    running = true
    runEntry = sent.entry
    doneLabel = nil
    index = sent.idx - 1
    runManual = true
    nextAt = GetTime()
    sent = nil
    Print("The game wanted a click for that line. Switched to Manual: press Next line to send it.")
    if RefreshCooldowns then RefreshCooldowns() end
    UpdateControls()
end)
driver:SetScript("OnUpdate", function()
    if running and not runManual then Step(false) end
end)

---------------------------------------------------------------------
-- Data helpers
---------------------------------------------------------------------
local ALL_KEYS = {}
for _, top in ipairs(CATEGORIES) do
    if top.subs then
        for _, sub in ipairs(top.subs) do
            ALL_KEYS[#ALL_KEYS + 1] = { key = "prof:" .. sub.key, label = top.name .. ": " .. sub.name, icon = sub.icon }
        end
    else
        ALL_KEYS[#ALL_KEYS + 1] = { key = top.key, label = top.name, icon = top.icon }
    end
end
local KEY_INFO = {}
for _, k in ipairs(ALL_KEYS) do KEY_INFO[k.key] = k end

local function Entries(key)
    DB.entries[key] = DB.entries[key] or {}
    return DB.entries[key]
end

local function EntryIcon(e, key)
    return (e and e.icon) or (KEY_INFO[key] and KEY_INFO[key].icon) or ICON .. "INV_Misc_QuestionMark"
end

local function Current()
    local top = CATEGORIES[curTop]
    if top.subs then
        local sub = top.subs[curSub]
        return { key = "prof:" .. sub.key, title = top.name .. ": " .. sub.name }
    end
    return { key = top.key, title = top.name }
end

local function Favorites()
    local out = {}
    for _, k in ipairs(ALL_KEYS) do
        for idx, e in ipairs(Entries(k.key)) do
            if e.fav then
                out[#out + 1] = { e = e, key = k.key, idx = idx, label = k.label }
            end
        end
    end
    return out
end

local function ResolveIcon(s)
    s = Trim(s)
    if s == "" then return nil end
    local n = tonumber(s)
    if n then return n end
    if s:find("\\", 1, true) or s:find("/", 1, true) then return s end
    return ICON .. s
end

local ICON_LIST
local function IconList()
    if ICON_LIST then return ICON_LIST end
    local all, seen = {}, {}
    local function add(p)
        if not seen[p] then
            seen[p] = true
            all[#all + 1] = p
        end
    end
    for _, k in ipairs(ALL_KEYS) do add(k.icon) end
    for _, n in ipairs(ICON_CHOICES) do add(ICON .. n) end

    local list = all
    if type(GetFileIDFromPath) == "function" then
        local filtered = {}
        for _, p in ipairs(all) do
            local ok, id = pcall(GetFileIDFromPath, p)
            if ok and id then filtered[#filtered + 1] = p end
        end
        if #filtered >= 12 then list = filtered end
    end
    ICON_LIST = list
    return list
end

local function ColorOf(e)
    return e and e.color and COLOR_BY_KEY[e.color]
end

---------------------------------------------------------------------
-- Entry editor + icon picker
---------------------------------------------------------------------
local edKey, edIdx, edIcon, edColor, edFav
local pickPage = 1

local function EditorSetIcon(icon)
    edIcon = icon
    ui.editor.iconBtn.icon:SetTexture(EntryIcon({ icon = icon }, edKey))
end

local function EditorSetColor(key)
    edColor = key or "none"
    for _, sw in ipairs(ui.editor.swatches) do
        sw.sel:SetShown(sw.key == edColor)
    end
end

local function EditorSetFav(v)
    edFav = v and true or false
    local b = ui.editor.favBtn
    b.star:SetDesaturated(not edFav)
    b.star:SetAlpha(edFav and 1 or 0.45)
    ui.editor.favText:SetText(edFav and "Favorite" or "Not a favorite")
end

local function OpenEditor(key, idx)
    local e = ui.editor
    edKey, edIdx = key, idx
    local entry = idx and Entries(key)[idx]
    e.nameBox:SetText(entry and entry.name or "")
    e.edit:SetText(entry and entry.text or "")
    e.tagsBox:SetText(entry and entry.tags or "")
    EditorSetIcon(entry and entry.icon or nil)
    EditorSetColor(entry and entry.color or "none")
    EditorSetFav(entry and entry.fav)
    if e.TitleText then e.TitleText:SetText(KEY_INFO[key] and KEY_INFO[key].label or key) end
    e.delete:SetEnabled(entry ~= nil)
    e.earlier:SetEnabled(entry ~= nil)
    e.later:SetEnabled(entry ~= nil)
    ui.picker:Hide()
    e:Show()
    e.nameBox:SetFocus()
end

local function EditorSave()
    local name = Trim(ui.editor.nameBox:GetText())
    if name == "" then name = "Untitled" end
    local tags = ParseTags(ui.editor.tagsBox:GetText())
    local list = Entries(edKey)
    local entry = edIdx and list[edIdx]
    if not entry then
        entry = {}
        list[#list + 1] = entry
    end
    entry.name = name
    entry.text = ui.editor.edit:GetText()
    entry.icon = edIcon
    entry.color = (edColor ~= "none") and edColor or nil
    entry.fav = edFav or nil
    entry.tags = (#tags > 0) and table.concat(tags, ", ") or nil
    ui.editor:Hide()
    Snd("IG_MAINMENU_OPTION_CHECKBOX_ON")
    Refresh()
end

local function EditorDelete()
    local list = Entries(edKey)
    if edIdx and list[edIdx] then
        if list[edIdx] == runEntry then Stop() end
        table.remove(list, edIdx)
    end
    ui.editor:Hide()
    Refresh()
end

local function EditorMove(dir)
    local list = Entries(edKey)
    local j = edIdx and (edIdx + dir)
    if not (edIdx and list[edIdx] and list[j]) then return end
    list[edIdx], list[j] = list[j], list[edIdx]
    edIdx = j
    Refresh()
end

local function RefreshPicker()
    local p = ui.picker
    local list = IconList()
    local per = PICK_COLS * PICK_ROWS
    local pages = math.max(1, math.ceil(#list / per))
    if pickPage > pages then pickPage = pages end
    if pickPage < 1 then pickPage = 1 end
    for i, b in ipairs(p.buttons) do
        local path = list[(pickPage - 1) * per + i]
        b.path = path
        if path then
            b.icon:SetTexture(path)
            b:Show()
        else
            b:Hide()
        end
    end
    p.pageText:SetText(("%d / %d"):format(pickPage, pages))
    p.prev:SetEnabled(pickPage > 1)
    p.nextB:SetEnabled(pickPage < pages)
end

local function BuildIconPicker()
    local p = CreateFrame("Frame", "YapbookIconPicker", ui.editor, "BasicFrameTemplateWithInset")
    p:SetSize(284, 410)
    p:SetPoint("TOPLEFT", ui.editor, "TOPRIGHT", 4, 0)
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:SetFrameLevel(ui.editor:GetFrameLevel() + 10)
    p:EnableMouse(true)
    p:Hide()
    if p.TitleText then p.TitleText:SetText("Choose an icon") end
    tinsert(UISpecialFrames, "YapbookIconPicker")

    p.buttons = {}
    for i = 1, PICK_COLS * PICK_ROWS do
        local col = (i - 1) % PICK_COLS
        local row = math.floor((i - 1) / PICK_COLS)
        local b = CreateFrame("Button", nil, p)
        b:SetSize(36, 36)
        b:SetPoint("TOPLEFT", 18 + col * 42, -34 - row * 42)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints()
        b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetScript("OnClick", function(self)
            if self.path then
                EditorSetIcon(self.path)
                Snd("IG_MAINMENU_OPTION_CHECKBOX_ON")
                p:Hide()
            end
        end)
        b:SetScript("OnEnter", function(self)
            if not self.path then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText((tostring(self.path):gsub("^Interface\\Icons\\", "")), 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        p.buttons[i] = b
    end

    p:EnableMouseWheel(true)
    p:SetScript("OnMouseWheel", function(_, d)
        pickPage = pickPage - d
        RefreshPicker()
    end)

    local prev = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    prev:SetSize(28, 22)
    prev:SetPoint("BOTTOMLEFT", 18, 84)
    prev:SetText("<")
    prev:SetScript("OnClick", function() pickPage = pickPage - 1 RefreshPicker() end)
    p.prev = prev

    local nextB = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    nextB:SetSize(28, 22)
    nextB:SetPoint("BOTTOMRIGHT", -18, 84)
    nextB:SetText(">")
    nextB:SetScript("OnClick", function() pickPage = pickPage + 1 RefreshPicker() end)
    p.nextB = nextB

    p.pageText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p.pageText:SetPoint("BOTTOM", 0, 89)

    local custom = CreateFrame("EditBox", "YapbookIconCustom", p, "InputBoxTemplate")
    custom:SetSize(170, 22)
    custom:SetPoint("BOTTOMLEFT", 24, 50)
    custom:SetAutoFocus(false)
    custom:SetScript("OnEscapePressed", custom.ClearFocus)
    local hint = custom:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", 2, 0)
    hint:SetText("or type an icon name / ID")
    custom:SetScript("OnTextChanged", function(self) hint:SetShown(self:GetText() == "") end)
    local function UseCustom()
        local icon = ResolveIcon(custom:GetText())
        if icon then
            EditorSetIcon(icon)
            custom:SetText("")
            custom:ClearFocus()
            p:Hide()
        end
    end
    custom:SetScript("OnEnterPressed", UseCustom)

    local use = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    use:SetSize(60, 22)
    use:SetPoint("LEFT", custom, "RIGHT", 6, 0)
    use:SetText("Use")
    use:SetScript("OnClick", UseCustom)

    local def = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    def:SetSize(248, 24)
    def:SetPoint("BOTTOM", 0, 16)
    def:SetText("Use the chapter's default icon")
    def:SetScript("OnClick", function()
        EditorSetIcon(nil)
        p:Hide()
    end)

    p:SetScript("OnShow", RefreshPicker)
    ui.picker = p
end

local function BuildEditor()
    local e = CreateFrame("Frame", "YapbookEditor", UIParent, "BasicFrameTemplateWithInset")
    e:SetSize(500, 520)
    e:SetPoint("CENTER")
    e:SetFrameStrata("FULLSCREEN_DIALOG")
    e:SetMovable(true)
    e:EnableMouse(true)
    e:RegisterForDrag("LeftButton")
    e:SetScript("OnDragStart", e.StartMoving)
    e:SetScript("OnDragStop", e.StopMovingOrSizing)
    e:Hide()
    tinsert(UISpecialFrames, "YapbookEditor")

    -- Icon
    local ib = CreateFrame("Button", nil, e)
    ib:SetSize(44, 44)
    ib:SetPoint("TOPLEFT", 22, -38)
    ib.icon = ib:CreateTexture(nil, "ARTWORK")
    ib.icon:SetAllPoints()
    ib.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    ib.rim = ib:CreateTexture(nil, "OVERLAY")
    ib.rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    ib.rim:SetSize(78, 78)
    ib.rim:SetPoint("CENTER", 0, -1)
    ib:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    ib:SetScript("OnClick", function()
        if ui.picker:IsShown() then ui.picker:Hide() else ui.picker:Show() end
    end)
    ib:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Icon", 1, 1, 1)
        GameTooltip:AddLine("Click to choose an icon for this message.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    ib:SetScript("OnLeave", GameTooltip_Hide)
    e.iconBtn = ib

    -- Name
    local l1 = e:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l1:SetPoint("TOPLEFT", 82, -34)
    l1:SetText("Name")
    local nameBox = CreateFrame("EditBox", "YapbookEditorName", e, "InputBoxTemplate")
    nameBox:SetSize(270, 22)
    nameBox:SetPoint("TOPLEFT", 88, -52)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(40)
    nameBox:SetScript("OnEscapePressed", nameBox.ClearFocus)
    nameBox:SetScript("OnEnterPressed", nameBox.ClearFocus)
    e.nameBox = nameBox

    -- Favorite toggle
    local fb = CreateFrame("Button", nil, e)
    fb:SetSize(24, 24)
    fb:SetPoint("TOPLEFT", 376, -50)
    fb.star = fb:CreateTexture(nil, "ARTWORK")
    fb.star:SetAllPoints()
    fb.star:SetTexture(STAR)
    fb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    fb:SetScript("OnClick", function() EditorSetFav(not edFav) end)
    e.favBtn = fb
    e.favText = e:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    e.favText:SetPoint("LEFT", fb, "RIGHT", 6, 0)

    -- Color swatches
    local l2 = e:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l2:SetPoint("TOPLEFT", 22, -100)
    l2:SetText("Color")
    e.swatches = {}
    for i, c in ipairs(COLORS) do
        local sw = CreateFrame("Button", nil, e)
        sw:SetSize(20, 20)
        sw:SetPoint("TOPLEFT", 88 + (i - 1) * 30, -96)
        sw.key = c.key
        local tex = sw:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        if c.r then
            tex:SetColorTexture(c.r, c.g, c.b, 1)
        else
            tex:SetColorTexture(0.18, 0.18, 0.18, 1)
            local x = sw:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            x:SetPoint("CENTER", 0, 0)
            x:SetText("x")
        end
        local frame = sw:CreateTexture(nil, "BORDER")
        frame:SetPoint("TOPLEFT", -1, 1)
        frame:SetPoint("BOTTOMRIGHT", 1, -1)
        frame:SetColorTexture(0, 0, 0, 1)
        sw.sel = sw:CreateTexture(nil, "OVERLAY")
        sw.sel:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        sw.sel:SetBlendMode("ADD")
        sw.sel:SetVertexColor(1, 0.85, 0.2)
        sw.sel:SetSize(40, 40)
        sw.sel:SetPoint("CENTER")
        sw.sel:Hide()
        sw:SetScript("OnClick", function() EditorSetColor(c.key) end)
        sw:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(c.name, 1, 1, 1)
            GameTooltip:Show()
        end)
        sw:SetScript("OnLeave", GameTooltip_Hide)
        e.swatches[i] = sw
    end

    -- Tags
    local l3 = e:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l3:SetPoint("TOPLEFT", 22, -134)
    l3:SetText("Tags")
    local tagsBox = CreateFrame("EditBox", "YapbookEditorTags", e, "InputBoxTemplate")
    tagsBox:SetSize(380, 22)
    tagsBox:SetPoint("TOPLEFT", 88, -130)
    tagsBox:SetAutoFocus(false)
    tagsBox:SetMaxLetters(80)
    tagsBox:SetScript("OnEscapePressed", tagsBox.ClearFocus)
    tagsBox:SetScript("OnEnterPressed", tagsBox.ClearFocus)
    local thint = tagsBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    thint:SetPoint("LEFT", 2, 0)
    thint:SetText("e.g. lyrics, meme, wts  (searchable)")
    tagsBox:SetScript("OnTextChanged", function(self) thint:SetShown(self:GetText() == "") end)
    e.tagsBox = tagsBox

    -- Message
    local l4 = e:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    l4:SetPoint("TOPLEFT", 22, -168)
    l4:SetText("Message  (every line becomes one chat message)")
    local scroll = CreateFrame("ScrollFrame", "YapbookEditorScroll", e, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -188)
    scroll:SetPoint("BOTTOMRIGHT", -36, 56)
    local edit = CreateFrame("EditBox", "YapbookEditorEdit", scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(430)
    edit:SetMaxLetters(0)
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    scroll:SetScrollChild(edit)
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function() edit:SetFocus() end)
    e.edit = edit

    local function Btn(text, w, point, x, fn)
        local b = CreateFrame("Button", nil, e, "UIPanelButtonTemplate")
        b:SetSize(w, 26)
        b:SetPoint(point, x, 16)
        b:SetText(text)
        b:SetScript("OnClick", fn)
        return b
    end
    Btn("Save", 80, "BOTTOMLEFT", 16, EditorSave)
    e.delete = Btn("Delete", 80, "BOTTOMLEFT", 100, EditorDelete)
    Btn("Cancel", 80, "BOTTOMLEFT", 184, function() e:Hide() end)
    e.later = Btn("Later >", 80, "BOTTOMRIGHT", -16, function() EditorMove(1) end)
    e.earlier = Btn("< Earlier", 80, "BOTTOMRIGHT", -100, function() EditorMove(-1) end)

    ui.editor = e
    e:SetScript("OnHide", function() if ui.picker then ui.picker:Hide() end end)
    BuildIconPicker()
end

---------------------------------------------------------------------
-- Book UI
---------------------------------------------------------------------
local function MakeIconButton(parent, size, iconPath)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexture(iconPath)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.rim = b:CreateTexture(nil, "OVERLAY")
    b.rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    b.rim:SetSize(size * 1.78, size * 1.78)
    b.rim:SetPoint("CENTER", 0, -1)
    b.glow = b:CreateTexture(nil, "OVERLAY", nil, 2)
    b.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.glow:SetBlendMode("ADD")
    b.glow:SetVertexColor(1, 0.85, 0.2)
    b.glow:SetSize(size * 1.9, size * 1.9)
    b.glow:SetPoint("CENTER")
    b.glow:Hide()
    b.glowAnim = b.glow:CreateAnimationGroup()
    local ga = b.glowAnim:CreateAnimation("Alpha")
    ga:SetFromAlpha(1)
    ga:SetToAlpha(0.5)
    ga:SetDuration(1.0)
    b.glowAnim:SetLooping("BOUNCE")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    return b
end

local function SetTabSelected(b, sel)
    b.glow:SetShown(sel)
    b.icon:SetDesaturated(not sel)
    if sel then
        if not b.glowAnim:IsPlaying() then b.glowAnim:Play() end
    else
        b.glowAnim:Stop()
    end
end

local function SetInk(fs, c, a)
    fs:SetTextColor(c[1], c[2], c[3], a or 1)
end

local function FillCell(c, item)
    c.item = item
    if not item then
        c:Hide()
        return
    end
    c:Show()
    if item.add then
        c.icon:SetTexture(nil)
        c.icon:SetColorTexture(0.35, 0.22, 0.1, 0.25)
        c.plus:Show()
        c.name:SetText("New message")
        c.sub:SetText("Click to write one")
        c.stripe:Hide()
        c.bg:SetColorTexture(0.30, 0.17, 0.06, 0.10)
        c.star:Hide()
        c.cd:SetCooldown(0, 0)
        return
    end

    local e = item.e
    c.icon:SetTexture(EntryIcon(e, item.key))
    c.plus:Hide()
    c.name:SetText(e.name)

    local parts = {}
    if item.label then parts[#parts + 1] = item.label end
    local tl = TagLine(e)
    if tl then parts[#parts + 1] = tl end
    local n = #BuildQueue(e.text)
    parts[#parts + 1] = (n == 1) and "1 line" or (n .. " lines")
    c.sub:SetText(table.concat(parts, "  -  "))

    local col = ColorOf(e)
    if col then
        c.stripe:SetColorTexture(col.r, col.g, col.b, 1)
        c.stripe:Show()
        c.bg:SetColorTexture(col.r, col.g, col.b, 0.16)
    else
        c.stripe:Hide()
        c.bg:SetColorTexture(0.30, 0.17, 0.06, 0.10)
    end

    c.star:Show()
    c.star.tex:SetDesaturated(not e.fav)
    c.star.tex:SetAlpha(e.fav and 1 or 0.3)

    ApplyCooldown(c.cd, e)
end

local function EntryTooltip(owner, it)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(it.e.name, 1, 1, 1)
    if it.label then GameTooltip:AddLine(it.label, 1, 0.82, 0) end
    local tl = TagLine(it.e)
    if tl then GameTooltip:AddLine(tl, 0.55, 0.75, 1) end
    local preview = (it.e.text or ""):sub(1, 200)
    if preview ~= "" then GameTooltip:AddLine(preview, 0.8, 0.8, 0.8, true) end
    local left = CooldownLeft(it.e)
    if left > 0 then
        GameTooltip:AddLine(("Cooldown: %ds left (Shift-click to override)"):format(math.ceil(left)), 1, 0.4, 0.3)
    end
    GameTooltip:AddLine("Left-click: send", 0.4, 0.8, 1)
    GameTooltip:AddLine("Right-click: edit", 0.4, 0.8, 1)
    GameTooltip:Show()
end

RefreshCooldowns = function()
    for _, c in ipairs(ui.cells) do
        if c:IsShown() and c.item and c.item.e then ApplyCooldown(c.cd, c.item.e) end
    end
    for _, b in ipairs(ui.favs) do
        if b:IsShown() and b.item then ApplyCooldown(b.cd, b.item.e) end
    end
end

Refresh = function(animate)
    if not ui.frame then return end
    local q = Trim(ui.search:GetText()):lower()
    q = (q:gsub("^#", ""))
    local searching = q ~= ""
    local cur = Current()

    -- list for the grid
    local list = {}
    if searching then
        for _, k in ipairs(ALL_KEYS) do
            for idx, e in ipairs(Entries(k.key)) do
                if e.name:lower():find(q, 1, true)
                    or (e.text or ""):lower():find(q, 1, true)
                    or (e.tags or ""):find(q, 1, true) then
                    list[#list + 1] = { e = e, key = k.key, idx = idx, label = k.label }
                end
            end
        end
    else
        for idx, e in ipairs(Entries(cur.key)) do
            list[#list + 1] = { e = e, key = cur.key, idx = idx }
        end
        list[#list + 1] = { add = true, key = cur.key }
    end

    local pages = math.max(1, math.ceil(#list / PER_PAGE))
    if page > pages then page = pages end
    if page < 1 then page = 1 end

    ui.title:SetText(searching and "Search results" or cur.title)

    -- vertical layout: favorites row, profession row, grid
    local y = -80
    local favs = Favorites()
    if #favs > 0 then
        ui.favRow:ClearAllPoints()
        ui.favRow:SetPoint("TOPLEFT", ui.pageArea, "TOPLEFT", 28, y)
        ui.favRow:Show()
        for i = 1, MAX_FAVS do
            local b, it = ui.favs[i], favs[i]
            b.item = it
            if it then
                b.icon:SetTexture(EntryIcon(it.e, it.key))
                ApplyCooldown(b.cd, it.e)
                b:Show()
            else
                b:Hide()
            end
        end
        ui.favMore:SetShown(#favs > MAX_FAVS)
        ui.favMore:SetText("+" .. (#favs - MAX_FAVS))
        y = y - 40
    else
        ui.favRow:Hide()
    end

    local isProf = (not searching) and CATEGORIES[curTop].subs ~= nil
    if isProf then
        ui.subRow:ClearAllPoints()
        ui.subRow:SetPoint("TOPLEFT", ui.pageArea, "TOPLEFT", 28, y)
        ui.subRow:Show()
        y = y - 38
    else
        ui.subRow:Hide()
    end
    local gridTop = y - 8

    for i = 1, PER_PAGE do
        local c = ui.cells[i]
        local col = (i - 1) % COLS
        local row = math.floor((i - 1) / COLS)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", ui.pageArea, "TOPLEFT", 28 + col * (CELL_W + 8), gridTop - row * ROW_H)
        FillCell(c, list[(page - 1) * PER_PAGE + i])
        if animate and c:IsShown() then
            c:SetAlpha(0)
            c.fade:Stop()
            c.fadeAnim:SetStartDelay((i - 1) * 0.025)
            c.fade:Play()
        else
            c.fade:Stop()
            c:SetAlpha(1)
        end
    end

    ui.pageText:SetText(("Page %d/%d"):format(page, pages))
    ui.prev:SetEnabled(page > 1)
    ui.nextPage:SetEnabled(page < pages)
    ui.empty:SetShown(searching and #list == 0)

    local onlyAdd = (not searching) and #list == 1
    ui.hint2:SetShown(onlyAdd)
    if onlyAdd then
        if CATEGORIES[curTop].subs then
            ui.hint2:SetText("No " .. CATEGORIES[curTop].subs[curSub].name .. " messages yet. Time to advertise your wares!")
        else
            ui.hint2:SetText("No yaps inscribed yet. Click + to write your first.")
        end
    end

    for i, t in ipairs(ui.tabs) do SetTabSelected(t, (not searching) and i == curTop) end
    for i, t in ipairs(ui.subtabs) do SetTabSelected(t, i == curSub) end
    UpdateControls()
end

local function CycleChannel(dir)
    local list = ChannelList()
    local cur = 1
    for i, c in ipairs(list) do
        if c == DB.channel then cur = i break end
    end
    DB.channel = list[((cur - 1 + dir) % #list) + 1]
    UpdateControls()
end

local function SimpleTooltip(frame, title, ...)
    local lines = { ... }
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(title, 1, 1, 1)
        for _, l in ipairs(lines) do GameTooltip:AddLine(l, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

local function BuildCell(pg)
    local c = CreateFrame("Button", nil, pg)
    c:SetSize(CELL_W, CELL_H)
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    c.bg = c:CreateTexture(nil, "BACKGROUND")
    c.bg:SetAllPoints()
    c.bg:SetColorTexture(0.30, 0.17, 0.06, 0.10)

    c.line = c:CreateTexture(nil, "BORDER")
    c.line:SetColorTexture(0.35, 0.20, 0.08, 0.35)
    c.line:SetPoint("BOTTOMLEFT")
    c.line:SetPoint("BOTTOMRIGHT")
    c.line:SetHeight(1)

    c.stripe = c:CreateTexture(nil, "BORDER")
    c.stripe:SetPoint("TOPLEFT")
    c.stripe:SetPoint("BOTTOMLEFT")
    c.stripe:SetWidth(4)
    c.stripe:Hide()

    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetSize(38, 38)
    c.icon:SetPoint("LEFT", 10, 0)
    c.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    c.rim = c:CreateTexture(nil, "OVERLAY")
    c.rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    c.rim:SetSize(68, 68)
    c.rim:SetPoint("CENTER", c.icon, "CENTER", 0, -1)

    c.cd = NewCooldown(c, c.icon)

    c.plus = c:CreateFontString(nil, "OVERLAY")
    c.plus:SetFont(FONT_BODY, 30, "OUTLINE")
    c.plus:SetTextColor(1, 0.82, 0)
    c.plus:SetPoint("CENTER", c.icon, "CENTER", 0, 1)
    c.plus:SetText("+")
    c.plus:Hide()

    c.name = c:CreateFontString(nil, "OVERLAY")
    c.name:SetFont(FONT_BODY, 14, "")
    SetInk(c.name, INK)
    c.name:SetPoint("LEFT", c.icon, "RIGHT", 14, 9)
    c.name:SetWidth(CELL_W - 86)
    c.name:SetJustifyH("LEFT")
    c.name:SetWordWrap(false)

    c.sub = c:CreateFontString(nil, "OVERLAY")
    c.sub:SetFont(FONT_BODY, 11, "")
    SetInk(c.sub, INK_SOFT)
    c.sub:SetPoint("LEFT", c.icon, "RIGHT", 14, -8)
    c.sub:SetWidth(CELL_W - 70)
    c.sub:SetJustifyH("LEFT")
    c.sub:SetWordWrap(false)

    -- gold pulse while this entry is being sent
    c.run = c:CreateTexture(nil, "OVERLAY")
    c.run:SetAllPoints()
    c.run:SetColorTexture(1, 0.80, 0.20, 0.30)
    c.run:Hide()
    c.runAnim = c.run:CreateAnimationGroup()
    local ra = c.runAnim:CreateAnimation("Alpha")
    ra:SetFromAlpha(1)
    ra:SetToAlpha(0.2)
    ra:SetDuration(0.6)
    c.runAnim:SetLooping("BOUNCE")

    -- click flash
    c.flash = c:CreateTexture(nil, "OVERLAY")
    c.flash:SetAllPoints()
    c.flash:SetColorTexture(1, 0.85, 0.40, 0.55)
    c.flash:SetAlpha(0)
    c.flashAnim = c.flash:CreateAnimationGroup()
    local fa = c.flashAnim:CreateAnimation("Alpha")
    fa:SetFromAlpha(1)
    fa:SetToAlpha(0)
    fa:SetDuration(0.45)
    c.flashAnim:SetScript("OnPlay", function() c.flash:SetAlpha(1) end)
    c.flashAnim:SetScript("OnFinished", function() c.flash:SetAlpha(0) end)

    -- page fade-in
    c.fade = c:CreateAnimationGroup()
    c.fadeAnim = c.fade:CreateAnimation("Alpha")
    c.fadeAnim:SetFromAlpha(0)
    c.fadeAnim:SetToAlpha(1)
    c.fadeAnim:SetDuration(0.22)
    c.fadeAnim:SetSmoothing("OUT")
    c.fade:SetScript("OnFinished", function() c:SetAlpha(1) end)

    local hl = c:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 0.9, 0.5, 0.22)

    -- favorite star
    local star = CreateFrame("Button", nil, c)
    star:SetSize(16, 16)
    star:SetPoint("TOPRIGHT", -5, -5)
    star.tex = star:CreateTexture(nil, "OVERLAY")
    star.tex:SetAllPoints()
    star.tex:SetTexture(STAR)
    star:SetScript("OnClick", function()
        local it = c.item
        if not (it and it.e) then return end
        it.e.fav = (not it.e.fav) or nil
        Snd(it.e.fav and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
        Refresh()
    end)
    star:SetScript("OnEnter", function(self)
        local it = c.item
        if not (it and it.e) then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(it.e.fav and "Remove from favorites" or "Add to favorites", 1, 1, 1)
        GameTooltip:Show()
    end)
    star:SetScript("OnLeave", GameTooltip_Hide)
    c.star = star

    c:SetScript("OnClick", function(self, btn)
        local it = self.item
        if not it then return end
        if it.add then
            OpenEditor(it.key, nil)
        elseif btn == "RightButton" then
            OpenEditor(it.key, it.idx)
        else
            self.flashAnim:Stop()
            self.flashAnim:Play()
            StartEntry(it.e, IsShiftKeyDown())
        end
    end)
    c:SetScript("OnEnter", function(self)
        local it = self.item
        if not it then return end
        if it.add then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("New message", 1, 1, 1)
            GameTooltip:AddLine("Write a new entry in this chapter.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        else
            EntryTooltip(self, it)
        end
    end)
    c:SetScript("OnLeave", GameTooltip_Hide)
    return c
end

local function BuildFavRow(pg)
    local row = CreateFrame("Frame", nil, pg)
    row:SetSize(720, 32)

    local st = row:CreateTexture(nil, "ARTWORK")
    st:SetTexture(STAR)
    st:SetSize(18, 18)
    st:SetPoint("LEFT", 0, 0)
    local lbl = row:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BODY, 13, "")
    SetInk(lbl, INK)
    lbl:SetPoint("LEFT", st, "RIGHT", 6, 0)
    lbl:SetText("Favorites")

    for i = 1, MAX_FAVS do
        local b = CreateFrame("Button", nil, row)
        b:SetSize(28, 28)
        b:SetPoint("LEFT", 100 + (i - 1) * 36, 0)
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints()
        b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        b.rim = b:CreateTexture(nil, "OVERLAY")
        b.rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        b.rim:SetSize(50, 50)
        b.rim:SetPoint("CENTER", 0, -1)
        b.cd = NewCooldown(b, b.icon)
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetScript("OnClick", function(self, btn)
            local it = self.item
            if not it then return end
            if btn == "RightButton" then
                OpenEditor(it.key, it.idx)
            else
                StartEntry(it.e, IsShiftKeyDown())
            end
        end)
        b:SetScript("OnEnter", function(self)
            if self.item then EntryTooltip(self, self.item) end
        end)
        b:SetScript("OnLeave", GameTooltip_Hide)
        ui.favs[i] = b
    end

    ui.favMore = row:CreateFontString(nil, "OVERLAY")
    ui.favMore:SetFont(FONT_BODY, 12, "")
    SetInk(ui.favMore, INK_SOFT)
    ui.favMore:SetPoint("LEFT", 100 + MAX_FAVS * 36, 0)

    local ln = row:CreateTexture(nil, "BORDER")
    ln:SetColorTexture(0.35, 0.20, 0.08, 0.30)
    ln:SetPoint("BOTTOMLEFT", 0, -4)
    ln:SetPoint("BOTTOMRIGHT", 0, -4)
    ln:SetHeight(1)

    ui.favRow = row
end

local function BuildUI()
    local tpl = BackdropTemplateMixin and "BackdropTemplate" or nil
    local f = CreateFrame("Frame", "YapbookFrame", UIParent, tpl)
    f:SetSize(800, 730)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    f:Hide()
    tinsert(UISpecialFrames, "YapbookFrame")
    f:SetScript("OnHide", function()
        Snd("IG_SPELLBOOK_CLOSE")
        if ui.editor then ui.editor:Hide() end
    end)
    f:SetScript("OnShow", function()
        Snd("IG_SPELLBOOK_OPEN")
        if DB and ui.frame then Refresh(true) end
    end)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_TITLE, 22, "")
    title:SetTextColor(1, 0.82, 0)
    title:SetPoint("TOP", 0, -20)
    title:SetText("Yapbook")
    title:SetShadowOffset(1, -1)
    title:SetShadowColor(0, 0, 0, 1)
    for _, side in ipairs({ -1, 1 }) do
        local l = f:CreateTexture(nil, "ARTWORK")
        l:SetColorTexture(0.72, 0.55, 0.18, 0.8)
        l:SetSize(150, 2)
        l:SetPoint(side < 0 and "RIGHT" or "LEFT", title, side < 0 and "LEFT" or "RIGHT", side * 14, -1)
    end

    -- Chapter tabs
    for i, top in ipairs(CATEGORIES) do
        local t = MakeIconButton(f, 44, top.icon)
        t:SetPoint("TOPLEFT", 34 + (i - 1) * 62, -50)
        t:SetScript("OnClick", function()
            curTop = i
            page = 1
            ui.search:SetText("")
            Snd("IG_CHARACTER_INFO_TAB")
            Refresh(true)
        end)
        SimpleTooltip(t, top.name)
        ui.tabs[i] = t
    end

    -- Search
    local search = CreateFrame("EditBox", "YapbookSearch", f, "InputBoxTemplate")
    search:SetSize(300, 22)
    search:SetPoint("TOPRIGHT", -60, -62)
    search:SetAutoFocus(false)
    search:SetScript("OnEscapePressed", function(self) self:SetText("") self:ClearFocus() end)
    search:SetScript("OnEnterPressed", search.ClearFocus)
    local hint = search:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("LEFT", 2, 0)
    hint:SetText("Search messages, keywords, #tags")
    search:SetScript("OnTextChanged", function(self)
        hint:SetShown(self:GetText() == "")
        page = 1
        Refresh()
    end)
    ui.search = search

    -- Parchment page
    local pg = CreateFrame("Frame", nil, f)
    pg:SetPoint("TOPLEFT", 22, -108)
    pg:SetPoint("BOTTOMRIGHT", -22, 160)
    local base = pg:CreateTexture(nil, "BACKGROUND")
    base:SetAllPoints()
    base:SetColorTexture(0.80, 0.66, 0.44, 1)

    for i = 0, 9 do
        local al = 0.22 - i * 0.021
        local off = i * 3
        local l = pg:CreateTexture(nil, "BORDER")
        l:SetColorTexture(0.30, 0.17, 0.05, al)
        l:SetPoint("TOPLEFT", off, -off)
        l:SetPoint("BOTTOMLEFT", off, off)
        l:SetWidth(3)
        local r = pg:CreateTexture(nil, "BORDER")
        r:SetColorTexture(0.30, 0.17, 0.05, al)
        r:SetPoint("TOPRIGHT", -off, -off)
        r:SetPoint("BOTTOMRIGHT", -off, off)
        r:SetWidth(3)
        local t = pg:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.30, 0.17, 0.05, al)
        t:SetPoint("TOPLEFT", off + 3, -off)
        t:SetPoint("TOPRIGHT", -off - 3, -off)
        t:SetHeight(3)
        local bt = pg:CreateTexture(nil, "BORDER")
        bt:SetColorTexture(0.30, 0.17, 0.05, al)
        bt:SetPoint("BOTTOMLEFT", off + 3, off)
        bt:SetPoint("BOTTOMRIGHT", -off - 3, off)
        bt:SetHeight(3)
    end

    local function Gold(p1, r1, p2, r2, x1, y1, x2, y2, w, h)
        local g = f:CreateTexture(nil, "ARTWORK")
        g:SetColorTexture(0.72, 0.55, 0.18, 0.95)
        g:SetPoint(p1, pg, r1, x1, y1)
        g:SetPoint(p2, pg, r2, x2, y2)
        if w then g:SetWidth(w) end
        if h then g:SetHeight(h) end
    end
    Gold("BOTTOMLEFT", "TOPLEFT", "BOTTOMRIGHT", "TOPRIGHT", -2, 0, 2, 0, nil, 2)
    Gold("TOPLEFT", "BOTTOMLEFT", "TOPRIGHT", "BOTTOMRIGHT", -2, 0, 2, 0, nil, 2)
    Gold("TOPRIGHT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT", 0, 2, 0, -2, 2, nil)
    Gold("TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", 0, 2, 0, -2, 2, nil)
    ui.pageArea = pg

    local ptitle = pg:CreateFontString(nil, "OVERLAY")
    ptitle:SetFont(FONT_TITLE, 30, "")
    SetInk(ptitle, INK)
    ptitle:SetPoint("TOPLEFT", 28, -22)
    ptitle:SetShadowOffset(1, -1)
    ptitle:SetShadowColor(1, 0.95, 0.8, 0.45)
    ui.title = ptitle

    local rule = pg:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(0.35, 0.2, 0.08, 0.75)
    rule:SetPoint("TOPLEFT", 24, -66)
    rule:SetPoint("TOPRIGHT", -24, -66)
    rule:SetHeight(2)
    local gem = pg:CreateTexture(nil, "OVERLAY")
    gem:SetColorTexture(0.55, 0.35, 0.10, 1)
    gem:SetSize(9, 9)
    gem:SetPoint("CENTER", rule, "CENTER", 0, 0)
    if gem.SetRotation then gem:SetRotation(math.rad(45)) end

    BuildFavRow(pg)

    -- Profession sub-tabs
    local subRow = CreateFrame("Frame", nil, pg)
    subRow:SetSize(700, 32)
    for i, sub in ipairs(CATEGORIES[2].subs) do
        local t = MakeIconButton(subRow, 28, sub.icon)
        t:SetPoint("LEFT", (i - 1) * 40, 0)
        t:SetScript("OnClick", function()
            curSub = i
            page = 1
            Snd("IG_CHARACTER_INFO_TAB")
            Refresh(true)
        end)
        SimpleTooltip(t, sub.name)
        ui.subtabs[i] = t
    end
    ui.subRow = subRow

    for i = 1, PER_PAGE do ui.cells[i] = BuildCell(pg) end

    ui.empty = pg:CreateFontString(nil, "OVERLAY")
    ui.empty:SetFont(FONT_BODY, 14, "")
    SetInk(ui.empty, INK_SOFT)
    ui.empty:SetPoint("CENTER", 0, 20)
    ui.empty:SetText("No messages match your search.")
    ui.empty:Hide()

    ui.hint2 = pg:CreateFontString(nil, "OVERLAY")
    ui.hint2:SetFont(FONT_BODY, 13, "")
    SetInk(ui.hint2, INK_SOFT)
    ui.hint2:SetPoint("CENTER", 0, -10)
    ui.hint2:Hide()

    local tip = pg:CreateFontString(nil, "OVERLAY")
    tip:SetFont(FONT_BODY, 11, "")
    SetInk(tip, INK_SOFT)
    tip:SetPoint("BOTTOMLEFT", 28, 14)
    tip:SetText("Left-click: send  -  Shift-click: ignore cooldown  -  Right-click: edit  -  Star: favorite")

    local nextPage = CreateFrame("Button", nil, pg, "UIPanelButtonTemplate")
    nextPage:SetSize(28, 22)
    nextPage:SetPoint("BOTTOMRIGHT", -24, 10)
    nextPage:SetText(">")
    nextPage:SetScript("OnClick", function() page = page + 1 Snd("IG_ABILITY_PAGE_TURN") Refresh(true) end)
    ui.nextPage = nextPage

    local prev = CreateFrame("Button", nil, pg, "UIPanelButtonTemplate")
    prev:SetSize(28, 22)
    prev:SetPoint("RIGHT", nextPage, "LEFT", -4, 0)
    prev:SetText("<")
    prev:SetScript("OnClick", function() page = page - 1 Snd("IG_ABILITY_PAGE_TURN") Refresh(true) end)
    ui.prev = prev

    local pageText = pg:CreateFontString(nil, "OVERLAY")
    pageText:SetFont(FONT_BODY, 12, "")
    SetInk(pageText, INK)
    pageText:SetPoint("RIGHT", prev, "LEFT", -10, 0)
    ui.pageText = pageText

    pg:EnableMouseWheel(true)
    pg:SetScript("OnMouseWheel", function(_, d)
        local old = page
        page = page - d
        Refresh(false)
        if page ~= old then
            Snd("IG_ABILITY_PAGE_TURN")
            Refresh(true)
        end
    end)

    -- Controls row A: delay, cooldown, channel
    local slider = CreateFrame("Slider", "YapbookDelay", f, "OptionsSliderTemplate")
    slider:SetPoint("BOTTOMLEFT", 44, 116)
    slider:SetWidth(220)
    slider:SetMinMaxValues(MIN_DELAY, 10)
    slider:SetValueStep(0.5)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    _G[slider:GetName() .. "Low"]:SetText(tostring(MIN_DELAY) .. "s")
    _G[slider:GetName() .. "High"]:SetText("10s")
    slider:SetScript("OnValueChanged", function(self, v)
        if DB then DB.delay = v end
        _G[self:GetName() .. "Text"]:SetText(("Delay between lines: %.1fs"):format(v))
    end)
    ui.slider = slider

    local cds = CreateFrame("Slider", "YapbookCooldown", f, "OptionsSliderTemplate")
    cds:SetPoint("BOTTOMLEFT", 300, 116)
    cds:SetWidth(220)
    cds:SetMinMaxValues(0, 300)
    cds:SetValueStep(5)
    if cds.SetObeyStepOnDrag then cds:SetObeyStepOnDrag(true) end
    _G[cds:GetName() .. "Low"]:SetText("Off")
    _G[cds:GetName() .. "High"]:SetText("5 min")
    cds:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v + 0.5)
        if DB then DB.cooldown = v end
        _G[self:GetName() .. "Text"]:SetText(v == 0 and "Entry cooldown: off" or ("Entry cooldown: %ds"):format(v))
        if ui.frame and RefreshCooldowns then RefreshCooldowns() end
    end)
    ui.cdSlider = cds

    local chBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    chBtn:SetSize(190, 24)
    chBtn:SetPoint("BOTTOMLEFT", 560, 112)
    chBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    chBtn:SetScript("OnClick", function(_, btn) CycleChannel(btn == "RightButton" and -1 or 1) end)
    SimpleTooltip(chBtn, "Channel",
        "Left-click: next   Right-click: previous",
        "Joined channels (General, Trade, LocalDefense, custom) are listed after Yell.",
        "PREVIEW prints to your own chat only. Say, Yell, Emote and joined channels switch to Manual automatically.")
    ui.channel = chBtn

    -- Controls row B: stop, next, mode
    local stop = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    stop:SetSize(90, 26)
    stop:SetPoint("BOTTOMLEFT", 44, 64)
    stop:SetText("Stop")
    stop:SetScript("OnClick", function() Stop("Stopped.") end)

    local nextBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    nextBtn:SetSize(110, 26)
    nextBtn:SetPoint("LEFT", stop, "RIGHT", 8, 0)
    nextBtn:SetText("Next line")
    nextBtn:SetScript("OnClick", function() Step(true) end)
    ui.next = nextBtn

    local mode = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    mode:SetSize(190, 24)
    mode:SetPoint("BOTTOMLEFT", 560, 66)
    mode:SetScript("OnClick", function()
        DB.manual = not DB.manual
        UpdateControls()
    end)
    if mode.SetMotionScriptsWhileDisabled then mode:SetMotionScriptsWhileDisabled(true) end
    mode:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Mode", 1, 1, 1)
        if NeedsManual(DB.channel) then
            GameTooltip:AddLine(ChannelLabel(DB.channel) .. " only accepts messages right after a click or key press, so Manual is used automatically.", 1, 0.8, 0.2, true)
            GameTooltip:AddLine("Your click on the entry sends line 1. Next line sends the rest.", 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine("Auto: all lines are sent on a timer.", 0.8, 0.8, 0.8, true)
            GameTooltip:AddLine("Manual: you press Next line for each line.", 0.8, 0.8, 0.8, true)
            GameTooltip:AddLine("This choice applies to Party, Raid, Guild, Instance and Preview.", 0.6, 0.6, 0.6, true)
        end
        GameTooltip:Show()
    end)
    mode:SetScript("OnLeave", GameTooltip_Hide)
    ui.mode = mode

    -- Controls row C: status + progress
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    status:SetPoint("BOTTOMLEFT", 46, 40)
    ui.status = status

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetSize(704, 10)
    bar:SetPoint("BOTTOMLEFT", 44, 24)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(1, 0.78, 0.15)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    local barbg = bar:CreateTexture(nil, "BACKGROUND")
    barbg:SetAllPoints()
    barbg:SetColorTexture(0, 0, 0, 0.6)
    ui.bar = bar

    ui.frame = f
    BuildEditor()
end

---------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------
local function PositionMinimapButton()
    local b = ui.mm
    if not b then return end
    local angle = math.rad(DB.minimapAngle or 215)
    local r = (Minimap:GetWidth() / 2) + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function BuildMinimapButton()
    local b = CreateFrame("Button", "YapbookMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(22, 22)
    bg:SetPoint("CENTER", 0, 1)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(MINIMAP_ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local pulseTex = b:CreateTexture(nil, "OVERLAY", nil, 1)
    pulseTex:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    pulseTex:SetBlendMode("ADD")
    pulseTex:SetAllPoints()
    pulseTex:Hide()
    local pulse = pulseTex:CreateAnimationGroup()
    local pa = pulse:CreateAnimation("Alpha")
    pa:SetFromAlpha(1)
    pa:SetToAlpha(0.25)
    pa:SetDuration(0.7)
    pulse:SetLooping("BOUNCE")
    b.pulseTex, b.pulse = pulseTex, pulse

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local dragging = false
    b:SetScript("OnDragStart", function(self)
        dragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            DB.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
            PositionMinimapButton()
        end)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        C_Timer.After(0.05, function() dragging = false end)
    end)
    b:SetScript("OnClick", function(_, btn)
        if dragging then return end
        if btn == "RightButton" then
            DB.manual = not DB.manual
            UpdateControls()
            Print(ModeMessage())
        else
            if ui.frame:IsShown() then ui.frame:Hide() else ui.frame:Show() end
        end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Yapbook", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: open / close", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: toggle Auto / Manual", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: move button", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)

    ui.mm = b
    PositionMinimapButton()
    b:SetShown(not DB.hideMinimap)
end

---------------------------------------------------------------------
-- Init + slash commands
---------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON_NAME then return end
    YapbookDB = YapbookDB or {}
    DB = YapbookDB
    for k, v in pairs(defaults) do
        if DB[k] == nil then DB[k] = (type(v) == "table") and {} or v end
    end

    -- One-time import from the old LyricPlayer addon, if its data is present.
    if not DB.migrated then
        local old = _G.LyricPlayerDB
        if type(old) == "table" then
            local g = Entries("general")
            if type(old.presets) == "table" then
                for _, p in ipairs(old.presets) do
                    g[#g + 1] = { name = p.name or "Untitled", text = p.text or "" }
                end
            end
            if type(old.text) == "string" and Trim(old.text) ~= "" then
                g[#g + 1] = { name = "Imported text", text = old.text }
            end
            if old.channel then DB.channel = old.channel end
            if old.delay then DB.delay = old.delay end
            if old.manual ~= nil then DB.manual = old.manual end
            if old.minimapAngle then DB.minimapAngle = old.minimapAngle end
        end
        DB.migrated = true
    end

    BuildUI()
    BuildMinimapButton()
    ui.slider:SetValue(DB.delay)
    ui.cdSlider:SetValue(DB.cooldown)
    Refresh()
end)

SLASH_YAPBOOK1 = "/yap"
SLASH_YAPBOOK2 = "/yapbook"
SlashCmdList["YAPBOOK"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "next" then
        Step(true)
    elseif cmd == "stop" then
        Stop("Stopped.")
    elseif cmd == "manual" then
        DB.manual = not DB.manual
        UpdateControls()
        Print(ModeMessage())
    elseif cmd == "minimap" then
        DB.hideMinimap = not DB.hideMinimap
        ui.mm:SetShown(not DB.hideMinimap)
        Print("Minimap button " .. (DB.hideMinimap and "hidden" or "shown"))
    elseif cmd == "cooldown" then
        local n = tonumber(arg)
        if n then
            n = math.max(0, math.min(300, math.floor(n)))
            ui.cdSlider:SetValue(n)
            Print(n == 0 and "Entry cooldown off" or ("Entry cooldown set to %ds"):format(n))
        else
            Print("Usage: /yap cooldown 60   (0 turns it off)")
        end
    elseif cmd == "channel" then
        local want = arg:lower()
        local num = tonumber(arg)
        if num then
            local _, cname = GetChannelName(num)
            if cname then
                DB.channel = "CH:" .. cname
                UpdateControls()
                Print("Channel set to " .. ChannelLabel(DB.channel))
                return
            end
        end
        for _, c in ipairs(ChannelList()) do
            if c:lower() == want or ChannelLabel(c):lower() == want then
                DB.channel = c
                UpdateControls()
                Print("Channel set to " .. ChannelLabel(c))
                return
            end
        end
        local names = {}
        for _, c in ipairs(ChannelList()) do names[#names + 1] = ChannelLabel(c) end
        Print("Unknown channel. Available: " .. table.concat(names, ", "))
    elseif cmd == "delay" then
        local n = tonumber(arg)
        if n then
            n = math.max(MIN_DELAY, math.min(10, n))
            DB.delay = n
            ui.slider:SetValue(n)
            Print(("Delay set to %.1fs"):format(n))
        else
            Print("Usage: /yap delay 3.5")
        end
    else
        if ui.frame:IsShown() then ui.frame:Hide() else ui.frame:Show() end
    end
end
