
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    for _, v in ipairs(playerGui:GetChildren()) do
        if v.Name:match("EX_StealAnEgg") or (v.Name == "GameMenu" and v:FindFirstChild("GlassBG", true)) then v:Destroy() end
    end
end)

local VERSION = "V36 (Glass)"
local SAVE_FILE = "cfg_a1.json"
local BASE_RADIUS = 140

local HINTS = {
    hatch = { "hatch" }, place = { "place" }, fuse = { "fuse" },
    index = { "claim" }, treadmill = { "treadmill", "tredmill" },
    trap = { "trap", "snare", "cage", "stun", "freeze", "glue" },
    sell = { "sell" }, favorite = { "favorite", "favourite" }, upgrade = { "upgrade" },
}
local UPGRADES = {
    upgTrail = { name = "Trail", words = { "trail" } },
    upgTreadmill = { name = "Treadmill", words = { "treadmill", "tredmill" } },
    upgBase = { name = "Base", words = { "base", "plot" } },
}
local AREAS = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom", "Titan Temple", "Angels & Demons", "Enchanted Forest" }
local AREA_DETECT = {
    { "Enchanted Forest", { "enchanted" } }, { "Angels & Demons", { "angel", "demon" } },
    { "Cherry Blossom", { "cherry", "blossom" } }, { "Titan Temple", { "titan" } },
    { "Abyss Ocean", { "abyss" } }, { "Prehistoric", { "prehistoric" } },
    { "Cosmic", { "cosmic" } }, { "Volcano", { "volcano" } }, { "Snow", { "snow" } },
    { "Jungle", { "jungle" } }, { "Desert", { "desert" } }, { "Lake", { "lake" } }, { "Forest", { "forest" } },
}
local FILTERS = {
    { "Size", { "Small", "Medium", "Large", "Giant" } },
    { "Rarity", { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Cosmic", "Eternal", "Divine" } },
    { "Variant", { "Normal", "Silver", "Golden", "Rainbow", "Bloom", "Spirit Bloom", "Parasite", "Fractured", "Scrambled" } },
}
local EVENT_DEFS = {
    { id = "scramble", name = "Dr. Scramble Mecha & Drone", desc = "Boss tiap 30 mnt, drop Samples", keywords = { "scramble", "mecha", "drone" }, mode = "attack", tool = "bat" },
    { id = "rift", name = "Rift & Overlord", desc = "Tiap 30 mnt, drop Boss Tokens", keywords = { "overlord", "rift" }, mode = "attack", tool = "bat" },
    { id = "greatbloom", name = "Great Bloom", desc = "Tiap 30 mnt", keywords = { "greatbloom", "great bloom" }, mode = "collect" },
    { id = "butterfly", name = "Butterfly Bloom", desc = "Tangkap kupu-kupu", keywords = { "butterfly" }, mode = "collect", tool = "net" },
    { id = "frog", name = "Hungry Frog (parasit)", desc = "5 parasit = Monster Chest", keywords = { "parasite", "hungryfrog", "frog" }, mode = "collect" },
    { id = "angdem", name = "Angels vs Demons (ring)", desc = "Kumpulkan ring tim", keywords = { "ring" }, mode = "touch" },
    { id = "admin", name = "Admin Abuse (Sammy)", desc = "Event admin mingguan", keywords = { "sammy" }, mode = "attack", tool = "bat" },
}
local SHOPS = {
    { name = "Shop Utama", info = "Featured: Extinction Egg (Robux)", gui = { "shop" }, world = { "shop" }, exclude = { "boss", "experiment", "lab", "scramble" } },
    { name = "Experiment Shop", info = "Booster, mutasi Scrambled, Experiment Egg", gui = { "experiment" }, world = { "experiment" }, exclude = {} },
    { name = "Dr. Scramble's Lab", info = "Tukar 3 egg jadi pet eksperimen (jalan ke NPC/lab lalu tekan prompt)", gui = { "laboratory", "lab", "scramble" },
      world = { "laboratory", "lab", "scramble", "drscramble", "scientist" },
      exclude = { "label", "available", "collab", "scrambled", "mecha", "drone", "boss", "event", "timer" },
      worldExclude = { "label", "available", "collab", "scrambled", "mecha", "drone", "overlord" } },
    { name = "Boss Shop", info = "Hadiah dari Rift / Overlord", gui = { "boss shop", "bossshop" }, world = { "bossshop", "boss shop" }, exclude = {} },
}
local THEME = {
    bg1 = Color3.fromRGB(20, 8, 36), bg2 = Color3.fromRGB(5, 2, 10),
    card = Color3.fromRGB(20, 9, 36), off = Color3.fromRGB(40, 20, 72),
    accent = Color3.fromRGB(142, 62, 255), accent2 = Color3.fromRGB(206, 160, 255),
    text = Color3.fromRGB(246, 240, 255), sub = Color3.fromRGB(172, 142, 222),
    good = Color3.fromRGB(196, 140, 255), warn = Color3.fromRGB(168, 108, 255),
    bad = Color3.fromRGB(104, 34, 184),
}

local function listToSet(list) local s = {}; for _, v in ipairs(list or {}) do s[v] = true end; return s end
local function setToList(set) local l = {}; for k, on in pairs(set) do if on then table.insert(l, k) end end; table.sort(l); return l end
local function norm(s) return (tostring(s):lower():gsub("[^%w]", "")) end
local function abbr(n)
    n = tonumber(n); if not n then return "?" end
    local units = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }; local i = 1
    while math.abs(n) >= 1000 and i < #units do n = n / 1000; i += 1 end
    if i == 1 then return ("%.0f"):format(n) end; return ("%.2f%s"):format(n, units[i])
end
local function nameHas(name, kw)
    local lname = name:lower(); kw = kw:lower(); local init = 1
    while true do
        local s = lname:find(kw, init, true); if not s then return false end
        local prev = name:sub(s - 1, s - 1); local cur = name:sub(s, s)
        if s == 1 or not prev:match("%a") or (prev:match("%l") and cur:match("%u")) then return true end
        init = s + 1
    end
end
local function nameHasAny(name, list) for _, k in ipairs(list) do if nameHas(name, k) then return true end end; return false end

local saved = {}
do
    if typeof(readfile) == "function" and typeof(isfile) == "function" then
        for _, fileName in ipairs({ SAVE_FILE }) do
            local ok, data = pcall(function() if isfile(fileName) then return HttpService:JSONDecode(readfile(fileName)) end; return nil end)
            if ok and type(data) == "table" then saved = data; break end
        end
    end
end
saved.winW = nil; saved.winH = nil; saved.fxBorder = nil; saved.cleanFx = nil; saved.antiKB = nil; saved.antiTrap = nil

local function S(key, default) local v = saved[key]; if v == nil then return default end; return v end
local function newFilterSet(key)
    local raw = S(key, {}); if type(raw) ~= "table" then raw = {} end
    local out = { Size = listToSet(raw.Size), Rarity = listToSet(raw.Rarity), Variant = listToSet(raw.Variant) }
    for _, entry in ipairs(FILTERS) do
        local valid = listToSet(entry[2])
        for k in pairs(out[entry[1]]) do if not valid[k] then out[entry[1]][k] = nil end end
    end
    return out
end

local areaCenters = { Forest = Vector3.new(597, 10, -324) }
for name, arr in pairs(S("areaCenters", {})) do
    if type(arr) == "table" and #arr == 3 then areaCenters[name] = Vector3.new(arr[1], arr[2], arr[3]) end
end

local config = {
    running = false, treadmillIdle = false,
    method = S("method", "Walk"), targetMode = S("targetMode", "All"),
    filters = newFilterSet("filters"), placeFilters = newFilterSet("placeFilters"),
    areas = listToSet(S("areas", {})), skipOwn = S("skipOwn", true), legit = S("legit", false), instantSteal = S("instantSteal", false),
    eggPredict = false, priorityOn = false,
    priority = S("priority", { "steal", "event", "hatch", "place", "fuse", "sell", "favorite" }),
    sellFilters = newFilterSet("sellFilters"), favFilters = newFilterSet("favFilters"), favNames = S("favNames", ""),
    petPlaceFilters = newFilterSet("petPlaceFilters"), petPlaceNames = S("petPlaceNames", ""),
    petSellFilters = newFilterSet("petSellFilters"), petSellNames = S("petSellNames", ""),
    afkSaver = false, fpsCap = S("fpsCap", 15), winW = S("winW", 430), winH = S("winH", 310),
    flySpeed = S("flySpeed2", 130), flyHeight = S("flyHeight", 12),
    fxBorder = S("fxBorder", true), antiKB = S("antiKB", false), antiTrap = S("antiTrap", false),
    antiAfk = S("antiAfk", true), pingPanel = S("pingPanel", true),
    removePopups = S("cleanFx", false), antiLag = S("antiLag", false),
    events = {}, auto = {
        hatch = false, place = false, fuse = false, index = false, sell = false, favorite = false,
        upgTrail = false, upgTreadmill = false, upgBase = false, petPlace = false, petSell = false,
    },
    autoInterval = S("autoInterval", 6),
    eggWebhookOn = false, eggWebhookUrl = S("eggWebhookUrl", ""),
    statsWebhookOn = false, statsWebhookUrl = S("statsWebhookUrl", ""),
    statsIntervalMin = S("statsIntervalMin", 5),
}

local V25 = {}
do
    local a = S("safeSpot", nil)
    if type(a) == "table" and #a == 3 then V25.manualSafe = Vector3.new(a[1], a[2], a[3]) end
end
local stats = { stolen = 0, failed = 0 }
local sessionStart = os.clock()
local baseCFrame = nil
local homeCFrame = nil
do
    local c0 = player.Character
    local r0 = c0 and c0:FindFirstChild("HumanoidRootPart")
    if r0 then homeCFrame = r0.CFrame end
end
local connections = {}
local uiAlive = true
local ui = {}
local sg

local function track(conn) table.insert(connections, conn); return conn end

local lastSavedJson = nil
local function saveSettings(force)
    if typeof(writefile) ~= "function" then return false end
    local function f(sets) return { Size = setToList(sets.Size), Rarity = setToList(sets.Rarity), Variant = setToList(sets.Variant) } end
    local centers = {}
    for name, v in pairs(areaCenters) do centers[name] = { v.X, v.Y, v.Z } end
    local data = {
        areas = setToList(config.areas), filters = f(config.filters), placeFilters = f(config.placeFilters),
        sellFilters = f(config.sellFilters), favFilters = f(config.favFilters), favNames = config.favNames,
        petPlaceFilters = f(config.petPlaceFilters), petPlaceNames = config.petPlaceNames,
        petSellFilters = f(config.petSellFilters), petSellNames = config.petSellNames,
        legit = config.legit, instantSteal = config.instantSteal, priority = config.priority, fpsCap = config.fpsCap,
        winW = config.winW, winH = config.winH, method = config.method, targetMode = config.targetMode,
        skipOwn = config.skipOwn, flySpeed2 = config.flySpeed, flyHeight = config.flyHeight,
        fxBorder = config.fxBorder, antiKB = config.antiKB, antiTrap = config.antiTrap,
        antiAfk = config.antiAfk, pingPanel = config.pingPanel, cleanFx = config.removePopups,
        antiLag = config.antiLag, autoInterval = config.autoInterval,
        eggWebhookUrl = config.eggWebhookUrl, statsWebhookUrl = config.statsWebhookUrl,
        statsIntervalMin = config.statsIntervalMin, areaCenters = centers,
        safeSpot = V25.manualSafe and { V25.manualSafe.X, V25.manualSafe.Y, V25.manualSafe.Z } or nil,
    }
    local okEnc, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not okEnc then return false end
    if not force and json == lastSavedJson then return true end
    local okWrite = pcall(writefile, SAVE_FILE, json)
    if okWrite then lastSavedJson = json end
    return okWrite
end

local logLines = {}
local function log(msg)
    msg = os.date("%H:%M:%S") .. "  " .. tostring(msg)
    table.insert(logLines, msg)
    if #logLines > 80 then table.remove(logLines, 1) end
    if ui.logLabel then
        ui.logLabel.Text = table.concat(logLines, "\n")
        task.defer(function() if ui.logScroll then ui.logScroll.CanvasPosition = Vector2.new(0, 1e6) end end)
    end
end
local function setStatus(text, color)
    if ui.statusText then ui.statusText.Text = text end
    if ui.statusDot then ui.statusDot.BackgroundColor3 = color or THEME.sub end
end
local function refreshStats()
    if ui.statsText then ui.statsText.Text = ("Berhasil: %d    Gagal: %d"):format(stats.stolen, stats.failed) end
    if ui.modeText then
        local move = config.method == "Fly" and "Terbang" or "Jalan"
        local target = config.targetMode == "All" and "Semua" or "Filter"
        local areaCount = 0; for _ in pairs(config.areas) do areaCount += 1 end
        ui.modeText.Text = ("Gerak: %s   Target: %s   Area: %s"):format(move, target, areaCount > 0 and (areaCount .. " dipilih") or "semua")
    end
end

local function getChar()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hrp, hum, char
end
local function getHRP() local hrp = getChar(); return hrp end
local function ensureBase()
    if not baseCFrame then local hrp = getHRP(); if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0) end end
end
local function getInstPosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Attachment") then return inst.WorldPosition end
    if inst:IsA("Model") then local ok, cf = pcall(function() return inst:GetPivot() end); if ok then return cf.Position end end
    return nil
end
local function getPromptPosition(prompt)
    local pos = getInstPosition(prompt.Parent); if pos then return pos end
    local model = prompt:FindFirstAncestorOfClass("Model")
    if model then pos = getInstPosition(model); if pos then return pos end end
    local part = prompt.Parent and prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

-- Snapshot: GetDescendants() hanya dipanggil SEKALI (saat pertama dibutuhkan). Setelah itu daftar dijaga lewat
-- DescendantAdded/DescendantRemoving, dan disusun ulang paling cepat tiap 5 detik bila ada perubahan (tanpa panggilan engine berat).
local Snapshot = { t = 0, list = {}, set = nil, pending = {}, dirty = false }
function Snapshot.get()
    if not Snapshot.set then
        local set, list = {}, Workspace:GetDescendants()
        for _, d in ipairs(list) do set[d] = true end
        Snapshot.set, Snapshot.list, Snapshot.t = set, list, os.clock()
        track(Workspace.DescendantAdded:Connect(function(d)
            if not Snapshot.set[d] then Snapshot.set[d] = true; Snapshot.pending[#Snapshot.pending + 1] = d; Snapshot.dirty = true end
        end))
        track(Workspace.DescendantRemoving:Connect(function(d)
            if Snapshot.set[d] then Snapshot.set[d] = nil; Snapshot.dirty = true end
        end))
        return list
    end
    if Snapshot.dirty and os.clock() - Snapshot.t > 5 then
        local set, seen, out = Snapshot.set, {}, {}
        for _, d in ipairs(Snapshot.list) do
            if set[d] and not seen[d] then seen[d] = true; out[#out + 1] = d end
        end
        for _, d in ipairs(Snapshot.pending) do
            if set[d] and not seen[d] then seen[d] = true; out[#out + 1] = d end
        end
        Snapshot.list, Snapshot.pending, Snapshot.t, Snapshot.dirty = out, {}, os.clock(), false
    end
    return Snapshot.list
end

local function promptText(p) return (p.Name .. " " .. (p.ActionText or "") .. " " .. (p.ObjectText or "")):lower() end
local function promptMatches(p, kws)
    local t = promptText(p)
    for _, k in ipairs(kws) do if t:find(k, 1, true) then return true end end
    return false
end
local function triggerPrompt(prompt)
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt); if ok then return true end
    end
    return pcall(function() prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd() end)
end
local function firePromptsNear(pos, radius, kws)
    local count = 0
    for _, p in ipairs(Snapshot.get()) do
        if p:IsA("ProximityPrompt") and p.Parent and p.Enabled then
            local pp = getPromptPosition(p)
            if pp and (pp - pos).Magnitude <= radius and (not kws or promptMatches(p, kws)) then
                if triggerPrompt(p) then count += 1 end
            end
        end
    end
    return count
end

local function guiVisible(obj)
    local cur = obj
    while cur and cur ~= playerGui do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("ScreenGui") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    return true
end
local function buttonLabel(btn)
    local t = ""; if btn:IsA("TextButton") then t = btn.Text end
    if t == "" then
        for _, d in ipairs(btn:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then t = d.Text; break end
        end
    end
    return t
end
local function findButtons(keywords, exact)
    local found = {}
    for _, d in ipairs(playerGui:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and not (sg and d:IsDescendantOf(sg)) and guiVisible(d) then
            local lab = buttonLabel(d):lower(); local nm = d.Name:lower()
            for _, k in ipairs(keywords) do
                if exact then
                    if lab == k or nm == k then table.insert(found, d); break end
                elseif lab:find(k, 1, true) or nm:find(k, 1, true) then
                    table.insert(found, d); break
                end
            end
        end
    end
    return found
end
local function clickButton(btn)
    local label = (buttonLabel(btn) .. " " .. btn.Name):lower()
    if label:find("buy", 1, true) or label:find("purchase", 1, true) or label:find("robux", 1, true) or label:find("r$", 1, true) then return false end
    if typeof(firesignal) == "function" then
        pcall(firesignal, btn.MouseButton1Click); pcall(firesignal, btn.Activated); return true
    elseif typeof(getconnections) == "function" then
        pcall(function() for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end end); return true
    end
    return false
end
local function clickFirstMatching(keys)
    for _, k in ipairs(keys) do
        local btns = findButtons({ k }, false)
        for _, b in ipairs(btns) do if clickButton(b) then return true end end
    end
    return false
end
local function equipTool(kw)
    local hrp, hum, char = getChar()
    if not char or not hum then return nil end
    local function match(t)
        if not t:IsA("Tool") then return false end
        local n = t.Name:lower()
        if kw then return n:find(kw, 1, true) ~= nil end
        return not n:find("egg", 1, true)
    end
    for _, t in ipairs(char:GetChildren()) do if match(t) then return t end end
    for _, t in ipairs(player.Backpack:GetChildren()) do
        if match(t) then pcall(function() hum:EquipTool(t) end); task.wait(0.15); return t end
    end
    return nil
end

local Lock = { queue = {}, held = false }
function Lock.acquire()
    local ticket = {}; table.insert(Lock.queue, ticket)
    while uiAlive and (Lock.held or Lock.queue[1] ~= ticket) do task.wait(0.1) end
    local idx = table.find(Lock.queue, ticket); if idx then table.remove(Lock.queue, idx) end
    Lock.held = true
end
function Lock.release() Lock.held = false end
function Lock.run(fn) Lock.acquire(); local ok, err = pcall(fn); Lock.release(); return ok, err end

local Protect = { lastWalk = 16, flying = false, treadmillActive = false }
local BODY_MOVERS = { BodyVelocity = true, BodyPosition = true, BodyForce = true, BodyThrust = true, BodyAngularVelocity = true, LinearVelocity = true, VectorForce = true, LineForce = true }

function Protect.bindChar(char)
    if Protect.charConn then Protect.charConn:Disconnect() end
    Protect.charConn = track(char.DescendantAdded:Connect(function(d)
        if config.antiKB and not Protect.treadmillActive and BODY_MOVERS[d.ClassName] then
            task.defer(function()
                pcall(function()
                    if d:IsA("Constraint") then d.Enabled = false
                    elseif d:IsA("BodyMover") then d:Destroy() end
                end)
            end)
        end
    end))
end
track(player.CharacterAdded:Connect(Protect.bindChar))
if player.Character then Protect.bindChar(player.Character) end
function Protect.unstick(hrp)
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0); hrp.AssemblyLinearVelocity = Vector3.zero
    local _, hum = getChar()
    if hum then hum.PlatformStand = false; hum.Sit = false; hum.Jump = true end
end

local protectAccum = 0
local function protectStep(dt)
    if not (config.antiKB or config.antiTrap) then return end
    local hrp, hum, char = getChar(); if not hrp or not hum then return end
    if config.antiKB and not Protect.flying and not Protect.treadmillActive then
        local v = hrp.AssemblyLinearVelocity
        local horiz = Vector3.new(v.X, 0, v.Z)
        local allowed = math.max(hum.WalkSpeed, 16) * 1.6 + 10
        if horiz.Magnitude > allowed then
            local lim = horiz.Unit * allowed
            hrp.AssemblyLinearVelocity = Vector3.new(lim.X, math.min(v.Y, 80), lim.Z)
        elseif v.Y > 90 then hrp.AssemblyLinearVelocity = Vector3.new(v.X, 90, v.Z) end
    end
    protectAccum += dt; if protectAccum < 0.5 then return end; protectAccum = 0
    if config.antiKB then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    if config.antiTrap then
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum.Sit then hum.Sit = false end
        if hum.WalkSpeed > 1 then Protect.lastWalk = hum.WalkSpeed else hum.WalkSpeed = Protect.lastWalk end
        for _, d in ipairs(char:GetDescendants()) do
            if not d:IsA("Tool") and not d:IsA("Accessory") and nameHasAny(d.Name, HINTS.trap) then
                pcall(function() d:Destroy() end)
            elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") then
                local other
                if d.Part0 and not d.Part0:IsDescendantOf(char) then other = d.Part0
                elseif d.Part1 and not d.Part1:IsDescendantOf(char) then other = d.Part1 end
                if other and nameHasAny(other:GetFullName(), HINTS.trap) then pcall(function() d:Destroy() end) end
            end
        end
    end
end
-- Heartbeat proteksi hanya tersambung selama Anti Knockback / Anti Trapped ON
function Protect.sync()
    local need = (config.antiKB or config.antiTrap) and true or false
    if need and not Protect.hbConn then
        protectAccum = 0
        Protect.hbConn = track(RunService.Heartbeat:Connect(protectStep))
    elseif not need and Protect.hbConn then
        pcall(function() Protect.hbConn:Disconnect() end)
        Protect.hbConn = nil
    end
end

-- Anti AFK: Humanoid.Jump = true sesekali (tanpa VirtualUser)
local function afkJump()
    if not config.antiAfk or Protect.flying or Protect.treadmillActive then return end
    pcall(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then hum.Jump = true end
    end)
end
-- Idled + timer lompat hanya aktif selama Anti AFK ON
local AFK = { conn = nil, token = 0 }
function AFK.sync()
    if config.antiAfk and not AFK.conn then
        AFK.token += 1
        local my = AFK.token
        AFK.conn = track(player.Idled:Connect(afkJump))
        task.spawn(function()
            local rnd = Random.new()
            while uiAlive and AFK.token == my do
                task.wait(rnd:NextInteger(240, 300))
                if uiAlive and AFK.token == my then afkJump() end
            end
        end)
    elseif not config.antiAfk and AFK.conn then
        AFK.token += 1
        pcall(function() AFK.conn:Disconnect() end)
        AFK.conn = nil
    end
end

local function isEggPrompt(p)
    if not p:IsA("ProximityPrompt") then return false end
    local name = p.Name:lower(); local action = (p.ActionText or ""):lower()
    if name:find("carryareaegg", 1, true) then return true end
    if action:find("carry", 1, true) or action:find("steal", 1, true) then return true end
    if name:find("egg", 1, true) and (action:find("grab", 1, true) or action:find("take", 1, true) or action:find("pick", 1, true)) then return true end
    return false
end
local eggPromptCache = { t = -10, list = {} }
local function collectEggPrompts()
    if os.clock() - eggPromptCache.t < 2 then
        local alive = {}
        for _, p in ipairs(eggPromptCache.list) do if p.Parent then table.insert(alive, p) end end
        return alive
    end
    local result = {}
    local function scan(list)
        for _, d in ipairs(list) do if d:IsA("ProximityPrompt") and isEggPrompt(d) then table.insert(result, d) end end
    end
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if folder then scan(folder:GetDescendants()) end
    if #result == 0 then scan(Snapshot.get()) end
    eggPromptCache.t = os.clock(); eggPromptCache.list = result
    return result
end

local OWNER_ATTRS = { "Owner", "OwnerId", "OwnerUserId", "OwnerName", "UserId", "PlayerName", "Player" }
-- V35: plot sendiri = plot yang papan namanya (PlotSign...PlayerName) berisi nama/display name kita.
-- Nomor plot berubah tiap server, jadi SELALU dibaca dari papan nama, bukan dari nomor.
function V25.myPlot()
    local c = V25.myPlotCache
    if c and os.clock() - c.t < 3 and (not c.plot or c.plot.Parent) then return c.plot end
    local found
    local folder = Workspace:FindFirstChild("Plots")
    if folder then
        local myName, myDisp = player.Name:lower(), player.DisplayName:lower()
        for _, plot in ipairs(folder:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            local lbl = sign and sign:FindFirstChild("PlayerName", true)
            if lbl and lbl:IsA("TextLabel") then
                local t = lbl.Text:lower()
                if t == myDisp or t == myName then found = plot; break end
            end
        end
    end
    V25.myPlotCache = { t = os.clock(), plot = found }
    return found
end
local function ownedByMe(inst)
    local myName = player.Name:lower(); local myDisplay = player.DisplayName:lower(); local myId = tostring(player.UserId)
    local mp = V25.myPlot()
    if mp and (inst == mp or inst:IsDescendantOf(mp)) then return true end
    local cur = inst
    while cur and cur ~= Workspace do
        if cur == player.Character then return true end
        if cur.Name:sub(1, #myId + 1) == myId .. "_" then return true end
        for _, a in ipairs(OWNER_ATTRS) do
            local v = cur:GetAttribute(a)
            if v ~= nil then
                local s = tostring(v):lower()
                if s == myName or s == myId or s == myDisplay then return true end
            end
        end
        local ov = cur:FindFirstChild("Owner")
        if ov then
            if ov:IsA("ObjectValue") and ov.Value == player then return true end
            if ov:IsA("StringValue") and ov.Value:lower() == myName then return true end
            if ov:IsA("IntValue") and tostring(ov.Value) == myId then return true end
        end
        cur = cur.Parent
    end
    return false
end
local function getEggRoot(prompt)
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if folder and prompt:IsDescendantOf(folder) then
        local cur = prompt.Parent
        while cur and cur.Parent ~= folder do cur = cur.Parent end
        if cur and cur ~= folder then return cur end
    end
    -- V35: prompt telur ada di Workspace.SmartPromptPart (bukan di dalam folder slot). Visual telurnya = slot
    -- AreaEggSlotsClient yang posisinya sama dengan prompt (selisih ~0 stud menurut scan).
    if folder then
        V25.eggRootCache = V25.eggRootCache or setmetatable({}, { __mode = "k" })
        V25.slotPosCache = V25.slotPosCache or setmetatable({}, { __mode = "k" })
        local c = V25.eggRootCache[prompt]
        if c and c.root.Parent == folder and os.clock() - c.t < 5 then return c.root end
        local pos = getPromptPosition(prompt)
        if pos then
            local best, bd = nil, 3
            for _, ch in ipairs(folder:GetChildren()) do
                local sc = V25.slotPosCache[ch]
                if not sc or os.clock() - sc.t > 5 then
                    sc = { pos = getInstPosition(ch), t = os.clock() }
                    V25.slotPosCache[ch] = sc
                end
                if sc.pos then
                    local dd = (sc.pos - pos).Magnitude
                    if dd < bd then best, bd = ch, dd end
                end
            end
            if best then V25.eggRootCache[prompt] = { root = best, t = os.clock() }; return best end
        end
    end
    return prompt:FindFirstAncestorOfClass("Model") or prompt.Parent
end
local function collectEggText(root)
    local parts = { root.Name:lower() }
    local function addAttrs(inst) for k, v in pairs(inst:GetAttributes()) do table.insert(parts, tostring(k):lower() .. ":" .. tostring(v):lower()) end end
    addAttrs(root)
    local count = 0
    for _, d in ipairs(root:GetDescendants()) do
        count += 1; if count > 500 then break end
        table.insert(parts, d.Name:lower()); addAttrs(d)
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            table.insert(parts, (d.Text:gsub("<[^>]+>", "")):lower())
        elseif d:IsA("StringValue") then
            table.insert(parts, d.Value:lower())
        elseif d:IsA("ProximityPrompt") then
            table.insert(parts, ((d.ObjectText or "") .. " " .. (d.ActionText or "")):lower())
        end
    end
    local text = table.concat(parts, " ")
    -- versi tanpa spasi/simbol supaya "Spirit Bloom" / "SpiritBloom" / "spirit_bloom" sama-sama cocok
    return text .. " " .. text:gsub("[^%w]", "")
end
local function collectAncestorText(inst)
    local parts = {}; local cur = inst
    while cur and cur ~= Workspace do
        table.insert(parts, cur.Name:lower())
        for k, v in pairs(cur:GetAttributes()) do
            if type(v) == "string" then table.insert(parts, tostring(k):lower() .. ":" .. v:lower()) end
        end
        cur = cur.Parent
    end
    return table.concat(parts, " ")
end
local function detectAreaFromText(normText)
    for _, entry in ipairs(AREA_DETECT) do for _, key in ipairs(entry[2]) do
        if normText:find(key, 1, true) then return entry[1] end
    end end
    return nil
end
local function nearestAreaByCenter(pos)
    local count, best, bestD = 0, nil, math.huge
    for name, c in pairs(areaCenters) do
        count += 1; local d = (c - pos).Magnitude
        if d < bestD then best, bestD = name, d end
    end
    if count >= 2 then return best end
    return nil
end

local VARIANT_KEYS = { "silver", "golden", "rainbow", "bloom", "parasite", "monstrous", "fractured", "scrambled" }
local VARIANT_ALIASES = { ["parasite"] = { "parasite", "monstrous" }, ["spirit bloom"] = { "spirit bloom", "spiritbloom", "spirit_bloom" } }
local function matchesValue(root, text, key)
    key = key:lower()
    if key == "normal" then
        for _, k in ipairs(VARIANT_KEYS) do if text:find(k, 1, true) then return false end end
        return true
    end
    if key == "common" then text = (text:gsub("uncommon", "")) end
    if key == "bloom" then text = (text:gsub("spirit[%s_]*bloom", "")) end
    local aliases = VARIANT_ALIASES[key]
    if aliases then
        for _, a in ipairs(aliases) do if text:find(a, 1, true) then return true end end
        return false
    end
    if text:find(key, 1, true) then return true end
    if root and root:IsA("Model") and (key == "small" or key == "medium" or key == "large" or key == "giant") then
        local ok, _, size = pcall(function() return root:GetBoundingBox() end)
        if ok and size then
            local m = math.max(size.X, size.Y, size.Z)
            if key == "small" then return m <= 3.5 end
            if key == "medium" then return m > 3.5 and m <= 7 end
            if key == "large" then return m > 7 and m <= 15 end
            if key == "giant" then return m > 15 end
        end
    end
    return false
end
local function hasAnyFilter(filters)
    for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do if next(filters[cat]) ~= nil then return true end end
    return false
end
local function passesFilters(root, text, filters)
    for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do
        local set = filters[cat]
        if next(set) ~= nil then
            local ok = false
            for key, on in pairs(set) do
                if on and matchesValue(root, text, key) then ok = true; break end
            end
            if not ok then return false end
        end
    end
    return true
end

local banned = {}
local lastNoTargetLog = 0
local function findTarget(hrp, silent)
    local c = { total = 0, mine = 0, filtered = 0, area = 0, nopos = 0, banned = 0, off = 0 }
    local best
    local filterOn = config.targetMode == "Filter" and hasAnyFilter(config.filters)
    local areaOn = next(config.areas) ~= nil
    local cands = {}
    for _, prompt in ipairs(collectEggPrompts()) do
        c.total += 1
        local pos = getPromptPosition(prompt)
        if not pos then c.nopos += 1
        elseif banned[prompt] and banned[prompt] > os.clock() then c.banned += 1
        else table.insert(cands, { prompt = prompt, pos = pos, d = (pos - hrp.Position).Magnitude }) end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    local examined = 0
    for _, cand in ipairs(cands) do
        if best and best.enabled then break end
        if examined >= 400 then break end
        local prompt, pos = cand.prompt, cand.pos
        if config.skipOwn and ownedByMe(prompt) then c.mine += 1
        else
            examined += 1
            local root = getEggRoot(prompt)
            local text = (filterOn or areaOn) and collectEggText(root) or nil
            local area = nil; local pass = true
            if areaOn then
                area = detectAreaFromText(norm(collectAncestorText(prompt) .. " " .. text)) or nearestAreaByCenter(pos)
                if not area or not config.areas[area] then c.area += 1; pass = false end
            end
            if pass and filterOn and not passesFilters(root, text, config.filters) then
                c.filtered += 1; pass = false
                if not c.sample then c.sample = root.Name .. " :: " .. text:sub(1, 220) end
            end
            if pass then
                local enabled = prompt.Enabled
                if not enabled then c.off += 1 end
                local d = (pos - hrp.Position).Magnitude
                if not best or (enabled and not best.enabled) or (enabled == best.enabled and d < best.dist) then
                    best = { prompt = prompt, pos = pos, dist = d, enabled = enabled, root = root, area = area }
                end
            end
        end
    end
    if best and not best.area then
        best.area = detectAreaFromText(norm(collectAncestorText(best.prompt))) or nearestAreaByCenter(best.pos)
    end
    if not best and not silent and os.clock() - lastNoTargetLog > 3 then
        lastNoTargetLog = os.clock()
        log(("Tidak ada target | prompt %d | milik sendiri %d | filter %d | area %d | tanpa posisi %d | diblok %d")
            :format(c.total, c.mine, c.filtered, c.area, c.nopos, c.banned))
        if c.filtered > 0 and c.sample then
            log("Contoh telur ditolak filter -> " .. c.sample)
            log("Jika rarity/variant tidak muncul di teks itu, filter tidak bisa membacanya. Coba mode 'Semua telur' atau kirim teks ini.")
        end
        if c.total > 0 and c.mine == c.total then
            log("Semua telur dianggap milik sendiri. Matikan 'Lewati telur milik sendiri' di tab Main.")
        end
    end
    return best, c
end

-- ==========================================
-- V33: ZONA AMAN, TITIK BERDIRI AMAN, PENDARATAN
-- ==========================================
local Safe = { cache = nil, key = nil, t = 0 }
Safe.words = { "lava", "kill", "death", "acid", "void", "damage", "hurt", "magma", "poison" }
function Safe.excl()
    local ex = {}
    for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(ex, pl.Character) end end
    return ex
end
function Safe.ray(x, fromY, z, length)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = Safe.excl()
    pcall(function() p.RespectCanCollide = true end)
    return Workspace:Raycast(Vector3.new(x, fromY, z), Vector3.new(0, -(length or 80), 0), p)
end
function Safe.hazard(res)
    if not res then return true end
    if res.Material == Enum.Material.Water then return true end
    local full = res.Instance:GetFullName():lower()
    for _, w in ipairs(Safe.words) do if full:find(w, 1, true) then return true end end
    return false
end
function Safe.clear(pos)
    local op = OverlapParams.new()
    op.FilterType = Enum.RaycastFilterType.Exclude
    op.FilterDescendantsInstances = Safe.excl()
    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 0.5, 0)), Vector3.new(4, 5, 4), op)
    end)
    if not ok then return true end
    for _, p in ipairs(parts) do if p.CanCollide then return false end end
    return true
end
-- ==========================================
-- V34: TITIK AMAN = TENGAH GARIS PERBATASAN SAFE ZONE <-> FOREST (di sisi dalam Safe Zone)
-- ==========================================
Safe.LINE_WORDS = { "line", "border", "boundary", "divider", "garis", "barrier", "edge" }
Safe.INSET = 6
-- kumpulkan semua part/model bernama "safe" yang cukup besar, lengkap dengan sumbu & ukuran horizontalnya
function Safe.zones()
    local out = {}
    for _, d in ipairs(Snapshot.get()) do
        if d.Parent and (d:IsA("BasePart") or d:IsA("Model")) and nameHas(d.Name, "safe")
            and not (player.Character and d:IsDescendantOf(player.Character)) then
            local cf, size
            if d:IsA("BasePart") then cf, size = d.CFrame, d.Size
            else
                local ok, c, sz = pcall(function() return d:GetBoundingBox() end)
                if ok then cf, size = c, sz end
            end
            if cf and size then
                local axes = { cf.RightVector, cf.UpVector, cf.LookVector }
                local sizes = { size.X, size.Y, size.Z }
                local vi = 1
                for i = 2, 3 do if math.abs(axes[i].Y) > math.abs(axes[vi].Y) then vi = i end end
                local hi = {}
                for i = 1, 3 do if i ~= vi then table.insert(hi, i) end end
                local a1 = Vector3.new(axes[hi[1]].X, 0, axes[hi[1]].Z)
                local a2 = Vector3.new(axes[hi[2]].X, 0, axes[hi[2]].Z)
                if a1.Magnitude > 0.1 and a2.Magnitude > 0.1 and sizes[hi[1]] >= 12 and sizes[hi[2]] >= 12 then
                    table.insert(out, {
                        inst = d, center = cf.Position, a1 = a1.Unit, a2 = a2.Unit,
                        e1 = sizes[hi[1]] / 2, e2 = sizes[hi[2]] / 2,
                        area = sizes[hi[1]] * sizes[hi[2]],
                        topY = cf.Position.Y + (sizes[vi] / 2) * math.abs(axes[vi].Y),
                    })
                end
            end
        end
    end
    return out
end
-- cari bagian "garis" (part tipis & panjang) di dekat sisi Safe Zone yang menghadap Forest
function Safe.findLine(edgeMid, tangent)
    local best, bestD
    for _, d in ipairs(Snapshot.get()) do
        if d.Parent and d:IsA("BasePart") and nameHasAny(d.Name, Safe.LINE_WORDS)
            and not (player.Character and d:IsDescendantOf(player.Character)) then
            local sz = d.Size
            local thin, long = math.min(sz.X, sz.Y, sz.Z), math.max(sz.X, sz.Y, sz.Z)
            if thin <= 4 and long >= 14 then
                local dist = (Vector3.new(d.Position.X, 0, d.Position.Z) - Vector3.new(edgeMid.X, 0, edgeMid.Z)).Magnitude
                if dist <= 40 and (not bestD or dist < bestD) then
                    local axes = { d.CFrame.RightVector, d.CFrame.UpVector, d.CFrame.LookVector }
                    local li = (sz.X >= sz.Y and sz.X >= sz.Z) and 1 or ((sz.Y >= sz.Z) and 2 or 3)
                    local ld = Vector3.new(axes[li].X, 0, axes[li].Z)
                    if ld.Magnitude > 0.1 and math.abs(ld.Unit:Dot(tangent)) >= 0.8 then best, bestD = d, dist end
                end
            end
        end
    end
    return best
end
-- hitung titik tengah perbatasan: { stand, inward, tan, topY, desc }
function Safe.border()
    local zones = Safe.zones()
    if #zones == 0 then return nil end
    local forest = areaCenters.Forest
    if not forest then return nil end
    local maxA = 0
    for _, z in ipairs(zones) do if z.area > maxA then maxA = z.area end end
    local best, bestDist
    for _, z in ipairs(zones) do
        if z.area >= maxA * 0.4 then
            local d = forest - z.center
            local c1, c2 = d:Dot(z.a1), d:Dot(z.a2)
            local q1, q2 = math.clamp(c1, -z.e1, z.e1), math.clamp(c2, -z.e2, z.e2)
            local dist = math.sqrt((c1 - q1) ^ 2 + (c2 - q2) ^ 2)
            if not bestDist or dist < bestDist then best, bestDist = z, dist end
        end
    end
    local z = best
    local d = forest - z.center
    local c1, c2 = d:Dot(z.a1), d:Dot(z.a2)
    local dir, tangent, ext
    if math.abs(c1 / z.e1) >= math.abs(c2 / z.e2) then
        dir = z.a1 * (c1 >= 0 and 1 or -1); tangent = z.a2; ext = z.e1
    else
        dir = z.a2 * (c2 >= 0 and 1 or -1); tangent = z.a1; ext = z.e2
    end
    local edgeMid = z.center + dir * ext
    local inward = -dir
    local desc = "tengah sisi Safe Zone '" .. z.inst.Name .. "' yang menghadap Forest"
    local anchorPt = edgeMid
    local line = Safe.findLine(edgeMid, tangent)
    if line then
        anchorPt = Vector3.new(line.Position.X, edgeMid.Y, line.Position.Z)
        desc = "tengah garis '" .. line.Name .. "' (Safe Zone '" .. z.inst.Name .. "' <-> Forest)"
    end
    return { stand = anchorPt + inward * Safe.INSET, inward = inward, tan = tangent, topY = z.topY, desc = desc }
end
-- cari titik berdiri di sekitar titik perbatasan: geser ke dalam Safe Zone & menyamping sampai ketemu tanah bebas bahaya
function V25.safeBorderPos()
    local info = Safe.border()
    if not info then return nil end
    for _, dIn in ipairs({ 0, 3, 6, 10, 16 }) do
        for _, dLat in ipairs({ 0, 4, -4, 8, -8 }) do
            local x = info.stand.X + info.inward.X * dIn + info.tan.X * dLat
            local zc = info.stand.Z + info.inward.Z * dIn + info.tan.Z * dLat
            local res = Safe.ray(x, info.topY + 30, zc, 160)
            if res and res.Normal.Y > 0.7 and not Safe.hazard(res) then
                local pos = res.Position + Vector3.new(0, 3, 0)
                if Safe.clear(pos) then return pos, info end
            end
        end
    end
    return nil
end
-- titik pulang: 1) titik manual (tombol "Set Titik Aman"), 2) tengah perbatasan Safe Zone/Forest, 3) cadangan: sekitar base
function V25.safeBasePos()
    if V25.manualSafe then return V25.manualSafe end
    local key = tostring(baseCFrame and baseCFrame.Position or "nobase")
    if Safe.cache and Safe.key == key and os.clock() - Safe.t < 15 then return Safe.cache end
    local pos
    local okB, p, info = pcall(V25.safeBorderPos)
    if okB and p then
        pos = p
        if info and Safe.lastDesc ~= info.desc then Safe.lastDesc = info.desc; log("Titik aman: " .. info.desc) end
    end
    if not pos then
        if not baseCFrame then return nil end
        local fallback = baseCFrame.Position
        local ok, result = pcall(function()
            local refY = fallback.Y
            for _, r in ipairs({ 0, 5, 10, 16, 24, 34 }) do
                local steps = (r == 0) and 1 or 10
                for i = 0, steps - 1 do
                    local a = (i / steps) * math.pi * 2
                    local x, z = fallback.X + math.cos(a) * r, fallback.Z + math.sin(a) * r
                    local res = Safe.ray(x, refY + 12, z, 60)
                    if res and res.Normal.Y > 0.7 and not Safe.hazard(res) then
                        local cand = res.Position + Vector3.new(0, 3, 0)
                        if Safe.clear(cand) then return cand end
                    end
                end
            end
            return fallback
        end)
        pos = ok and result or fallback
        if Safe.lastDesc ~= "fallback" then
            Safe.lastDesc = "fallback"
            log("Safe Zone tidak terdeteksi, pakai sekitar base. Berdiri di tengah perbatasan lalu tekan 'Set Titik Aman'.")
        end
    end
    Safe.cache, Safe.key, Safe.t = pos, key, os.clock()
    return pos
end
function V25.scanSafe(dbg)
    dbg("== SCAN SAFE ZONE ==")
    local zones = Safe.zones()
    dbg("Zona 'safe' (>=12x12): " .. #zones)
    for i, z in ipairs(zones) do
        if i > 8 then dbg("... dipotong"); break end
        dbg(("  %s | luas %d | %.0fx%.0f | y=%.0f"):format(z.inst:GetFullName(), z.area, z.e1 * 2, z.e2 * 2, z.center.Y))
    end
    local f = areaCenters.Forest
    dbg("Pusat Forest: " .. (f and ("%.0f, %.0f, %.0f"):format(f.X, f.Y, f.Z) or "belum di-set"))
    local info = Safe.border()
    if info then
        dbg("Perbatasan: " .. info.desc)
        dbg(("Titik dasar: %.0f, %.0f, %.0f"):format(info.stand.X, info.stand.Y, info.stand.Z))
    else dbg("Perbatasan tidak ketemu (tidak ada part/model bernama 'safe' atau Forest belum di-set)") end
    local p = V25.safeBasePos()
    dbg("Titik pulang final: " .. (p and ("%.0f, %.0f, %.0f"):format(p.X, p.Y, p.Z) or "nil") .. (V25.manualSafe and " [manual]" or " [otomatis]"))
end
-- titik tertinggi sepanjang jalur terbang (supaya tidak menembus gunung/atap)
function V25.pathTop(a, b)
    local top = math.max(a.Y, b.Y)
    local dist = (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
    local n = math.clamp(math.ceil(dist / 12), 1, 60)
    local startY = math.max(a.Y, b.Y) + 120
    for i = 0, n do
        local t = i / n
        local x, z = a.X + (b.X - a.X) * t, a.Z + (b.Z - a.Z) * t
        local res = Safe.ray(x, startY, z, 900)
        if res and res.Position.Y > top and res.Position.Y < startY - 5 then top = res.Position.Y end
    end
    return top
end
-- mendarat pelan ke tanah (tidak dibiarkan jatuh dari ketinggian / ke void)
function V25.softLand(hrp)
    if not hrp or not hrp.Parent then return end
    Protect.flying = true
    pcall(function()
        local _, hum = getChar()
        if hum then hum.PlatformStand = false; hum.Sit = false end
        local res = Safe.ray(hrp.Position.X, hrp.Position.Y, hrp.Position.Z, 600)
        if not res or Safe.hazard(res) or res.Position.Y < Workspace.FallenPartsDestroyHeight + 20 then
            local safe = V25.safeBasePos()
            if safe then V25.safeTeleport(CFrame.new(safe) * (hrp.CFrame - hrp.CFrame.Position)) end
            return
        end
        local goalY = res.Position.Y + 3
        local guard = 0
        while hrp.Parent and hrp.Position.Y - goalY > 1.5 and guard < 400 do
            guard += 1
            local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
            local step = math.min(hrp.Position.Y - goalY, 45 * dt)
            local cf = hrp.CFrame
            hrp.CFrame = cf - Vector3.new(0, step, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
        end
        hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    Protect.flying = false
end

local function flyToInner(hrp, targetPos, speed, alive, through, follow)
    targetPos = Vector3.new(targetPos.X, math.max(targetPos.Y, Workspace.FallenPartsDestroyHeight + 40), targetPos.Z)
    local lastPos, lastT, stalls = hrp.Position, os.clock(), 0
    local accel = math.max(speed * 4, 80)
    local cur = V25.flyCarry or 0
    local stopDist = through or 1.5
    local followY, nextProbe = nil, 0
    while alive() do
        if not hrp.Parent then V25.flyCarry = 0; return false end
        do local _, hmChk = getChar(); if hmChk and hmChk.Health <= 0 then V25.flyCarry = 0; return false end end
        local delta = targetPos - hrp.Position
        local dist = delta.Magnitude
        if dist < stopDist then break end
        local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
        local want = through and speed or math.min(speed, math.sqrt(2 * accel * dist) + 2)
        if cur < want then cur = math.min(want, cur + accel * dt)
        else cur = math.max(want, cur - accel * 2 * dt) end
        cur = math.max(cur, 12)
        local dir = delta.Unit
        if follow and os.clock() >= nextProbe then
            nextProbe = os.clock() + 0.1
            local p = hrp.Position
            local fd = Vector3.new(dir.X, 0, dir.Z)
            fd = fd.Magnitude > 0.05 and fd.Unit or Vector3.zero
            local best
            for _, off in ipairs({ 0, 25, 60 }) do
                local q = p + fd * off
                local res = Safe.ray(q.X, p.Y + 150, q.Z, 700)
                if res and (not best or res.Position.Y > best) then best = res.Position.Y end
            end
            followY = best and (best + follow) or nil
        end
        local step = math.min(dist, cur * dt)
        local newPos = hrp.Position + dir * step
        if followY and newPos.Y < followY then
            newPos = newPos + Vector3.new(0, math.min(followY - newPos.Y, 90 * dt), 0)
        end
        local cf = hrp.CFrame
        local rot = cf - cf.Position
        local flat = Vector3.new(dir.X, 0, dir.Z)
        if flat.Magnitude > 0.05 then
            local face = CFrame.lookAt(Vector3.zero, flat)
            rot = rot:Lerp(face, math.min(1, dt * 10))
        end
        hrp.CFrame = CFrame.new(newPos) * rot
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if os.clock() - lastT > 1.2 then
            if (hrp.Position - lastPos).Magnitude < 1 then
                stalls += 1; Protect.unstick(hrp)
                if stalls >= 3 then V25.flyCarry = 0; return false end
            else stalls = 0 end
            lastPos, lastT = hrp.Position, os.clock()
        end
    end
    V25.flyCarry = through and cur or 0
    return true
end
local function flyTo(hrp, targetPos, speed, alive, through, follow)
    Protect.flying = true
    local ok = flyToInner(hrp, targetPos, speed, alive, through, follow)
    Protect.flying = false
    return ok
end
function V25.flyRoute(hrp, targetPos, alive)
    local speed = config.flySpeed
    V25.flyCarry = 0
    if (hrp.Position - targetPos).Magnitude < 15 then return flyTo(hrp, targetPos, speed, alive) end
    if (hrp.Position - targetPos).Magnitude > 150 then task.spawn(function() V25.streamTo(targetPos, 3) end) end
    local cruiseY = math.max(hrp.Position.Y, targetPos.Y) + config.flyHeight
    local okTop, top = pcall(V25.pathTop, hrp.Position, targetPos)
    if okTop and top then cruiseY = math.max(cruiseY, top + 8) end
    cruiseY = math.min(cruiseY, math.max(hrp.Position.Y, targetPos.Y) + 200)
    if not flyTo(hrp, Vector3.new(hrp.Position.X, cruiseY, hrp.Position.Z), speed, alive, 2.5) then return false end
    if not flyTo(hrp, Vector3.new(targetPos.X, cruiseY, targetPos.Z), speed, alive, 12, config.flyHeight + 6) then return false end
    return flyTo(hrp, targetPos, speed, alive)
end
local function goTo(hrp, targetPos, alive)
    if config.method ~= "Fly" then return V25.legitWalk(targetPos, alive) end
    local ok = V25.flyRoute(hrp, targetPos, alive)
    -- apa pun hasilnya (selesai / gagal / dihentikan), jangan biarkan karakter menggantung lalu jatuh
    local h = getHRP()
    if h then V25.softLand(h) end
    return ok
end

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
local function validWebhook(url)
    if type(url) ~= "string" then return false end
    return url:match("^https://[%w%.]*discord%.com/api/webhooks/") ~= nil
        or url:match("^https://[%w%.]*discordapp%.com/api/webhooks/") ~= nil
end
local function postWebhook(url, payload)
    if not validWebhook(url) then return false, "URL webhook tidak valid" end
    if not httpRequest then return false, "executor tidak punya request" end
    local ok, res = pcall(httpRequest, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) })
    if not ok then return false, tostring(res) end
    local code = res and (res.StatusCode or res.status_code)
    if code and code >= 200 and code < 300 then return true end
    return false, "HTTP " .. tostring(code)
end
local webhookQueue = {}; local webhookWorker = false
local function queueWebhook(url, payload)
    table.insert(webhookQueue, { url = url, payload = payload })
    if webhookWorker then return end
    webhookWorker = true
    task.spawn(function()
        while #webhookQueue > 0 and uiAlive do
            local item = table.remove(webhookQueue, 1)
            local ok, err = postWebhook(item.url, item.payload)
            if not ok then log("Webhook gagal: " .. tostring(err)) end
            task.wait(1.3)
        end
        webhookWorker = false
    end)
end
local function cut(s, n) s = tostring(s); if #s > n then return s:sub(1, n - 3) .. "..." end; return s end
local WEBHOOK_NAME = "Vura"
local WEBHOOK_COLOR = 0xC084FC -- ungu terang
local function embedPayload(title, color, fields)
    return { username = WEBHOOK_NAME, embeds = { { title = title, color = color or WEBHOOK_COLOR, fields = fields, footer = { text = "Vura | Premium" }, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") } } }
end
-- Opsional: kalau gambar telur tidak terbaca otomatis, isi manual: ["Nama Telur"] = "https://link-gambar.png"
local EGG_IMAGE_URLS = {}
local imageUrlCache = {}
local function assetIdOf(v)
    if type(v) ~= "string" then return nil end
    return v:match("rbxassetid://(%d+)") or v:match("[?&]id=(%d+)")
end
local function findEggImageId(root)
    if not root then return nil end
    for _, a in ipairs({ "Image", "Icon", "Thumbnail", "ImageId", "Texture" }) do
        local id = assetIdOf(root:GetAttribute(a)); if id then return id end
    end
    local fallback, n = nil, 0
    for _, d in ipairs(root:GetDescendants()) do
        n += 1; if n > 500 then break end
        local id
        if d:IsA("ImageLabel") or d:IsA("ImageButton") then id = assetIdOf(d.Image)
        elseif d:IsA("Decal") or d:IsA("Texture") then id = assetIdOf(d.Texture) end
        if id then return id end
        if not fallback then
            if d:IsA("MeshPart") then fallback = assetIdOf(d.TextureID)
            elseif d:IsA("SpecialMesh") then fallback = assetIdOf(d.TextureId) end
        end
    end
    return fallback
end
local function stringAttr(root, keys)
    for _, k in ipairs(keys) do
        local v = root:GetAttribute(k)
        if type(v) == "string" and v ~= "" then return v end
    end
    return nil
end
-- dipanggil SEBELUM telur diambil (setelah diambil, isi model bisa hilang)
local function describeEgg(root)
    if not root then return { name = "Telur", rarity = "-", variant = "Normal", size = "-", detail = "" } end
    local okText, text = pcall(collectEggText, root)
    if not okText or type(text) ~= "string" then text = root.Name:lower() end
    local function hitsOf2(cat)
        local out = {}
        for _, entry in ipairs(FILTERS) do
            if entry[1] == cat then
                for _, o in ipairs(entry[2]) do
                    local ok, hit = pcall(matchesValue, root, text, o)
                    if ok and hit then table.insert(out, o) end
                end
            end
        end
        return out
    end
    local rarity = stringAttr(root, { "Rarity", "EggRarity", "Tier" })
    local variant = stringAttr(root, { "Variant", "Mutation", "EggVariant" })
    local size = stringAttr(root, { "Size", "EggSize" })
    if not rarity then local h = hitsOf2("Rarity"); rarity = #h > 0 and table.concat(h, "/") or "-" end
    if not variant then local h = hitsOf2("Variant"); variant = #h > 0 and table.concat(h, "/") or "Normal" end
    if not size then local h = hitsOf2("Size"); size = h[1] or "-" end
    local parts = {}
    for k, v in pairs(root:GetAttributes()) do table.insert(parts, tostring(k) .. ": " .. tostring(v)) end
    table.sort(parts); while #parts > 8 do table.remove(parts) end
    return {
        name = stringAttr(root, { "EggName", "DisplayName", "Name", "EggType", "Type" }) or root.Name,
        rarity = rarity, variant = variant, size = size,
        imageId = findEggImageId(root),
        detail = table.concat(parts, "\n"),
    }
end
local function resolveEggImage(info)
    if EGG_IMAGE_URLS[info.name] then return EGG_IMAGE_URLS[info.name] end
    local id = info.imageId
    if not id then return nil end
    if imageUrlCache[id] then return imageUrlCache[id] end
    if not httpRequest then return nil end
    local ok, res = pcall(httpRequest, {
        Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. id .. "&size=420x420&format=Png&isCircular=false",
        Method = "GET",
    })
    if not ok or not res then return nil end
    local code = res.StatusCode or res.status_code
    if code ~= 200 or not res.Body then return nil end
    local okJ, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    local row = okJ and data and data.data and data.data[1]
    if row and row.state == "Completed" and row.imageUrl then
        imageUrlCache[id] = row.imageUrl
        return row.imageUrl
    end
    return nil
end
local function sendEggWebhook(info)
    if not config.eggWebhookOn then return end
    local total = ("%d berhasil / %d gagal"):format(stats.stolen, stats.failed)
    task.spawn(function()
        local okImg, img = pcall(resolveEggImage, info)
        local payload = embedPayload("🥚 Telur didapat", WEBHOOK_COLOR, {
            { name = "Nama Telur", value = cut(info.name, 200), inline = false },
            { name = "Rarity", value = cut(info.rarity or "-", 100), inline = true },
            { name = "Variant", value = cut(info.variant or "Normal", 100), inline = true },
            { name = "Size", value = cut(info.size or "-", 100), inline = true },
            { name = "Area", value = info.area or "-", inline = true },
            { name = "Pemain", value = player.DisplayName, inline = true },
            { name = "Total sesi", value = total, inline = true },
        })
        if okImg and img then payload.embeds[1].image = { url = img } end
        queueWebhook(config.eggWebhookUrl, payload)
    end)
end
local function findStatValue(names, textMustHave)
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local n = v.Name:lower()
            for _, nm in ipairs(names) do
                if n:find(nm, 1, true) and v:IsA("ValueBase") then return v.Value, "leaderstats." .. v.Name end
            end
        end
    end
    for k, v in pairs(player:GetAttributes()) do
        local n = tostring(k):lower()
        for _, nm in ipairs(names) do if n:find(nm, 1, true) then return v, "attribute " .. tostring(k) end end
    end
    for _, d in ipairs(playerGui:GetDescendants()) do
        if d:IsA("TextLabel") and not (sg and d:IsDescendantOf(sg)) and d.Text ~= "" then
            local n = d.Name:lower()
            for _, nm in ipairs(names) do
                if n:find(nm, 1, true) and (not textMustHave or d.Text:find(textMustHave, 1, true)) then return d.Text, "HUD " .. d.Name end
            end
        end
    end
    return nil, nil
end
local function readStats()
    local speed, speedSrc = findStatValue({ "speed" }, nil)
    if speed == nil then
        local _, hum = getChar()
        if hum then speed, speedSrc = hum.WalkSpeed, "WalkSpeed" end
    end
    local money, moneySrc = findStatValue({ "cash", "money", "coin" }, "$")
    if money == nil then money, moneySrc = findStatValue({ "cash", "money", "coin" }, nil) end
    local function fmt(v)
        if v == nil then return "tidak terbaca" end
        if type(v) == "number" then return abbr(v) end
        return tostring(v)
    end
    return { speed = fmt(speed), speedSrc = speedSrc or "-", money = fmt(money), moneySrc = moneySrc or "-" }
end
local function currentPing()
    local ping = 0
    pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    return ping
end
local function sendStatsWebhook(force)
    if not force and not config.statsWebhookOn then return end
    local s = readStats()
    local up = math.floor((os.clock() - sessionStart) / 60)
    queueWebhook(config.statsWebhookUrl, embedPayload("📊 Laporan AFK", WEBHOOK_COLOR, {
        { name = "Speed", value = s.speed, inline = true },
        { name = "Uang", value = s.money, inline = true },
        { name = "Ping", value = currentPing() .. " ms", inline = true },
        { name = "Telur", value = ("%d berhasil / %d gagal"):format(stats.stolen, stats.failed), inline = true },
        { name = "Durasi sesi", value = up .. " menit", inline = true },
        { name = "Pemain", value = player.DisplayName, inline = true },
    }))
end
local statsToken = 0
local function startStatsLoop()
    statsToken += 1
    local my = statsToken
    task.spawn(function()
        local last = os.clock()
        while uiAlive and config.statsWebhookOn and statsToken == my do
            task.wait(1)
            if os.clock() - last >= config.statsIntervalMin * 60 then last = os.clock(); sendStatsWebhook(false) end
        end
    end)
end

local brainWanted
local Treadmill = { inst = nil, notified = false, how = nil, info = {} }
function Treadmill.reset() Treadmill.inst = nil; Treadmill.how = nil; Treadmill.info = {} end
local function treadmillSpot(inst)
    if inst:IsA("BasePart") then return inst.Position + Vector3.new(0, inst.Size.Y / 2 + 3, 0) end
    local ok, cf, size = pcall(function() return inst:GetBoundingBox() end)
    if ok then return cf.Position + Vector3.new(0, size.Y / 2 + 3, 0) end
    local p = getInstPosition(inst)
    return p and (p + Vector3.new(0, 4, 0)) or nil
end
local function isTreadmillTop(d)
    if not (d:IsA("Model") or d:IsA("BasePart")) then return false end
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if plotsFolder then
        -- struktur game: Workspace.Plots.<n>.TreadmillBottom (TreadmillUpgrade & __ClientTreadmillRenders bukan treadmill)
        return d.Name == "TreadmillBottom" and d.Parent ~= nil and d.Parent.Parent == plotsFolder
    end
    if not nameHasAny(d.Name, HINTS.treadmill) then return false end
    local par = d.Parent
    if par and par:IsA("Model") and nameHasAny(par.Name, HINTS.treadmill) then return false end
    return true
end
-- naik ke atas sampai batas "plot" yang hanya berisi 1 treadmill (ini plot pemilik treadmill)
local function treadmillPlotRoot(inst)
    local root, cur = inst, inst.Parent
    while cur and cur ~= Workspace do
        local n = 0
        for _, d in ipairs(cur:GetDescendants()) do
            if isTreadmillTop(d) then n += 1; if n > 1 then break end end
        end
        if n > 1 then break end
        root = cur; cur = cur.Parent
    end
    return root
end
-- hasil: "me" (milikku), "other" (milik pemain lain), nil (tidak diketahui)
local function treadmillOwnerInfo(inst)
    local cached = Treadmill.info[inst]
    if cached and os.clock() - cached.t < 30 then return cached.v end
    local verdict
    if ownedByMe(inst) then verdict = "me"
    else
        local root = treadmillPlotRoot(inst)
        if ownedByMe(root) then verdict = "me"
        else
            local myName, myDisp = player.Name:lower(), player.DisplayName:lower()
            local others = {}
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= player then
                    table.insert(others, pl.Name:lower())
                    if #pl.DisplayName >= 3 then table.insert(others, pl.DisplayName:lower()) end
                end
            end
            local mine, other = false, false
            local function check(text)
                text = tostring(text):lower()
                if text == "" then return end
                if text:find(myName, 1, true) or (#myDisp >= 3 and text:find(myDisp, 1, true)) then mine = true end
                for _, o in ipairs(others) do if text:find(o, 1, true) then other = true; break end end
            end
            check(root.Name)
            for k, v in pairs(root:GetAttributes()) do if type(v) == "string" then check(v) end end
            local count = 0
            for _, d in ipairs(root:GetDescendants()) do
                count += 1; if count > 600 then break end
                if d:IsA("TextLabel") then check(d.Text)
                elseif d:IsA("StringValue") then check(d.Value)
                elseif d:IsA("ObjectValue") then
                    if d.Value == player then mine = true
                    elseif d.Value and d.Value:IsA("Player") then other = true end
                end
            end
            if mine and not other then verdict = "me"
            elseif other and not mine then verdict = "other" end
        end
    end
    Treadmill.info[inst] = { v = verdict, t = os.clock() }
    return verdict
end
Treadmill.banned = {}
function Treadmill.othersNear(pos, radius)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and pl.Character then
            local r = pl.Character:FindFirstChild("HumanoidRootPart")
            if r and (r.Position - pos).Magnitude <= radius then return true end
        end
    end
    return false
end
local function findTreadmill()
    -- pilihan manual (tombol "Set Treadmill") selalu menang
    local man = Treadmill.manual
    if man and man.Parent and man:IsDescendantOf(Workspace) then Treadmill.inst = man; return man end
    local mp = V25.myPlot()
    local mine = mp and mp:FindFirstChild("TreadmillBottom")
    if mine and mine.Parent and not Treadmill.banned[mine] then
        if Treadmill.inst ~= mine then
            Treadmill.inst = mine; Treadmill.notified = false
            log("Treadmill dipilih: " .. mine:GetFullName() .. " [papan nama plot: " .. player.DisplayName .. "]")
        end
        Treadmill.how = "papan nama plot"
        return mine
    end
    if Workspace:FindFirstChild("Plots") then
        -- struktur Plots dikenal: jangan menebak treadmill lain (plot kosong/orang lain). Tunggu papan nama atau pakai "Set Treadmill".
        local why = mp and "plot-treadmill-di-ban" or "plot-belum-ketemu"
        if Treadmill.how ~= why then
            log(mp and "Treadmill plotmu sedang dilewati sementara (gagal dijangkau)" or "Plot sendiri belum terbaca dari papan nama. Tunggu sebentar atau pakai tombol Set Treadmill")
            Treadmill.how = why
        end
        Treadmill.inst = nil
        return nil
    end
    if Treadmill.inst and Treadmill.inst.Parent and Treadmill.inst:IsDescendantOf(Workspace) and not Treadmill.banned[Treadmill.inst] then
        return Treadmill.inst
    end
    Treadmill.inst = nil
    local hrp = getHRP()
    local ref = (baseCFrame and baseCFrame.Position) or (homeCFrame and homeCFrame.Position) or (hrp and hrp.Position)
    local all = {}
    for _, d in ipairs(Snapshot.get()) do
        if d.Parent and isTreadmillTop(d) and not Treadmill.banned[d] then
            local pos = getInstPosition(d)
            if pos then table.insert(all, { inst = d, pos = pos, dist = ref and (pos - ref).Magnitude or 0 }) end
        end
    end
    table.sort(all, function(x, y) return x.dist < y.dist end)
    local pick, how
    -- 1) ada penanda pemilik yang jelas = milikku
    for _, e in ipairs(all) do
        e.who = treadmillOwnerInfo(e.inst)
        if e.who == "me" then pick, how = e, "milik sendiri (terdeteksi)"; break end
    end
    -- 2) tidak ada penanda: HANYA treadmill paling dekat dari base, jaraknya dekat, bukan milik orang lain,
    --    dan tidak ada pemain lain berdiri di sekitarnya. Selain itu -> tidak ditebak (hindari naik treadmill orang).
    if not pick and all[1] then
        local n = all[1]
        n.who = n.who or treadmillOwnerInfo(n.inst)
        if n.who ~= "other" and n.dist <= 60 and not Treadmill.othersNear(n.pos, 18) then
            pick, how = n, "terdekat dari base"
        end
    end
    if pick then
        Treadmill.inst = pick.inst
        if Treadmill.how ~= how then log("Treadmill dipilih: " .. pick.inst:GetFullName() .. " [" .. how .. "]") end
        Treadmill.how = how
        Treadmill.notified = false
        return pick.inst
    end
    return nil
end
-- tombol "Set Treadmill": berdiri di atas treadmill-mu lalu tekan -> script mengunci treadmill itu
function Treadmill.setFromPlayer()
    local hrp = getHRP()
    if not hrp then return false, "Karakter belum ada" end
    local found
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = Safe.excl()
    local res = Workspace:Raycast(hrp.Position, Vector3.new(0, -14, 0), rp)
    if res then
        local cur = res.Instance
        while cur and cur ~= Workspace do
            if isTreadmillTop(cur) then found = cur; break end
            cur = cur.Parent
        end
    end
    if not found then
        local bestD = 14
        for _, d in ipairs(Snapshot.get()) do
            if d.Parent and isTreadmillTop(d) then
                local pos = getInstPosition(d)
                if pos then
                    local dd = (pos - hrp.Position).Magnitude
                    if dd < bestD then found, bestD = d, dd end
                end
            end
        end
    end
    if not found then return false, "Tidak ada treadmill di bawah/dekat karaktermu (radius 14 stud)" end
    Treadmill.manual = found
    Treadmill.inst = found
    Treadmill.how = "manual"
    Treadmill.info = {}
    Treadmill.banned = {}
    Treadmill.notified = false
    return true, found:GetFullName()
end
function Treadmill.clearManual()
    Treadmill.manual = nil; Treadmill.banned = {}; Treadmill.reset()
end
-- V33: cari "sabuk" treadmill (part datar terbesar), titik berdiri di permukaannya, dan cek apakah sedang berdiri di atasnya
function Treadmill.belt(inst)
    if inst:IsA("BasePart") then return inst end
    local best, bestScore = nil, -1
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide and d.Size.Y <= math.max(d.Size.X, d.Size.Z) then
            local n = d.Name:lower()
            local bonus = (n:find("belt", 1, true) or n:find("tread", 1, true) or n:find("track", 1, true)
                or n:find("run", 1, true) or n:find("floor", 1, true)) and 4 or 1
            local score = d.Size.X * d.Size.Z * bonus
            if score > bestScore then best, bestScore = d, score end
        end
    end
    if best then return best end
    for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then return d end end
    return nil
end
function Treadmill.surface(inst, belt)
    local origin = belt.Position
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Include
    p.FilterDescendantsInstances = { inst }
    local res = Workspace:Raycast(origin + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), p)
    if res then return res.Position end
    return origin + Vector3.new(0, belt.Size.Y / 2, 0)
end
function Treadmill.on(inst, hrp)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Include
    p.FilterDescendantsInstances = { inst }
    return Workspace:Raycast(hrp.Position, Vector3.new(0, -9, 0), p) ~= nil
end
function Treadmill.flat(v) return Vector3.new(v.X, 0, v.Z) end
-- naik ke treadmill: jalan/terbang -> jalan halus ke titik -> (bila perlu & bukan Legit) teleport
function Treadmill.approach(inst, belt)
    local surface = Treadmill.surface(inst, belt)
    local stand = surface + Vector3.new(0, 3, 0)
    for attempt = 1, 3 do
        if not brainWanted() then return false end
        local h, hm = getChar(); if not h or not hm or hm.Health <= 0 then return false end
        if Treadmill.on(inst, h) then return true end
        setStatus("Menuju treadmill (" .. attempt .. "/3)...", THEME.accent2)
        goTo(h, config.method == "Fly" and stand or surface, brainWanted)
        task.wait(0.2)
        h, hm = getChar(); if not h or not hm then return false end
        local t0 = os.clock()
        while brainWanted() and os.clock() - t0 < 4 and not Treadmill.on(inst, h) and (Treadmill.flat(h.Position) - Treadmill.flat(surface)).Magnitude > 2 do
            hm:MoveTo(Vector3.new(surface.X, h.Position.Y, surface.Z))
            if h.Position.Y < surface.Y - 1 then hm.Jump = true end
            task.wait(0.15)
        end
        task.wait(0.3)
        h = getHRP(); if not h then return false end
        if Treadmill.on(inst, h) then return true end
    end
    if not config.legit then
        local h = getHRP()
        if h then
            log("Treadmill: jalan kaki gagal, pindah langsung ke treadmill")
            h.AssemblyLinearVelocity = Vector3.zero
            h.CFrame = CFrame.new(stand) * (h.CFrame - h.CFrame.Position)
            task.wait(0.5)
            return Treadmill.on(inst, h)
        end
    end
    return false
end
function Treadmill.run(duration)
    local hrp, hum = getChar()
    if not hrp or not hum then task.wait(1); return end
    local inst = findTreadmill()
    if not inst then
        if not Treadmill.notified then Treadmill.notified = true; log("Treadmill milikmu tidak terdeteksi dengan yakin. Berdiri DI ATAS treadmill-mu lalu tekan 'Set Treadmill' (tab Main).") end
        setStatus("Idle (treadmill tidak ada)", THEME.warn)
        task.wait(duration); return
    end
    local belt = Treadmill.belt(inst)
    if not belt then task.wait(duration); return end
    -- pengaman: kalau bukan pilihan manual / bukan terdeteksi milik sendiri dan ada pemain lain di dekatnya -> batalkan
    if not Treadmill.manual and Treadmill.how ~= "milik sendiri (terdeteksi)" and Treadmill.othersNear(belt.Position, 14) then
        Treadmill.banned[inst] = true; Treadmill.reset()
        log("Treadmill dibatalkan: ada pemain lain di dekatnya (kemungkinan milik orang). Pakai tombol 'Set Treadmill' bila ini memang milikmu.")
        task.wait(duration); return
    end
    setStatus("Treadmill (idle)", THEME.good)
    Protect.treadmillActive = true
    if not Treadmill.on(inst, hrp) then
        if not Treadmill.approach(inst, belt) then
            Protect.treadmillActive = false
            Treadmill.fails = (Treadmill.fails or 0) + 1
            if Treadmill.fails >= 3 then Treadmill.reset(); Treadmill.fails = 0; log("Treadmill gagal dijangkau, mencari ulang") end
            task.wait(1.5); return
        end
        Treadmill.fails = 0
        task.wait(0.2)
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled and promptMatches(d, { "treadmill", "run", "start" }) then triggerPrompt(d) end
        end
    end
    -- sumbu sabuk (sisi terpanjang) untuk lari bolak-balik di atas sabuk
    local axis = (belt.Size.X >= belt.Size.Z) and belt.CFrame.RightVector or belt.CFrame.LookVector
    axis = Treadmill.flat(axis); if axis.Magnitude < 0.1 then axis = Vector3.new(0, 0, -1) end; axis = axis.Unit
    local halfLen = math.max(belt.Size.X, belt.Size.Z) / 2
    local sign = 1
    local t0 = os.clock()
    -- V38: perilaku tidak robotik: jeda acak, kadang diam ("mikir"), kadang lompat (~8 dtk acak)
    local nextJump = os.clock() + 6 + math.random() * 4
    local graceUntil = 0 -- selama lompat, jangan anggap "jatuh dari treadmill"
    while os.clock() - t0 < duration and brainWanted() do
        local h, hm = getChar()
        if not h or not hm or hm.Health <= 0 then break end
        if not Treadmill.on(inst, h) and os.clock() > graceUntil then break end -- jatuh dari treadmill -> iterasi berikutnya naik lagi
        if math.random() < 0.08 then
            -- 8% kemungkinan diam sebentar (mimic "mikir")
            hm:Move(Vector3.zero, false)
            task.wait(0.3 + math.random() * 0.6)
        else
            local dir
            local bv = Treadmill.flat(belt.AssemblyLinearVelocity)
            if bv.Magnitude > 0.5 then
                dir = -bv.Unit -- sabuk berjalan: lari melawan arah sabuk (diam di tempat)
            else
                local off = (h.Position - belt.Position):Dot(axis)
                if sign > 0 and off > halfLen - 3 then sign = -1
                elseif sign < 0 and off < -(halfLen - 3) then sign = 1 end
                dir = axis * sign
            end
            hm:Move(dir, false)
            if os.clock() >= nextJump then
                hm.Jump = true
                graceUntil = os.clock() + 1.5
                nextJump = os.clock() + 6 + math.random() * 4
            end
            task.wait(0.08 + math.random() * 0.15)
        end
    end
    Protect.treadmillActive = false
    if not (brainWanted() and config.treadmillIdle) then
        local _, hm2 = getChar()
        if hm2 then hm2:Move(Vector3.zero, false) end
    end
end

local popupConns = {}
local setPopupCleaner
do
    local FX_CLASSES = { ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true }
    local queue, head = {}, 1
    local loopOn = false
    local function textLooksLikeGain(t)
        t = t:gsub("<[^>]+>", "")
        if t:match("^%s*%+%s*[%d%.,]+%s*%a*") then return true end
        return t:find("+", 1, true) ~= nil and t:lower():find("speed", 1, true) ~= nil
    end
    local function checkPopup(inst)
        if not inst.Parent or (sg and inst:IsDescendantOf(sg)) then return end
        local target
        if inst:IsA("TextLabel") then if textLooksLikeGain(inst.Text) then target = inst end
        elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") and textLooksLikeGain(d.Text) then target = inst; break end
            end
        end
        if target then pcall(function() target:Destroy() end) end
    end
    local function killFx(inst) pcall(function() inst.Enabled = false end) end
    local function onAdded(inst)
        if FX_CLASSES[inst.ClassName] then killFx(inst)
        elseif inst:IsA("TextLabel") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            if #queue - head < 2000 then queue[#queue + 1] = { inst, os.clock() + 0.08 } end
        end
    end
    local function startLoop()
        if loopOn then return end
        loopOn = true
        task.spawn(function()
            while loopOn and uiAlive do
                task.wait(0.15)
                local now, processed = os.clock(), 0
                while head <= #queue and processed < 80 do
                    local e = queue[head]
                    if e[2] > now then break end
                    queue[head] = false; head += 1; processed += 1
                    if e[1].Parent then checkPopup(e[1]) end
                end
                if head > #queue then table.clear(queue); head = 1 end
            end
            loopOn = false
        end)
    end
    setPopupCleaner = function(state)
        config.removePopups = state
        for _, c in ipairs(popupConns) do c:Disconnect() end
        table.clear(popupConns)
        if not state then loopOn = false; table.clear(queue); head = 1; return end
        table.insert(popupConns, Workspace.DescendantAdded:Connect(onAdded))
        table.insert(popupConns, playerGui.DescendantAdded:Connect(onAdded))
        startLoop()
    end
end

local function isCarrying()
    local function hasCarryAttr(inst)
        for name, value in pairs(inst:GetAttributes()) do
            if tostring(name):lower():find("carry", 1, true) and value then return true end
        end
        return false
    end
    if hasCarryAttr(player) then return true end
    local char = player.Character
    if not char then return false end
    if hasCarryAttr(char) then return true end
    for _, d in ipairs(char:GetDescendants()) do
        if d.Name:lower():find("egg", 1, true) then return true end
    end
    return false
end

do
    local PathfindingService = game:GetService("PathfindingService")
    local function flatDist(a, b) return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude end
    function V25.legitWalk(dest, alive)
        local hrp, hum = getChar()
        if not hrp or not hum then return false end
        if flatDist(hrp.Position, dest) <= 8 then return true end
        local speed = math.max(hum.WalkSpeed, 8)
        local limit = math.max(12, flatDist(hrp.Position, dest) / speed * 2 + 10)
        local t0 = os.clock()
        setStatus("Berjalan...", THEME.accent2)
        local function nudgeIfStuck(state)
            local now = os.clock()
            if now - state.t >= 1 then
                if (hrp.Position - state.p).Magnitude < 0.6 then hum.Jump = true end
                state.t, state.p = now, hrp.Position
            end
        end
        local stuck = { t = os.clock(), p = hrp.Position }
        local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
        local okPath = pcall(function() path:ComputeAsync(hrp.Position, dest) end)
        if okPath and path.Status == Enum.PathStatus.Success then
            for _, wp in ipairs(path:GetWaypoints()) do
                if not alive() or os.clock() - t0 > limit or not hrp.Parent then break end
                if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                hum:MoveTo(wp.Position)
                local reached = false
                local conn = hum.MoveToFinished:Connect(function() reached = true end)
                local w0 = os.clock()
                while not reached and alive() and os.clock() - w0 < 3 and os.clock() - t0 <= limit do
                    task.wait(0.1); nudgeIfStuck(stuck)
                end
                conn:Disconnect()
            end
        end
        while alive() and hrp.Parent and os.clock() - t0 <= limit and flatDist(hrp.Position, dest) > 8 do
            hum:MoveTo(dest); task.wait(0.25); nudgeIfStuck(stuck)
        end
        hum:Move(Vector3.zero, false)
        return hrp.Parent ~= nil and flatDist(hrp.Position, dest) <= 8
    end
    function V25.legitTrigger(prompt)
        return pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(prompt.HoldDuration, 0) + 0.15)
            prompt:InputHoldEnd()
        end)
    end
end

local lastSweep = 0; local sweepIdx = 0
local function waitForTarget(hrp, alive)
    local target = findTarget(hrp, false)
    if target then return target end
    if config.legit then return nil end
    if os.clock() - lastSweep < 90 then return nil end
    lastSweep = os.clock()
    local visit = {}
    for name, pos in pairs(areaCenters) do
        if next(config.areas) == nil or config.areas[name] then table.insert(visit, { name = name, pos = pos }) end
    end
    table.sort(visit, function(a, b) return a.name < b.name end)
    local picked = {}
    for i = 1, math.min(2, #visit) do sweepIdx = sweepIdx % #visit + 1; table.insert(picked, visit[sweepIdx]) end
    for _, v in ipairs(picked) do
        if not alive() then return nil end
        setStatus("Menuju area " .. v.name .. "...", THEME.warn)
        pcall(function() player:RequestStreamAroundAsync(v.pos, 3) end)
        goTo(hrp, v.pos, alive)
        local t0 = os.clock()
        repeat task.wait(0.5); target = findTarget(hrp, true)
        until target or not alive() or os.clock() - t0 > 3
        if target then return target end
    end
    if baseCFrame and alive() then goTo(hrp, V25.safeBasePos() or baseCFrame.Position, alive) end
    return nil
end

local function releaseAnchor()
    local h = getHRP()
    if h then pcall(function() h.Anchored = false end) end
end
V25.instantDeaths = 0
V25.instantPauseUntil = 0
-- minta server memuat area di sekitar posisi (StreamingEnabled): wajib untuk tujuan yang jauh
function V25.streamTo(pos, timeout)
    pcall(function() player:RequestStreamAroundAsync(pos, timeout or 3) end)
end
-- teleport aman: karakter di-anchor sampai tanah di tujuan benar-benar termuat, baru dilepas (anti jatuh ke void)
function V25.safeTeleport(cf)
    local hrp = getHRP(); if not hrp then return false end
    local pos = cf.Position
    local far = (hrp.Position - pos).Magnitude > 120
    local ok = false
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = cf
        hrp.Anchored = true
        if far then V25.streamTo(pos, 2.5) end
        local t0 = os.clock()
        while os.clock() - t0 < 4 do
            local h = getHRP(); if not h or h ~= hrp then break end
            local res = Safe.ray(pos.X, pos.Y + 6, pos.Z, 40)
            if res then ok = true; break end
            task.wait(0.1)
        end
    end)
    local h = getHRP()
    if h then pcall(function() h.Anchored = false; h.AssemblyLinearVelocity = Vector3.zero end) end
    return ok
end
-- titik ambil aman: berdiri DI SAMPING telur (bukan di atasnya), di tanah bebas bahaya, masih dalam jarak aktivasi prompt
function V25.pickGrabSpot(target, fromPos)
    local pos = target.pos
    local maxAct = target.prompt.MaxActivationDistance or 10
    local reach = math.clamp(maxAct * 0.6, 3, 8)
    local away = Vector3.new(fromPos.X - pos.X, 0, fromPos.Z - pos.Z)
    if away.Magnitude < 0.1 then away = Vector3.new(0, 0, 1) end
    away = away.Unit
    for _, r in ipairs({ reach, reach * 0.6, reach * 1.2, 2.5 }) do
        for _, ang in ipairs({ 0, 40, -40, 80, -80, 120, -120, 180 }) do
            local dir = CFrame.Angles(0, math.rad(ang), 0):VectorToWorldSpace(away)
            local x, z = pos.X + dir.X * r, pos.Z + dir.Z * r
            local res = Safe.ray(x, pos.Y + 8, z, 40)
            if res and res.Normal.Y > 0.6 and not Safe.hazard(res) and math.abs(res.Position.Y - pos.Y) <= 8
                and res.Position.Y > Workspace.FallenPartsDestroyHeight + 40 then
                local stand = res.Position + Vector3.new(0, 3, 0)
                if Safe.clear(stand) and (stand - pos).Magnitude <= maxAct + 1 then return stand end
            end
        end
    end
    return nil
end
function V25.banEggArea(center, radius, secs)
    for _, p in ipairs(collectEggPrompts()) do
        local pp = getPromptPosition(p)
        if pp and (pp - center).Magnitude <= radius then banned[p] = os.clock() + secs end
    end
end
local function instantStealCycle(target, alive)
    local hrp, hum = getChar()
    if not hrp or not hum or hum.Health <= 0 then task.wait(1); return "none" end
    local prompt = target.prompt
    target.info = describeEgg(target.root)
    if target.pos.Y < Workspace.FallenPartsDestroyHeight + 30 then
        stats.failed += 1; banned[prompt] = os.clock() + 30
        log("Telur terlalu rendah (dekat void), dilewati"); refreshStats(); return "failed"
    end
    local origin = hrp.CFrame
    local safeP = V25.safeBasePos()
    local dest = safeP and (CFrame.new(safeP) * (origin - origin.Position)) or origin
    local far = (hrp.Position - target.pos).Magnitude > 120
    if far then
        setStatus("Memuat area telur...", THEME.accent2)
        V25.streamTo(target.pos, 3)
        if not alive() then return "none" end
        hrp, hum = getChar()
        if not hrp or not hum or hum.Health <= 0 then return "none" end
    end
    local spot = V25.pickGrabSpot(target, dest.Position)
    if not spot and far then
        local tw = os.clock()
        while not spot and alive() and os.clock() - tw < 3 do task.wait(0.3); spot = V25.pickGrabSpot(target, dest.Position) end
    end
    if not spot then
        stats.failed += 1; banned[prompt] = os.clock() + 60
        log("Tidak ada titik berdiri aman di dekat telur (bahaya/air/terhalang), dilewati 60 detik"); refreshStats(); return "failed"
    end
    local result, damaged = "failed", false
    local startHp = hum.Health
    local hpConn = hum.HealthChanged:Connect(function(h) if h < startHp - 0.5 then damaged = true end end)
    local okRun, errRun = pcall(function()
        hum.Sit = false
        setStatus("Teleport instan...", THEME.accent)
        if not V25.safeTeleport(CFrame.lookAt(spot, Vector3.new(target.pos.X, spot.Y, target.pos.Z))) then
            log("Tanah di dekat telur belum termuat, dibatalkan")
            result = "failed"; return
        end
        task.wait(0.12)
        if prompt.Parent and not prompt.Enabled then
            local t0 = os.clock()
            while alive() and prompt.Parent and not prompt.Enabled and not damaged and os.clock() - t0 < 1.0 do task.wait(0.1) end
            if prompt.Parent and not prompt.Enabled then pcall(function() prompt.Enabled = true end) end
        end
        setStatus("Mengambil telur...", THEME.accent)
        local success = false
        for _ = 1, 3 do
            if damaged then break end
            if not alive() then result = "none"; return end
            local _, hm = getChar()
            if not hm or hm.Health <= 0 then break end
            if not prompt.Parent then success = true; break end
            triggerPrompt(prompt)
            task.wait(0.25)
            if isCarrying() or not prompt.Parent or not prompt.Enabled then success = true; break end
        end
        result = success and "stolen" or "failed"
    end)
    hpConn:Disconnect()
    -- selalu: pulang ke titik aman secepatnya (kalau masih hidup)
    local h2, hm2 = getChar()
    if h2 and hm2 and hm2.Health > 0 then
        pcall(function()
            h2.Anchored = false
            h2.AssemblyLinearVelocity = Vector3.zero
            h2.AssemblyAngularVelocity = Vector3.zero
        end)
        V25.safeTeleport(dest)
        task.wait(0.35)
    end
    local _, hm3 = getChar()
    local died = (not hm3) or hm3.Health <= 0
    if not okRun then log("Steal instan error: " .. tostring(errRun)); result = "failed" end
    if died then
        result = "failed"
        V25.instantDeaths += 1
        V25.banEggArea(target.pos, 35, 300)
        log("Mati saat steal instan di dekat telur ini. Area itu di-blok 5 menit.")
        if V25.instantDeaths >= 2 then
            V25.instantPauseUntil = os.clock() + 120
            V25.instantDeaths = 0
            log("Mati 2x berturut-turut: steal instan dijeda 2 menit, pakai steal biasa dulu.")
        end
    elseif damaged then
        V25.banEggArea(target.pos, 30, 180)
        log("Kena damage di lokasi telur, kabur ke titik aman. Area itu di-blok 3 menit.")
    end
    if result == "stolen" then
        V25.instantDeaths = 0
        stats.stolen += 1; log("Telur berhasil diambil (teleport instan)")
        local info = target.info or describeEgg(target.root); info.area = target.area; sendEggWebhook(info)
    elseif result == "failed" then
        stats.failed += 1; banned[prompt] = os.clock() + 20
        if not died then log("Gagal mengambil telur, dilewati 20 detik") end
    end
    refreshStats()
    return result
end

local function stealCycle(alive)
    local hrp, hum = getChar()
    if not hrp or not hum or hum.Health <= 0 then task.wait(1); return "none" end
    ensureBase()
    setStatus("Mencari telur...", THEME.accent2)
    local target = waitForTarget(hrp, alive)
    if not alive() then return "none" end
    if not target then setStatus("Tidak ada telur", THEME.warn); return "none" end
    local prompt = target.prompt
    target.info = describeEgg(target.root)
    log(("Target: %s (%d stud%s)"):format(prompt:GetFullName(), math.floor(target.dist), target.enabled and "" or ", prompt nonaktif"))
    if config.instantSteal and not config.legit then
        if os.clock() >= V25.instantPauseUntil then return instantStealCycle(target, alive) end
        if not V25.pauseLogged or os.clock() - V25.pauseLogged > 60 then
            V25.pauseLogged = os.clock(); log("Steal instan sedang dijeda (habis mati), memakai steal biasa")
        end
    end
    setStatus(config.method == "Fly" and not config.legit and "Terbang..." or "Berjalan...", THEME.accent2)
    local reached
    if config.legit then reached = V25.legitWalk(target.pos, alive)
    else reached = goTo(hrp, target.pos + Vector3.new(0, 3, 0), alive) end
    if not alive() then return "none" end
    if not reached and hrp.Parent and (hrp.Position - target.pos).Magnitude > 25 then
        stats.failed += 1; banned[prompt] = os.clock() + 15
        log("Gagal mencapai telur, dilewati 15 detik"); refreshStats(); return "failed"
    end
    task.wait(0.3)
    hrp = getHRP() or hrp
    if prompt.Parent and not prompt.Enabled then
        local t0 = os.clock()
        while alive() and prompt.Parent and not prompt.Enabled and os.clock() - t0 < 2 do task.wait(0.1) end
        if prompt.Parent and not prompt.Enabled and not config.legit then pcall(function() prompt.Enabled = true end) end
    end
    setStatus("Mengambil telur...", THEME.accent)
    local success = false
    for _ = 1, 3 do
        if not alive() then return "none" end
        if not prompt.Parent then success = true; break end
        if config.legit then V25.legitTrigger(prompt) else triggerPrompt(prompt) end
        task.wait(0.4)
        if isCarrying() or not prompt.Parent or not prompt.Enabled then success = true; break end
    end
    local result
    if success then
        stats.stolen += 1; result = "stolen"; log("Telur berhasil diambil")
        local info = target.info or describeEgg(target.root); info.area = target.area; sendEggWebhook(info)
    else
        stats.failed += 1; result = "failed"; banned[prompt] = os.clock() + 20
        log("Gagal mengambil telur, dilewati 20 detik")
    end
    refreshStats()
    hrp = getHRP() or hrp
    if baseCFrame and alive() then
        setStatus("Pulang ke base...", THEME.good)
        local homePos = V25.safeBasePos() or baseCFrame.Position
        if config.legit then V25.legitWalk(homePos, alive)
        else goTo(hrp, homePos, alive) end
        task.wait(0.5)
    end
    return result
end

local EventBan = {}; local EventAttempts = {}
local function anyEventEnabled()
    for _, on in pairs(config.events) do if on then return true end end
    return false
end
-- Boss dianggap "muncul" hanya bila punya Humanoid hidup (atau atribut Health > 0)
-- dan bukan pemain / bukan objek dekorasi statis.
local function bossIsLive(m)
    if not m:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    local hum = m:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health > 0 and hum.MaxHealth > 0 end
    for _, a in ipairs({ "Health", "HP", "health", "hp", "CurrentHealth" }) do
        local v = m:GetAttribute(a)
        if type(v) == "number" then return v > 0 end
    end
    for _, d in ipairs(m:GetChildren()) do
        if d:IsA("NumberValue") or d:IsA("IntValue") then
            local n = d.Name:lower()
            if n == "health" or n == "hp" then return d.Value > 0 end
        end
    end
    return false
end
local function findEventTarget(def, hrp)
    local best, bestD = nil, math.huge
    local matched = {}
    local eggFolder = Workspace:FindFirstChild("AreaEggSlotsClient")
    local isAttack = def.mode == "attack"
    for _, d in ipairs(Snapshot.get()) do
        if d.Parent and not (eggFolder and d:IsDescendantOf(eggFolder)) and not (EventBan[d] and EventBan[d] > os.clock()) then
            local cand
            if d:IsA("ProximityPrompt") then
                if not isAttack then
                    local pname = d.Parent and d.Parent.Name or ""
                    local text = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name
                    if d.Enabled and (nameHasAny(pname, def.keywords) or nameHasAny(text, def.keywords)) then
                        local pos = getPromptPosition(d)
                        if pos then cand = { inst = d, prompt = d, pos = pos } end
                    end
                end
            elseif d:IsA("Model") or d:IsA("BasePart") then
                if nameHasAny(d.Name, def.keywords) and not Players:GetPlayerFromCharacter(d) then
                    local inside = false; local anc = d.Parent
                    while anc and anc ~= Workspace do
                        if matched[anc] then inside = true; break end
                        anc = anc.Parent
                    end
                    if not inside then
                        if isAttack then
                            -- boss: wajib Model hidup, kalau belum muncul -> abaikan total (tidak gerak/tidak equip)
                            if d:IsA("Model") and bossIsLive(d) then
                                matched[d] = true
                                local pos = getInstPosition(d)
                                if pos and pos.Y > Workspace.FallenPartsDestroyHeight + 30 then cand = { inst = d, pos = pos } end
                            end
                        else
                            matched[d] = true
                            local hum = d:IsA("Model") and d:FindFirstChildOfClass("Humanoid")
                            if not (hum and hum.Health <= 0) then
                                local pos = getInstPosition(d)
                                if pos then cand = { inst = d, pos = pos } end
                            end
                        end
                    end
                end
            end
            if cand then
                local dist = (cand.pos - hrp.Position).Magnitude
                if dist < bestD then best, bestD = cand, dist end
            end
        end
    end
    return best
end
local function runEvent(def, t, alive)
    local hrp = getHRP(); if not hrp then return end
    local inst = t.inst
    setStatus("Event: " .. def.name, THEME.accent)
    log("Event " .. def.name .. " -> " .. inst:GetFullName())
    if def.mode == "attack" then
        if not bossIsLive(inst) then return end
        goTo(hrp, t.pos + Vector3.new(0, 3, 4), function() return alive() and inst.Parent ~= nil and bossIsLive(inst) end)
        local tool = nil
        local t0 = os.clock()
        while alive() and inst.Parent and bossIsLive(inst) and os.clock() - t0 < 40 do
            local p = getInstPosition(inst); local h = getHRP()
            if not p or not h then break end
            if (h.Position - p).Magnitude > 12 then
                goTo(h, p + Vector3.new(0, 3, 4), function() return alive() and inst.Parent ~= nil and bossIsLive(inst) end)
            end
            if not bossIsLive(inst) then break end
            if not tool or tool.Parent ~= player.Character then
                tool = equipTool(def.tool)
                if not tool then
                    log("Tool " .. tostring(def.tool) .. " tidak ada di backpack")
                    EventBan[inst] = os.clock() + 30
                    break
                end
            end
            pcall(function() tool:Activate() end)
            task.wait(0.15)
        end
        -- simpan kembali pentungan saat boss selesai / hilang
        local _, hm = getChar()
        if hm then pcall(function() hm:UnequipTools() end) end
        return
    end
    goTo(hrp, t.pos + Vector3.new(0, 3, 4), alive)
    if false then
    elseif def.mode == "collect" then
        local tool = def.tool and equipTool(def.tool) or nil
        for _ = 1, 4 do
            if not alive() or not inst.Parent then break end
            local fired = false
            if t.prompt and t.prompt.Parent then fired = triggerPrompt(t.prompt)
            else fired = firePromptsNear(t.pos, 14, nil) > 0 end
            local h = getHRP()
            if not fired and h and typeof(firetouchinterest) == "function" and inst:IsA("BasePart") then
                pcall(firetouchinterest, h, inst, 0); pcall(firetouchinterest, h, inst, 1)
            end
            if tool and tool.Parent == player.Character then pcall(function() tool:Activate() end) end
            task.wait(0.35)
        end
    else
        local h = getHRP()
        if h then
            if (h.Position - t.pos).Magnitude > 4 then goTo(h, t.pos + Vector3.new(0, 1.5, 0), alive) end
            if typeof(firetouchinterest) == "function" and inst:IsA("BasePart") then
                pcall(firetouchinterest, h, inst, 0); pcall(firetouchinterest, h, inst, 1)
            end
            task.wait(0.4)
        end
    end
    if inst.Parent then
        EventAttempts[inst] = (EventAttempts[inst] or 0) + 1
        if EventAttempts[inst] >= 4 then EventBan[inst] = os.clock() + 30; EventAttempts[inst] = nil end
    else EventAttempts[inst] = nil end
end
local function eventStep(alive)
    local hrp = getHRP(); if not hrp then return false end
    for _, def in ipairs(EVENT_DEFS) do
        if config.events[def.id] and alive() then
            local t = findEventTarget(def, hrp)
            if t then runEvent(def, t, alive); return true end
        end
    end
    return false
end

local function nearBase(pos, radius) return baseCFrame ~= nil and (pos - baseCFrame.Position).Magnitude <= radius end
local function actOnPrompts(kws)
    local hrp = getHRP(); if not hrp then return 0 end
    local count = 0
    local always = function() return uiAlive end
    for _, p in ipairs(Snapshot.get()) do
        if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, kws) then
            local pos = getPromptPosition(p)
            if pos and (ownedByMe(p) or nearBase(pos, BASE_RADIUS)) then
                goTo(hrp, pos + Vector3.new(0, 3, 0), always)
                task.wait(0.2)
                triggerPrompt(p)
                count += 1
                task.wait(0.4)
                if count >= 10 then break end
            end
        end
    end
    return count
end
-- V36: hatch/place berbasis data scan: telur yang sudah ditaruh = Workspace.PlacedEggRenders (nama "<UserId>_<UID>"),
-- prompt "Hatch!" ada di Workspace.SmartPromptPart yang berpindah sendiri ke telur terdekat dari karakter.
function V25.myPlotAnchor()
    local mp = V25.myPlot()
    if not mp then return nil end
    for _, path in ipairs({ { "CenterPoint" }, { "ToUpdate", "CenterPoint" }, { "ToUpdate", "PetArea" }, { "SpawnPoint" } }) do
        local cur = mp
        for _, nm in ipairs(path) do cur = cur and cur:FindFirstChild(nm) end
        if cur and cur:IsA("BasePart") then return cur.Position end
    end
    return getInstPosition(mp)
end
function V25.myPlacedEggs()
    local list = {}
    local f = Workspace:FindFirstChild("PlacedEggRenders")
    if f then
        for _, m in ipairs(f:GetChildren()) do
            if ownedByMe(m) and getInstPosition(m) then table.insert(list, m) end
        end
    end
    return list
end
function V25.nearbyPrompt(kws, maxDist, excludePath)
    local hrp = getHRP(); if not hrp then return nil end
    local sources = {}
    for _, ch in ipairs(Workspace:GetChildren()) do
        if ch.Name == "SmartPromptPart" then
            for _, d in ipairs(ch:GetDescendants()) do table.insert(sources, d) end
        end
    end
    if #sources == 0 then sources = Snapshot.get() end
    local best, bestD = nil, maxDist
    for _, p in ipairs(sources) do
        if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, kws) then
            if not (excludePath and p:GetFullName():lower():find(excludePath, 1, true)) then
                local pos = getPromptPosition(p)
                if pos then
                    local d = (pos - hrp.Position).Magnitude
                    if d <= bestD then best, bestD = p, d end
                end
            end
        end
    end
    return best
end
function V25.logNearbyPrompts(tag)
    local hrp = getHRP(); if not hrp then return end
    local seen = 0
    for _, p in ipairs(Snapshot.get()) do
        if p:IsA("ProximityPrompt") and p.Parent then
            local pos = getPromptPosition(p)
            if pos and (pos - hrp.Position).Magnitude <= 20 then
                seen += 1
                if seen > 4 then break end
                log(("%s: prompt dekat aksi='%s' objek='%s' aktif=%s (%s)"):format(tag, tostring(p.ActionText), tostring(p.ObjectText), tostring(p.Enabled), p.Parent.Name))
            end
        end
    end
    if seen == 0 then log(tag .. ": tidak ada prompt dalam 20 stud") end
end
local function autoHatchOnce()
    ensureBase()
    local btns = findButtons(HINTS.hatch, false)
    if #btns > 0 then clickButton(btns[1]); task.wait(0.3) end
    local always = function() return uiAlive end
    local count = 0
    local eggs = V25.myPlacedEggs()
    for i, egg in ipairs(eggs) do
        if not uiAlive or i > 12 then break end
        local hrp = getHRP(); local pos = getInstPosition(egg)
        if not hrp or not pos or not egg.Parent then break end
        if (hrp.Position - pos).Magnitude > 8 then goTo(hrp, pos + Vector3.new(0, 3, 0), always) end
        local p
        for _ = 1, 6 do
            p = V25.nearbyPrompt(HINTS.hatch, 18)
            if p then break end
            task.wait(0.15)
        end
        if p then triggerPrompt(p); count += 1; task.wait(0.5) end
    end
    if count == 0 then count = actOnPrompts(HINTS.hatch) end
    if count > 0 then log("Auto Hatch: " .. count)
    elseif #eggs > 0 then log("Auto Hatch: " .. #eggs .. " telur di plot, prompt Hatch belum muncul (belum siap?)") end
end
local function eggToolMatches(tool)
    local text = tool.Name:lower()
    for k, v in pairs(tool:GetAttributes()) do text = text .. " " .. tostring(k):lower() .. ":" .. tostring(v):lower() end
    return passesFilters(tool, text, config.placeFilters)
end
function V25.netRemote(name)
    local rs = game:GetService("ReplicatedStorage")
    local pk = rs:FindFirstChild("Packages")
    local nw = pk and pk:FindFirstChild("Networking")
    return nw and nw:FindFirstChild(name)
end
-- game memakai RF/EggWorld/AskWearTool(UID) saat telur dipegang dari hotbar; tiru supaya server ikut tahu telur dipegang
function V25.wearEgg(tool, hum)
    if tool.Parent == player.Character then return true end
    local uid = tool:GetAttribute("UID")
    local r = uid and V25.netRemote("RF/EggWorld/AskWearTool")
    if r and r:IsA("RemoteFunction") then
        pcall(function() r:InvokeServer(uid) end)
        for _ = 1, 10 do
            if tool.Parent == player.Character then return true end
            task.wait(0.1)
        end
    end
    pcall(function() hum:EquipTool(tool) end)
    task.wait(0.3)
    return tool.Parent == player.Character
end
function V25.isEggItem(t)
    return t:IsA("Tool") and (t:GetAttribute("ItemType") == "AssetEgg" or t.Name:lower():find("egg", 1, true) ~= nil)
end
local function autoPlaceOnce()
    ensureBase()
    local hrp, hum, char = getChar(); if not hrp or not hum then return end
    local always = function() return uiAlive end
    -- 1) pilih / pegang telur yang lolos filter place
    local tool
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if V25.isEggItem(t) and eggToolMatches(t) then tool = t; break end
        end
    end
    if not tool then
        for _, t in ipairs(player.Backpack:GetChildren()) do
            if V25.isEggItem(t) and eggToolMatches(t) then
                tool = t
                V25.wearEgg(t, hum)
                break
            end
        end
    end
    if not tool then return end
    -- 2) titik tempat taruh = Prompt1/2/3 + GridCenter di StarterPen plot sendiri
    local spots = {}
    local mp = V25.myPlot()
    local td = mp and mp:FindFirstChild("ToUpdate")
    local pen = td and td:FindFirstChild("StarterPen")
    if pen then
        for _, nm in ipairs({ "Prompt1", "Prompt2", "Prompt3", "GridCenter" }) do
            local part = pen:FindFirstChild(nm)
            if part and part:IsA("BasePart") then table.insert(spots, part.Position) end
        end
    end
    if #spots == 0 then
        local a = V25.myPlotAnchor()
        if a then table.insert(spots, a) end
    end
    if #spots == 0 then log("Auto Place: plot sendiri tidak ditemukan"); return end
    local before = #V25.myPlacedEggs()
    -- percobaan sebelumnya gagal dengan jumlah telur plot yang sama (kemungkinan slot penuh): jangan keliling lagi,
    -- tunggu sampai ada telur yang di-hatch (jumlah berubah)
    if V25.placeFullAt == before then return end
    local function toolGone()
        return tool.Parent ~= player.Character and tool.Parent ~= player.Backpack
    end
    for _, sp in ipairs(spots) do
        if not uiAlive then return end
        local h = getHRP(); if not h then return end
        if (h.Position - sp).Magnitude > 6 then goTo(h, sp + Vector3.new(0, 3, 0), always) end
        if tool.Parent ~= player.Character then V25.wearEgg(tool, hum) end
        local p
        for _ = 1, 6 do
            p = V25.nearbyPrompt(HINTS.place, 14, "fusion")
            if p then break end
            task.wait(0.15)
        end
        if p then triggerPrompt(p)
        elseif tool.Parent == player.Character then pcall(function() tool:Activate() end) end
        task.wait(0.8)
        if toolGone() or #V25.myPlacedEggs() > before then
            V25.placeFullAt = nil
            log("Auto Place: telur ditaruh")
            return
        end
    end
    V25.placeFullAt = before
    log("Auto Place: gagal menaruh telur (plot berisi " .. before .. " telur; kalau slot penuh, hatch dulu)")
    V25.logNearbyPrompts("Auto Place")
end
local function autoFuseOnce()
    ensureBase()
    local n = actOnPrompts(HINTS.fuse)
    if n > 0 then
        task.wait(0.8)
        for _ = 1, 3 do clickFirstMatching({ "auto select", "select all", "fuse" }); task.wait(0.5) end
        log("Auto Fuse dijalankan")
    end
end
local function autoIndexOnce()
    local claimed = 0
    local function claimAll()
        for _, b in ipairs(findButtons(HINTS.index, false)) do
            if clickButton(b) then claimed += 1; task.wait(0.15) end
        end
    end
    claimAll()
    if claimed == 0 then
        local open = findButtons({ "index" }, true)
        if #open > 0 then clickButton(open[1]); task.wait(0.6); claimAll(); clickButton(open[1]) end
    end
    if claimed > 0 then log("Auto Claim Index: " .. claimed) end
end

do
    local warned = {}
    local function warnOnce(key, msg) if not warned[key] then warned[key] = true; log(msg) end end
    local GEAR_WORDS = { "bat", "net", "racket", "racquet", "scrambler", "consumable", "booster", "potion" }
    local MAX_ITEMS_PER_RUN = 12
    local alive = function() return uiAlive end
    local function allTools()
        local list = {}
        local _, _, char = getChar()
        if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(list, t) end end end
        for _, t in ipairs(player.Backpack:GetChildren()) do if t:IsA("Tool") then table.insert(list, t) end end
        return list
    end
    local function toolAlive(t) return t.Parent == player.Backpack or (player.Character ~= nil and t.Parent == player.Character) end
    local function itemText(tool)
        local parts = { tool.Name:lower() }
        for k, v in pairs(tool:GetAttributes()) do table.insert(parts, tostring(k):lower() .. ":" .. tostring(v):lower()) end
        local count = 0
        for _, d in ipairs(tool:GetDescendants()) do
            count += 1; if count > 40 then break end
            table.insert(parts, d.Name:lower())
            if d:IsA("TextLabel") then table.insert(parts, d.Text:lower()) end
            if d:IsA("StringValue") then table.insert(parts, d.Value:lower()) end
        end
        return table.concat(parts, " ")
    end
    local function isFavorited(tool, text)
        for k, v in pairs(tool:GetAttributes()) do
            local kl = tostring(k):lower()
            local favKey = kl:find("favorite", 1, true) or kl:find("favourite", 1, true)
                or kl == "fav" or kl == "isfav" or kl == "locked" or kl == "islocked" or kl == "lock"
            if favKey and v and v ~= 0 and v ~= "" then return true end
        end
        return text:find("favorited", 1, true) ~= nil
    end
    function V25.isEggTool(tool) return tool.Name:lower():find("egg", 1, true) ~= nil end
    local function isGearTool(tool) return nameHasAny(tool.Name, GEAR_WORDS) end
    local function isPetTool(tool) return not V25.isEggTool(tool) and not isGearTool(tool) end
    local function parseNames(s)
        local list = {}
        for w in tostring(s or ""):gmatch("[^,;\n]+") do
            w = w:lower():gsub("^%s+", ""):gsub("%s+$", "")
            if w ~= "" then table.insert(list, w) end
        end
        return list
    end
    local function matchesSpec(tool, text, names, filters)
        for _, w in ipairs(names) do if text:find(w, 1, true) then return true end end
        if hasAnyFilter(filters) and passesFilters(tool, text, filters) then return true end
        return false
    end
    local function equipHeld(tool)
        local _, hum = getChar(); if not hum then return false end
        if tool.Parent ~= player.Character then pcall(function() hum:EquipTool(tool) end); task.wait(0.3) end
        return tool.Parent == player.Character
    end
    local function backToBase()
        local hrp = getHRP(); if hrp and baseCFrame then goTo(hrp, V25.safeBasePos() or baseCFrame.Position, alive) end
    end
    local function clickLabeled(keys, bannedWords)
        for _, b in ipairs(findButtons(keys, false)) do
            local lab = (buttonLabel(b) .. " " .. b.Name):lower()
            local skip = false
            for _, w in ipairs(bannedWords) do if lab:find(w, 1, true) then skip = true; break end end
            if not skip and clickButton(b) then return true end
        end
        return false
    end
    local function sellTools(tools, label)
        local hrp = getHRP(); if not hrp then return 0 end
        local sold, fails = 0, 0
        for i, tool in ipairs(tools) do
            if i > MAX_ITEMS_PER_RUN or not uiAlive then break end
            if toolAlive(tool) and equipHeld(tool) then
                local done = clickLabeled(HINTS.sell, { "all" })
                if not done then
                    for _, p in ipairs(Snapshot.get()) do
                        if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, HINTS.sell) then
                            local pos = getPromptPosition(p)
                            if pos and (ownedByMe(p) or nearBase(pos, BASE_RADIUS)) then
                                goTo(hrp, pos + Vector3.new(0, 3, 0), alive); task.wait(0.2); triggerPrompt(p)
                                done = true; break
                            end
                        end
                    end
                end
                if not done then warnOnce("sell_none_" .. label, "Auto Sell: tombol tidak ditemukan. Cek Debug."); break end
                task.wait(0.35); clickLabeled({ "confirm" }, {}); task.wait(0.4)
                if toolAlive(tool) then
                    fails += 1
                    if fails >= 2 then warnOnce("sell_fail_" .. label, "Auto Sell: item tidak terjual. Dihentikan."); break end
                else sold += 1; fails = 0 end
            end
        end
        backToBase(); return sold
    end
    function V25.autoSellOnce()
        ensureBase()
        if not hasAnyFilter(config.sellFilters) then warnOnce("sell_nofilter", "Auto Sell Egg: pilih rarity dulu."); return end
        local list = {}
        for _, t in ipairs(allTools()) do
            if V25.isEggTool(t) then
                local text = itemText(t)
                if not isFavorited(t, text) and passesFilters(t, text, config.sellFilters) then table.insert(list, t) end
            end
        end
        if #list == 0 then return end
        local n = sellTools(list, "egg"); if n > 0 then log("Auto Sell: " .. n) end
    end
    local favTried = {}
    function V25.autoFavoriteOnce()
        local names = parseNames(config.favNames)
        if #names == 0 and not hasAnyFilter(config.favFilters) then warnOnce("fav_nocrit", "Auto Favorit: isi kriteria dulu."); return end
        local done, fails = 0, 0
        for _, t in ipairs(allTools()) do
            if done >= 8 or not uiAlive then break end
            if not isGearTool(t) and (favTried[t] == nil or favTried[t] < os.clock()) then
                local text = itemText(t)
                if not isFavorited(t, text) and matchesSpec(t, text, names, config.favFilters) then
                    favTried[t] = os.clock() + 300
                    if equipHeld(t) then
                        local clicked = clickLabeled(HINTS.favorite, { "unfav", "unlock" })
                        if not clicked then warnOnce("fav_btn", "Auto Favorit: tombol tidak ditemukan."); break end
                        task.wait(0.4)
                        if isFavorited(t, itemText(t)) then done += 1; fails = 0
                        else
                            fails += 1
                            if fails >= 2 then warnOnce("fav_fail", "Auto Favorit: klik tidak efek. Dihentikan."); break end
                        end
                    end
                end
            end
        end
        if done > 0 then log("Auto Favorit: " .. done) end
    end
    local function contextText(btn)
        local parts = {}; local cur = btn
        for _ = 1, 5 do
            if not cur or cur == playerGui then break end
            table.insert(parts, cur.Name:lower())
            local parent = cur.Parent
            if parent then
                for _, sib in ipairs(parent:GetChildren()) do
                    if sib:IsA("TextLabel") and sib.Text ~= "" then table.insert(parts, sib.Text:lower()) end
                end
            end
            cur = parent
        end
        return table.concat(parts, " ")
    end
    local function hasWord(text, words) for _, w in ipairs(words) do if text:find(w, 1, true) then return true end end; return false end
    local function upgradeOnce(key)
        local def = UPGRADES[key]
        ensureBase()
        local clicked = 0
        for _, b in ipairs(findButtons(HINTS.upgrade, false)) do
            local ctx = contextText(b)
            if hasWord(ctx, def.words) and not ctx:find("robux", 1, true) and not ctx:find("r$", 1, true) then
                if clickButton(b) then clicked += 1; task.wait(0.3) end
                if clicked >= 5 then break end
            end
        end
        if clicked == 0 then
            local hrp = getHRP(); local n = 0
            for _, p in ipairs(Snapshot.get()) do
                if n >= 3 or not hrp then break end
                if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, HINTS.upgrade) then
                    local pos = getPromptPosition(p)
                    local full = p:GetFullName():lower()
                    if pos and hasWord(full, def.words) and (ownedByMe(p) or nearBase(pos, BASE_RADIUS)) then
                        goTo(hrp, pos + Vector3.new(0, 3, 0), alive); task.wait(0.2); triggerPrompt(p)
                        clicked += 1; n += 1; task.wait(0.4)
                    end
                end
            end
            if clicked > 0 then backToBase() end
        end
        if clicked > 0 then log("Auto Upgrade " .. def.name .. ": " .. clicked .. "x")
        else warnOnce("upg_" .. key, "Auto Upgrade " .. def.name .. ": tombol tidak ditemukan.") end
    end
    function V25.autoUpgTrailOnce() upgradeOnce("upgTrail") end
    function V25.autoUpgTreadmillOnce() upgradeOnce("upgTreadmill") end
    function V25.autoUpgBaseOnce() upgradeOnce("upgBase") end
    function V25.autoPetPlaceOnce()
        ensureBase()
        local names = parseNames(config.petPlaceNames)
        if #names == 0 and not hasAnyFilter(config.petPlaceFilters) then warnOnce("petplace_nocrit", "Pet Place: isi kriteria dulu."); return end
        local chosen
        for _, t in ipairs(allTools()) do
            if isPetTool(t) then
                local text = itemText(t)
                if matchesSpec(t, text, names, config.petPlaceFilters) then chosen = t; break end
            end
        end
        if not chosen then warnOnce("petplace_none", "Pet Place: tidak ada pet cocok."); return end
        if not equipHeld(chosen) then return end
        local n = actOnPrompts(HINTS.place)
        if n > 0 then log("Pet Place: " .. n .. " prompt dipicu") end
    end
    function V25.autoPetSellOnce()
        ensureBase()
        local names = parseNames(config.petSellNames)
        if #names == 0 and not hasAnyFilter(config.petSellFilters) then warnOnce("petsell_nocrit", "Pet Sell: isi kriteria dulu."); return end
        local list = {}
        for _, t in ipairs(allTools()) do
            if isPetTool(t) then
                local text = itemText(t)
                if not isFavorited(t, text) and matchesSpec(t, text, names, config.petSellFilters) then table.insert(list, t) end
            end
        end
        if #list == 0 then return end
        local n = sellTools(list, "pet"); if n > 0 then log("Pet Sell: " .. n) end
    end
    function V25.scanBackpack(dbg)
        dbg("== SCAN BACKPACK ==")
        for i, t in ipairs(allTools()) do
            if i > 40 then dbg("... dipotong"); break end
            local text = itemText(t)
            local kind = V25.isEggTool(t) and "EGG" or (isGearTool(t) and "GEAR" or "PET/ITEM")
            local attrs = {}
            for k, v in pairs(t:GetAttributes()) do table.insert(attrs, tostring(k) .. "=" .. tostring(v)) end
            dbg(("%s | %s | fav=%s | attr: %s"):format(t.Name, kind, tostring(isFavorited(t, text)), #attrs > 0 and table.concat(attrs, ", ") or "-"))
        end
    end
    function V25.scanActions(dbg)
        dbg("== SCAN AKSI ==")
        local n = 0
        for _, group in ipairs({ HINTS.sell, HINTS.upgrade, HINTS.favorite }) do
            for _, b in ipairs(findButtons(group, false)) do
                n += 1; if n > 40 then dbg("... dipotong"); return end
                dbg(("%s | teks='%s' | konteks: %s"):format(b:GetFullName(), buttonLabel(b), contextText(b):sub(1, 90)))
            end
        end
        if n == 0 then dbg("Tidak ada tombol terlihat. Buka menu dulu lalu scan lagi.") end
    end
    local function optsOf(cat) for _, entry in ipairs(FILTERS) do if entry[1] == cat then return entry[2] end end; return {} end
    local function hitsOf(root, text, cat)
        local hits = {}
        for _, o in ipairs(optsOf(cat)) do if matchesValue(root, text, o) then table.insert(hits, o) end end
        return hits
    end
    local function eggPredictText()
        local hrp = getHRP(); if not hrp then return "Karakter belum ada" end
        local list = {}
        for _, p in ipairs(collectEggPrompts()) do
            local pos = getPromptPosition(p)
            if pos and not (config.skipOwn and ownedByMe(p)) then table.insert(list, { p = p, pos = pos, d = (pos - hrp.Position).Magnitude }) end
        end
        if #list == 0 then return "Tidak ada telur terdeteksi" end
        table.sort(list, function(a, b) return a.d < b.d end)
        local filterOn = config.targetMode == "Filter" and hasAnyFilter(config.filters)
        local lines = {}
        for i = 1, math.min(4, #list) do
            local e = list[i]
            local root = getEggRoot(e.p)
            local text = collectEggText(root)
            local rar = hitsOf(root, text, "Rarity")
            local var = hitsOf(root, text, "Variant")
            local siz = hitsOf(root, text, "Size")
            local area = detectAreaFromText(norm(collectAncestorText(e.p) .. " " .. text)) or nearestAreaByCenter(e.pos) or "?"
            local verdict = filterOn and (passesFilters(root, text, config.filters) and "LOLOS" or "TIDAK") or "-"
            table.insert(lines, ("#%d %s | %s | %s | %s | %d stud | %s"):format(
                i, #rar > 0 and table.concat(rar, "/") or "rarity ?",
                #var > 0 and table.concat(var, "/") or "Normal",
                #siz > 0 and siz[1] or "size ?",
                area, math.floor(e.d), verdict))
        end
        return table.concat(lines, "\n")
    end
    local predictToken = 0
    function V25.startEggPredict()
        predictToken += 1; local my = predictToken
        task.spawn(function()
            while uiAlive and config.eggPredict and predictToken == my do
                local ok, txt = pcall(eggPredictText)
                if ui.predictLabel then ui.predictLabel.Text = ok and txt or ("Error: " .. tostring(txt)) end
                task.wait(2.5)
            end
        end)
    end
end

local autoTokens = {}
local function runAutoLoop(key, fn)
    autoTokens[key] = (autoTokens[key] or 0) + 1
    local my = autoTokens[key]
    task.spawn(function()
        while uiAlive and config.auto[key] and autoTokens[key] == my do
            local ok, err = Lock.run(fn)
            if not ok then log("Auto " .. key .. " error: " .. tostring(err)) end
            local iv = key == "index" and 60 or config.autoInterval
            local waited = 0
            while waited < iv and uiAlive and config.auto[key] and autoTokens[key] == my do task.wait(0.25); waited += 0.25 end
        end
    end)
end
local ensureBrain
local function setAuto(key, on, fn)
    config.auto[key] = on
    if on then
        if config.priorityOn then ensureBrain() else runAutoLoop(key, fn) end
    end
end

do
    V25.AUTO_META = {
        hatch = { "Auto Hatch", autoHatchOnce }, place = { "Auto Place", autoPlaceOnce },
        fuse = { "Auto Fuse", autoFuseOnce }, index = { "Auto Claim Index", autoIndexOnce },
        sell = { "Auto Sell Egg", V25.autoSellOnce }, favorite = { "Auto Favorit", V25.autoFavoriteOnce },
        upgTrail = { "Upgrade Trail", V25.autoUpgTrailOnce }, upgTreadmill = { "Upgrade Treadmill", V25.autoUpgTreadmillOnce },
        upgBase = { "Upgrade Base", V25.autoUpgBaseOnce }, petPlace = { "Pet: Taruh", V25.autoPetPlaceOnce },
        petSell = { "Pet: Jual", V25.autoPetSellOnce },
    }
    V25.AUTO_ORDER = { "hatch", "place", "fuse", "index", "sell", "favorite", "upgTrail", "upgTreadmill", "upgBase", "petPlace", "petSell" }
    V25.PRIORITY_OPTIONS = { { id = "none", label = "- Kosong -" }, { id = "event", label = "Event (yang aktif)" } }
    for _, key in ipairs(V25.AUTO_ORDER) do table.insert(V25.PRIORITY_OPTIONS, { id = key, label = V25.AUTO_META[key][1] }) end
    local valid = { none = true, event = true }; for k in pairs(V25.AUTO_META) do valid[k] = true end
    local fixed = { "steal" }
    local src = type(config.priority) == "table" and config.priority or {}
    for i = 2, 7 do
        local id = src[i]
        fixed[i] = (type(id) == "string" and valid[id]) and id or "none"
    end
    config.priority = fixed
    V25.lastAutoRun = {}
    function V25.autoDue(key)
        local iv = key == "index" and 60 or config.autoInterval
        return os.clock() - (V25.lastAutoRun[key] or 0) >= iv
    end
    function V25.applyPriorityMode(on)
        config.priorityOn = on and true or false
        if on then
            for key in pairs(autoTokens) do autoTokens[key] = autoTokens[key] + 1 end
            ensureBrain()
        else
            for key, meta in pairs(V25.AUTO_META) do if config.auto[key] then runAutoLoop(key, meta[2]) end end
        end
    end
end

local function shopNameMatch(name, def)
    local n = norm(name)
    for _, ex in ipairs(def.exclude or {}) do if n:find(ex, 1, true) then return false end end
    for _, k in ipairs(def.gui) do if n:find(norm(k), 1, true) then return true end end
    return false
end
V25.SHOP_SKIP_FRAME = { "button", "btn", "icon", "notif", "item", "template", "slot", "card", "entry", "label", "title", "timer", "badge", "tag", "tooltip" }
V25.SHOP_SKIP_GUI = { "button", "btn", "icon", "notif" }
local function shopContainers(def)
    local list = {}
    for _, d in ipairs(playerGui:GetDescendants()) do
        if (d:IsA("Frame") or d:IsA("ScrollingFrame") or d:IsA("CanvasGroup") or d:IsA("ScreenGui"))
            and not (sg and (d == sg or d:IsDescendantOf(sg))) and shopNameMatch(d.Name, def) then
            local n = d.Name:lower()
            local skipList = d:IsA("ScreenGui") and V25.SHOP_SKIP_GUI or V25.SHOP_SKIP_FRAME
            local skip = false
            for _, w in ipairs(skipList) do if n:find(w, 1, true) then skip = true; break end end
            if not skip then table.insert(list, d) end
        end
    end
    return list
end
-- "jendela" shop: frame bernama shop, atau (kalau ScreenGui bernama shop) anak-anaknya sampai 2 level
function V25.windowsOf(def)
    local out, seen = {}, {}
    local function add(o) if o:IsA("GuiObject") and not seen[o] then seen[o] = true; table.insert(out, o) end end
    for _, c in ipairs(shopContainers(def)) do
        if c:IsA("ScreenGui") then
            for _, ch in ipairs(c:GetChildren()) do
                add(ch)
                if ch:IsA("GuiObject") then for _, g in ipairs(ch:GetChildren()) do add(g) end end
            end
        else add(c) end
    end
    return out
end
function V25.viewport()
    local cam = Workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(900, 600)
end
function V25.bigOnScreen(o, vp)
    local s2, p2 = o.AbsoluteSize, o.AbsolutePosition
    if s2.X < 150 or s2.Y < 100 then return false end
    if p2.X >= vp.X - 40 or p2.Y >= vp.Y - 40 or p2.X + s2.X <= 40 or p2.Y + s2.Y <= 40 then return false end
    return true
end
local function shopIsOpen(def)
    local vp = V25.viewport()
    for _, d in ipairs(V25.windowsOf(def)) do
        if guiVisible(d) and V25.bigOnScreen(d, vp) then return true end
    end
    return false
end
-- semua frame besar yang sedang tampil di PlayerGui (selain GUI script ini) -> untuk mendeteksi "ada jendela baru terbuka"
function V25.bigVisible()
    local vp = V25.viewport()
    local set = {}
    for _, d in ipairs(playerGui:GetDescendants()) do
        if (d:IsA("Frame") or d:IsA("ScrollingFrame") or d:IsA("CanvasGroup")) and d.Visible
            and not (sg and d:IsDescendantOf(sg))
            and d.AbsoluteSize.X >= 200 and d.AbsoluteSize.Y >= 150
            and not (d.AbsoluteSize.X >= vp.X * 0.97 and d.AbsoluteSize.Y >= vp.Y * 0.97)
            and d.BackgroundTransparency < 0.9 and guiVisible(d) then
            set[d] = true
        end
    end
    return set
end
function V25.newWindowSince(before)
    for d in pairs(V25.bigVisible()) do if not before[d] then return d end end
    return nil
end
local function isCloseButton(b)
    local l = (buttonLabel(b) .. " " .. b.Name):lower()
    return l:find("close", 1, true) ~= nil or l:find("exit", 1, true) ~= nil or l:gsub("%s", "") == "x"
end
local function pressVariants(btn)
    return {
        function() if typeof(firesignal) ~= "function" then error("no firesignal") end
            firesignal(btn.MouseButton1Click) end,
        function() if typeof(firesignal) ~= "function" then error("no firesignal") end
            firesignal(btn.Activated, Enum.UserInputType.MouseButton1, 1) end,
        function() if typeof(getconnections) ~= "function" then error("no getconnections") end
            for _, sig in ipairs({ btn.MouseButton1Down, btn.MouseButton1Click, btn.MouseButton1Up, btn.Activated }) do
                for _, c in ipairs(getconnections(sig)) do pcall(function() c:Fire() end) end
            end end,
    }
end
function V25.shopRelated(a, b) return a == b or a:IsDescendantOf(b) or b:IsDescendantOf(a) end
-- tutup satu jendela: tekan tombol close SEKALI (di dalam jendela / 2 level induk), kalau masih terlihat baru disembunyikan
function V25.closeShopContainer(c)
    local function findClose(root)
        for _, d in ipairs(root:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and guiVisible(d) and isCloseButton(d) then return d end
        end
        return nil
    end
    local btn = findClose(c)
    if not btn then
        local par, hops = c.Parent, 0
        while not btn and par and par ~= playerGui and hops < 2 do
            btn = findClose(par); par = par.Parent; hops += 1
        end
    end
    if btn then
        for _, fn in ipairs(pressVariants(btn)) do
            if pcall(fn) then break end
        end
        task.wait(0.5)
    end
    if c.Parent and guiVisible(c) then pcall(function() c.Visible = false end) end
end
-- semua jendela shop yang sedang terbuka (kecuali milik `except`)
function V25.openShopWindows(except)
    local mine = except and V25.windowsOf(except) or {}
    local vp = V25.viewport()
    local out = {}
    for _, def in ipairs(SHOPS) do
        if def ~= except then
            for _, w in ipairs(V25.windowsOf(def)) do
                local related = false
                for _, m in ipairs(mine) do if V25.shopRelated(w, m) then related = true; break end end
                if not related and guiVisible(w) and V25.bigOnScreen(w, vp) then table.insert(out, w) end
            end
        end
    end
    return out
end
function V25.closeOtherShops(except)
    for _, w in ipairs(V25.openShopWindows(except)) do
        if w.Parent and guiVisible(w) then V25.closeShopContainer(w) end
    end
end
function V25.closeAllShops()
    local n = 0
    for _ = 1, 3 do
        local list = V25.openShopWindows(nil)
        if #list == 0 then break end
        for _, w in ipairs(list) do
            if w.Parent and guiVisible(w) then V25.closeShopContainer(w); n += 1 end
        end
    end
    return n
end
-- tombol HUD yang cocok dengan shop (hanya yang terlihat; tombol di dalam jendela shop yang sedang tertutup otomatis tidak ikut)
function V25.shopHudButtons(def)
    local out, seen = {}, {}
    for _, exact in ipairs({ true, false }) do
        for _, b in ipairs(findButtons(def.gui, exact)) do
            if not seen[b] and not isCloseButton(b) and shopNameMatch(buttonLabel(b) .. " " .. b.Name, def) then
                seen[b] = true; table.insert(out, b)
            end
        end
    end
    return out
end
-- buka lewat tombol HUD. Setiap tekan DIVERIFIKASI dulu (nama jendela ATAU ada frame besar baru) sebelum menekan lagi,
-- maksimal 3 tekan total. TIDAK ada lagi "paksa tampil" -> tidak ada UI bertumpuk / tak bisa ditutup.
local function tryOpenShopGui(def)
    if shopIsOpen(def) then return true end
    V25.closeOtherShops(def)
    local totalPress = 0
    for bi, b in ipairs(V25.shopHudButtons(def)) do
        if bi > 2 or totalPress >= 3 then break end
        for _, fn in ipairs(pressVariants(b)) do
            if totalPress >= 3 then break end
            if shopIsOpen(def) then return true end
            local before = V25.bigVisible()
            if pcall(fn) then
                totalPress += 1
                local t0 = os.clock()
                while os.clock() - t0 < 2.2 do
                    task.wait(0.2)
                    if shopIsOpen(def) then return true end
                    local w = V25.newWindowSince(before)
                    if w then log("Jendela terbuka: " .. w:GetFullName()); return true end
                end
            end
        end
    end
    return shopIsOpen(def)
end
-- cari prompt/objek dunia untuk shop (cek nama prompt, teks aksi/objek, dan nama induk sampai 5 level)
function V25.findShopWorldTarget(def, hrp)
    local best, bestD = nil, math.huge
    local function chainText(inst)
        local parts, cur, n = {}, inst, 0
        while cur and cur ~= Workspace and n < 5 do table.insert(parts, cur.Name); cur = cur.Parent; n += 1 end
        return table.concat(parts, " ")
    end
    local function excluded(txt)
        local nt = norm(txt)
        for _, ex in ipairs(def.worldExclude or def.exclude or {}) do if nt:find(ex, 1, true) then return true end end
        return false
    end
    for _, d in ipairs(Snapshot.get()) do
        if d.Parent and d:IsA("ProximityPrompt") and not isEggPrompt(d) then
            local chain = chainText(d)
            if (nameHasAny(chain, def.world) or promptMatches(d, def.world)) and not excluded(chain .. " " .. promptText(d)) then
                local pos = getPromptPosition(d)
                if pos then
                    local dist = (pos - hrp.Position).Magnitude
                    if dist < bestD then best, bestD = { prompt = d, pos = pos }, dist end
                end
            end
        end
    end
    if best then return best end
    for _, d in ipairs(Snapshot.get()) do
        if d.Parent and d:IsA("Model") and nameHasAny(d.Name, def.world) and not excluded(d.Name) then
            local pos = getInstPosition(d)
            if pos then
                local dist = (pos - hrp.Position).Magnitude
                if dist < bestD then best, bestD = { pos = pos }, dist end
            end
        end
    end
    return best
end

local shopBusy = false
local function openShop(def)
    if shopBusy then log("Shop masih diproses, tunggu sebentar"); return end
    shopBusy = true
    task.spawn(function()
        local ok, err = pcall(function()
            Lock.run(function()
                if tryOpenShopGui(def) then log("Membuka " .. def.name); return end
                local hrp = getHRP(); if not hrp then return end
                local best = V25.findShopWorldTarget(def, hrp)
                if not best then
                    log(def.name .. ": tombol HUD & objek dunia tidak ditemukan. Pakai 'Scan Shop GUI' di tab Debug.")
                    return
                end
                log("Menuju " .. def.name)
                local before = V25.bigVisible()
                goTo(hrp, best.pos + Vector3.new(0, 3, 3), function() return uiAlive end)
                task.wait(0.4)
                local pr = best.prompt
                if not pr then
                    -- tidak ada prompt di objek itu: pakai prompt non-telur terdekat (<= 20 stud)
                    local h2 = getHRP()
                    local bd = 20
                    for _, d in ipairs(Snapshot.get()) do
                        if d.Parent and d:IsA("ProximityPrompt") and d.Enabled and not isEggPrompt(d) then
                            local pp = getPromptPosition(d)
                            if pp and h2 and (pp - h2.Position).Magnitude < bd then pr, bd = d, (pp - h2.Position).Magnitude end
                        end
                    end
                end
                if not pr then log("Sudah di lokasi " .. def.name .. " tapi tidak ada prompt untuk ditekan."); return end
                for attempt = 1, 2 do
                    triggerPrompt(pr)
                    local t0 = os.clock()
                    while os.clock() - t0 < 3 do
                        task.wait(0.2)
                        if shopIsOpen(def) then log(def.name .. " terbuka"); return end
                        local w = V25.newWindowSince(before)
                        if w then log("Jendela terbuka: " .. w:GetFullName()); return end
                    end
                end
                log(def.name .. ": prompt sudah ditekan tapi UI tidak muncul. Coba 'Scan Shop GUI' & 'Scan Prompt sekitar' (tab Debug).")
            end)
        end)
        if not ok then log("Shop error: " .. tostring(err)) end
        shopBusy = false
    end)
end

local function anyPriorityAutoEnabled()
    if not config.priorityOn then return false end
    for key in pairs(V25.AUTO_META) do if config.auto[key] then return true end end
    return false
end
brainWanted = function()
    return uiAlive and (config.running or anyEventEnabled() or config.treadmillIdle or anyPriorityAutoEnabled())
end
local brainRunning = false
function ensureBrain()
    if brainRunning or not brainWanted() then return end
    brainRunning = true
    task.spawn(function()
        log("AFK manager berjalan")
        local aliveSteal = function() return config.running and uiAlive end
        local aliveEvents = function() return anyEventEnabled() and uiAlive end
        while brainWanted() do
            local did = false
            local ok, err = Lock.run(function()
                local hrp = getHRP()
                if not hrp then task.wait(1); return end
                if config.priorityOn then
                    for _, id in ipairs(config.priority) do
                        if not brainWanted() then break end
                        if id == "steal" then
                            if config.running and stealCycle(aliveSteal) ~= "none" then did = true; return end
                        elseif id == "event" then
                            if anyEventEnabled() and eventStep(aliveEvents) then did = true; return end
                        else
                            local meta = V25.AUTO_META[id]
                            if meta and config.auto[id] and V25.autoDue(id) then
                                V25.lastAutoRun[id] = os.clock()
                                local okA, errA = pcall(meta[2])
                                if not okA then log("Priority " .. meta[1] .. " error: " .. tostring(errA)) end
                                did = true; return
                            end
                        end
                    end
                else
                    if anyEventEnabled() and eventStep(aliveEvents) then did = true; return end
                    if config.running then
                        local res = stealCycle(aliveSteal)
                        if res ~= "none" then did = true; return end
                    end
                end
                if config.treadmillIdle then Treadmill.run(4)
                else task.wait(2.5) end
            end)
            if not ok then releaseAnchor(); log("Error: " .. tostring(err)); task.wait(1) end
            task.wait(did and 0.2 or 0.4)
        end
        brainRunning = false
        setStatus("Idle", THEME.sub)
        log("AFK manager berhenti")
    end)
end

local function containsPoint(inst, pos)
    if inst:IsA("BasePart") then
        local rel = inst.CFrame:PointToObjectSpace(pos)
        return math.abs(rel.X) <= inst.Size.X / 2 + 25 and math.abs(rel.Z) <= inst.Size.Z / 2 + 25 and math.abs(rel.Y) <= inst.Size.Y / 2 + 80
    end
    if inst:IsA("Model") then
        local ok, cf, size = pcall(function() return inst:GetBoundingBox() end)
        if ok then
            local rel = cf:PointToObjectSpace(pos)
            return math.abs(rel.X) <= size.X / 2 + 25 and math.abs(rel.Z) <= size.Z / 2 + 25 and math.abs(rel.Y) <= size.Y / 2 + 80
        end
    end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("BasePart") and (d.Position - pos).Magnitude < 60 then return true end
    end
    return false
end
local function hasEggPrompt(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") and isEggPrompt(d) then return true end
    end
    return false
end
local function isEggRelated(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if cur.Name:lower():find("egg", 1, true) then return true end
        cur = cur.Parent
    end
    return false
end
local plotKeepMine = true
local plotWatcher
local function plotRemovable(d)
    if not d:IsDescendantOf(Workspace) then return false end
    if not (d:IsA("Model") or d:IsA("Folder") or d:IsA("BasePart")) then return false end
    if not nameHas(d.Name, "plot") then return false end
    local char = player.Character
    if char and (char == d or char:IsDescendantOf(d)) then return false end
    if plotKeepMine then
        if ownedByMe(d) then return false end
        if baseCFrame and containsPoint(d, baseCFrame.Position) then return false end
    end
    if hasEggPrompt(d) then return false end
    return true
end
local function removePlots()
    local removed, skipped = 0, 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsDescendantOf(Workspace) and nameHas(d.Name, "plot") then
            if plotRemovable(d) then pcall(function() d:Destroy() end); removed += 1
            else skipped += 1 end
        end
    end
    log(("Plot dihapus: %d (dilewati: %d)"):format(removed, skipped))
end
local function setPlotWatcher(state)
    if plotWatcher then plotWatcher:Disconnect(); plotWatcher = nil end
    if not state then return end
    plotWatcher = Workspace.DescendantAdded:Connect(function(d)
        task.delay(0.1, function()
            if d.Parent and nameHas(d.Name, "plot") and plotRemovable(d) then pcall(function() d:Destroy() end) end
        end)
    end)
    track(plotWatcher)
end
local antiLagConn
local function setAntiLag(state)
    if antiLagConn then antiLagConn:Disconnect(); antiLagConn = nil end
    if not state then return end
    local function clean(v)
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then pcall(function() v.Enabled = false end) end
    end
    task.spawn(function() for _, v in ipairs(Workspace:GetDescendants()) do clean(v) end end)
    antiLagConn = Workspace.DescendantAdded:Connect(clean)
    track(antiLagConn)
end
local function superFpsBoost()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
        end
    end)
    plotKeepMine = true
    removePlots(); setPlotWatcher(true); setAntiLag(true)
    log("Super FPS Boost aktif")
end

do
    local savedVolume
    function V25.setAfkSaver(state)
        config.afkSaver = state and true or false
        if typeof(setfpscap) == "function" then pcall(setfpscap, state and math.clamp(config.fpsCap, 5, 60) or 60) end
        pcall(function()
            local gs = UserSettings():GetService("UserGameSettings")
            if state then savedVolume = savedVolume or gs.MasterVolume; gs.MasterVolume = 0
            elseif savedVolume then gs.MasterVolume = savedVolume; savedVolume = nil end
        end)
    end
end

-- ===== SCAN DEBUG (V35): data nyata dari game supaya skrip tidak menebak =====
do
    local function clip(s, n) s = tostring(s); if #s > n then return s:sub(1, n) .. "..." end return s end
    local function attrStr(inst)
        local parts = {}
        for k, v in pairs(inst:GetAttributes()) do table.insert(parts, tostring(k) .. "=" .. clip(v, 40)) end
        table.sort(parts)
        if #parts == 0 then return "-" end
        while #parts > 12 do table.remove(parts) end
        return table.concat(parts, "; ")
    end
    local function chainText(inst)
        local parts, cur, n = {}, inst, 0
        while cur and cur ~= Workspace and cur ~= game and n < 5 do table.insert(parts, cur.Name); cur = cur.Parent; n += 1 end
        return table.concat(parts, " ")
    end
    local function matchesAny(text, keys)
        local nt = norm(text)
        for _, k in ipairs(keys) do if nt:find(k, 1, true) then return true end end
        return false
    end
    local function distOf(pos, hrp)
        if not (pos and hrp) then return -1 end
        return math.floor((pos - hrp.Position).Magnitude)
    end
    local function valueLine(d)
        if d:IsA("ObjectValue") then return tostring(d.Value and d.Value:GetFullName() or "nil") end
        return tostring(d.Value)
    end

    -- 1) Treadmill: siapa pemiliknya
    function V25.scanTreadmill(dbg)
        local hrp = getHRP()
        dbg("== SCAN TREADMILL ==")
        dbg(("Pemain: %s | display: %s | UserId: %d"):format(player.Name, player.DisplayName, player.UserId))
        local others = {}
        for _, pl in ipairs(Players:GetPlayers()) do if pl ~= player then table.insert(others, pl.Name) end end
        dbg("Pemain lain di server: " .. (#others > 0 and clip(table.concat(others, ", "), 200) or "(tidak ada)"))
        local list = {}
        for _, d in ipairs(Workspace:GetDescendants()) do
            if isTreadmillTop(d) then
                local pos = getInstPosition(d)
                table.insert(list, { inst = d, pos = pos, dist = (pos and hrp) and (pos - hrp.Position).Magnitude or math.huge })
            end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
        dbg(("Treadmill ditemukan: %d (tampil max 6 terdekat)"):format(#list))
        local okF, cur = pcall(findTreadmill)
        if not okF then cur = nil end
        dbg("Plot milikku (papan nama): " .. (V25.myPlot() and V25.myPlot().Name or "TIDAK DITEMUKAN"))
        dbg("Terpilih skrip: " .. (cur and cur:GetFullName() or "belum ada") .. " [" .. tostring(Treadmill.how) .. "]")
        for i, e in ipairs(list) do
            if i > 6 then break end
            local inst = e.inst
            Treadmill.info[inst] = nil
            local verdict = treadmillOwnerInfo(inst)
            local root = treadmillPlotRoot(inst)
            local okOn, onIt = false, false
            if hrp then okOn, onIt = pcall(Treadmill.on, inst, hrp) end
            dbg(("-- #%d %s (%s) | jarak=%d | berdiri di atasnya=%s"):format(i, inst:GetFullName(), inst.ClassName, e.dist == math.huge and -1 or math.floor(e.dist), tostring(okOn and onIt)))
            dbg(("   verdict skrip=%s | ownedByMe(treadmill)=%s | ownedByMe(plot)=%s"):format(tostring(verdict), tostring(ownedByMe(inst)), tostring(ownedByMe(root))))
            dbg("   atribut treadmill: " .. attrStr(inst))
            dbg("   plot root: " .. root:GetFullName() .. " | atribut: " .. attrStr(root))
            local par, n = inst.Parent, 0
            while par and par ~= Workspace and n < 5 do
                dbg(("   induk: %s (%s) | %s"):format(par.Name, par.ClassName, attrStr(par)))
                par = par.Parent; n += 1
            end
            local cnt, shown = 0, 0
            for _, d in ipairs(root:GetDescendants()) do
                cnt += 1; if cnt > 800 or shown >= 14 then break end
                if d:IsA("ValueBase") then
                    shown += 1; dbg(("   value: %s (%s) = %s"):format(d.Name, d.ClassName, clip(valueLine(d), 80)))
                elseif d:IsA("TextLabel") and d.Text ~= "" then
                    shown += 1; dbg(("   teks: %s = '%s'"):format(d.Name, clip(d.Text, 60)))
                elseif d:IsA("ProximityPrompt") then
                    shown += 1; dbg(("   prompt: induk=%s | aksi='%s' | objek='%s'"):format(d.Parent and d.Parent.Name or "?", tostring(d.ActionText), tostring(d.ObjectText)))
                end
            end
        end
    end

    -- 2) Plot / base: cara game menandai plot sendiri
    function V25.scanPlot(dbg)
        local hadBase = baseCFrame ~= nil
        local hrp = getHRP()
        dbg("== SCAN PLOT / BASE ==")
        dbg("Base sudah di-set sebelum scan: " .. tostring(hadBase))
        dbg("Isi Workspace (anak langsung bertipe Model/Folder):")
        local n = 0
        for _, c in ipairs(Workspace:GetChildren()) do
            if c:IsA("Model") or c:IsA("Folder") then
                n += 1; if n > 40 then dbg("   ... dipotong"); break end
                dbg(("   %s (%s) anak=%d | %s"):format(c.Name, c.ClassName, #c:GetChildren(), attrStr(c)))
            end
        end
        local plotsFolder = Workspace:FindFirstChild("Plots")
        if plotsFolder then
            local kids = {}
            for _, c in ipairs(plotsFolder:GetChildren()) do
                local pos = getInstPosition(c)
                table.insert(kids, { inst = c, dist = (pos and hrp) and (pos - hrp.Position).Magnitude or math.huge })
            end
            table.sort(kids, function(a, b) return a.dist < b.dist end)
            dbg(("Workspace.Plots berisi %d plot (urut terdekat dari karaktermu)"):format(#kids))
            local mpn = V25.myPlot()
            dbg("Plot milikku menurut skrip (dari papan nama): " .. (mpn and mpn.Name or "TIDAK DITEMUKAN"))
            for _, e in ipairs(kids) do
                local sign = e.inst:FindFirstChild("PlotSign")
                local lbl = sign and sign:FindFirstChild("PlayerName", true)
                dbg(("   papan nama plot %s = '%s'"):format(e.inst.Name, lbl and lbl:IsA("TextLabel") and lbl.Text or "(tidak ada)"))
            end
            for i, e in ipairs(kids) do
                local c = e.inst
                dbg(("-- plot %s (%s) | jarak=%d | ownedByMe=%s | atribut: %s"):format(
                    c.Name, c.ClassName, e.dist == math.huge and -1 or math.floor(e.dist), tostring(ownedByMe(c)), attrStr(c)))
                if i <= 3 then
                    -- detail penuh untuk 3 plot terdekat: anak langsung + atribut, lalu value/teks/prompt di dalamnya
                    for _, ch in ipairs(c:GetChildren()) do
                        dbg(("   anak: %s (%s) | %s"):format(ch.Name, ch.ClassName, attrStr(ch)))
                    end
                    local cnt, shown = 0, 0
                    for _, v in ipairs(c:GetDescendants()) do
                        cnt += 1; if cnt > 1500 or shown >= 40 then break end
                        local rel = v:GetFullName():sub(#c:GetFullName() + 2)
                        if v:IsA("ValueBase") then shown += 1; dbg(("   value %s (%s) = %s"):format(rel, v.ClassName, clip(valueLine(v), 70)))
                        elseif v:IsA("TextLabel") and v.Text ~= "" then shown += 1; dbg(("   teks %s = '%s'"):format(rel, clip(v.Text, 60)))
                        elseif v:IsA("ProximityPrompt") then shown += 1; dbg(("   prompt %s | aksi='%s' | objek='%s'"):format(rel, tostring(v.ActionText), tostring(v.ObjectText))) end
                    end
                end
            end
            return
        end
        local plots = {}
        for _, d in ipairs(Workspace:GetDescendants()) do
            if (d:IsA("Model") or d:IsA("Folder")) and nameHas(d.Name, "plot") then
                local pos = d:IsA("Model") and getInstPosition(d) or nil
                table.insert(plots, { inst = d, dist = (pos and hrp) and (pos - hrp.Position).Magnitude or math.huge })
            end
        end
        table.sort(plots, function(a, b) return a.dist < b.dist end)
        dbg(("Objek bernama 'plot': %d (tampil max 10 terdekat)"):format(#plots))
        for i, e in ipairs(plots) do
            if i > 10 then break end
            local d = e.inst
            dbg(("-- #%d %s (%s) | jarak=%d | milikku=%s"):format(i, d:GetFullName(), d.ClassName, e.dist == math.huge and -1 or math.floor(e.dist), tostring(ownedByMe(d))))
            dbg("   atribut: " .. attrStr(d))
            local cnt, shown = 0, 0
            for _, v in ipairs(d:GetDescendants()) do
                cnt += 1; if cnt > 500 or shown >= 6 then break end
                if v:IsA("ValueBase") then shown += 1; dbg(("   value: %s = %s"):format(v.Name, clip(valueLine(v), 60)))
                elseif v:IsA("TextLabel") and v.Text ~= "" then shown += 1; dbg(("   teks: %s = '%s'"):format(v.Name, clip(v.Text, 50))) end
            end
        end
    end

    -- 3) Data pemain (stats, leaderstats, atribut)
    function V25.scanPlayerData(dbg)
        dbg("== SCAN DATA PEMAIN ==")
        dbg("Atribut Player: " .. attrStr(player))
        for _, c in ipairs(player:GetChildren()) do
            if c.Name ~= "Backpack" and c.Name ~= "PlayerGui" and c.Name ~= "PlayerScripts" then
                local line = ("%s (%s)"):format(c.Name, c.ClassName)
                if c:IsA("ValueBase") then line = line .. " = " .. clip(valueLine(c), 60) end
                dbg("  " .. line)
                if c:IsA("Folder") or c:IsA("Configuration") then
                    local k = 0
                    for _, v in ipairs(c:GetDescendants()) do
                        k += 1; if k > 30 then dbg("    ... dipotong"); break end
                        dbg(("    %s (%s)%s"):format(v.Name, v.ClassName, v:IsA("ValueBase") and (" = " .. clip(valueLine(v), 60)) or ""))
                    end
                end
            end
        end
        local char = player.Character
        if char then
            dbg("Atribut Character: " .. attrStr(char))
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then dbg(("Humanoid: WalkSpeed=%s | JumpPower=%s | Health=%s/%s"):format(tostring(hum.WalkSpeed), tostring(hum.JumpPower), tostring(math.floor(hum.Health)), tostring(math.floor(hum.MaxHealth)))) end
        end
    end

    -- 4) Lab Dr. Scramble / Experiment Shop: tombol HUD, prompt, NPC
    function V25.scanLab(dbg)
        local hrp = getHRP()
        local keys = { "lab", "laboratory", "scramble", "drscramble", "experiment", "scientist" }
        dbg("== SCAN LAB DR. SCRAMBLE / EXPERIMENT ==")
        dbg("[GUI] tombol yang cocok (ditandai terlihat/tidak):")
        local n = 0
        for _, b in ipairs(playerGui:GetDescendants()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and not b:IsDescendantOf(sg) then
                local label = buttonLabel(b)
                if matchesAny(b.Name .. " " .. label .. " " .. b.Parent.Name, keys) then
                    n += 1; if n > 25 then dbg("   ... dipotong"); break end
                    dbg(("   %s | teks='%s' | terlihat=%s"):format(b:GetFullName(), clip(label, 40), tostring(guiVisible(b))))
                end
            end
        end
        if n == 0 then dbg("   (tidak ada tombol GUI yang cocok)") end
        dbg("[DUNIA] Model yang namanya cocok:")
        n = 0
        for _, m in ipairs(Workspace:GetDescendants()) do
            if m:IsA("Model") and matchesAny(m.Name, keys) then
                n += 1; if n > 15 then dbg("   ... dipotong"); break end
                dbg(("   %s | jarak=%d | punya Humanoid=%s"):format(m:GetFullName(), distOf(getInstPosition(m), hrp), tostring(m:FindFirstChildOfClass("Humanoid") ~= nil)))
            end
        end
        dbg("[PROMPT] ProximityPrompt yang cocok (jarak berapa pun):")
        n = 0
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") and matchesAny(chainText(p) .. " " .. tostring(p.ActionText) .. " " .. tostring(p.ObjectText), keys) then
                n += 1; if n > 15 then dbg("   ... dipotong"); break end
                dbg(("   %s | aksi='%s' | objek='%s' | jarak=%d | aktif=%s | maxJarak=%s | tahan=%s"):format(
                    p:GetFullName(), tostring(p.ActionText), tostring(p.ObjectText), distOf(getPromptPosition(p), hrp),
                    tostring(p.Enabled), tostring(p.MaxActivationDistance), tostring(p.HoldDuration)))
            end
        end
        if n == 0 then dbg("   (tidak ada)") end
        dbg("[PROMPT] semua prompt dalam 25 stud dari karaktermu (berdiri dekat NPC/lab dulu):")
        n = 0
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                local pos = getPromptPosition(p)
                if pos and hrp and (pos - hrp.Position).Magnitude <= 25 then
                    n += 1; if n > 10 then dbg("   ... dipotong"); break end
                    dbg(("   %s | aksi='%s' | objek='%s'"):format(p:GetFullName(), tostring(p.ActionText), tostring(p.ObjectText)))
                end
            end
        end
        if n == 0 then dbg("   (tidak ada)") end
        dbg("[NPC] model ber-Humanoid (bukan pemain) dalam 80 stud / namanya cocok:")
        n = 0
        for _, h in ipairs(Workspace:GetDescendants()) do
            if h:IsA("Humanoid") and h.Parent and h.Parent:IsA("Model") and not Players:GetPlayerFromCharacter(h.Parent) then
                local m = h.Parent
                local pos = getInstPosition(m)
                local dd = distOf(pos, hrp)
                if matchesAny(m.Name, keys) or (dd >= 0 and dd <= 80) then
                    n += 1; if n > 12 then dbg("   ... dipotong"); break end
                    dbg(("   %s | jarak=%d | atribut: %s"):format(m:GetFullName(), dd, attrStr(m)))
                end
            end
        end
        if n == 0 then dbg("   (tidak ada)") end
        dbg("[CLICK] ClickDetector yang cocok:")
        n = 0
        for _, c in ipairs(Workspace:GetDescendants()) do
            if c:IsA("ClickDetector") and matchesAny(chainText(c), keys) then
                n += 1; if n > 8 then break end
                dbg("   " .. c:GetFullName())
            end
        end
        if n == 0 then dbg("   (tidak ada)") end
    end

    -- 5) Jendela GUI yang sedang terbuka (jalankan sebelum & sesudah membuka shop, lalu bandingkan)
    function V25.scanWindows(dbg)
        dbg("== SCAN JENDELA / GUI AKTIF ==")
        for _, g in ipairs(playerGui:GetChildren()) do
            if g:IsA("ScreenGui") and g ~= sg then
                dbg(("ScreenGui %s | Enabled=%s | DisplayOrder=%d | anak=%d"):format(g.Name, tostring(g.Enabled), g.DisplayOrder, #g:GetChildren()))
            end
        end
        dbg("Jendela besar yang sedang terlihat (>=250x150):")
        local n = 0
        for _, d in ipairs(playerGui:GetDescendants()) do
            if (d:IsA("Frame") or d:IsA("ScrollingFrame") or d:IsA("ImageLabel")) and not d:IsDescendantOf(sg) then
                local sz = d.AbsoluteSize
                if sz.X >= 250 and sz.Y >= 150 and guiVisible(d) then
                    n += 1; if n > 25 then dbg("   ... dipotong"); break end
                    local titles, k = {}, 0
                    for _, t in ipairs(d:GetDescendants()) do
                        if t:IsA("TextLabel") and t.Text ~= "" and guiVisible(t) then
                            k += 1; table.insert(titles, clip(t.Text, 24))
                            if k >= 4 then break end
                        end
                    end
                    dbg(("   %s | %dx%d | teks: %s"):format(d:GetFullName(), math.floor(sz.X), math.floor(sz.Y), table.concat(titles, " / ")))
                end
            end
        end
        if n == 0 then dbg("   (tidak ada jendela besar terlihat)") end
    end

    -- 6) Detail telur untuk webhook (nama, rarity, variant, size, gambar)
    function V25.scanEggDetail(dbg)
        local hrp = getHRP()
        dbg("== SCAN DETAIL TELUR / WEBHOOK (3 terdekat) ==")
        local list = {}
        for _, p in ipairs(collectEggPrompts()) do
            local pos = getPromptPosition(p)
            if pos then table.insert(list, { p = p, d = hrp and (pos - hrp.Position).Magnitude or 0 }) end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        if #list == 0 then dbg("Tidak ada prompt telur"); return end
        for i = 1, math.min(3, #list) do
            local root = getEggRoot(list[i].p)
            local rootName = root:GetFullName()
            dbg(("-- #%d %s (%s) | jarak=%d"):format(i, rootName, root.ClassName, math.floor(list[i].d)))
            dbg("   atribut: " .. attrStr(root))
            local sizeV
            if root:IsA("Model") then
                local okB, _, sz = pcall(function() return root:GetBoundingBox() end)
                if okB then sizeV = sz end
            elseif root:IsA("BasePart") then sizeV = root.Size end
            if sizeV then dbg(("   ukuran fisik: %.1f x %.1f x %.1f"):format(sizeV.X, sizeV.Y, sizeV.Z)) end
            local cnt, shown = 0, 0
            for _, d in ipairs(root:GetDescendants()) do
                cnt += 1; if cnt > 400 or shown >= 40 then break end
                local rel = d:GetFullName():sub(#rootName + 2)
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    if d.Text ~= "" then shown += 1; dbg(("   teks %s = '%s'"):format(rel, clip(d.Text, 50))) end
                elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                    shown += 1; dbg(("   gambar %s = %s"):format(rel, tostring(d.Image)))
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    shown += 1; dbg(("   decal %s = %s"):format(rel, tostring(d.Texture)))
                elseif d:IsA("MeshPart") then
                    if d.TextureID ~= "" then shown += 1; dbg(("   meshpart %s tekstur = %s"):format(rel, tostring(d.TextureID))) end
                elseif d:IsA("ValueBase") then
                    shown += 1; dbg(("   value %s = %s"):format(rel, clip(valueLine(d), 60)))
                elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                    shown += 1; dbg("   gui3d " .. rel)
                end
            end
            local okD, info = pcall(describeEgg, root)
            if okD and type(info) == "table" then
                dbg(("   HASIL SKRIP -> nama=%s | rarity=%s | variant=%s | size=%s | imageId=%s"):format(
                    tostring(info.name), tostring(info.rarity), tostring(info.variant), tostring(info.size), tostring(info.imageId)))
                local okI, url = pcall(resolveEggImage, info)
                dbg("   URL gambar: " .. ((okI and url) and tostring(url) or "TIDAK DAPAT (isi EGG_IMAGE_URLS manual atau kirim data di atas)"))
            else
                dbg("   describeEgg error: " .. tostring(info))
            end
        end
    end

    -- 7) Remote penting (nama yang berkaitan shop/lab/treadmill/telur dst)
    function V25.scanRemotesKey(dbg)
        local keys = { "shop", "lab", "scramble", "open", "buy", "purchase", "sell", "treadmill", "egg", "steal", "claim", "upgrade", "pet", "favorite", "equip", "place", "boss", "event", "experiment", "teleport", "gui", "menu", "hatch", "collect", "incubat", "slot", "pen" }
        dbg("== SCAN REMOTE PENTING ==")
        local total, n = 0, 0
        for _, root in ipairs({ game:GetService("ReplicatedStorage"), Workspace }) do
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") then
                    total += 1
                    if matchesAny(d:GetFullName(), keys) then
                        n += 1
                        if n <= 120 then dbg(d.ClassName .. " | " .. d:GetFullName()) end
                    end
                end
            end
        end
        dbg(("Total remote/event: %d | cocok kata kunci: %d%s"):format(total, n, n > 120 and " (dipotong 120)" or ""))
    end

    -- (V38) Spy Remote dibuang total: tidak ada hookmetamethod.

    -- 8) Event / boss (Dr. Scramble Mecha & Drone, dll) + timer di GUI
    function V25.scanEvents(dbg)
        local hrp = getHRP()
        local keys = { "scramble", "mecha", "drone", "boss", "overlord", "meteor", "event" }
        dbg("== SCAN EVENT / BOSS ==")
        dbg("[DUNIA] model yang cocok:")
        local n = 0
        for _, m in ipairs(Workspace:GetDescendants()) do
            if m:IsA("Model") and matchesAny(m.Name, keys) and not nameHas(m.Name, "label") then
                n += 1; if n > 20 then dbg("   ... dipotong"); break end
                local hum = m:FindFirstChildOfClass("Humanoid")
                dbg(("   %s | jarak=%d | HP=%s | atribut: %s"):format(m:GetFullName(), distOf(getInstPosition(m), hrp),
                    hum and (math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or "-", attrStr(m)))
            end
        end
        if n == 0 then dbg("   (tidak ada)") end
        dbg("[GUI] teks terlihat tentang event/boss/timer:")
        n = 0
        for _, t in ipairs(playerGui:GetDescendants()) do
            if t:IsA("TextLabel") and t.Text ~= "" and not t:IsDescendantOf(sg) and guiVisible(t) then
                if matchesAny(t.Text, keys) or t.Text:match("%d+:%d%d") then
                    n += 1; if n > 15 then dbg("   ... dipotong"); break end
                    dbg(("   %s = '%s'"):format(t:GetFullName(), clip(t.Text, 70)))
                end
            end
        end
        if n == 0 then dbg("   (tidak ada)") end
    end
    -- 9) Place / Hatch: apa yang sebenarnya ada di plot sendiri untuk menaruh & menetaskan telur
    function V25.scanPlaceHatch(dbg)
        local hrp = getHRP()
        local keys = { "hatch", "place", "collect", "incubat", "claim", "ready", "slot", "pen" }
        dbg("== SCAN PLACE / HATCH ==")
        local plot = V25.myPlot()
        dbg("Plot milikku: " .. (plot and plot.Name or "TIDAK DITEMUKAN"))
        if plot then
            dbg("[POHON PLOT] kedalaman maks 3:")
            local lines = 0
            local function walk(inst, depth)
                for _, ch in ipairs(inst:GetChildren()) do
                    lines += 1
                    if lines > 150 then return end
                    dbg(("%s%s (%s) | %s"):format(string.rep("  ", depth), ch.Name, ch.ClassName, attrStr(ch)))
                    if depth < 3 then walk(ch, depth + 1) end
                end
            end
            walk(plot, 1)
            if lines > 150 then dbg("   ... dipotong 150 baris") end
            dbg("[PROMPT di plotku]:")
            local n = 0
            local base = #plot:GetFullName() + 2
            for _, p in ipairs(plot:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    n += 1; if n > 30 then dbg("   ... dipotong"); break end
                    dbg(("   %s | aksi='%s' | objek='%s' | aktif=%s | jarak=%d"):format(
                        p:GetFullName():sub(base), tostring(p.ActionText), tostring(p.ObjectText), tostring(p.Enabled), distOf(getPromptPosition(p), hrp)))
                end
            end
            if n == 0 then dbg("   (tidak ada)") end
        end
        for _, fname in ipairs({ "PlacedEggRenders", "Eggs" }) do
            local f = Workspace:FindFirstChild(fname)
            dbg(("[%s] %s"):format(fname, f and ("anak=" .. #f:GetChildren()) or "tidak ada"))
            if f then
                for i, ch in ipairs(f:GetChildren()) do
                    if i > 8 then dbg("   ... dipotong"); break end
                    dbg(("   %s (%s) | jarak=%d | milikku=%s | atribut: %s"):format(ch.Name, ch.ClassName, distOf(getInstPosition(ch), hrp), tostring(ownedByMe(ch)), attrStr(ch)))
                    local k = 0
                    for _, d in ipairs(ch:GetDescendants()) do
                        if k >= 6 then break end
                        if d:IsA("TextLabel") and d.Text ~= "" then k += 1; dbg(("      teks %s = '%s'"):format(d.Name, clip(d.Text, 50)))
                        elseif d:IsA("ProximityPrompt") then k += 1; dbg(("      prompt aksi='%s' | objek='%s'"):format(tostring(d.ActionText), tostring(d.ObjectText)))
                        elseif d:IsA("ValueBase") then k += 1; dbg(("      value %s = %s"):format(d.Name, clip(valueLine(d), 50))) end
                    end
                end
            end
        end
        dbg("[PROMPT dunia] aksi/objek berisi hatch/place/collect/dst (jarak berapa pun):")
        local n2 = 0
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") and matchesAny(tostring(p.ActionText) .. " " .. tostring(p.ObjectText), keys) then
                n2 += 1; if n2 > 20 then dbg("   ... dipotong"); break end
                dbg(("   %s | aksi='%s' | objek='%s' | jarak=%d"):format(p:GetFullName(), tostring(p.ActionText), tostring(p.ObjectText), distOf(getPromptPosition(p), hrp)))
            end
        end
        if n2 == 0 then dbg("   (tidak ada)") end
        dbg("[GUI] tombol terlihat yang cocok hatch/place/collect/dst:")
        local n3 = 0
        for _, b in ipairs(playerGui:GetDescendants()) do
            if (b:IsA("TextButton") or b:IsA("ImageButton")) and not b:IsDescendantOf(sg) and guiVisible(b) then
                local label = buttonLabel(b)
                if matchesAny(b.Name .. " " .. label, keys) then
                    n3 += 1; if n3 > 25 then dbg("   ... dipotong"); break end
                    dbg(("   %s | teks='%s'"):format(b:GetFullName(), clip(label, 40)))
                end
            end
        end
        if n3 == 0 then dbg("   (tidak ada)") end
        dbg("[BACKPACK / TOOL TELUR]")
        pcall(V25.scanBackpack, dbg)
    end

    -- 10) Kamus telur: nilai rarity/variant/size/atribut/teks yang BENAR-BENAR ada di game + uji filter skrip
    function V25.scanEggVocab(dbg)
        dbg("== SCAN KAMUS TELUR ==")
        local roots, seen = {}, {}
        local function add(r) if r and not seen[r] then seen[r] = true; table.insert(roots, r) end end
        for _, p in ipairs(collectEggPrompts()) do add(getEggRoot(p)) end
        for _, fname in ipairs({ "PlacedEggRenders", "Eggs" }) do
            local f = Workspace:FindFirstChild(fname)
            if f then for _, ch in ipairs(f:GetChildren()) do add(ch) end end
        end
        for _, t in ipairs(player.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("egg", 1, true) then add(t) end
        end
        dbg(("Telur dianalisis: %d"):format(#roots))
        if #roots == 0 then return end
        local names, attrCount, texts = {}, {}, {}
        local function bump(map, key) map[key] = (map[key] or 0) + 1 end
        local function dump(title, map, maxN)
            local arr = {}
            for k, v in pairs(map) do table.insert(arr, { k = k, v = v }) end
            table.sort(arr, function(a, b) if a.v ~= b.v then return a.v > b.v end return a.k < b.k end)
            dbg(title .. " (" .. #arr .. " unik)")
            for i, e in ipairs(arr) do
                if i > maxN then dbg("   ... dipotong"); break end
                dbg(("   %s  x%d"):format(e.k, e.v))
            end
        end
        for _, r in ipairs(roots) do
            bump(names, r.Name)
            for k, v in pairs(r:GetAttributes()) do
                attrCount[k] = attrCount[k] or {}
                bump(attrCount[k], clip(tostring(v), 40))
            end
            local c = 0
            for _, d in ipairs(r:GetDescendants()) do
                c += 1; if c > 300 then break end
                if d:IsA("TextLabel") and d.Text ~= "" then bump(texts, clip(d.Text, 40)) end
            end
        end
        dump("[NAMA objek telur]", names, 40)
        local keysSorted = {}
        for k in pairs(attrCount) do table.insert(keysSorted, k) end
        table.sort(keysSorted)
        for _, k in ipairs(keysSorted) do dump("[ATRIBUT " .. k .. "]", attrCount[k], 25) end
        dump("[TEKS di dalam telur]", texts, 50)
        dbg("[UJI FILTER SKRIP] jumlah telur yang cocok per opsi (0 = opsi tidak pernah terlihat):")
        local texts2 = {}
        for _, r in ipairs(roots) do
            local ok, t = pcall(collectEggText, r)
            texts2[r] = (ok and type(t) == "string") and t or r.Name:lower()
        end
        for _, entry in ipairs(FILTERS) do
            local line = {}
            for _, o in ipairs(entry[2]) do
                local cnt = 0
                for _, r in ipairs(roots) do
                    local ok, hit = pcall(matchesValue, r, texts2[r], o)
                    if ok and hit then cnt += 1 end
                end
                table.insert(line, o .. "=" .. cnt)
            end
            dbg("   " .. entry[1] .. ": " .. table.concat(line, ", "))
        end
    end
    -- 11) Struktur telur: hubungan prompt <-> model visual, pemilik telur terpasang, katalog NewEggs
    function V25.scanEggStruct(dbg)
        local hrp = getHRP()
        dbg("== SCAN STRUKTUR TELUR ==")
        local myPrefix = tostring(player.UserId) .. "_"
        local function tree(inst, maxDepth, maxLines, indent)
            local lines = 0
            local function walk(node, depth)
                for _, ch in ipairs(node:GetChildren()) do
                    lines += 1
                    if lines > maxLines then return end
                    local extra = ""
                    if ch:IsA("MeshPart") then extra = " mesh=" .. tostring(ch.MeshId) .. " tex=" .. tostring(ch.TextureID)
                    elseif ch:IsA("SpecialMesh") then extra = " mesh=" .. tostring(ch.MeshId) .. " tex=" .. tostring(ch.TextureId)
                    elseif ch:IsA("TextLabel") then extra = " text='" .. clip(ch.Text, 30) .. "'"
                    elseif ch:IsA("ValueBase") then extra = " = " .. clip(valueLine(ch), 40) end
                    dbg(("%s%s (%s)%s | %s"):format(indent .. string.rep("  ", depth), ch.Name, ch.ClassName, extra, attrStr(ch)))
                    if depth < maxDepth then walk(ch, depth + 1) end
                end
            end
            walk(inst, 1)
            if lines > maxLines then dbg(indent .. "  ... dipotong") end
        end
        local list = {}
        for _, p in ipairs(collectEggPrompts()) do
            local pos = getPromptPosition(p)
            if pos then table.insert(list, { p = p, pos = pos, d = hrp and (pos - hrp.Position).Magnitude or 0 }) end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        dbg(("Prompt telur: %d (detail 4 terdekat)"):format(#list))
        local visualFolders = {}
        for _, fname in ipairs({ "PlacedEggRenders", "AreaEggSlotsClient", "Eggs" }) do
            local f = Workspace:FindFirstChild(fname)
            if f then table.insert(visualFolders, f) end
        end
        for i = 1, math.min(4, #list) do
            local e = list[i]
            local p = e.p
            dbg(("-- #%d %s | jarak=%d"):format(i, p:GetFullName(), math.floor(e.d)))
            dbg(("   aksi='%s' | objek='%s' | aktif=%s | tahan=%s | atribut prompt: %s"):format(
                tostring(p.ActionText), tostring(p.ObjectText), tostring(p.Enabled), tostring(p.HoldDuration), attrStr(p)))
            local par, n = p.Parent, 0
            while par and par ~= Workspace and n < 6 do
                dbg(("   induk: %s (%s) | %s"):format(par.Name, par.ClassName, attrStr(par)))
                par = par.Parent; n += 1
            end
            local best, bd = nil, 15
            for _, f in ipairs(visualFolders) do
                for _, ch in ipairs(f:GetChildren()) do
                    local cp = getInstPosition(ch)
                    if cp then
                        local dd = (cp - e.pos).Magnitude
                        if dd < bd then best, bd = ch, dd end
                    end
                end
            end
            if best then
                dbg(("   visual terdekat: %s | selisih=%.1f stud | atribut: %s"):format(best:GetFullName(), bd, attrStr(best)))
                tree(best, 3, 40, "      ")
            else
                dbg("   (tidak ada visual di PlacedEggRenders/AreaEggSlotsClient/Eggs dalam 15 stud)")
            end
        end
        local pf = Workspace:FindFirstChild("PlacedEggRenders")
        if pf then
            local owners = {}
            for _, ch in ipairs(pf:GetChildren()) do
                local id = ch.Name:match("^(%d+)_")
                if id then owners[id] = (owners[id] or 0) + 1 end
            end
            local arr = {}
            for id, c in pairs(owners) do
                local who = (id == tostring(player.UserId)) and "AKU" or "?"
                for _, pl in ipairs(Players:GetPlayers()) do if tostring(pl.UserId) == id then who = pl.Name end end
                table.insert(arr, id .. "=" .. c .. " (" .. who .. ")")
            end
            table.sort(arr)
            dbg("Pemilik telur di PlacedEggRenders (awalan nama = UserId?): " .. (#arr > 0 and table.concat(arr, ", ") or "-"))
            dbg("[TELUR YANG KAMU TARUH] awalan " .. myPrefix .. " (maks 3):")
            local cnt = 0
            for _, ch in ipairs(pf:GetChildren()) do
                if ch.Name:sub(1, #myPrefix) == myPrefix then
                    cnt += 1
                    if cnt > 3 then break end
                    dbg(("   %s (%s) | jarak=%d | atribut: %s"):format(ch.Name, ch.ClassName, distOf(getInstPosition(ch), hrp), attrStr(ch)))
                    tree(ch, 3, 40, "      ")
                end
            end
            if cnt == 0 then dbg("   (tidak ada)") end
        else
            dbg("Workspace.PlacedEggRenders tidak ada")
        end
        dbg("[KATALOG NewEggs]")
        local cat = Workspace:FindFirstChild("NewEggs", true) or game:GetService("ReplicatedStorage"):FindFirstChild("NewEggs", true)
        if cat then
            local kids = cat:GetChildren()
            dbg(("   %s | anak=%d | atribut: %s"):format(cat:GetFullName(), #kids, attrStr(cat)))
            local names = {}
            for i, k in ipairs(kids) do
                if i > 60 then break end
                table.insert(names, k.Name)
            end
            dbg("   nama: " .. table.concat(names, ", "))
            for i = 1, math.min(2, #kids) do
                dbg(("   contoh %s (%s) | atribut: %s"):format(kids[i].Name, kids[i].ClassName, attrStr(kids[i])))
                tree(kids[i], 2, 20, "      ")
            end
        else
            dbg("   (folder NewEggs tidak ditemukan di Workspace/ReplicatedStorage)")
        end
    end
    -- 12) Telur yang dibawa / tool / ringkasan slot area (sumber nama, rarity, variant, size)
    function V25.scanEggItem(dbg)
        dbg("== SCAN TELUR DIBAWA / TOOL / SLOT AREA ==")
        local char = player.Character
        dbg("Atribut Player: " .. attrStr(player))
        if char then dbg("Atribut Character: " .. attrStr(char)) end
        local function tree(inst, maxDepth, maxLines, indent)
            local lines = 0
            local function walk(node, depth)
                for _, ch in ipairs(node:GetChildren()) do
                    lines += 1
                    if lines > maxLines then return end
                    local extra = ""
                    if ch:IsA("MeshPart") then extra = " mesh=" .. tostring(ch.MeshId) .. " tex=" .. tostring(ch.TextureID)
                    elseif ch:IsA("SpecialMesh") then extra = " mesh=" .. tostring(ch.MeshId) .. " tex=" .. tostring(ch.TextureId)
                    elseif ch:IsA("TextLabel") then extra = " text='" .. clip(ch.Text, 30) .. "'"
                    elseif ch:IsA("ValueBase") then extra = " = " .. clip(valueLine(ch), 40) end
                    dbg(("%s%s (%s)%s | %s"):format(indent .. string.rep("  ", depth), ch.Name, ch.ClassName, extra, attrStr(ch)))
                    if depth < maxDepth then walk(ch, depth + 1) end
                end
            end
            walk(inst, 1)
            if lines > maxLines then dbg(indent .. "  ... dipotong") end
        end
        local tools = {}
        if char then
            for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(tools, { t = t, where = "Character" }) end end
        end
        for _, t in ipairs(player.Backpack:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, { t = t, where = "Backpack" }) end
        end
        dbg(("[TOOL] jumlah: %d"):format(#tools))
        do
            local counts = {}
            for _, e in ipairs(tools) do
                local it = tostring(e.t:GetAttribute("ItemType") or "?")
                counts[it] = (counts[it] or 0) + 1
            end
            local parts = {}
            for it, c in pairs(counts) do table.insert(parts, it .. "=" .. c) end
            table.sort(parts)
            dbg("[TOOL] ringkasan ItemType: " .. table.concat(parts, ", "))
            -- item bukan pet (telur / gear) ditaruh paling atas supaya tidak terpotong
            local function rank(e)
                if e.where == "Character" then return 0 end
                if e.t:GetAttribute("ItemType") ~= "Asset" then return 1 end
                return 2
            end
            for i, e in ipairs(tools) do e.i = i end
            table.sort(tools, function(a, b)
                local ra, rb = rank(a), rank(b)
                if ra ~= rb then return ra < rb end
                return a.i < b.i
            end)
        end
        local detailed = 0
        for i, e in ipairs(tools) do
            if i > 40 then dbg("   ... dipotong"); break end
            local t = e.t
            dbg(("   %s | %s (%s) | atribut: %s"):format(e.where, t.Name, t.ClassName, attrStr(t)))
            local eggLike = matchesAny(t.Name .. " " .. attrStr(t), { "egg" })
            if (eggLike or e.where == "Character") and detailed < 4 then
                detailed += 1
                tree(t, 3, 40, "        ")
            end
        end
        dbg("[OBJEK bernama 'egg' di Character (telur yang sedang dibawa)]:")
        local k = 0
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d.Name:lower():find("egg", 1, true) then
                    k += 1
                    if k > 6 then dbg("   ... dipotong"); break end
                    dbg(("   %s (%s) | atribut: %s"):format(d:GetFullName(), d.ClassName, attrStr(d)))
                    if k <= 2 then tree(d, 2, 20, "        ") end
                end
            end
        end
        if k == 0 then dbg("   (tidak ada)") end
        local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
        if folder then
            local groups, sig = {}, {}
            for _, ch in ipairs(folder:GetChildren()) do
                local kind, uid, _, area = ch.Name:match("^(.-)_(%d+)_(%d+)_([^:]+):Slot_%d+")
                local key = kind and (kind .. " uid=" .. uid .. " area=" .. area) or ("(format lain) " .. ch.Name)
                groups[key] = (groups[key] or 0) + 1
                local ids = {}
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("MeshPart") then table.insert(ids, tostring(d.MeshId):match("%d+") or "?") end
                end
                table.sort(ids)
                local sg2 = table.concat(ids, "+")
                sig[sg2] = sig[sg2] or { n = 0, ex = ch.Name }
                sig[sg2].n += 1
            end
            dbg("[SLOT AREA] AreaEggSlotsClient dikelompokkan (jenis, pemilik, area):")
            local n = 0
            for key, c in pairs(groups) do
                n += 1; if n > 20 then dbg("   ... dipotong"); break end
                dbg(("   %s x%d"):format(key, c))
            end
            dbg("[SLOT AREA] jenis visual (gabungan MeshId) dan jumlahnya:")
            n = 0
            for s, v in pairs(sig) do
                n += 1; if n > 20 then dbg("   ... dipotong"); break end
                dbg(("   %s x%d | contoh %s"):format(clip(s, 80), v.n, v.ex))
            end
        else
            dbg("Workspace.AreaEggSlotsClient tidak ada")
        end
    end
end

do
    local saved = {}      -- ScreenGui game -> status Enabled sebelum disembunyikan
    local loopToken = 0
    local function hide(g)
        if g == sg or not g:IsA("ScreenGui") then return end
        if saved[g] == nil then saved[g] = g.Enabled end
        if g.Enabled then pcall(function() g.Enabled = false end) end
    end
    -- V38: hanya ScreenGui.Enabled = false di PlayerGui (tanpa StarterGui:SetCoreGuiEnabled)
    function V25.setHideAllGui(state)
        state = state and true or false
        V25.hideGuiOn = state
        loopToken += 1
        local my = loopToken
        if state then
            task.spawn(function()
                -- ulangi supaya GUI baru / GUI yang dinyalakan game ikut tersembunyi
                while uiAlive and V25.hideGuiOn and loopToken == my do
                    for _, g in ipairs(playerGui:GetChildren()) do hide(g) end
                    task.wait(0.5)
                end
            end)
        else
            for g, was in pairs(saved) do
                if g.Parent then pcall(function() g.Enabled = was end) end
            end
            table.clear(saved)
        end
    end
end

local function cleanup()
    uiAlive = false
    if V25.hideGuiOn then pcall(V25.setHideAllGui, false) end
    config.running = false; config.treadmillIdle = false
    config.statsWebhookOn = false; config.eggWebhookOn = false
    config.priorityOn = false; config.eggPredict = false
    if config.afkSaver then pcall(V25.setAfkSaver, false) end
    for k in pairs(config.events) do config.events[k] = false end
    for k in pairs(config.auto) do config.auto[k] = false end
    Protect.flying = false; Protect.treadmillActive = false
    pcall(releaseAnchor)
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    for _, c in ipairs(popupConns) do pcall(function() c:Disconnect() end) end
    table.clear(popupConns)
    if antiLagConn then pcall(function() antiLagConn:Disconnect() end) end
    if plotWatcher then pcall(function() plotWatcher:Disconnect() end) end
    local _, hum = getChar()
    if hum then
        pcall(function()
            hum:Move(Vector3.zero, false); hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        end)
    end
    if sg then pcall(function() sg:Destroy() end) end
end
local EX_STEAL_EGG_CLEANUP = cleanup

-- ==========================================
-- UI
-- ==========================================
local function buildUI()
    local camera = Workspace.CurrentCamera
    local vp = camera and camera.ViewportSize or Vector2.new(900, 600)
    local W = math.max(300, math.min(config.winW, vp.X - 16))
    local H = math.max(230, math.min(config.winH, vp.Y - 16))
    local SIDE = 86
    local FONT_B, FONT_M, FONT_R = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.Gotham
    local WHITE = Color3.new(1, 1, 1)
    local orderCounter = 0

    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if o:IsA("GuiObject") and props.LayoutOrder == nil then
            orderCounter += 1; o.LayoutOrder = orderCounter
        end
        if parent then o.Parent = parent end
        return o
    end
    local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
    local function fit(frame, layout)
        local function upd() frame.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y) end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd); upd()
    end
    local function makeDraggable(handle, target)
        local state = { moved = false }
        local dragging, dragStart, startPos = false, nil, nil
        track(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; state.moved = false; dragStart = input.Position; startPos = target.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false; if conn then conn:Disconnect() end end
                end)
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                if d.Magnitude > 6 then state.moved = true end
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
        return state
    end

    sg = new("ScreenGui", {
        Name = "GameMenu", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 3,
    })
    sg.Parent = playerGui

    local win = new("Frame", {
        Name = "Window", Size = UDim2.fromOffset(W, H),
        Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
        BackgroundColor3 = Color3.fromRGB(14, 6, 28), BackgroundTransparency = 0.25,
        BorderSizePixel = 0, ClipsDescendants = true,
    }, sg)
    corner(win, 12)
    local winStroke = new("UIStroke", { Color = WHITE, Thickness = 1.5, Transparency = 0.25 }, win)
    local strokeGrad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, THEME.accent),
            ColorSequenceKeypoint.new(0.5, THEME.accent2),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 20, 130)),
        }),
    }, winStroke)

    -- Background: Frame + UIGradient animasi (tanpa file/asset eksternal) + orb galaksi ungu
    local bh = { rings = {}, stars = nil, core = nil, coreStroke = nil }
    local bgRoot = new("Frame", {
        Name = "GlassBG", Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(10, 4, 22), BackgroundTransparency = 0.1,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = -5,
    }, win)
    corner(bgRoot, 12)
    do
        -- gradient animasi (diputar di loop RenderStepped lewat bh.rings)
        local gradFrame = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.25,
            BorderSizePixel = 0, ZIndex = -4,
        }, bgRoot)
        corner(gradFrame, 12)
        local gradBg = new("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 6, 40)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(95, 30, 170)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 4, 32)),
            }),
        }, gradFrame)
        table.insert(bh.rings, { grad = gradBg, speed = 14 })
        -- orb ungu bercahaya + bebatuan (statis, hampir tanpa biaya)
        local function disc(size, color, transp, z, px, py)
            local f = new("Frame", {
                Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(px or 0.55, 0, py or 0.38, 0),
                BackgroundColor3 = color, BackgroundTransparency = transp,
                BorderSizePixel = 0, ZIndex = z,
            }, bgRoot)
            new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            return f
        end
        local D = math.max(W, H)
        disc(D * 1.1, Color3.fromRGB(70, 20, 140), 0.8, -4)
        disc(D * 0.7, Color3.fromRGB(150, 50, 230), 0.72, -4)
        disc(D * 0.4, Color3.fromRGB(210, 120, 255), 0.55, -4)
        bh.core = disc(D * 0.22, Color3.fromRGB(200, 90, 255), 0.05, -3)
        bh.coreStroke = new("UIStroke", { Thickness = 3, Color = Color3.fromRGB(240, 190, 255), Transparency = 0.2 }, bh.core)
        local rr = Random.new(5)
        for _ = 1, 16 do
            local sz = rr:NextInteger(10, 34)
            local rock = new("Frame", {
                Size = UDim2.fromOffset(sz, math.floor(sz * rr:NextNumber(0.6, 0.9))),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(rr:NextNumber(0.02, 0.98), 0, rr:NextNumber(0.62, 1.02), 0),
                BackgroundColor3 = Color3.fromRGB(rr:NextInteger(26, 44), rr:NextInteger(10, 22), rr:NextInteger(48, 78)),
                BorderSizePixel = 0, Rotation = rr:NextInteger(0, 360), ZIndex = -3,
            }, bgRoot)
            new("UICorner", { CornerRadius = UDim.new(0.4, 0) }, rock)
            new("UIStroke", { Color = Color3.fromRGB(150, 70, 230), Thickness = 1, Transparency = 0.5 }, rock)
        end
    end
    -- tint agar teks tetap terbaca
    new("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(8, 3, 18),
        BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = -2,
    }, bgRoot)
    -- lapisan kaca (frosted): kilau putih tipis dari atas
    local glassSheen = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = WHITE,
        BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = -1,
    }, bgRoot)
    new("UIGradient", {
        Rotation = 70,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(0.35, 0.95),
            NumberSequenceKeypoint.new(1, 0.985),
        }),
    }, glassSheen)

    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, win)
    local titleLbl = new("TextLabel", {
        Size = UDim2.new(1, -86, 1, -4), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = "Options",
        TextColor3 = WHITE, TextScaled = true, Font = FONT_B,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    new("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 7 }, titleLbl)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.55, THEME.accent2),
            ColorSequenceKeypoint.new(1, THEME.accent),
        }),
    }, titleLbl)
    local divider = new("Frame", {
        Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 32),
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, BorderSizePixel = 0,
    }, win)
    corner(divider, 2)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 16, 120)),
            ColorSequenceKeypoint.new(0.5, THEME.accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 16, 120)),
        }),
    }, divider)

    local minBtn = new("TextButton", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -40, 0.5, -8),
        BackgroundColor3 = THEME.off, BackgroundTransparency = 0.3, Text = "-",
        TextColor3 = WHITE, TextSize = 12, Font = FONT_B,
    }, header)
    corner(minBtn, 5)
    new("UIStroke", { Color = THEME.accent2, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, minBtn)
    local closeBtn = new("TextButton", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -20, 0.5, -8),
        BackgroundColor3 = THEME.bad, BackgroundTransparency = 0.2, Text = "X",
        TextColor3 = WHITE, TextSize = 9, Font = FONT_B,
    }, header)
    corner(closeBtn, 5)
    new("UIStroke", { Color = THEME.accent2, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, closeBtn)

    -- Tombol Discord (kiri tombol minimize): klik -> langsung buka invite Discord
    do
        local DISCORD_INVITE = "https://discord.gg/jyfHZfdYRZ"
        local DISCORD_LOGO_ASSET = "" -- opsional: isi "rbxassetid://ANGKA" kalau logo Discord sudah diupload ke Roblox
        local BLURPLE = Color3.fromRGB(88, 101, 242)
        local dcBtn = new("TextButton", {
            Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -60, 0.5, -8),
            BackgroundColor3 = BLURPLE, BackgroundTransparency = 0, Text = "",
            AutoButtonColor = true, ZIndex = 3,
        }, header)
        corner(dcBtn, 5)
        new("UIStroke", { Color = THEME.accent2, Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, dcBtn)
        if DISCORD_LOGO_ASSET ~= "" then
            new("ImageLabel", {
                Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2),
                BackgroundTransparency = 1, Image = DISCORD_LOGO_ASSET, ZIndex = 4,
            }, dcBtn)
        else
            -- logo Discord sederhana dari bentuk UI: wajah putih + dua mata
            local face = new("Frame", {
                Size = UDim2.fromOffset(10, 7), Position = UDim2.fromOffset(3, 4),
                BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4,
            }, dcBtn)
            new("UICorner", { CornerRadius = UDim.new(0.45, 0) }, face)
            for _, x in ipairs({ 2, 6 }) do
                local eye = new("Frame", {
                    Size = UDim2.fromOffset(2, 3), Position = UDim2.fromOffset(x, 2),
                    BackgroundColor3 = BLURPLE, BorderSizePixel = 0, ZIndex = 5,
                }, face)
                new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, eye)
            end
        end
        local opening = false
        dcBtn.MouseButton1Click:Connect(function()
            if opening then return end
            opening = true
            task.spawn(function()
                local opened = false
                local code = DISCORD_INVITE:match("discord%.gg/([%w%-]+)")
                if httpRequest and code then
                    -- minta aplikasi Discord di perangkat membuka invite (jalan kalau Discord app terpasang & terbuka)
                    local ok, res = pcall(httpRequest, {
                        Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
                        Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" },
                        Body = HttpService:JSONEncode({ cmd = "INVITE_BROWSER", args = { code = code }, nonce = HttpService:GenerateGUID(false) }),
                    })
                    local status = ok and res and (res.StatusCode or res.status_code)
                    opened = status ~= nil and status >= 200 and status < 300
                end
                if opened then
                    log("Membuka Discord Vura...")
                else
                    local copied = false
                    if typeof(setclipboard) == "function" then copied = pcall(setclipboard, DISCORD_INVITE) end
                    log(copied and ("Link Discord disalin, paste di browser: " .. DISCORD_INVITE) or ("Link Discord: " .. DISCORD_INVITE))
                end
                task.wait(1.5); opening = false
            end)
        end)
    end
    makeDraggable(header, win)

    local MIN_W, MIN_H = 300, 230
    local grip = new("TextButton", {
        Name = "ResizeGrip", Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -30, 1, -30), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 30,
    }, win)
    for _, p in ipairs({ { 21, 21 }, { 14, 21 }, { 21, 14 }, { 7, 21 }, { 14, 14 }, { 21, 7 } }) do
        local dot = new("Frame", {
            Size = UDim2.fromOffset(3, 3), Position = UDim2.fromOffset(p[1], p[2]),
            BackgroundColor3 = THEME.accent2, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, ZIndex = 31,
        }, grip)
        corner(dot, 2)
    end
    local resizing, rStart, rSize = false, nil, nil
    track(grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true; rStart = input.Position; rSize = win.AbsoluteSize
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    config.winW, config.winH = math.floor(win.AbsoluteSize.X), math.floor(win.AbsoluteSize.Y)
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - rStart
            local cam = Workspace.CurrentCamera
            local v = cam and cam.ViewportSize or Vector2.new(900, 600)
            local nw = math.clamp(rSize.X + d.X, MIN_W, math.max(MIN_W, v.X - 8))
            local nh = math.clamp(rSize.Y + d.Y, MIN_H, math.max(MIN_H, v.Y - 8))
            win.Size = UDim2.fromOffset(nw, nh)
        end
    end))

    local icon, iconGrad, iconGlowStroke
    do
        local DARK = Color3.fromRGB(6, 3, 14)
        icon = new("TextButton", {
            Name = "EXIcon", Size = UDim2.fromOffset(60, 60),
            Position = UDim2.new(0, 24, 0, 60), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, Visible = false,
        }, sg)
        local glow = new("Frame", {
            Size = UDim2.new(1, 12, 1, 12), Position = UDim2.new(0, -6, 0, -6),
            BackgroundTransparency = 1, BorderSizePixel = 0,
        }, icon)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
        iconGlowStroke = new("UIStroke", { Color = THEME.accent, Thickness = 6, Transparency = 0.7,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, glow)
        local disk = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = DARK,
            BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
        }, icon)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, disk)
        local st = new("UIStroke", { Color = WHITE, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, disk)
        iconGrad = new("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, THEME.accent),
                ColorSequenceKeypoint.new(0.35, Color3.fromRGB(230, 205, 255)),
                ColorSequenceKeypoint.new(0.65, Color3.fromRGB(60, 16, 120)),
                ColorSequenceKeypoint.new(1, THEME.accent),
            }),
        }, st)
        local shade = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = DARK,
            BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4,
        }, disk)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, shade)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "V",
            TextColor3 = WHITE, TextSize = 18, Font = FONT_B,
            TextStrokeColor3 = THEME.accent, TextStrokeTransparency = 0.3, ZIndex = 5,
        }, disk)
    end
    local iconDrag = makeDraggable(icon, icon)
    minBtn.MouseButton1Click:Connect(function() win.Visible = false; icon.Visible = true end)
    icon.MouseButton1Click:Connect(function()
        if iconDrag.moved then return end
        win.Visible = true; icon.Visible = false
    end)
    -- Konfirmasi tutup: X -> dialog Ya/Batal (anti kepencet, skrip tidak mati tiba-tiba)
    do
        local confirmFrame
        local function closeConfirm()
            if confirmFrame then pcall(function() confirmFrame:Destroy() end); confirmFrame = nil end
        end
        closeBtn.MouseButton1Click:Connect(function()
            if confirmFrame then return end
            confirmFrame = new("Frame", {
                Name = "CloseConfirm", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
                BorderSizePixel = 0, Active = true, ZIndex = 200,
            }, win)
            local box = new("Frame", {
                Size = UDim2.fromOffset(250, 118), Position = UDim2.new(0.5, -125, 0.5, -59),
                BackgroundColor3 = Color3.fromRGB(22, 10, 42), BackgroundTransparency = 0.05,
                BorderSizePixel = 0, ZIndex = 201,
            }, confirmFrame)
            corner(box, 10)
            new("UIStroke", { Color = THEME.accent2, Thickness = 1.2, Transparency = 0.2 }, box)
            new("TextLabel", {
                Size = UDim2.new(1, -20, 0, 52), Position = UDim2.fromOffset(10, 8),
                BackgroundTransparency = 1, Text = "Apakah anda yakin mau menutup Vura Script?",
                TextColor3 = WHITE, TextSize = 13, Font = FONT_B, TextWrapped = true, ZIndex = 202,
            }, box)
            local yes = new("TextButton", {
                Size = UDim2.fromOffset(104, 28), Position = UDim2.new(0, 12, 1, -40),
                BackgroundColor3 = THEME.bad, Text = "Ya, tutup",
                TextColor3 = WHITE, TextSize = 12, Font = FONT_B, ZIndex = 202,
            }, box)
            corner(yes, 6)
            local no = new("TextButton", {
                Size = UDim2.fromOffset(104, 28), Position = UDim2.new(1, -116, 1, -40),
                BackgroundColor3 = THEME.accent, Text = "Batal",
                TextColor3 = WHITE, TextSize = 12, Font = FONT_B, ZIndex = 202,
            }, box)
            corner(no, 6)
            yes.MouseButton1Click:Connect(function() closeConfirm(); cleanup() end)
            no.MouseButton1Click:Connect(closeConfirm)
        end)
    end

    -- Border FX: petir + batu jatuh (default OFF, toggle di CONFIG)
    do
        local rnd = Random.new((os.time() % 100000) + 7)
        local fxLayer = new("Frame", {
            Name = "BorderFX", Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ClipsDescendants = true, Active = false, ZIndex = 25,
            Visible = config.fxBorder ~= false,
        }, win)
        ui.fxLayer = fxLayer
        local CORE_COL = Color3.fromRGB(240, 224, 255)
        local SEGS = 5
        local EDGES = { 1, 3, 2, 4 }
        local flashFrame = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(230, 205, 255),
            BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ZIndex = 24 }, fxLayer)
        local flashT = 1
        local bolts = {}
        for i = 1, #EDGES do
            local b = { edge = EDGES[i], segs = {}, active = false, nextT = os.clock() + rnd:NextNumber(0.2, 1.5), endT = 0 }
            for s = 1, SEGS + 1 do
                local glow = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.accent,
                    BackgroundTransparency = 0.5, BorderSizePixel = 0,
                    Size = UDim2.fromOffset(2, 10), Visible = false, ZIndex = 26,
                }, fxLayer)
                local core2 = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CORE_COL,
                    BorderSizePixel = 0, Size = UDim2.fromOffset(2, 4), Visible = false, ZIndex = 27,
                }, fxLayer)
                b.segs[s] = { glow = glow, core = core2 }
            end
            bolts[i] = b
        end
        local function setSeg(q, x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            local len = math.sqrt(dx * dx + dy * dy) + 2
            local rot = math.deg(math.atan2(dy, dx))
            local pos = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
            q.glow.Position = pos; q.glow.Rotation = rot; q.glow.Size = UDim2.fromOffset(len, 10)
            q.core.Position = pos; q.core.Rotation = rot; q.core.Size = UDim2.fromOffset(len, 4)
            q.glow.Visible = true; q.core.Visible = true
        end
        local function strike(b)
            local W_, H_ = win.AbsoluteSize.X, win.AbsoluteSize.Y
            local e = b.edge
            local length = (e <= 2) and W_ or H_
            local span = length * rnd:NextNumber(0.22, 0.4)
            local start = rnd:NextNumber(0, math.max(1, length - span))
            local pts = {}
            for i = 0, SEGS do
                local along = start + span * i / SEGS
                local perp = (i == 0 or i == SEGS) and 2 or rnd:NextNumber(3, 13)
                local x, y
                if e == 1 then x, y = along, perp
                elseif e == 2 then x, y = along, H_ - perp
                elseif e == 3 then x, y = perp, along
                else x, y = W_ - perp, along end
                pts[i] = Vector2.new(x, y)
            end
            for i = 1, SEGS do setSeg(b.segs[i], pts[i - 1].X, pts[i - 1].Y, pts[i].X, pts[i].Y) end
            local o = pts[2]
            local inx, iny = 0, 0
            if e == 1 then iny = 1 elseif e == 2 then iny = -1 elseif e == 3 then inx = 1 else inx = -1 end
            local blen = rnd:NextNumber(10, 20); local lat = rnd:NextNumber(-8, 8)
            local tx = o.X + inx * blen + ((e <= 2) and lat or 0)
            local ty = o.Y + iny * blen + ((e > 2) and lat or 0)
            setSeg(b.segs[SEGS + 1], o.X, o.Y, tx, ty)
            flashT = 0.9
        end
        local rocks = {}
        for i = 1, 10 do
            local size = rnd:NextInteger(9, 17)
            local f = new("Frame", {
                Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(22, 9, 42), BorderSizePixel = 0, ZIndex = 26,
            }, fxLayer)
            new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, f)
            new("UIStroke", { Color = THEME.accent2, Thickness = 2, Transparency = 0.2,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
            rocks[i] = {
                f = f, side = (i % 2 == 0) and 1 or 2,
                y = rnd:NextNumber(-20, 300), vy = rnd:NextNumber(70, 150),
                rot = rnd:NextNumber(0, 360), vr = rnd:NextNumber(-180, 180),
                off = rnd:NextNumber(7, 14),
            }
        end
        local acc = 0
        track(RunService.Heartbeat:Connect(function(dt)
            if not uiAlive or not win.Visible then return end
            if not fxLayer.Visible then return end
            acc += dt
            if acc < 0.04 then return end
            local step = math.min(acc, 0.1); acc = 0
            local now = os.clock()
            local W_, H_ = win.AbsoluteSize.X, win.AbsoluteSize.Y
            if flashT < 1 then flashT = math.min(1, flashT + step * 1.6); flashFrame.BackgroundTransparency = flashT end
            for _, b in ipairs(bolts) do
                if b.active then
                    if now >= b.endT then
                        b.active = false
                        for _, q in ipairs(b.segs) do q.glow.Visible = false; q.core.Visible = false end
                        b.nextT = now + rnd:NextNumber(0.25, 1.3)
                    else
                        local tr = rnd:NextNumber(0.3, 0.7)
                        for _, q in ipairs(b.segs) do q.glow.BackgroundTransparency = tr end
                    end
                elseif now >= b.nextT then
                    b.active = true
                    b.endT = now + rnd:NextNumber(0.1, 0.24)
                    strike(b)
                end
            end
            for _, r in ipairs(rocks) do
                r.y += r.vy * step; r.rot += r.vr * step
                if r.y > H_ + 12 then
                    r.y = -12 - rnd:NextNumber(0, 60)
                    r.vy = rnd:NextNumber(70, 150); r.off = rnd:NextNumber(7, 14)
                end
                local x = (r.side == 1) and r.off or (W_ - r.off)
                r.f.Position = UDim2.fromOffset(x, r.y)
                r.f.Rotation = r.rot
            end
        end))
    end

    local side = new("ScrollingFrame", {
        Size = UDim2.new(0, SIDE, 1, -42), Position = UDim2.new(0, 6, 0, 38),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, win)
    new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, side)
    local content = new("Frame", {
        Size = UDim2.new(1, -(SIDE + 18), 1, -42), Position = UDim2.new(0, SIDE + 12, 0, 38),
        BackgroundTransparency = 1,
    }, win)

    local tabs = {}
    local function selectTab(t)
        for _, o in ipairs(tabs) do
            local on = (o == t)
            o.page.Visible = on
            o.btn.BackgroundColor3 = on and THEME.accent or THEME.card
            o.btn.BackgroundTransparency = on and 0.25 or 0.55
            o.btn.TextColor3 = on and WHITE or THEME.sub
            if o.stroke then o.stroke.Color = on and THEME.accent2 or THEME.off end
            if o.paintIcon then o.paintIcon(on and WHITE or THEME.sub) end
        end
    end
    local function buildTabIcon(parent, kind)
        local box = new("Frame", {
            Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, 3, 0.5, -10), Rotation = 0,
            BackgroundTransparency = 1,
        }, parent)
        new("UIScale", { Scale = 0.8 }, box)
        local parts = {}
        local function shape(x, y, w, h, o)
            o = o or {}
            local f = new("Frame", {
                Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
                BackgroundColor3 = THEME.sub, BackgroundTransparency = o.outline and 1 or 0,
                BorderSizePixel = 0, Rotation = o.rot or 0,
            }, box)
            if o.round == "full" then new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            elseif o.round then new("UICorner", { CornerRadius = UDim.new(0, o.round) }, f) end
            if o.outline then
                local st = new("UIStroke", { Color = THEME.sub, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
                table.insert(parts, { st, "Color" })
            else table.insert(parts, { f, "BackgroundColor3" }) end
        end
        if kind == "MAIN" then
            shape(4, 2, 12, 16, { outline = true, round = "full" }); shape(8, 9, 4, 4, { round = "full" })
        elseif kind == "PRIORITY" then
            shape(3, 4, 14, 3, { round = 1 }); shape(3, 9, 14, 3, { round = 1 }); shape(3, 14, 9, 3, { round = 1 })
        elseif kind == "AREA" then
            shape(4, 1, 12, 12, { outline = true, round = "full" }); shape(8, 5, 4, 4, { round = "full" }); shape(9, 13, 2, 6, { round = 1 })
        elseif kind == "AUTOMATION" then
            shape(4, 4, 12, 12, { outline = true, round = "full" }); shape(8, 8, 4, 4, { round = "full" })
            shape(9, 0, 2, 4); shape(9, 16, 2, 4); shape(0, 9, 4, 2); shape(16, 9, 4, 2)
        elseif kind == "EVENT" then
            shape(4, 4, 12, 12, { outline = true }); shape(4, 4, 12, 12, { outline = true, rot = 45 }); shape(8, 8, 4, 4, { round = "full" })
        elseif kind == "SHOP" then
            shape(6, 1, 8, 9, { outline = true, round = "full" }); shape(3, 8, 14, 11, { round = 2 })
        elseif kind == "PROTEKSI" then
            shape(4, 1, 12, 10, { round = 2 }); shape(5, 6, 10, 10, { rot = 45, round = 1 })
        elseif kind == "WEBHOOK" then
            shape(1, 6, 11, 8, { outline = true, round = "full" }); shape(8, 6, 11, 8, { outline = true, round = "full" })
        elseif kind == "CONFIG" then
            shape(2, 4, 16, 2, { round = 1 }); shape(2, 9, 16, 2, { round = 1 }); shape(2, 14, 16, 2, { round = 1 })
            shape(4, 2, 5, 6, { round = "full" }); shape(12, 7, 5, 6, { round = "full" }); shape(6, 12, 5, 6, { round = "full" })
        else
            shape(6, 5, 8, 12, { round = "full" }); shape(7, 1, 6, 5, { round = "full" })
            shape(2, 8, 4, 2); shape(14, 8, 4, 2); shape(2, 13, 4, 2); shape(14, 13, 4, 2)
        end
        return function(col) for _, p in ipairs(parts) do p[1][p[2]] = col end end
    end
    local function addTab(name)
        local btn = new("TextButton", {
            Size = UDim2.new(1, -4, 0, 28), BackgroundColor3 = THEME.card, BackgroundTransparency = 0.55, Text = name,
            TextColor3 = THEME.sub, TextSize = 10, TextScaled = true, Font = FONT_B, AutoButtonColor = false,
        }, side)
        corner(btn, 7)
        local tabStroke = new("UIStroke", { Color = THEME.off, Thickness = 1, Transparency = 0.2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn)
        new("UITextSizeConstraint", { MaxTextSize = 10, MinTextSize = 6 }, btn)
        new("UIPadding", { PaddingLeft = UDim.new(0, 26), PaddingRight = UDim.new(0, 3) }, btn)
        local paintIcon = buildTabIcon(btn, name)
        local page = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 4, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
        }, content)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
        new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12) }, page)
        local t = { btn = btn, page = page, stroke = tabStroke, paintIcon = paintIcon }
        table.insert(tabs, t)
        btn.MouseButton1Click:Connect(function() selectTab(t) end)
        return page
    end

    local function card(parent, h)
        local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = THEME.card,
            BackgroundTransparency = 0.5, BorderSizePixel = 0 }, parent)
        corner(f, 6)
        return f
    end
    local function label(parent, text, size, color, font)
        return new("TextLabel", {
            BackgroundTransparency = 1, Text = text, TextSize = size or 12,
            TextColor3 = color or THEME.text, Font = font or FONT_R,
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        }, parent)
    end
    local function section(parent, text)
        local l = label(parent, text, 11, THEME.accent2, FONT_B)
        l.Size = UDim2.new(1, 0, 0, 18); return l
    end
    local function note(parent, text)
        local l = label(parent, text, 11, THEME.sub)
        l.Size = UDim2.new(1, 0, 0, 0); l.AutomaticSize = Enum.AutomaticSize.Y; return l
    end
    local function safeCall(cb, ...)
        local ok, err = pcall(cb, ...)
        if not ok then log("Error UI: " .. tostring(err)) end
    end
    local function buttonRow(parent, text, cb, color)
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = color or THEME.accent,
            BackgroundTransparency = 0.25, Text = text, TextColor3 = WHITE,
            TextSize = 11, Font = FONT_B, AutoButtonColor = true,
        }, parent)
        corner(b, 6)
        b.MouseButton1Click:Connect(function() safeCall(cb, b) end)
        return b
    end
    local function toggleRow(parent, text, default, cb, subText, reserve)
        local h = subText and 44 or 34
        local row = card(parent, h)
        local lblW = 62 + (reserve or 0)
        local lbl = label(row, text, 11, THEME.text, FONT_M)
        lbl.Size = UDim2.new(1, -lblW, 0, subText and 22 or h)
        lbl.Position = UDim2.new(0, 10, 0, subText and 3 or 0)
        if subText then
            local sl = label(row, subText, 9, THEME.sub)
            sl.Size = UDim2.new(1, -lblW, 0, 14); sl.Position = UDim2.new(0, 10, 0, 25)
            sl.TextWrapped = false; sl.TextTruncate = Enum.TextTruncate.AtEnd
        end
        local sw = new("TextButton", {
            Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10),
            BackgroundColor3 = THEME.off, Text = "", AutoButtonColor = false,
        }, row)
        corner(sw, 10)
        local knob = new("Frame", {
            Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = WHITE, BorderSizePixel = 0,
        }, sw)
        corner(knob, 7)
        local isOn = default and true or false
        local function paint(animate)
            local kp = isOn and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            local col = isOn and THEME.accent or THEME.off
            if animate then
                TweenService:Create(knob, TweenInfo.new(0.15), { Position = kp }):Play()
                TweenService:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = col }):Play()
            else knob.Position = kp; sw.BackgroundColor3 = col end
        end
        paint(false)
        sw.MouseButton1Click:Connect(function()
            isOn = not isOn; paint(true); safeCall(cb, isOn)
        end)
        return { row = row, set = function(v) isOn = v and true or false; paint(false) end, get = function() return isOn end }
    end
    local function choiceRow(parent, title, options, current, cb)
        local row = card(parent, 58)
        local t = label(row, title, 11, THEME.sub, FONT_M)
        t.Size = UDim2.new(1, -20, 0, 16); t.Position = UDim2.new(0, 10, 0, 4)
        local btns = {}; local n = #options
        local function paint(val)
            for v, b in pairs(btns) do
                local on = (v == val)
                b.BackgroundColor3 = on and THEME.accent or THEME.off
                b.TextColor3 = on and WHITE or THEME.sub
            end
        end
        for i, opt in ipairs(options) do
            local b = new("TextButton", {
                Size = UDim2.new(1 / n, -8, 0, 26), Position = UDim2.new((i - 1) / n, 6, 0, 24),
                BackgroundColor3 = THEME.off, Text = opt[2], TextColor3 = THEME.sub,
                TextSize = 11, Font = FONT_B, AutoButtonColor = false,
            }, row)
            corner(b, 5); btns[opt[1]] = b
            b.MouseButton1Click:Connect(function() paint(opt[1]); safeCall(cb, opt[1]) end)
        end
        paint(current)
        return { paint = paint }
    end
    local function stepperRow(parent, title, value, minV, maxV, step, cb, suffix)
        local row = card(parent, 34)
        local t = label(row, title, 12, THEME.text, FONT_M)
        t.Size = UDim2.new(1, -126, 1, 0); t.Position = UDim2.new(0, 10, 0, 0)
        local val = math.clamp(tonumber(value) or minV, minV, maxV)
        local vl = new("TextLabel", {
            Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -86, 0.5, -12),
            BackgroundTransparency = 1, TextColor3 = THEME.accent2, TextSize = 12, Font = FONT_B, Text = "",
        }, row)
        local function show() vl.Text = tostring(val) .. (suffix or "") end
        local function mk(txt, x, delta)
            local b = new("TextButton", {
                Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, x, 0.5, -12),
                BackgroundColor3 = THEME.off, Text = txt, TextColor3 = THEME.text,
                TextSize = 14, Font = FONT_B,
            }, row)
            corner(b, 5)
            b.MouseButton1Click:Connect(function() val = math.clamp(val + delta, minV, maxV); show(); safeCall(cb, val) end)
        end
        mk("-", -116, -step); mk("+", -36, step)
        show()
    end
    local function textboxRow(parent, title, value, placeholder, cb)
        local row = card(parent, 58)
        local t = label(row, title, 11, THEME.sub, FONT_M)
        t.Size = UDim2.new(1, -20, 0, 16); t.Position = UDim2.new(0, 10, 0, 4)
        local box = new("TextBox", {
            Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 24),
            BackgroundColor3 = THEME.off, TextColor3 = THEME.text,
            PlaceholderText = placeholder, PlaceholderColor3 = THEME.sub,
            Text = value or "", TextSize = 11, Font = FONT_R, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        corner(box, 5)
        box.FocusLost:Connect(function() safeCall(cb, box.Text) end)
        return box
    end
    local function textBox(parent, h)
        local sc = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = THEME.bg2,
            BackgroundTransparency = 0.06, BorderSizePixel = 0, ScrollBarThickness = 3,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, parent)
        corner(sc, 6)
        local lbl = new("TextLabel", {
            Size = UDim2.new(1, -8, 0, 0), Position = UDim2.new(0, 4, 0, 2),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            TextColor3 = THEME.sub, TextSize = 11, Font = Enum.Font.Code,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, Text = "",
        }, sc)
        return sc, lbl
    end
    local function multiSelect(parent, title, sets, cats)
        local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, parent)
        local wl = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
        fit(wrap, wl)
        local head
        local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false }, wrap)
        head = buttonRow(wrap, "v  " .. title, function()
            body.Visible = not body.Visible
            head.Text = (body.Visible and "^  " or "v  ") .. title
        end, THEME.off)
        head.LayoutOrder = 1
        body.LayoutOrder = 2
        local bl = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, body)
        fit(body, bl)
        local painters = {}
        for _, entry in ipairs(FILTERS) do
            local cat, opts = entry[1], entry[2]
            if not cats or table.find(cats, cat) then
                local lb = label(body, cat, 11, THEME.accent2, FONT_B)
                lb.Size = UDim2.new(1, 0, 0, 16)
                local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, body)
                local gl = new("UIGridLayout", {
                    CellSize = UDim2.new(0.5, -4, 0, 26),
                    CellPadding = UDim2.fromOffset(6, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, grid)
                fit(grid, gl)
                for _, opt in ipairs(opts) do
                    local chip = new("TextButton", {
                        Text = opt, TextSize = 11, Font = FONT_M,
                        BackgroundColor3 = THEME.off, TextColor3 = THEME.sub, AutoButtonColor = false,
                    }, grid)
                    corner(chip, 5)
                    local function paint()
                        local on = sets[cat][opt] == true
                        chip.BackgroundColor3 = on and THEME.accent or THEME.off
                        chip.TextColor3 = on and WHITE or THEME.sub
                        chip.Font = on and FONT_B or FONT_M
                    end
                    paint(); table.insert(painters, paint)
                    chip.MouseButton1Click:Connect(function()
                        if sets[cat][opt] then sets[cat][opt] = nil else sets[cat][opt] = true end
                        paint()
                    end)
                end
            end
        end
        local clr = buttonRow(body, "Reset pilihan filter ini", function()
            for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do table.clear(sets[cat]) end
            for _, p in ipairs(painters) do p() end
        end, THEME.off)
        clr.TextSize = 11
        return wrap
    end
    local function dropdownRow(parent, title, options, current, cb)
        local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, parent)
        local wl = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
        fit(wrap, wl)
        local head = card(wrap, 34)
        head.LayoutOrder = 1
        local t = label(head, title, 12, THEME.text, FONT_M)
        t.Size = UDim2.new(0.22, 0, 1, 0); t.Position = UDim2.new(0, 10, 0, 0)
        local btn = new("TextButton", {
            Size = UDim2.new(0.78, -18, 0, 24), Position = UDim2.new(0.22, 4, 0.5, -12),
            BackgroundColor3 = THEME.off, TextColor3 = THEME.text, TextSize = 11,
            Font = FONT_B, AutoButtonColor = false, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
        }, head)
        corner(btn, 5)
        local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false }, wrap)
        body.LayoutOrder = 2
        local bl = new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, body)
        fit(body, bl)
        local names = {}
        for _, o in ipairs(options) do names[o.id] = o.label end
        local function show(id) btn.Text = (names[id] or "- Kosong -") .. "  v" end
        show(current)
        for _, o in ipairs(options) do
            local ob = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = THEME.off,
                Text = o.label, TextColor3 = THEME.sub, TextSize = 11,
                Font = FONT_M, AutoButtonColor = true,
            }, body)
            corner(ob, 5)
            ob.MouseButton1Click:Connect(function()
                body.Visible = false; show(o.id); safeCall(cb, o.id)
            end)
        end
        btn.MouseButton1Click:Connect(function() body.Visible = not body.Visible end)
        return wrap
    end

    -- ===== TAB MAIN =====
    local pageMain = addTab("MAIN")
    section(pageMain, "STATUS")
    local statusCard = card(pageMain, 62)
    ui.statusDot = new("Frame", {
        Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 10, 0, 9),
        BackgroundColor3 = THEME.sub, BorderSizePixel = 0,
    }, statusCard)
    corner(ui.statusDot, 5)
    ui.statusText = label(statusCard, "Idle", 12, THEME.text, FONT_B)
    ui.statusText.Size = UDim2.new(1, -34, 0, 18); ui.statusText.Position = UDim2.new(0, 28, 0, 5)
    ui.statsText = label(statusCard, "", 11, THEME.sub)
    ui.statsText.Size = UDim2.new(1, -20, 0, 16); ui.statsText.Position = UDim2.new(0, 10, 0, 26)
    ui.modeText = label(statusCard, "", 11, THEME.sub)
    ui.modeText.Size = UDim2.new(1, -20, 0, 16); ui.modeText.Position = UDim2.new(0, 10, 0, 43)
    ui.modeText.TextTruncate = Enum.TextTruncate.AtEnd
    ui.modeText.TextWrapped = false
    section(pageMain, "KONTROL")
    toggleRow(pageMain, "Auto Steal Telur", false, function(on)
        config.running = on
        if on then
            local hrp = getHRP()
            if hrp and not baseCFrame then
                baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0); Treadmill.reset()
                log("Auto Steal ON (base = posisimu sekarang)")
            else log("Auto Steal ON (memakai base tersimpan)") end
            ensureBrain()
        else log("Auto Steal OFF") end
        refreshStats()
    end)
    toggleRow(pageMain, "Treadmill saat idle", false, function(on)
        config.treadmillIdle = on
        if on then ensureBrain() end
    end, "Lari di treadmill bila tidak ada kerjaan")
    toggleRow(pageMain, "Lewati telur milik sendiri", config.skipOwn, function(on) config.skipOwn = on end)
    toggleRow(pageMain, "Legit Steal", config.legit, function(on)
        config.legit = on
        log("Legit Steal " .. (on and "ON" or "OFF"))
        refreshStats()
    end, "Jalan kaki + tahan tombol seperti pemain biasa")
    toggleRow(pageMain, "Steal Teleport Instan", config.instantSteal, function(on)
        config.instantSteal = on
        log("Steal Teleport Instan " .. (on and "ON" or "OFF") .. ((on and config.legit) and " (diabaikan saat Legit Steal aktif)" or ""))
    end, "Teleport ke telur, ambil, lalu balik ke base (anti jatuh/tenggelam)")
    choiceRow(pageMain, "Cara bergerak", { { "Walk", "Jalan (humanoid)" }, { "Fly", "Terbang halus" } }, config.method, function(v)
        config.method = v; refreshStats()
    end)
    choiceRow(pageMain, "Mode target", { { "All", "Semua telur" }, { "Filter", "Pakai filter" } }, config.targetMode, function(v)
        config.targetMode = v; refreshStats()
    end)
    stepperRow(pageMain, "Kecepatan terbang", config.flySpeed, 30, 400, 10, function(v) config.flySpeed = v end)
    stepperRow(pageMain, "Tinggi terbang", config.flyHeight, 0, 60, 2, function(v) config.flyHeight = v end)
    buttonRow(pageMain, "Set Base di posisi sekarang", function()
        local hrp = getHRP()
        if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0); Safe.cache = nil; Treadmill.reset(); log("Base disimpan") end
    end, THEME.off)
    buttonRow(pageMain, "Set Titik Aman (posisi sekarang)", function()
        local hrp = getHRP()
        if hrp then
            V25.manualSafe = hrp.Position; Safe.cache = nil
            log("Titik aman manual disimpan. Tekan 'SAVE CONFIG SEKARANG' agar permanen.")
        end
    end, THEME.off)
    buttonRow(pageMain, "Titik Aman: kembali ke otomatis", function()
        V25.manualSafe = nil; Safe.cache = nil; Safe.lastDesc = nil
        local p = V25.safeBasePos()
        log("Titik aman otomatis dipakai" .. (p and (" (%.0f, %.0f, %.0f)"):format(p.X, p.Y, p.Z) or ""))
    end, THEME.off)
    buttonRow(pageMain, "Set Treadmill (berdiri di atasnya)", function()
        local ok2, info = Treadmill.setFromPlayer()
        if ok2 then log("Treadmill dikunci: " .. tostring(info)) else log("Set Treadmill gagal: " .. tostring(info)) end
    end, THEME.off)
    buttonRow(pageMain, "Treadmill: kembali ke otomatis", function()
        Treadmill.clearManual(); log("Treadmill kembali ke deteksi otomatis")
    end, THEME.off)
    section(pageMain, "FILTER TELUR")
    multiSelect(pageMain, "Filter Size / Rarity / Variant", config.filters)
    section(pageMain, "EGG PREDICT")
    toggleRow(pageMain, "Egg Predict", false, function(on)
        config.eggPredict = on
        if on then V25.startEggPredict()
        elseif ui.predictLabel then ui.predictLabel.Text = "Egg Predict OFF" end
    end, "Baca rarity / variant / size telur terdekat")
    local predictCard = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = THEME.card, BackgroundTransparency = 0.5, BorderSizePixel = 0,
    }, pageMain)
    corner(predictCard, 6)
    new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, predictCard)
    ui.predictLabel = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = "Egg Predict OFF", TextColor3 = THEME.sub,
        TextSize = 11, Font = Enum.Font.Code, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    }, predictCard)
    note(pageMain, "Membaca teks/atribut telur yang terlihat di client.")
    section(pageMain, "AUTO SELL EGG")
    toggleRow(pageMain, "Auto Sell Egg", false, function(on)
        setAuto("sell", on, V25.autoSellOnce); log("Auto Sell Egg " .. (on and "ON" or "OFF"))
    end, "Jual egg di backpack sesuai rarity")
    multiSelect(pageMain, "Filter Rarity yang dijual", config.sellFilters, { "Rarity" })
    section(pageMain, "AUTO FAVORIT")
    toggleRow(pageMain, "Auto Favorit", false, function(on)
        setAuto("favorite", on, V25.autoFavoriteOnce); log("Auto Favorit " .. (on and "ON" or "OFF"))
    end, "Favoritkan item sesuai nama / rarity")
    textboxRow(pageMain, "Nama item (pisahkan dengan koma)", config.favNames, "contoh: dragon, phoenix", function(txt)
        config.favNames = txt
    end)
    multiSelect(pageMain, "Filter Rarity & Variant", config.favFilters, { "Rarity", "Variant" })
    section(pageMain, "LOG")
    local logScroll, logLabel = textBox(pageMain, 150)
    ui.logScroll, ui.logLabel = logScroll, logLabel

    -- ===== TAB PRIORITY =====
    local pagePrio = addTab("PRIORITY")
    note(pagePrio, "Default MATI. Saat dinyalakan, AFK manager mengerjakan sesuai urutan. #1 selalu Steal Egg.")
    toggleRow(pagePrio, "Aktifkan Priority", false, function(on)
        V25.applyPriorityMode(on); log("Priority " .. (on and "ON" or "OFF"))
    end, "Mati = tiap fitur jalan sendiri")
    section(pagePrio, "URUTAN PRIORITAS")
    local lockCard = card(pagePrio, 34)
    local lockLbl = label(lockCard, "#1   Steal Egg  (wajib, terkunci)", 12, THEME.accent2, FONT_B)
    lockLbl.Size = UDim2.new(1, -20, 1, 0); lockLbl.Position = UDim2.new(0, 10, 0, 0)
    for i = 2, 7 do
        dropdownRow(pagePrio, "#" .. i, V25.PRIORITY_OPTIONS, config.priority[i], function(id) config.priority[i] = id end)
    end

    -- ===== TAB AREA =====
    local pageArea = addTab("AREA")
    note(pageArea, "Pilih biome yang boleh dicuri. Kosong = semua area.")
    local areaToggles = {}
    buttonRow(pageArea, "Pilih semua area", function()
        for _, nm in ipairs(AREAS) do config.areas[nm] = true; areaToggles[nm].set(true) end
        refreshStats()
    end, THEME.off)
    buttonRow(pageArea, "Kosongkan pilihan", function()
        for _, nm in ipairs(AREAS) do config.areas[nm] = nil; areaToggles[nm].set(false) end
        refreshStats()
    end, THEME.off)
    for _, nm in ipairs(AREAS) do
        local t = toggleRow(pageArea, nm, config.areas[nm] == true, function(on)
            config.areas[nm] = on or nil; refreshStats()
        end, nil, 56)
        areaToggles[nm] = t
        local pin = new("TextButton", {
            Size = UDim2.fromOffset(46, 22), Position = UDim2.new(1, -114, 0.5, -11),
            BackgroundColor3 = THEME.off, Text = areaCenters[nm] and "SET*" or "SET",
            TextColor3 = areaCenters[nm] and THEME.good or THEME.sub, TextSize = 10, Font = FONT_B,
        }, t.row)
        corner(pin, 5)
        pin.MouseButton1Click:Connect(function()
            local hrp = getHRP(); if not hrp then return end
            areaCenters[nm] = hrp.Position; pin.Text = "SET*"; pin.TextColor3 = THEME.good
            log("Pusat area " .. nm .. " disimpan")
        end)
    end

    -- ===== TAB AUTOMATION =====
    local pageAuto = addTab("AUTOMATION")
    note(pageAuto, "Automation bekerja untuk prompt/tombol di sekitar base (radius " .. BASE_RADIUS .. ").")
    section(pageAuto, "TELUR & INDEX")
    local autoDefs = {
        { "hatch", "Auto Hatch", autoHatchOnce, "Menetaskan telur di base" },
        { "place", "Auto Place", autoPlaceOnce, "Menaruh telur dari backpack" },
        { "fuse", "Auto Fuse", autoFuseOnce, "Menjalankan fuse otomatis" },
        { "index", "Auto Claim Index", autoIndexOnce, "Klaim hadiah Index tiap 60 detik" },
    }
    for _, def in ipairs(autoDefs) do
        toggleRow(pageAuto, def[2], false, function(on)
            setAuto(def[1], on, def[3]); log(def[2] .. (on and " ON" or " OFF"))
        end, def[4])
    end
    stepperRow(pageAuto, "Jeda antar aksi", config.autoInterval, 2, 60, 1, function(v) config.autoInterval = v end, " dtk")
    multiSelect(pageAuto, "Filter telur untuk Place", config.placeFilters)
    section(pageAuto, "UPGRADE")
    local upgDefs = {
        { "upgTrail", "Auto Upgrade Trail", V25.autoUpgTrailOnce, "Klik tombol Upgrade milik Trail" },
        { "upgTreadmill", "Auto Upgrade Treadmill", V25.autoUpgTreadmillOnce, "Klik tombol Upgrade milik Treadmill" },
        { "upgBase", "Auto Upgrade Base", V25.autoUpgBaseOnce, "Klik tombol Upgrade milik Base" },
    }
    for _, def in ipairs(upgDefs) do
        toggleRow(pageAuto, def[2], false, function(on)
            setAuto(def[1], on, def[3]); log(def[2] .. (on and " ON" or " OFF"))
        end, def[4])
    end
    section(pageAuto, "PET AUTOMATION")
    toggleRow(pageAuto, "Auto Taruh Pet di Plot", false, function(on)
        setAuto("petPlace", on, V25.autoPetPlaceOnce); log("Auto Taruh Pet " .. (on and "ON" or "OFF"))
    end, "Pilih pet berdasarkan nama atau rarity")
    textboxRow(pageAuto, "Nama pet yang ditaruh (pisahkan koma)", config.petPlaceNames, "contoh: dragon, cat", function(txt) config.petPlaceNames = txt end)
    multiSelect(pageAuto, "Rarity pet yang ditaruh", config.petPlaceFilters, { "Rarity" })
    toggleRow(pageAuto, "Auto Jual Pet", false, function(on)
        setAuto("petSell", on, V25.autoPetSellOnce); log("Auto Jual Pet " .. (on and "ON" or "OFF"))
    end, "Pilih pet berdasarkan nama atau rarity")
    textboxRow(pageAuto, "Nama pet yang dijual (pisahkan koma)", config.petSellNames, "contoh: rat, mouse", function(txt) config.petSellNames = txt end)
    multiSelect(pageAuto, "Rarity pet yang dijual", config.petSellFilters, { "Rarity" })

    -- ===== TAB EVENT =====
    local pageEvent = addTab("EVENT")
    note(pageEvent, "Event aktif. Nama objek event di game harus sesuai dengan EVENT_DEFS di script.")
    for _, def in ipairs(EVENT_DEFS) do
        toggleRow(pageEvent, def.name, false, function(on)
            config.events[def.id] = on
            if on then ensureBrain() end
            log("Event " .. def.name .. (on and " ON" or " OFF"))
        end, def.desc)
    end

    -- ===== TAB SHOP =====
    local pageShop = addTab("SHOP")
    note(pageShop, "Membuka shop lewat tombol HUD atau terbang ke objek shop. Tombol pembelian tidak pernah diklik otomatis.")
    for _, def in ipairs(SHOPS) do
        buttonRow(pageShop, def.name, function() openShop(def) end)
        note(pageShop, def.info)
    end
    buttonRow(pageShop, "Tutup semua jendela shop", function()
        task.spawn(function()
            local n = V25.closeAllShops()
            log(n > 0 and ("Menutup " .. n .. " jendela shop") or "Tidak ada jendela shop yang terbuka")
        end)
    end, THEME.bad)

    -- ===== TAB PROTEKSI =====
    local pageProt = addTab("PROTEKSI")
    section(pageProt, "PROTEKSI")
    toggleRow(pageProt, "Anti Knockback", config.antiKB, function(on) config.antiKB = on; Protect.sync() end)
    toggleRow(pageProt, "Anti Trapped", config.antiTrap, function(on) config.antiTrap = on; Protect.sync() end)
    toggleRow(pageProt, "Anti AFK", config.antiAfk, function(on) config.antiAfk = on; AFK.sync() end)
    toggleRow(pageProt, "Hapus popup '+Speed' & partikel", config.removePopups, function(on) setPopupCleaner(on) end, "Hemat CPU/RAM")
    section(pageProt, "TAMPILAN & PERFORMA")
    local pingFrame = new("Frame", {
        Size = UDim2.fromOffset(160, 22), Position = UDim2.new(1, -170, 0, 6),
        BackgroundColor3 = THEME.bg2, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, Visible = config.pingPanel,
    }, sg)
    corner(pingFrame, 6)
    ui.pingLabel = new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        TextColor3 = THEME.good, TextSize = 11, Font = FONT_B, Text = "PING - | FPS -",
    }, pingFrame)
    toggleRow(pageProt, "Panel Ping & FPS", config.pingPanel, function(on)
        config.pingPanel = on; pingFrame.Visible = on
    end)
    local antiLagToggle = toggleRow(pageProt, "Anti Lag (matikan partikel)", config.antiLag, function(on)
        config.antiLag = on; setAntiLag(on)
    end)
    toggleRow(pageProt, "Hide All GUI", false, function(on)
        V25.setHideAllGui(on); log("Hide All GUI " .. (on and "ON" or "OFF"))
    end, "Sembunyikan semua GUI game (GUI Vura tetap tampil). Auto shop/jual butuh GUI game, matikan dulu")
    toggleRow(pageProt, "Mode AFK Hemat", false, function(on)
        V25.setAfkSaver(on); log("Mode AFK Hemat " .. (on and "ON" or "OFF"))
    end, "Batasi FPS + volume 0 (render 3D TIDAK dimatikan)")
    stepperRow(pageProt, "Batas FPS saat AFK hemat", config.fpsCap, 5, 60, 5, function(v)
        config.fpsCap = v
        if config.afkSaver and typeof(setfpscap) == "function" then pcall(setfpscap, v) end
    end)
    buttonRow(pageProt, "Hapus plot orang lain (plot sendiri aman)", function()
        plotKeepMine = true; task.spawn(removePlots)
    end, THEME.off)
    buttonRow(pageProt, "Super FPS Boost", function()
        task.spawn(function() superFpsBoost(); config.antiLag = true; antiLagToggle.set(true) end)
    end, THEME.warn)

    -- ===== TAB WEBHOOK =====
    local pageWh = addTab("WEBHOOK")
    section(pageWh, "NOTIFIKASI TELUR")
    toggleRow(pageWh, "Kirim webhook tiap telur didapat", false, function(on)
        config.eggWebhookOn = on
        if on and not validWebhook(config.eggWebhookUrl) then log("URL webhook telur belum valid") end
    end)
    textboxRow(pageWh, "URL Webhook Discord (telur)", config.eggWebhookUrl, "https://discord.com/api/webhooks/...", function(txt)
        config.eggWebhookUrl = (txt:gsub("%s+", ""))
    end)
    buttonRow(pageWh, "Tes webhook telur", function()
        if not validWebhook(config.eggWebhookUrl) then log("URL webhook telur belum valid"); return end
        queueWebhook(config.eggWebhookUrl, embedPayload("Tes webhook", 0x8B5CF6, {
            { name = "Status", value = "Berhasil terhubung", inline = true },
            { name = "Pemain", value = player.DisplayName, inline = true },
        }))
        log("Tes webhook telur dikirim")
    end, THEME.off)
    section(pageWh, "LAPORAN AFK")
    toggleRow(pageWh, "Kirim laporan berkala", false, function(on)
        config.statsWebhookOn = on
        if on then
            if not validWebhook(config.statsWebhookUrl) then log("URL webhook laporan belum valid") end
            startStatsLoop()
        end
    end)
    textboxRow(pageWh, "URL Webhook Discord (laporan)", config.statsWebhookUrl, "https://discord.com/api/webhooks/...", function(txt)
        config.statsWebhookUrl = (txt:gsub("%s+", ""))
    end)
    stepperRow(pageWh, "Interval laporan", config.statsIntervalMin, 1, 120, 1, function(v) config.statsIntervalMin = v end, " mnt")
    buttonRow(pageWh, "Kirim laporan sekarang", function()
        if not validWebhook(config.statsWebhookUrl) then log("URL webhook laporan belum valid"); return end
        sendStatsWebhook(true); log("Laporan dikirim")
    end, THEME.off)

    -- ===== TAB CONFIG =====
    local pageCfg = addTab("CONFIG")
    toggleRow(pageCfg, "Efek Petir & Batu (border)", config.fxBorder ~= false, function(on)
        config.fxBorder = on
        if ui.fxLayer then ui.fxLayer.Visible = on end
    end, "Ringan (25 FPS, objek dipakai ulang). Matikan bila HP berat")
    local saveBtn
    saveBtn = buttonRow(pageCfg, "SAVE CONFIG SEKARANG", function()
        local ok = saveSettings(true) -- satu-satunya tempat writefile dipanggil
        saveBtn.Text = ok and "TERSIMPAN!" or "GAGAL (executor tidak support writefile)"
        task.delay(1.5, function() if saveBtn.Parent then saveBtn.Text = "SAVE CONFIG SEKARANG" end end)
    end)
    note(pageCfg, "File config: " .. SAVE_FILE)
    buttonRow(pageCfg, "Hapus file simpanan", function()
        if typeof(delfile) == "function" and typeof(isfile) == "function" then
            pcall(function() if isfile(SAVE_FILE) then delfile(SAVE_FILE) end end)
            lastSavedJson = nil
            log("File simpanan dihapus.")
        else log("Executor tidak mendukung delfile") end
    end, THEME.bad)
    buttonRow(pageCfg, "Unload script", function() cleanup() end, THEME.bad)

    -- ===== TAB DEBUG =====
    local pageDbg = addTab("DEBUG")
    local dbgLines = {}
    local dbgLabel
    local function dbg(text)
        table.insert(dbgLines, tostring(text))
        if #dbgLines > 1500 then table.remove(dbgLines, 1) end
        if dbgLabel then
            local joined = table.concat(dbgLines, "\n")
            dbgLabel.Text = #joined > 8000 and ("...(tampilan dipotong, pakai Salin ke clipboard)\n" .. joined:sub(-8000)) or joined
        end
    end
    local function scanEggs()
        local hrp = getHRP()
        local list = collectEggPrompts()
        dbg(("== SCAN TELUR: %d prompt =="):format(#list))
        for i, p in ipairs(list) do
            if i > 15 then dbg("... dipotong"); break end
            local pos = getPromptPosition(p)
            local d = (hrp and pos) and math.floor((pos - hrp.Position).Magnitude) or -1
            dbg(("%s | aksi='%s' | aktif=%s | jarak=%s | milikku=%s"):format(
                p:GetFullName(), tostring(p.ActionText), tostring(p.Enabled), tostring(d), tostring(ownedByMe(p))))
        end
    end
    local function scanUI()
        dbg("== SCAN UI ==")
        local n = 0
        for _, d in ipairs(playerGui:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and not d:IsDescendantOf(sg) and guiVisible(d) then
                n += 1; if n > 60 then dbg("... dipotong"); break end
                dbg(("%s | teks='%s'"):format(d:GetFullName(), buttonLabel(d)))
            end
        end
    end
    local function scanPrompts()
        local hrp = getHRP()
        if not hrp then dbg("Karakter belum ada"); return end
        dbg("== SCAN PROMPT (radius 120) ==")
        local n = 0
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                local pos = getPromptPosition(p)
                if pos and (pos - hrp.Position).Magnitude <= 120 then
                    n += 1; if n > 40 then dbg("... dipotong"); break end
                    dbg(("%s | aksi='%s' | objek='%s' | aktif=%s"):format(
                        p:GetFullName(), tostring(p.ActionText), tostring(p.ObjectText), tostring(p.Enabled)))
                end
            end
        end
    end
    local function scanRemotes()
        dbg("== SCAN REMOTE ==")
        local n = 0
        for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                n += 1; if n > 80 then dbg("... dipotong"); break end
                dbg(d.ClassName .. " | " .. d:GetFullName())
            end
        end
    end
    local function scanStats()
        local s = readStats()
        dbg("== SCAN STATS ==")
        dbg(("Speed: %s (sumber: %s)"):format(s.speed, s.speedSrc))
        dbg(("Uang: %s (sumber: %s)"):format(s.money, s.moneySrc))
        dbg(("Ping: %d ms"):format(currentPing()))
        local tm = findTreadmill()
        dbg("Treadmill: " .. (tm and (tm:GetFullName() .. " [" .. tostring(Treadmill.how) .. "]") or "tidak ditemukan"))
        dbg("Base: " .. (baseCFrame and "sudah di-set" or "belum di-set"))
    end
    local function scanShopGui()
        dbg("== SCAN SHOP GUI ==")
        for _, def in ipairs(SHOPS) do
            local conts = shopContainers(def)
            dbg(("[%s] frame cocok: %d | terbuka: %s"):format(def.name, #conts, tostring(shopIsOpen(def))))
            for i, c in ipairs(conts) do
                if i > 6 then dbg("  ... dipotong"); break end
                local vis = c:IsA("GuiObject") and ("vis=" .. tostring(c.Visible) .. " size=" .. math.floor(c.AbsoluteSize.X) .. "x" .. math.floor(c.AbsoluteSize.Y)) or ("enabled=" .. tostring(c.Enabled))
                dbg("  " .. c:GetFullName() .. " | " .. vis)
            end
            for i, b in ipairs(findButtons(def.gui, false)) do
                if i > 4 then break end
                dbg("  tombol: " .. b:GetFullName() .. " | '" .. buttonLabel(b) .. "'")
            end
        end
    end
    local function scanFilterText()
        local hrp = getHRP()
        if not hrp then dbg("Karakter belum ada"); return end
        dbg("== SCAN TEKS FILTER (5 telur terdekat) ==")
        local list = {}
        for _, p in ipairs(collectEggPrompts()) do
            local pos = getPromptPosition(p)
            if pos then table.insert(list, { p = p, d = (pos - hrp.Position).Magnitude }) end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        for i = 1, math.min(5, #list) do
            local root = getEggRoot(list[i].p)
            local text = collectEggText(root)
            dbg(("#%d %s | lolos filter=%s"):format(i, root:GetFullName(), tostring(passesFilters(root, text, config.filters))))
            dbg("   " .. text:sub(1, 300))
        end
        if #list == 0 then dbg("Tidak ada prompt telur") end
    end
    local dbgBtns = {
        { "Scan Treadmill (pemilik)", function() V25.scanTreadmill(dbg) end },
        { "Scan Plot / Base", function() V25.scanPlot(dbg) end },
        { "Scan Lab Dr. Scramble / Experiment", function() V25.scanLab(dbg) end },
        { "Scan Jendela GUI Terbuka", function() V25.scanWindows(dbg) end },
        { "Scan Detail Telur (webhook)", function() V25.scanEggDetail(dbg) end },
        { "Scan Remote Penting", function() V25.scanRemotesKey(dbg) end },
        { "Scan Event / Boss", function() V25.scanEvents(dbg) end },
        { "Scan Data Pemain", function() V25.scanPlayerData(dbg) end },
        { "Scan Place / Hatch (plot sendiri)", function() V25.scanPlaceHatch(dbg) end },
        { "Scan Kamus Telur + Uji Filter", function() V25.scanEggVocab(dbg) end },
        { "Scan Struktur Telur (prompt & visual)", function() V25.scanEggStruct(dbg) end },
        { "Scan Telur Dibawa / Tool / Slot Area", function() V25.scanEggItem(dbg) end },
        { "Scan Teks Filter Telur", scanFilterText },
        { "Scan Safe Zone", function() V25.scanSafe(dbg) end },
        { "Scan Shop GUI", scanShopGui },
        { "Scan Telur", scanEggs },
        { "Scan UI (tombol)", scanUI },
        { "Scan Prompt sekitar", scanPrompts },
        { "Scan Remote", scanRemotes },
        { "Scan Stats", scanStats },
        { "Scan Backpack (item)", function() V25.scanBackpack(dbg) end },
        { "Scan Aksi (sell/upgrade/favorit)", function() V25.scanActions(dbg) end },
    }
    local ALL_LABEL = "SCAN SEMUA (sekali tekan)"
    table.insert(dbgBtns, 1, { ALL_LABEL, function()
        dbg("##### SCAN SEMUA DIMULAI #####")
        for _, d in ipairs(dbgBtns) do
            if d[1] ~= ALL_LABEL and not d.skipAll then
                dbg("")
                dbg("##### " .. d[1] .. " #####")
                local ok, err = pcall(d[2])
                if not ok then dbg("ERROR: " .. tostring(err)) end
                task.wait(0.15)
            end
        end
        dbg("##### SELESAI. Tekan 'Salin output ke clipboard' lalu tempel ke chat #####")
    end })
    for _, d in ipairs(dbgBtns) do
        buttonRow(pageDbg, d[1], function()
            task.spawn(function()
                local ok, err = pcall(d[2])
                if not ok then dbg("ERROR scan: " .. tostring(err)) end
            end)
        end, d[1] == ALL_LABEL and THEME.warn or THEME.off)
    end
    buttonRow(pageDbg, "Salin output ke clipboard", function()
        if typeof(setclipboard) == "function" then setclipboard(table.concat(dbgLines, "\n")); log("Output debug disalin")
        else log("Executor tidak mendukung setclipboard") end
    end, THEME.off)
    buttonRow(pageDbg, "Bersihkan output", function() table.clear(dbgLines); if dbgLabel then dbgLabel.Text = "" end end, THEME.off)
    local _, dl = textBox(pageDbg, 220)
    dbgLabel = dl

    -- Animasi border + panel ping
    local frames, lastT = 0, os.clock()
    track(RunService.RenderStepped:Connect(function(dt)
        if not uiAlive then return end
        if win.Visible then
            strokeGrad.Rotation = (strokeGrad.Rotation + dt * 50) % 360
            for _, r in ipairs(bh.rings) do r.grad.Rotation = (r.grad.Rotation + dt * r.speed) % 360 end
            if bh.stars then bh.stars.Rotation = (bh.stars.Rotation + dt * 9) % 360 end
            if bh.coreStroke then bh.coreStroke.Transparency = 0.2 + 0.2 * math.sin(os.clock() * 1.6) end
        end
        frames += 1
        local now = os.clock()
        if now - lastT >= 0.5 then
            local fps = math.floor(frames / (now - lastT) + 0.5)
            frames, lastT = 0, now
            if pingFrame.Visible then
                ui.pingLabel.Text = ("PING %d ms | FPS %d"):format(currentPing(), fps)
            end
        end
    end))
    do
        local function addStroke(o, th)
            if o:FindFirstChildOfClass("UIStroke") then return end
            new("UIStroke", { Color = THEME.accent2, Thickness = th, Transparency = 0.7,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
        end
        for _, d in ipairs(content:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("TextBox") then
                if d.BackgroundTransparency < 1 and d:FindFirstChildOfClass("UICorner") then addStroke(d, 1) end
            elseif d:IsA("Frame") then
                if d.BackgroundTransparency < 0.6 and d:FindFirstChildOfClass("UICorner")
                    and (d.Size.Y.Offset >= 28 or d.AutomaticSize ~= Enum.AutomaticSize.None)
                    and d.Size.X.Scale > 0.3 then addStroke(d, 1) end
            end
        end
    end
    selectTab(tabs[1])
    refreshStats()
    setStatus("Idle", THEME.sub)
end

-- START
if config.method ~= "Fly" and config.method ~= "Walk" then config.method = "Walk" end
if config.targetMode ~= "All" and config.targetMode ~= "Filter" then config.targetMode = "All" end

local okUI, errUI = pcall(buildUI)
if not okUI then
    warn("[Vura] Gagal membuat UI: " .. tostring(errUI))
    pcall(cleanup)
    return
end
Protect.sync(); AFK.sync()
if config.removePopups then setPopupCleaner(true) end
if config.antiLag then setAntiLag(true) end
-- (V38) tidak ada loop auto-save: config disimpan hanya saat tombol SAVE CONFIG diklik
log("Loaded " .. VERSION)
