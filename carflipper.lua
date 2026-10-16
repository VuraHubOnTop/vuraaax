--[[ 
    ⚡ VURA | CAR FLIPPER RGB PREMIUM HUB ⚡
    Fitur: Animated RGB Border, Roll-Up Minimize, 100% Original Logic + Safety Warning
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui", 10)

if PlayerGui:FindFirstChild("VuraRgbHub") then
    PlayerGui.VuraRgbHub:Destroy()
end

-- ===== DATABASE MOBIL (RARITY) =====
local carRarity = {
    -- Common (0)
    ["Acad iRVS Sedan"]=0, ["Acadi RVS Sedan"]=0, ["Artho G1000"]=0,
    ["Bantt Rental"]=0, ["Bogdan 2099"]=0, ["Chiverleta Golde"]=0,
    ["Chiverleta Outskirts BT"]=0, ["Chiverleta Taohra BT"]=0, ["DAW 0909"]=0,
    ["Deutschotoren C3 B63"]=0, ["Deutschotoren C5 B21"]=0, ["Deutschotoren C543"]=0,
    ["Fedsel Coronet"]=0, ["Fedsel E-Line Cargo"]=0, ["Hakusho Ciri"]=0,
    ["Ivar Manguster"]=0, ["Nikken Altimata"]=0, ["Susuri Vitality"]=0,
    ["Volfsen Passo"]=0, ["Volfsen Rolf"]=0,

    -- Uncommon (1)
    ["Artho G451"]=1, ["Artho G672"]=1, ["Artho X723"]=1,
    ["Chiverleta Cerano"]=1, ["Dawson Hammer JHT8"]=1, ["Deutschotoren C3E5"]=1,
    ["Deutschotoren C560"]=1, ["Deutschotoren C783"]=1, ["Fedsel Expedition"]=1,
    ["Fedsel Stallion G3"]=1, ["Hakusho Concord"]=1, ["Luxius OJ100"]=1,
    ["Marcalen-Denz B660"]=1, ["Marcalen-Denz T600"]=1, ["Mazuta 29"]=1,
    ["Mazuta Mint"]=1, ["Preischel Crayele"]=1, ["Quantum H26"]=1,
    ["Tokina Karma"]=1, ["Tokina RP60"]=1,

    -- Rare (2)
    ["Artho G623"]=2, ["Chiverleta Ceretta X05"]=2, ["Chiverleta Taohra SVV"]=2,
    ["Cryele 222B"]=2, ["Dawson Hammer SCV"]=2, ["Deutschotoren C297x"]=2,
    ["Deutschotoren C393"]=2, ["Fedsel Expedition Hybrid"]=2, ["Fedsel Stallion G5"]=2,
    ["Land Ranger V500"]=2, ["Luxius VQ"]=2, ["Marcalen-Denz K413"]=2,
    ["Mazuta JO4"]=2, ["Mitta Aydens REO"]=2, ["Nikken 290S"]=2,
    ["Nikken Sinata B21"]=2, ["Quantum N500"]=2, ["Suiba Presse RST"]=2,
    ["Tokina Absoluta SR 3.0"]=2,

    -- Epic (3)
    ["Artho F9 ST"]=3, ["Artho G770"]=3, ["Artho VS600"]=3,
    ["Chiverleta Cerano XZ2"]=3, ["Chiverleta Ceretta X07"]=3, ["Chiverleta Imalo 67"]=3,
    ["Dawson Competition"]=3, ["Dawson Hammer"]=3, ["Dawson Hammer 70"]=3,
    ["Dawson Rhino SCT"]=3, ["Deserter Grand Prince"]=3, ["Deutschotoren C2"]=3,
    ["Deutschotoren C3"]=3, ["Deutschotoren C4 DSG"]=3, ["Deutschotoren C483"]=3,
    ["Deutschotoren C5 600"]=3, ["Deutschotoren C873"]=3, ["Deutschotoren S5"]=3,
    ["Deutschotoren U8"]=3, ["Hakusho MRB Sport"]=3, ["Lilia Exima"]=3,
    ["Luxius BG600"]=3, ["Marcalen-Denz VT"]=3, ["Marcalen-Denz LPS"]=3,
    ["Marcalen-Denz LPS94"]=3, ["Nikken Starline S340"]=3, ["Nikken Starline S350"]=3,
    ["Preischel 313n"]=3, ["Tokina Absoluta SR 2.0"]=3,
}

local function getRarity(carName)
    if carName and carRarity[carName] ~= nil then return carRarity[carName] end
    return nil
end

local function getCarNameFromSlot(slotId)
    local pd = player:FindFirstChild("PlayerData") or ReplicatedStorage:FindFirstChild("PlayerData")
    if pd then
        local cars = pd:FindFirstChild("Cars") or pd:FindFirstChild("Inventory") or pd:FindFirstChild("Garage")
        if cars and cars:FindFirstChild(tostring(slotId)) then
            local cObj = cars[tostring(slotId)]
            local nVal = cObj:FindFirstChild("CarName") or cObj:FindFirstChild("Name")
            if nVal and nVal:IsA("StringValue") then return nVal.Value
            elseif cObj:IsA("StringValue") then return cObj.Value end
        end
    end
    
    local runtimeGui = player.PlayerGui:FindFirstChild("RuntimeGui")
    local carList = runtimeGui and runtimeGui:FindFirstChild("Guis") 
        and runtimeGui.Guis:FindFirstChild("Garage") 
        and runtimeGui.Guis.Garage:FindFirstChild("MainFrame") 
        and runtimeGui.Guis.Garage.MainFrame:FindFirstChild("GridFrame") 
        and runtimeGui.Guis.Garage.MainFrame.GridFrame.GridFrame:FindFirstChild("CarList")
    if carList and carList:FindFirstChild(tostring(slotId)) then
        local label = carList[tostring(slotId)]:FindFirstChildWhichIsA("TextLabel", true)
        if label and label.Text ~= "" then return label.Text end
    end
    return nil
end

local buyFilter = {[0]=false, [1]=false, [2]=false, [3]=false, [4]=false, [5]=false}
local sellFilter = {[0]=false, [1]=false, [2]=false, [3]=false}

-- ===== REMOTES ASLI =====
local RemoteFixCar    = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Repair"):WaitForChild("FixCar")
local RemoteBuyCar    = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Merchant"):WaitForChild("BuyCar")
local RemoteRollCard  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Junkyard"):WaitForChild("Roll")
local RemoteSellCar   = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Garage"):WaitForChild("SellCar")

-- ===== UI CORE & STYLING =====
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "VuraRgbHub"
ScreenGui.ResetOnSpawn = false

-- Tombol Toggle
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 110, 0, 32)
ToggleBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Text = "⚡ VURA RGB"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 12
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.fromRGB(0, 255, 150)

-- Main Frame Panel
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 440, 0, 270)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -135)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- ANIMATED RGB BORDER
local RgbStroke = Instance.new("UIStroke", MainFrame)
RgbStroke.Thickness = 2.5
local RgbGradient = Instance.new("UIGradient", RgbStroke)
RgbGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
RunService.RenderStepped:Connect(function()
    RgbGradient.Rotation = (RgbGradient.Rotation + 2) % 360
end)

-- TEXTURE GRID
local GridPattern = Instance.new("ImageLabel", MainFrame)
GridPattern.Size = UDim2.new(1, 0, 1, 0)
GridPattern.BackgroundTransparency = 1
GridPattern.Image = "rbxassetid://4743439972"
GridPattern.ImageTransparency = 0.90
GridPattern.ScaleType = Enum.ScaleType.Tile
GridPattern.TileSize = UDim2.new(0, 40, 0, 40)
Instance.new("UICorner", GridPattern).CornerRadius = UDim.new(0, 10)

local Glow = Instance.new("ImageLabel", MainFrame)
Glow.Size = UDim2.new(1, 0, 1, 0)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = Color3.fromRGB(100, 0, 255)
Glow.ImageTransparency = 0.8
Glow.ZIndex = 0

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0.03, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.Text = "⚡ VURA | RGB Auto Flipper"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize (Roll-up)
local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -55, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(220, 150, 40)
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(1, 0, 0, 1)
Line.Position = UDim2.new(0, 0, 0, 35)
Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Line.BackgroundTransparency = 0.85

-- Logic Animasi Minimize
local isMinimized = false
local openSize = UDim2.new(0, 440, 0, 270)
local minSize = UDim2.new(0, 440, 0, 35)

local function toggleMinimize()
    isMinimized = not isMinimized
    local targetSize = isMinimized and minSize or openSize
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end

MinBtn.MouseButton1Click:Connect(toggleMinimize)
ToggleBtn.MouseButton1Click:Connect(toggleMinimize)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 120, 1, -45)
Sidebar.Position = UDim2.new(0, 10, 0, 40)
Sidebar.BackgroundTransparency = 1
local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.Padding = UDim.new(0, 5)

-- Content Area
local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.Size = UDim2.new(1, -145, 1, -45)
ContentContainer.Position = UDim2.new(0, 135, 0, 40)
ContentContainer.BackgroundTransparency = 1

local function createButton(parent, text, height, bgCol)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -5, 0, height or 30)
    btn.BackgroundColor3 = bgCol or Color3.fromRGB(25, 25, 35)
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(230, 230, 245)
    btn.Text = text
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(60, 60, 80)
    return btn
end

local pages, tabButtons = {}, {}
local function createPage(name)
    local page = Instance.new("ScrollingFrame", ContentContainer)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.Visible = false
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 5)
    pages[name] = page

    local btn = createButton(Sidebar, name, 32, Color3.fromRGB(20, 20, 28))
    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do
            p.Visible = (n == name)
            tabButtons[n].BackgroundColor3 = (n == name) and Color3.fromRGB(90, 40, 180) or Color3.fromRGB(20, 20, 28)
        end
    end)
    return page
end

local pageMain = createPage("🚀 Main Menu")
local pageBuy = createPage("🛒 Buy Setup")
local pageSell = createPage("💰 Sell Setup")
local pageTp = createPage("📍 Teleport")

pages["🚀 Main Menu"].Visible = true
tabButtons["🚀 Main Menu"].BackgroundColor3 = Color3.fromRGB(90, 40, 180)

-- ===== ISI PAGE 1: MAIN MENU =====
local btnAutoFarm = createButton(pageMain, "[ SAFE AUTO FARM: OFF ]", 38, Color3.fromRGB(120, 30, 40))
local btnRepairAll = createButton(pageMain, "🔧 REPAIR ALL CARS", 34)
local btnRollCard = createButton(pageMain, "🎴 ROLL CARD (JUNKYARD)", 34)

-- ===== ISI PAGE 2: BUY SETUP =====
local function makeLabel(parent, txt)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, -5, 0, 20)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(180, 180, 200)
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
end

makeLabel(pageBuy, "Filter Beli Otomatis:")
local function makeToggle(parent, dict, key, label)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -5, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0.05, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = label
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = createButton(row, dict[key] and "ON" or "OFF", 20, dict[key] and Color3.fromRGB(40,140,60) or Color3.fromRGB(140,40,50))
    btn.Size = UDim2.new(0.3, 0, 0, 20)
    btn.Position = UDim2.new(0.65, 0, 0.1, 0)
    
    btn.MouseButton1Click:Connect(function()
        dict[key] = not dict[key]
        btn.Text = dict[key] and "ON" or "OFF"
        btn.BackgroundColor3 = dict[key] and Color3.fromRGB(40,140,60) or Color3.fromRGB(140,40,50)
    end)
end

makeToggle(pageBuy, buyFilter, 0, "Common (0)")
makeToggle(pageBuy, buyFilter, 1, "Uncommon (1)")
makeToggle(pageBuy, buyFilter, 2, "Rare (2)")
makeToggle(pageBuy, buyFilter, 3, "Epic (3)")
makeToggle(pageBuy, buyFilter, 4, "Legend (4)")
makeToggle(pageBuy, buyFilter, 5, "Mythical (5)")

makeLabel(pageBuy, "Beli Manual:")
local zones = {"Junkyard", "LowTiers", "Auction", "Suburbs1", "Suburbs2", "Suburbs3", "Port"}
local function buyFromZoneFunc(zone)
    if not RemoteBuyCar then return end
    local merchants = workspace:FindFirstChild("ActiveMerchants")
    if not merchants then return end
    for slot = 1, 40 do
        local mName = nil
        for _, mObj in ipairs(merchants:GetChildren()) do
            for _, ch in ipairs(mObj:GetChildren()) do
                local p = ch:FindFirstChild("MerchantPrompt", true)
                if p and p:GetAttribute("MerchantZone") == zone and tostring(p:GetAttribute("MerchantId")) == tostring(slot) then
                    mName = mObj.Name; break
                end
            end
            if mName then break end
        end
        if mName then
            local r = getRarity(mName)
            if r and buyFilter[r] == true then
                RemoteBuyCar:FireServer(zone, tostring(slot))
                task.wait(0.01)
            end
        end
    end
end
for _, z in ipairs(zones) do
    local b = createButton(pageBuy, "Buy " .. z, 28)
    b.MouseButton1Click:Connect(function() buyFromZoneFunc(z) end)
end

-- ===== ISI PAGE 3: SELL SETUP & MODAL =====
makeLabel(pageSell, "Filter Jual Otomatis:")
makeToggle(pageSell, sellFilter, 0, "Common (0)")
makeToggle(pageSell, sellFilter, 1, "Uncommon (1)")
makeToggle(pageSell, sellFilter, 2, "Rare (2)")
makeToggle(pageSell, sellFilter, 3, "Epic (3)")

local btnClickSell = createButton(pageSell, "🔥 JUAL MOBIL FILTERED", 36, Color3.fromRGB(160, 50, 60))

-- PENGEMBALIAN FITUR WARNING MODAL
local FrameWarning = Instance.new("Frame", ScreenGui)
FrameWarning.Size = UDim2.new(0, 280, 0, 130)
FrameWarning.Position = UDim2.new(0.5, -140, 0.5, -65)
FrameWarning.BackgroundColor3 = Color3.fromRGB(20, 10, 15)
FrameWarning.Active = true
FrameWarning.Draggable = true
FrameWarning.Visible = false
Instance.new("UICorner", FrameWarning).CornerRadius = UDim.new(0, 8)
local WarnStroke = Instance.new("UIStroke", FrameWarning)
WarnStroke.Color = Color3.fromRGB(255, 0, 0)
WarnStroke.Thickness = 2

-- RGB untuk frame warning (biar dapet kesan bahaya neon)
local WarnGrad = Instance.new("UIGradient", WarnStroke)
WarnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
RunService.RenderStepped:Connect(function() WarnGrad.Rotation = (WarnGrad.Rotation + 3) % 360 end)

local WarningText = Instance.new("TextLabel", FrameWarning)
WarningText.Size = UDim2.new(0.9, 0, 0, 45)
WarningText.Position = UDim2.new(0.05, 0, 0, 10)
WarningText.BackgroundTransparency = 1
WarningText.TextColor3 = Color3.fromRGB(255, 200, 200)
WarningText.Font = Enum.Font.Code
WarningText.TextSize = 11
WarningText.TextWrapped = true
WarningText.Text = "Open gara your PLS :( if not car Mythical will sell"

local btnOpenGarage = createButton(FrameWarning, "forgetten I'll open", 35, Color3.fromRGB(80, 20, 20))
btnOpenGarage.Size = UDim2.new(0.42, 0, 0, 35)
btnOpenGarage.Position = UDim2.new(0.05, 0, 0, 75)

local btnConfirmSell = createButton(FrameWarning, "yeh sell car", 35, Color3.fromRGB(20, 80, 20))
btnConfirmSell.Size = UDim2.new(0.42, 0, 0, 35)
btnConfirmSell.Position = UDim2.new(0.53, 0, 0, 75)

local function sellFilteredCars()
    if not RemoteSellCar then return end
    for s = 1, 40 do
        local n = getCarNameFromSlot(s)
        if n then
            local r = getRarity(n)
            if r ~= nil and sellFilter[r] == true then
                RemoteSellCar:FireServer(tostring(s))
                task.wait(0.02)
            end
        end
    end
end

btnClickSell.MouseButton1Click:Connect(function() FrameWarning.Visible = true end)

btnOpenGarage.MouseButton1Click:Connect(function()
    FrameWarning.Visible = false
    local runtimeGui = player.PlayerGui:FindFirstChild("RuntimeGui")
    local garageBtn = runtimeGui and runtimeGui:FindFirstChild("SideBar") and runtimeGui.SideBar:FindFirstChild("Garage")
    if garageBtn and getconnections then
        for _, conn in ipairs(getconnections(garageBtn.Activated)) do conn:Fire() end
        for _, conn in ipairs(getconnections(garageBtn.MouseButton1Click)) do conn:Fire() end
    end
end)

btnConfirmSell.MouseButton1Click:Connect(function()
    FrameWarning.Visible = false
    sellFilteredCars()
end)

-- ===== ISI PAGE 4: TELEPORTS =====
local tpSpots = {
    {name="Suburbs 1", x=-2403, y=5, z=223},
    {name="Suburbs 2", x=-142, y=-25, z=952},
    {name="Suburbs 3", x=1863, y=5, z=-534},
}
for _, sp in ipairs(tpSpots) do
    local b = createButton(pageTp, "Tp " .. sp.name, 32)
    b.MouseButton1Click:Connect(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            hrp.CFrame = CFrame.new(sp.x, sp.y + 3, sp.z)
        end
    end)
end

-- ===== AUTO FARM LOGIC =====
local autoActive = false

local function repairAll()
    if not RemoteFixCar then return end
    for s = 1, 40 do
        for _ = 1, 15 do RemoteFixCar:FireServer(tostring(s)) end
        task.wait(0.01)
    end
end
btnRepairAll.MouseButton1Click:Connect(repairAll)

btnRollCard.MouseButton1Click:Connect(function()
    if RemoteRollCard then
        for i = 1, 20 do RemoteRollCard:FireServer(tostring(i)); task.wait(0.02) end
    end
end)

local function sellLow()
    if not RemoteSellCar then return end
    for s = 1, 40 do
        local n = getCarNameFromSlot(s)
        if n then
            local r = getRarity(n)
            if r == 0 or r == 1 or r == 2 then
                RemoteSellCar:FireServer(tostring(s)); task.wait(0.02)
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if autoActive then
            for _, z in ipairs(zones) do
                if not autoActive then break end
                -- Mengambil fungsi asli buyAllFromZone(zone) tanpa filter rarity
                if RemoteBuyCar then
                    for s = 1, 40 do RemoteBuyCar:FireServer(z, tostring(s)); task.wait(0.01) end
                end
            end
            if autoActive then repairAll(); task.wait(0.2) end
            if autoActive then sellLow(); task.wait(0.2) end
        end
    end
end)

btnAutoFarm.MouseButton1Click:Connect(function()
    autoActive = not autoActive
    if autoActive then
        btnAutoFarm.Text = "[ SAFE AUTO FARM: ON ]"
        btnAutoFarm.BackgroundColor3 = Color3.fromRGB(40, 160, 70)
    else
        btnAutoFarm.Text = "[ SAFE AUTO FARM: OFF ]"
        btnAutoFarm.BackgroundColor3 = Color3.fromRGB(120, 30, 40)
    end
end)

-- Toggle On/Off via Ctrl
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.LeftControl then
        MainFrame.Visible = not MainFrame.Visible
        if not MainFrame.Visible then
            FrameWarning.Visible = false
        end
    end
end)
