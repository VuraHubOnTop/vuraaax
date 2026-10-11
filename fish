--[[ FISH IT — DIAGNOSTIC SCANNER
     Jalankan DI DALAM game Fish It (Delta/Codex)
     Copy semua output dari tab "OUTPUT" lalu kirim ke Claude
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

local OUT = {}
local function put(s) OUT[#OUT+1] = tostring(s) end
local function head(t) put(""); put("====================================="); put("## "..t); put("=====================================") end

-- ============================================
-- 1. SEMUA REMOTE
-- ============================================
head("1. SEMUA REMOTE (ReplicatedStorage)")
for _, d in ipairs(RS:GetDescendants()) do
    if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
        put(("%s | %s"):format(d.ClassName, d:GetFullName()))
    end
end

-- ============================================
-- 2. SEMUA MODULESCRIPT (untuk cari data ikan)
-- ============================================
head("2. MODULESCRIPT di ReplicatedStorage (top 100)")
local count = 0
for _, d in ipairs(RS:GetDescendants()) do
    if d:IsA("ModuleScript") then
        count += 1
        if count > 100 then put("... dipotong"); break end
        put(("ModuleScript | %s"):format(d:GetFullName()))
    end
end
put(("Total ModuleScript: %d"):format(count))

-- ============================================
-- 3. LEADERSTATS + ATRIBUT PLAYER
-- ============================================
head("3. LEADERSTATS + ATRIBUT PEMAIN")
local ls = lp:FindFirstChild("leaderstats")
if ls then
    for _, v in ipairs(ls:GetChildren()) do
        put(("leaderstats.%s = %s"):format(v.Name, tostring(v.Value)))
    end
else
    put("(tidak ada leaderstats)")
end
put("-- Atribut Player --")
for k, v in pairs(lp:GetAttributes()) do
    put(("attr %s = %s"):format(k, tostring(v)))
end

-- ============================================
-- 4. STRUCTURED FOLDER (kandidat data ikan/rod/bait)
-- ============================================
head("4. FOLDER/MODEL KANDIDAT DATA")
for _, d in ipairs(RS:GetChildren()) do
    put(("%s (%s) - %d anak"):format(d.Name, d.ClassName, #d:GetChildren()))
end
put("")
put("-- Folder di Workspace (top 30) --")
local n = 0
for _, d in ipairs(workspace:GetChildren()) do
    n += 1; if n > 30 then break end
    put(("%s (%s)"):format(d.Name, d.ClassName))
end

-- ============================================
-- 5. GUI UTAMA (untuk cari tombol sell/equip/upgrade)
-- ============================================
head("5. SCREENGUI PEMAIN")
for _, sg in ipairs(pg:GetChildren()) do
    if sg:IsA("ScreenGui") then
        put(("ScreenGui | %s | Enabled=%s"):format(sg.Name, tostring(sg.Enabled)))
    end
end

-- ============================================
-- 6. HOOK REMOTE saat memancing manual (WAJIB!)
-- ============================================
head("6. LIVE HOOK (25 detik) — SILAKAN PANCING MANUAL 1x SEKARANG")
put("==> Petunjuk: tekan OK, LALU pancing manual 1x (charge + reel sampai selesai).")
put("==> Kalau ada efek visual 'kamu dapat ikan X', itu yang kita cari.")
put("")

if hookmetamethod and getnamecallmethod then
    local recorded = {}
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
            local key = self:GetFullName()
            if not recorded[key] then
                recorded[key] = { method = m, args = {}, count = 0 }
            end
            recorded[key].count += 1
            if #recorded[key].args < 3 then
                local a = {}
                for i = 1, select("#", ...) do
                    local v = select(i, ...)
                    local t = typeof(v)
                    if t == "string" then a[i] = '"'..v:sub(1,40)..'"'
                    elseif t == "number" then a[i] = tostring(v)
                    elseif t == "boolean" or t == "nil" then a[i] = tostring(v)
                    elseif t == "table" then
                        local parts = {}
                        for k2, v2 in pairs(v) do
                            parts[#parts+1] = tostring(k2).."="..tostring(v2):sub(1,20)
                            if #parts >= 5 then break end
                        end
                        a[i] = "{"..table.concat(parts, ",").."}"
                    else a[i] = "<"..t..">" end
                end
                recorded[key].args[#recorded[key].args+1] = "("..table.concat(a, ", ")..")"
            end
        end
        return old(self, ...)
    end)

    put("Hook aktif. Menunggu 25 detik...")
    task.wait(25)
    
    put("")
    put("-- HASIL HOOK (remote yang di-fire saat memancing) --")
    for name, info in pairs(recorded) do
        put(("%s | %s | dipanggil %dx"):format(info.method, name, info.count))
        for i, argStr in ipairs(info.args) do
            put("   contoh "..i..": "..argStr)
        end
    end
else
    put("❌ hookmetamethod tidak tersedia di executor ini.")
    put("   Coba pakai Delta Pro / Codex / Synapse.")
end

-- ============================================
-- 7. TRACKER ONSET: cari OnClientEvent yang terpanggil
-- ============================================
head("7. LIVE TRACKER OnClientEvent (25 detik)")
put("==> Pancing manual 1x lagi setelah tekan OK.")
put("")

local caughtData = {}
for _, d in ipairs(RS:GetDescendants()) do
    if d:IsA("RemoteEvent") then
        pcall(function()
            d.OnClientEvent:Connect(function(...)
                local args = table.pack(...)
                local snapshot = {}
                for i = 1, math.min(args.n, 5) do
                    local v = args[i]
                    local t = typeof(v)
                    if t == "string" then snapshot[i] = '"'..v:sub(1,60)..'"'
                    elseif t == "number" then snapshot[i] = tostring(v)
                    elseif t == "table" then
                        local parts = {}
                        for k, v2 in pairs(v) do
                            parts[#parts+1] = tostring(k).."="..tostring(v2):sub(1,30)
                            if #parts >= 8 then break end
                        end
                        snapshot[i] = "{"..table.concat(parts, ",").."}"
                    else snapshot[i] = "<"..t..">" end
                end
                local key = d:GetFullName()
                caughtData[key] = caughtData[key] or {}
                caughtData[key][#caughtData[key]+1] = "("..table.concat(snapshot, ", ")..")"
            end)
        end)
    end
end

task.wait(25)

put("-- HASIL OnClientEvent --")
local any = false
for name, list in pairs(caughtData) do
    any = true
    put(name.." | dipanggil "..#list.."x")
    for i, argStr in ipairs(list) do
        put("   contoh "..i..": "..argStr)
        if i >= 3 then break end
    end
end
if not any then
    put("(tidak ada remote yang memanggil OnClientEvent — mungkin info ikan pakai Attribute/Value/leaderstats)")
end

-- ============================================
-- 8. CEK ATTRIBUTE yang berubah saat memancing
-- ============================================
head("8. ATRIBUT PLAYER - snapshot akhir")
for k, v in pairs(lp:GetAttributes()) do
    put(("attr %s = %s"):format(k, tostring(v)))
end

-- ============================================
-- 9. ISI leaderstats AKHIR (mungkin ada counter ikan)
-- ============================================
head("9. LEADERSTATS - snapshot akhir")
if ls then
    for _, v in ipairs(ls:GetChildren()) do
        put(("%s = %s"):format(v.Name, tostring(v.Value)))
    end
end

-- ============================================
-- TAMPILKAN HASIL
-- ============================================
local finalText = table.concat(OUT, "\n")

-- GUI kecil untuk lihat + copy
local sg = Instance.new("ScreenGui")
sg.Name = "FishItDiagnostic"
sg.ResetOnSpawn = false
sg.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 700, 0, 500)
frame.Position = UDim2.new(0.5, -350, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(20, 9, 36)
frame.BorderSizePixel = 0
frame.Parent = sg
local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.fromOffset(10, 6)
title.BackgroundTransparency = 1
title.Text = "🔍 Fish It Diagnostic — Copy semua teks di bawah"
title.TextColor3 = Color3.fromRGB(246,240,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.fromOffset(10, 40)
scroll.BackgroundColor3 = Color3.fromRGB(8, 3, 18)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.Parent = frame

local tl = Instance.new("TextLabel")
tl.Size = UDim2.new(1, -10, 0, 0)
tl.Position = UDim2.fromOffset(5, 5)
tl.AutomaticSize = Enum.AutomaticSize.Y
tl.BackgroundTransparency = 1
tl.Text = finalText
tl.TextColor3 = Color3.fromRGB(206, 160, 255)
tl.Font = Enum.Font.Code
tl.TextSize = 10
tl.TextWrapped = true
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.TextYAlignment = Enum.TextYAlignment.Top
tl.Parent = scroll

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 200, 0, 24)
copyBtn.Position = UDim2.new(0.5, -100, 1, -30)
copyBtn.BackgroundColor3 = Color3.fromRGB(142, 62, 255)
copyBtn.Text = "📋 Copy ke clipboard"
copyBtn.TextColor3 = Color3.new(1,1,1)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 12
copyBtn.Parent = frame
local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,6); c2.Parent = copyBtn
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(finalText)
        copyBtn.Text = "✅ Tersalin!"
        task.delay(2, function() copyBtn.Text = "📋 Copy ke clipboard" end)
    else
        copyBtn.Text = "❌ Executor tidak support setclipboard"
    end
end)
