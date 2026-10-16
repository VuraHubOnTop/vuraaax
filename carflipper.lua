--[[ 
    Vura | Car Flipper Ultimate Hub (Redesigned UI)
    Theme: Modern Dark Clay / Cyber Purple
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui", 10)

-- Hapus GUI lama jika ada
if PlayerGui:FindFirstChild("CarFlipperUltimateFixedHub") then
    PlayerGui.CarFlipperUltimateFixedHub:Destroy()
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
    if carName and carRarity[carName] ~= nil then
        return carRarity[carName]
    end
    return nil
end

local function getCarNameFromSlot(slotId)
    local playerData = player:FindFirstChild("PlayerData") or ReplicatedStorage:FindFirstChild("PlayerData")
    if playerData then
        local cars = playerData:FindFirstChild("Cars") 
            or playerData:FindFirstChild("Inventory") 
            or playerData:FindFirstChild("Garage")
        if cars and cars:FindFirstChild(tostring(slotId)) then
            local carObj = cars[tostring(slotId)]
            local nameVal = carObj:FindFirstChild("CarName") or carObj:FindFirstChild("Name")
            if nameVal and nameVal:IsA("StringValue") then
                return nameVal.Value
            elseif carObj:IsA("StringValue") then
                return carObj.Value
            end
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
        if label and label.Text ~= "" then
            return label.Text
        end
    end
    return nil
end

-- State Filters
local buyFilter = {[0]=false, [1]=false, [2]=false, [3]=false, [4]=false, [5]=false}
local sellFilter = {[0]=false, [1]=false, [2]=false, [3]=false}

-- ===== REMOTES ASLI =====
local RemoteFixCar    = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Repair"):WaitForChild("FixCar")
local RemoteBuyCar    = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Merchant"):WaitForChild("BuyCar")
local RemoteRollCard  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Junkyard"):WaitForChild("Roll")
local RemoteSellCar   = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Garage"):WaitForChild("SellCar")

-- ===== UI STYLING HELPERS =====
local function applyCorner(inst, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = inst
    return corner
end

local function applyStroke(inst, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(140, 80, 255)
    stroke.Thickness = thickness or 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = inst
    return stroke
end

local function applyGradient(inst, col1, col2, rotation)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, col1 or Color3.fromRGB(35, 25, 55)),
        ColorSequenceKeypoint.new(1, col2 or Color3.fromRGB(15, 12, 22))
    }
    grad.Rotation = rotation or 45
    grad.Parent = inst
    return grad
end

local function createStyledButton(parent, text, pos, size, bgCol)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = bgCol or Color3.fromRGB(32, 28, 48)
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(240, 240, 255)
    btn.Text = text
    btn.TextSize = 11
    btn.AutoButtonColor = true
    btn.Parent = parent
    applyCorner(btn, 6)
    applyStroke(btn, Color3.fromRGB(70, 60, 100), 1)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 42, 70)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bgCol or Color3.fromRGB(32, 28, 48)}):Play()
    end)
    
    return btn
end

-- ===== BUILD MAIN UI =====
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "CarFlipperUltimateFixedHub"
ScreenGui.ResetOnSpawn = false

-- Floating Toggle Button (Sangat rapi di pojok kiri atas)
local ToggleUIBtn = Instance.new("TextButton", ScreenGui)
ToggleUIBtn.Size = UDim2.new(0, 110, 0, 32)
ToggleUIBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleUIBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 36)
ToggleUIBtn.Font = Enum.Font.GothamBlack
ToggleUIBtn.Text = "⚡ HBM HUB"
ToggleUIBtn.TextColor3 = Color3.fromRGB(180, 120, 255)
ToggleUIBtn.TextSize = 12
applyCorner(ToggleUIBtn, 8)
applyStroke(ToggleUIBtn, Color3.fromRGB(140, 80, 255), 1.5)

-- Main Frame (Panel Utama)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 460, 0, 340)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 15, 26)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
applyCorner(MainFrame, 12)
applyStroke(MainFrame, Color3.fromRGB(140, 80, 255), 2)
applyGradient(MainFrame, Color3.fromRGB(32, 22, 50), Color3.fromRGB(12, 10, 18), 45)

ToggleUIBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Header / Top Bar
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.Text = "HBM | Car Flipper Hub"
Title.TextColor3 = Color3.fromRGB(240, 240, 255)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 55)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
applyCorner(CloseBtn, 6)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local HeaderLine = Instance.new("Frame", MainFrame)
HeaderLine.Size = UDim2.new(0.92, 0, 0, 1)
HeaderLine.Position = UDim2.new(0.04, 0, 0, 40)
HeaderLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderLine.BackgroundTransparency = 0.85

-- Sidebar Navigation (Tabs)
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 130, 1, -50)
Sidebar.Position = UDim2.new(0, 12, 0, 46)
Sidebar.BackgroundTransparency = 1

local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.Padding = UDim.new(0, 6)

-- Content Area
local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.Size = UDim2.new(1, -160, 1, -55)
ContentContainer.Position = UDim2.new(0, 148, 0, 46)
ContentContainer.BackgroundTransparency = 1

-- Page Frames (Tabs)
local pages = {}
local tabButtons = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame", ContentContainer)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(140, 80, 255)
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    
    pages[name] = page

    local btn = createStyledButton(Sidebar, name, UDim2.new(), UDim2.new(1, 0, 0, 32), Color3.fromRGB(26, 22, 40))
    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for pName, pFrame in pairs(pages) do
            local isTarget = (pName == name)
            pFrame.Visible = isTarget
            tabButtons[pName].BackgroundColor3 = isTarget and Color3.fromRGB(110, 60, 200) or Color3.fromRGB(26, 22, 40)
        end
    end)

    return page
end

local pageMain = createPage("⚡ Main Actions")
local pageBuy = createPage("🛒 Buy Merchant")
local pageSell = createPage("💰 Sell Filter")
local pageTeleport = createPage("📍 Teleports")

-- Open default page
pages["⚡ Main Actions"].Visible = true
tabButtons["⚡ Main Actions"].BackgroundColor3 = Color3.fromRGB(110, 60, 200)

-- ===== PAGE 1: MAIN ACTIONS =====
local btnAutoFarm = createStyledButton(pageMain, "[ SAFE AUTO FARM: OFF ]", UDim2.new(), UDim2.new(1, -6, 0, 36), Color3.fromRGB(120, 35, 45))
local btnRepairAll = createStyledButton(pageMain, "🔧 REPAIR ALL CARS", UDim2.new(), UDim2.new(1, -6, 0, 34), Color3.fromRGB(35, 30, 55))
local btnRollCard = createStyledButton(pageMain, "🎴 ROLL CARD (JUNKYARD)", UDim2.new(), UDim2.new(1, -6, 0, 34), Color3.fromRGB(35, 30, 55))

-- ===== PAGE 2: BUY MERCHANT & FILTER =====
local buyFilterHeader = Instance.new("TextLabel", pageBuy)
buyFilterHeader.Size = UDim2.new(1, -6, 0, 20)
buyFilterHeader.BackgroundTransparency = 1
buyFilterHeader.Font = Enum.Font.GothamBold
buyFilterHeader.Text = "Filter Rarity (Beli Automatic):"
buyFilterHeader.TextColor3 = Color3.fromRGB(180, 180, 210)
buyFilterHeader.TextSize = 10
buyFilterHeader.TextXAlignment = Enum.TextXAlignment.Left

local function makeBuyToggle(rarity, labelText)
    local row = Instance.new("Frame", pageBuy)
    row.Size = UDim2.new(1, -6, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(25, 22, 38)
    applyCorner(row, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.Position = UDim2.new(0.04, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = buyFilter[rarity]
    local btn = createStyledButton(row, state and "ON" or "OFF", UDim2.new(0.7, 0, 0.15, 0), UDim2.new(0.26, 0, 0.7, 0),
        state and Color3.fromRGB(40, 150, 70) or Color3.fromRGB(150, 45, 55))

    btn.MouseButton1Click:Connect(function()
        buyFilter[rarity] = not buyFilter[rarity]
        btn.Text = buyFilter[rarity] and "ON" or "OFF"
        btn.BackgroundColor3 = buyFilter[rarity] and Color3.fromRGB(40, 150, 70) or Color3.fromRGB(150, 45, 55)
    end)
end

makeBuyToggle(0, "Common (0)")
makeBuyToggle(1, "Uncommon (1)")
makeBuyToggle(2, "Rare (2)")
makeBuyToggle(3, "Epic (3)")
makeBuyToggle(4, "Legend (4)")
makeBuyToggle(5, "Mythical (5)")

local buyZonesHeader = Instance.new("TextLabel", pageBuy)
buyZonesHeader.Size = UDim2.new(1, -6, 0, 24)
buyZonesHeader.BackgroundTransparency = 1
buyZonesHeader.Font = Enum.Font.GothamBold
buyZonesHeader.Text = "Beli Manual Per Zone:"
buyZonesHeader.TextColor3 = Color3.fromRGB(180, 180, 210)
buyZonesHeader.TextSize = 10
buyZonesHeader.TextXAlignment = Enum.TextXAlignment.Left

local zones = {"Junkyard", "LowTiers", "Auction", "Suburbs1", "Suburbs2", "Suburbs3", "Port"}

local function buyFromMerchant(zone)
    if not RemoteBuyCar then return end
    local merchants = workspace:FindFirstChild("ActiveMerchants")
    if not merchants then return end

    for slot = 1, 40 do
        local merchantName = nil
        for _, merchantObj in ipairs(merchants:GetChildren()) do
            for _, child in ipairs(merchantObj:GetChildren()) do
                local prompt = child:FindFirstChild("MerchantPrompt", true)
                if prompt 
                    and prompt:GetAttribute("MerchantZone") == zone 
                    and tostring(prompt:GetAttribute("MerchantId")) == tostring(slot) 
                then
                    merchantName = merchantObj.Name
                    break
                end
            end
            if merchantName then break end
        end

        if merchantName then
            local rarity = getRarity(merchantName)
            if rarity and buyFilter[rarity] == true then
                RemoteBuyCar:FireServer(zone, tostring(slot))
                task.wait(0.01)
            end
        end
    end
end

for i, zone in ipairs(zones) do
    local btnZone = createStyledButton(pageBuy, i .. ". Buy Cars (" .. zone .. ")", UDim2.new(), UDim2.new(1, -6, 0, 28), Color3.fromRGB(30, 26, 45))
    btnZone.MouseButton1Click:Connect(function()
        buyFromMerchant(zone)
    end)
end

-- ===== PAGE 3: SELL FILTER & MODAL =====
local sellFilterHeader = Instance.new("TextLabel", pageSell)
sellFilterHeader.Size = UDim2.new(1, -6, 0, 20)
sellFilterHeader.BackgroundTransparency = 1
sellFilterHeader.Font = Enum.Font.GothamBold
sellFilterHeader.Text = "Filter Rarity (Jual Automatic):"
sellFilterHeader.TextColor3 = Color3.fromRGB(180, 180, 210)
sellFilterHeader.TextSize = 10
sellFilterHeader.TextXAlignment = Enum.TextXAlignment.Left

local function makeSellToggle(rarity, labelText)
    local row = Instance.new("Frame", pageSell)
    row.Size = UDim2.new(1, -6, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(25, 22, 38)
    applyCorner(row, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.Position = UDim2.new(0.04, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = sellFilter[rarity]
    local btn = createStyledButton(row, state and "ON" or "OFF", UDim2.new(0.7, 0, 0.15, 0), UDim2.new(0.26, 0, 0.7, 0),
        state and Color3.fromRGB(40, 150, 70) or Color3.fromRGB(150, 45, 55))

    btn.MouseButton1Click:Connect(function()
        sellFilter[rarity] = not sellFilter[rarity]
        btn.Text = sellFilter[rarity] and "ON" or "OFF"
        btn.BackgroundColor3 = sellFilter[rarity] and Color3.fromRGB(40, 150, 70) or Color3.fromRGB(150, 45, 55)
    end)
end

makeSellToggle(0, "Sell Common (0)")
makeSellToggle(1, "Sell Uncommon (1)")
makeSellToggle(2, "Sell Rare (2)")
makeSellToggle(3, "Sell Epic (3)")

local btnClickSell = createStyledButton(pageSell, "🔥 EXECUTE SELL FILTERED CARS", UDim2.new(), UDim2.new(1, -6, 0, 36), Color3.fromRGB(160, 45, 55))

-- Frame Warning Modal (Sell)
local FrameWarning = Instance.new("Frame", ScreenGui)
FrameWarning.Size = UDim2.new(0, 300, 0, 140)
FrameWarning.Position = UDim2.new(0.5, -150, 0.5, -70)
FrameWarning.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
FrameWarning.Active = true
FrameWarning.Draggable = true
FrameWarning.Visible = false
applyCorner(FrameWarning, 12)
applyStroke(FrameWarning, Color3.fromRGB(220, 60, 70), 2)

local WarningText = Instance.new("TextLabel", FrameWarning)
WarningText.Size = UDim2.new(0.9, 0, 0, 45)
WarningText.Position = UDim2.new(0.05, 0, 0, 12)
WarningText.BackgroundTransparency = 1
WarningText.TextColor3 = Color3.fromRGB(240, 240, 255)
WarningText.Font = Enum.Font.GothamMedium
WarningText.TextSize = 11
WarningText.TextWrapped = true
WarningText.Text = "Buka garasi kamu sekarang! Jika tidak, mobil Mythical berisiko terhapus/terjual."

local btnOpenGarage = createStyledButton(FrameWarning, "Buka Garasi", UDim2.new(0.05, 0, 0, 70), UDim2.new(0.42, 0, 0, 35), Color3.fromRGB(80, 30, 40))
local btnConfirmSell = createStyledButton(FrameWarning, "Tetap Jual", UDim2.new(0.53, 0, 0, 70), UDim2.new(0.42, 0, 0, 35), Color3.fromRGB(40, 130, 65))

local function sellFilteredCars()
    if not RemoteSellCar then return end
    for slot = 1, 40 do
        local carName = getCarNameFromSlot(slot)
        if carName then
            local rarity = getRarity(carName)
            if rarity ~= nil and sellFilter[rarity] == true then
                RemoteSellCar:FireServer(tostring(slot))
                task.wait(0.02)
            end
        end
    end
end

local function sellLowTiers()
    if not RemoteSellCar then return end
    for slot = 1, 40 do
        local carName = getCarNameFromSlot(slot)
        if carName then
            local rarity = getRarity(carName)
            if rarity == 0 or rarity == 1 or rarity == 2 then
                RemoteSellCar:FireServer(tostring(slot))
                task.wait(0.02)
            end
        end
    end
end

btnClickSell.MouseButton1Click:Connect(function()
    FrameWarning.Visible = true
end)

btnOpenGarage.MouseButton1Click:Connect(function()
    FrameWarning.Visible = false
    local runtimeGui = PlayerGui:FindFirstChild("RuntimeGui")
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

-- ===== PAGE 4: TELEPORTS =====
local function teleportTo(x, y, z)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(x, y + 3, z)
    end
end

local teleportSpots = {
    {name="Suburbs 1", x=-2403, y=5,   z=223},
    {name="Suburbs 2", x=-142,  y=-25, z=952},
    {name="Suburbs 3", x=1863,  y=5,   z=-534},
}

for i, spot in ipairs(teleportSpots) do
    local btnTp = createStyledButton(pageTeleport, i .. ". Teleport ke " .. spot.name, UDim2.new(), UDim2.new(1, -6, 0, 32), Color3.fromRGB(30, 45, 40))
    btnTp.MouseButton1Click:Connect(function()
        teleportTo(spot.x, spot.y, spot.z)
    end)
end

-- ===== FUNGSI OTOMATISASI KELAS KAKAP =====
local function buyAllFromZone(zone)
    if not RemoteBuyCar then return end
    local merchants = workspace:FindFirstChild("ActiveMerchants")
    if merchants then
        for slot = 1, 40 do
            RemoteBuyCar:FireServer(zone, tostring(slot))
            task.wait(0.01)
        end
    end
end

local function repairAllCars()
    if not RemoteFixCar then return end
    for slot = 1, 40 do
        for _ = 1, 15 do
            RemoteFixCar:FireServer(tostring(slot))
        end
        task.wait(0.01)
    end
end

btnRepairAll.MouseButton1Click:Connect(repairAllCars)

btnRollCard.MouseButton1Click:Connect(function()
    if RemoteRollCard then
        for i = 1, 20 do
            RemoteRollCard:FireServer(tostring(i))
            task.wait(0.02)
        end
    end
end)

-- ===== SAFE AUTO FARM LOOP =====
local autoFarmActive = false

local function autoFarmLoop()
    while autoFarmActive do
        for _, zone in ipairs(zones) do
            if not autoFarmActive then break end
            buyAllFromZone(zone)
            task.wait(0.1)
        end
        
        if autoFarmActive then
            repairAllCars()
            task.wait(0.2)
        end
        
        if autoFarmActive then
            sellLowTiers()
            task.wait(0.2)
        end
        task.wait(0.5)
    end
end

btnAutoFarm.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    if autoFarmActive then
        btnAutoFarm.Text = "[ SAFE AUTO FARM: ON ]"
        btnAutoFarm.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
        task.spawn(autoFarmLoop)
    else
        btnAutoFarm.Text = "[ SAFE AUTO FARM: OFF ]"
        btnAutoFarm.BackgroundColor3 = Color3.fromRGB(150, 45, 55)
    end
end)

-- Hotkey LeftControl
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
        MainFrame.Visible = not MainFrame.Visible
        if not MainFrame.Visible then
            FrameWarning.Visible = false
        end
    end
end)
