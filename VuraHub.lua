--[[
    ⚡ VURA | CAR FLIPPER PREMIUM HUB ⚡
    UI Redesign: Glass Panel, Animated Gradient Border, Sliding Tabs, Animated Switches,
    Toast Notification, Roll-Up Minimize, Pop-in Modal.
    Logic (remote, rarity, auto farm, sell, buy, teleport) = ASLI, tidak diubah.
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

-- =====================================================================
--  UI THEME & HELPERS
-- =====================================================================
local Theme = {
    Bg        = Color3.fromRGB(11, 11, 16),
    Panel     = Color3.fromRGB(17, 17, 25),
    Card      = Color3.fromRGB(23, 23, 34),
    CardHover = Color3.fromRGB(32, 32, 47),
    Line      = Color3.fromRGB(48, 48, 68),
    Text      = Color3.fromRGB(238, 238, 248),
    SubText   = Color3.fromRGB(150, 150, 175),
    Accent    = Color3.fromRGB(145, 95, 255),
    Accent2   = Color3.fromRGB(70, 200, 255),
    Gold      = Color3.fromRGB(255, 205, 110),
    Good      = Color3.fromRGB(60, 210, 130),
    Bad       = Color3.fromRGB(235, 70, 90),
    Warn      = Color3.fromRGB(255, 170, 60),
}

local RarityColor = {
    [0] = Color3.fromRGB(190, 190, 200),
    [1] = Color3.fromRGB(90, 220, 120),
    [2] = Color3.fromRGB(70, 150, 255),
    [3] = Color3.fromRGB(180, 90, 255),
    [4] = Color3.fromRGB(255, 190, 60),
    [5] = Color3.fromRGB(255, 70, 90),
}

local FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local BOUNCY = TweenInfo.new(0.35, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Line
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function padding(obj, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft, p.PaddingTop, p.PaddingRight, p.PaddingBottom =
        UDim.new(0, l), UDim.new(0, t), UDim.new(0, r), UDim.new(0, b)
    p.Parent = obj
    return p
end

local function gradient(obj, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent = obj
    return g
end

local function newLabel(parent, text, size, color, font, alignX)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = font or Enum.Font.GothamMedium
    l.Text = text
    l.TextSize = size or 12
    l.TextColor3 = color or Theme.Text
    l.TextXAlignment = alignX or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- Koneksi dikumpulkan supaya bersih saat UI di-destroy
local connections = {}
local function track(conn) table.insert(connections, conn) return conn end
local alive = true

-- =====================================================================
--  SCREEN GUI & MAIN WINDOW
-- =====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VuraRgbHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local WIN_W, WIN_H, HEADER_H = 540, 350, 44

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
Shadow.Size = UDim2.new(0, WIN_W + 70, 0, WIN_H + 70)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5028857084"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.35
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(24, 24, 276, 276)
Shadow.ZIndex = 0
Shadow.Parent = ScreenGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, WIN_W, 0, WIN_H)
MainFrame.BackgroundColor3 = Theme.Bg
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
corner(MainFrame, 14)
gradient(MainFrame, Color3.fromRGB(16, 14, 26), Color3.fromRGB(9, 9, 14), 135)

-- Skala otomatis untuk HP / layar kecil
local WinScale = Instance.new("UIScale")
WinScale.Parent = MainFrame
local function updateScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    WinScale.Scale = math.clamp(math.min(vp.X / (WIN_W + 40), vp.Y / (WIN_H + 40)), 0.55, 1)
end
updateScale()
if workspace.CurrentCamera then
    track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
end

-- Animated gradient border
local BorderStroke = Instance.new("UIStroke")
BorderStroke.Thickness = 2
BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
BorderStroke.Color = Color3.new(1, 1, 1)
BorderStroke.Parent = MainFrame
local BorderGrad = Instance.new("UIGradient")
BorderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 95, 255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(70, 200, 255)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 205, 110)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 90, 170)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(145, 95, 255)),
})
BorderGrad.Parent = BorderStroke

-- Ambient glow (dekorasi)
local Glow = Instance.new("ImageLabel")
Glow.BackgroundTransparency = 1
Glow.AnchorPoint = Vector2.new(0.5, 0)
Glow.Position = UDim2.new(0.5, 0, 0, -60)
Glow.Size = UDim2.new(1.2, 0, 0, 200)
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = Theme.Accent
Glow.ImageTransparency = 0.88
Glow.ZIndex = 0
Glow.Parent = MainFrame

-- ===== HEADER =====
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, HEADER_H)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = MainFrame

local LogoBadge = Instance.new("Frame")
LogoBadge.Size = UDim2.new(0, 28, 0, 28)
LogoBadge.Position = UDim2.new(0, 14, 0.5, -14)
LogoBadge.BackgroundColor3 = Theme.Accent
LogoBadge.Parent = Header
corner(LogoBadge, 8)
local LogoGrad = gradient(LogoBadge, Theme.Accent, Theme.Accent2, 45)
local LogoText = newLabel(LogoBadge, "⚡", 15, Color3.new(1, 1, 1), Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
LogoText.Size = UDim2.new(1, 0, 1, 0)

local Title = newLabel(Header, "VURA", 15, Theme.Text, Enum.Font.GothamBlack)
Title.Position = UDim2.new(0, 50, 0, 7)
Title.Size = UDim2.new(0, 200, 0, 16)
local TitleGrad = gradient(Title, Theme.Text, Theme.Gold, 0)

local SubTitle = newLabel(Header, "Car Flipper  •  Premium Hub", 10, Theme.SubText, Enum.Font.GothamMedium)
SubTitle.Position = UDim2.new(0, 50, 0, 23)
SubTitle.Size = UDim2.new(0, 220, 0, 12)

local function headerButton(text, xOffset, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 26)
    b.Position = UDim2.new(1, xOffset, 0.5, -13)
    b.BackgroundColor3 = Theme.Card
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBlack
    b.Text = text
    b.TextSize = 13
    b.TextColor3 = Theme.SubText
    b.Parent = Header
    corner(b, 8)
    local s = stroke(b, Theme.Line, 1)
    b.MouseEnter:Connect(function()
        tween(b, FAST, {BackgroundColor3 = color, TextColor3 = Color3.new(1, 1, 1)})
        tween(s, FAST, {Color = color})
    end)
    b.MouseLeave:Connect(function()
        tween(b, FAST, {BackgroundColor3 = Theme.Card, TextColor3 = Theme.SubText})
        tween(s, FAST, {Color = Theme.Line})
    end)
    return b
end

local MinBtn   = headerButton("–", -66, Theme.Warn)
local CloseBtn = headerButton("✕", -34, Theme.Bad)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, -28, 0, 1)
HeaderLine.Position = UDim2.new(0, 14, 0, HEADER_H)
HeaderLine.BackgroundColor3 = Theme.Line
HeaderLine.BackgroundTransparency = 0.4
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = MainFrame

-- ===== DRAG (custom, mendukung mobile & UIScale) =====
local function makeDraggable(handle, target, scaleObj, shadow)
    local dragging, dragStart, startPos = false, nil, nil
    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            local c; c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    c:Disconnect()
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local s = scaleObj and scaleObj.Scale or 1
            local d = (input.Position - dragStart) / s
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
            if shadow then
                shadow.Position = UDim2.new(target.Position.X.Scale, target.Position.X.Offset,
                                            target.Position.Y.Scale, target.Position.Y.Offset + 6)
            end
        end
    end))
end
makeDraggable(Header, MainFrame, WinScale, Shadow)

-- ===== TOAST =====
local Toast = Instance.new("Frame")
Toast.AnchorPoint = Vector2.new(0.5, 1)
Toast.Position = UDim2.new(0.5, 0, 1, 40)
Toast.Size = UDim2.new(0, 230, 0, 30)
Toast.BackgroundColor3 = Theme.Card
Toast.ZIndex = 20
Toast.Parent = MainFrame
corner(Toast, 10)
local ToastStroke = stroke(Toast, Theme.Accent, 1.2)
local ToastLabel = newLabel(Toast, "", 11, Theme.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
ToastLabel.Size = UDim2.new(1, 0, 1, 0)
ToastLabel.ZIndex = 21
local toastToken = 0
local function notify(text, color)
    toastToken += 1
    local my = toastToken
    ToastLabel.Text = text
    ToastStroke.Color = color or Theme.Accent
    Toast.Position = UDim2.new(0.5, 0, 1, 40)
    tween(Toast, BOUNCY, {Position = UDim2.new(0.5, 0, 1, -34)})
    task.delay(2, function()
        if toastToken == my and Toast.Parent then
            tween(Toast, SMOOTH, {Position = UDim2.new(0.5, 0, 1, 40)})
        end
    end)
end

-- ===== FOOTER / STATUS BAR =====
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, -28, 0, 22)
Footer.Position = UDim2.new(0, 14, 1, -28)
Footer.BackgroundTransparency = 1
Footer.Parent = MainFrame

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0, 0, 0.5, -4)
StatusDot.BackgroundColor3 = Theme.Bad
StatusDot.Parent = Footer
corner(StatusDot, 4)

local StatusText = newLabel(Footer, "Auto Farm: Idle", 10, Theme.SubText, Enum.Font.GothamMedium)
StatusText.Position = UDim2.new(0, 14, 0, 0)
StatusText.Size = UDim2.new(0.5, 0, 1, 0)

local HintText = newLabel(Footer, "LeftCtrl  •  Show / Hide", 10, Theme.SubText, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
HintText.Position = UDim2.new(0.5, 0, 0, 0)
HintText.Size = UDim2.new(0.5, 0, 1, 0)

-- ===== SIDEBAR & CONTENT =====
local BODY_TOP = HEADER_H + 10
local BODY_BOTTOM = 34

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 132, 1, -(BODY_TOP + BODY_BOTTOM))
Sidebar.Position = UDim2.new(0, 12, 0, BODY_TOP)
Sidebar.BackgroundColor3 = Theme.Panel
Sidebar.Parent = MainFrame
corner(Sidebar, 12)
stroke(Sidebar, Theme.Line, 1, 0.5)
padding(Sidebar, 6, 6, 6, 6)
local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -(12 + 132 + 10 + 12), 1, -(BODY_TOP + BODY_BOTTOM))
ContentContainer.Position = UDim2.new(0, 12 + 132 + 10, 0, BODY_TOP)
ContentContainer.BackgroundColor3 = Theme.Panel
ContentContainer.ClipsDescendants = true
ContentContainer.Parent = MainFrame
corner(ContentContainer, 12)
stroke(ContentContainer, Theme.Line, 1, 0.5)

-- ===== COMPONENT: ACTION BUTTON =====
local function makeButton(parent, text, height, c1, c2, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, height or 34)
    btn.BackgroundColor3 = Color3.new(1, 1, 1)
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextSize = 12
    btn.TextColor3 = Theme.Text
    btn.LayoutOrder = order or 0
    btn.Parent = parent
    corner(btn, 9)
    local g = gradient(btn, c1 or Theme.Card, c2 or (c1 or Theme.Card):Lerp(Color3.new(0, 0, 0), 0.25), 90)
    local s = stroke(btn, Theme.Line, 1, 0.3)
    local sc = Instance.new("UIScale")
    sc.Parent = btn

    btn.MouseEnter:Connect(function()
        tween(s, FAST, {Color = Theme.Accent, Transparency = 0})
        tween(btn, FAST, {TextColor3 = Color3.new(1, 1, 1)})
    end)
    btn.MouseLeave:Connect(function()
        tween(s, FAST, {Color = Theme.Line, Transparency = 0.3})
        tween(sc, FAST, {Scale = 1})
    end)
    btn.MouseButton1Down:Connect(function() tween(sc, FAST, {Scale = 0.96}) end)
    btn.MouseButton1Up:Connect(function() tween(sc, BOUNCY, {Scale = 1}) end)
    return btn, g, s
end

-- ===== COMPONENT: SECTION LABEL =====
local function makeSection(parent, txt, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order or 0
    f.Parent = parent
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 12)
    bar.Position = UDim2.new(0, 0, 0.5, -6)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = f
    corner(bar, 2)
    local l = newLabel(f, string.upper(txt), 10, Theme.SubText, Enum.Font.GothamBlack)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.Size = UDim2.new(1, -10, 1, 0)
    return f
end

-- ===== COMPONENT: SWITCH TOGGLE =====
local function makeToggle(parent, dict, key, label, color, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Theme.Card
    row.LayoutOrder = order or 0
    row.Parent = parent
    corner(row, 9)
    local rs = stroke(row, Theme.Line, 1, 0.5)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 10, 0.5, -4)
    dot.BackgroundColor3 = color or Theme.Accent
    dot.Parent = row
    corner(dot, 4)

    local lbl = newLabel(row, label, 11, Theme.Text, Enum.Font.GothamMedium)
    lbl.Position = UDim2.new(0, 26, 0, 0)
    lbl.Size = UDim2.new(1, -90, 1, 0)

    local track_ = Instance.new("TextButton")
    track_.Size = UDim2.new(0, 38, 0, 20)
    track_.Position = UDim2.new(1, -48, 0.5, -10)
    track_.AutoButtonColor = false
    track_.Text = ""
    track_.BackgroundColor3 = Theme.Line
    track_.Parent = row
    corner(track_, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 245)
    knob.Parent = track_
    corner(knob, 7)

    local function render(animate)
        local on = dict[key]
        local info = animate and BOUNCY or TweenInfo.new(0)
        tween(knob, info, {Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)})
        tween(track_, FAST, {BackgroundColor3 = on and Theme.Good or Theme.Line})
        tween(rs, FAST, {Color = on and Theme.Good or Theme.Line, Transparency = on and 0.4 or 0.5})
    end
    render(false)

    track_.MouseButton1Click:Connect(function()
        dict[key] = not dict[key]
        render(true)
    end)
    row.MouseEnter:Connect(function() tween(row, FAST, {BackgroundColor3 = Theme.CardHover}) end)
    row.MouseLeave:Connect(function() tween(row, FAST, {BackgroundColor3 = Theme.Card}) end)
    return row
end

-- ===== TABS =====
local pages, tabButtons = {}, {}
local currentTab = nil

local function setTab(name)
    if currentTab == name then return end
    currentTab = name
    for n, p in pairs(pages) do
        local tb = tabButtons[n]
        local active = (n == name)
        tween(tb.Button, FAST, {BackgroundTransparency = active and 0 or 1})
        tween(tb.Bar, SMOOTH, {Size = active and UDim2.new(0, 3, 0, 18) or UDim2.new(0, 3, 0, 0)})
        tween(tb.Label, FAST, {TextColor3 = active and Theme.Text or Theme.SubText})
        if active then
            p.Visible = true
            p.Position = UDim2.new(0, 0, 0, 14)
            tween(p, SMOOTH, {Position = UDim2.new(0, 0, 0, 0)})
        else
            p.Visible = false
        end
    end
end

local tabOrder = 0
local function createPage(name, icon)
    tabOrder += 1

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = ContentContainer
    padding(page, 10, 10, 12, 10)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    pages[name] = page

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Theme.Card
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.LayoutOrder = tabOrder
    btn.Parent = Sidebar
    corner(btn, 9)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 0)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.Position = UDim2.new(0, 2, 0.5, 0)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = btn
    corner(bar, 2)
    gradient(bar, Theme.Accent, Theme.Accent2, 90)

    local ic = newLabel(btn, icon, 14, Theme.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    ic.Position = UDim2.new(0, 10, 0, 0)
    ic.Size = UDim2.new(0, 22, 1, 0)

    local lbl = newLabel(btn, name, 11, Theme.SubText, Enum.Font.GothamBold)
    lbl.Position = UDim2.new(0, 36, 0, 0)
    lbl.Size = UDim2.new(1, -40, 1, 0)

    tabButtons[name] = {Button = btn, Bar = bar, Label = lbl}

    btn.MouseEnter:Connect(function()
        if currentTab ~= name then tween(btn, FAST, {BackgroundTransparency = 0.6}) end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= name then tween(btn, FAST, {BackgroundTransparency = 1}) end
    end)
    btn.MouseButton1Click:Connect(function() setTab(name) end)
    return page
end

local pageMain = createPage("Main Menu", "🚀")
local pageBuy  = createPage("Buy Setup", "🛒")
local pageSell = createPage("Sell Setup", "💰")
local pageTp   = createPage("Teleport", "📍")
local pageInfo = createPage("Info", "ℹ")

-- =====================================================================
--  PAGE 1: MAIN MENU
-- =====================================================================
makeSection(pageMain, "Automation", 1)

-- Kartu Auto Farm besar
local FarmCard = Instance.new("Frame")
FarmCard.Size = UDim2.new(1, 0, 0, 74)
FarmCard.BackgroundColor3 = Theme.Card
FarmCard.LayoutOrder = 2
FarmCard.Parent = pageMain
corner(FarmCard, 12)
local FarmStroke = stroke(FarmCard, Theme.Bad, 1.5, 0.3)
local FarmGrad = gradient(FarmCard, Color3.fromRGB(40, 22, 32), Color3.fromRGB(22, 18, 28), 0)

local FarmTitle = newLabel(FarmCard, "SAFE AUTO FARM", 13, Theme.Text, Enum.Font.GothamBlack)
FarmTitle.Position = UDim2.new(0, 14, 0, 10)
FarmTitle.Size = UDim2.new(1, -110, 0, 16)
local FarmDesc = newLabel(FarmCard, "Buy → Repair → Sell low rarity (loop)", 10, Theme.SubText, Enum.Font.GothamMedium)
FarmDesc.Position = UDim2.new(0, 14, 0, 28)
FarmDesc.Size = UDim2.new(1, -110, 0, 12)
local FarmState = newLabel(FarmCard, "● OFF", 11, Theme.Bad, Enum.Font.GothamBlack)
FarmState.Position = UDim2.new(0, 14, 0, 48)
FarmState.Size = UDim2.new(0, 80, 0, 16)

local FarmSwitch = Instance.new("TextButton")
FarmSwitch.Size = UDim2.new(0, 58, 0, 28)
FarmSwitch.Position = UDim2.new(1, -72, 0.5, -14)
FarmSwitch.AutoButtonColor = false
FarmSwitch.Text = ""
FarmSwitch.BackgroundColor3 = Theme.Line
FarmSwitch.Parent = FarmCard
corner(FarmSwitch, 14)
local FarmKnob = Instance.new("Frame")
FarmKnob.Size = UDim2.new(0, 22, 0, 22)
FarmKnob.Position = UDim2.new(0, 3, 0.5, -11)
FarmKnob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
FarmKnob.Parent = FarmSwitch
corner(FarmKnob, 11)

makeSection(pageMain, "Quick Actions", 3)
local btnRepairAll = makeButton(pageMain, "🔧   Repair All Cars", 36, Color3.fromRGB(34, 34, 52), Color3.fromRGB(26, 26, 40), 4)
local btnRollCard  = makeButton(pageMain, "🎴   Roll Card (Junkyard)", 36, Color3.fromRGB(34, 34, 52), Color3.fromRGB(26, 26, 40), 5)

-- =====================================================================
--  PAGE 2: BUY SETUP
-- =====================================================================
makeSection(pageBuy, "Filter Beli Otomatis", 1)
makeToggle(pageBuy, buyFilter, 0, "Common  (0)",    RarityColor[0], 2)
makeToggle(pageBuy, buyFilter, 1, "Uncommon  (1)",  RarityColor[1], 3)
makeToggle(pageBuy, buyFilter, 2, "Rare  (2)",      RarityColor[2], 4)
makeToggle(pageBuy, buyFilter, 3, "Epic  (3)",      RarityColor[3], 5)
makeToggle(pageBuy, buyFilter, 4, "Legend  (4)",    RarityColor[4], 6)
makeToggle(pageBuy, buyFilter, 5, "Mythical  (5)",  RarityColor[5], 7)

makeSection(pageBuy, "Beli Manual per Zona", 8)
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
for i, z in ipairs(zones) do
    local b = makeButton(pageBuy, "🛒   Buy  " .. z, 32, Color3.fromRGB(34, 34, 52), Color3.fromRGB(26, 26, 40), 8 + i)
    b.MouseButton1Click:Connect(function()
        notify("Buying from " .. z .. "...", Theme.Accent2)
        task.spawn(buyFromZoneFunc, z)
    end)
end

-- =====================================================================
--  PAGE 3: SELL SETUP & MODAL
-- =====================================================================
makeSection(pageSell, "Filter Jual Otomatis", 1)
makeToggle(pageSell, sellFilter, 0, "Common  (0)",   RarityColor[0], 2)
makeToggle(pageSell, sellFilter, 1, "Uncommon  (1)", RarityColor[1], 3)
makeToggle(pageSell, sellFilter, 2, "Rare  (2)",     RarityColor[2], 4)
makeToggle(pageSell, sellFilter, 3, "Epic  (3)",     RarityColor[3], 5)

makeSection(pageSell, "Aksi", 6)
local btnClickSell = makeButton(pageSell, "🔥   JUAL MOBIL FILTERED", 38, Color3.fromRGB(190, 55, 75), Color3.fromRGB(120, 30, 50), 7)

-- ===== WARNING MODAL =====
local Overlay = Instance.new("TextButton")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 1
Overlay.AutoButtonColor = false
Overlay.Text = ""
Overlay.Visible = false
Overlay.ZIndex = 50
Overlay.Parent = ScreenGui

local FrameWarning = Instance.new("Frame")
FrameWarning.AnchorPoint = Vector2.new(0.5, 0.5)
FrameWarning.Position = UDim2.new(0.5, 0, 0.5, 0)
FrameWarning.Size = UDim2.new(0, 320, 0, 170)
FrameWarning.BackgroundColor3 = Color3.fromRGB(20, 14, 20)
FrameWarning.ZIndex = 51
FrameWarning.Parent = Overlay
corner(FrameWarning, 14)
local WarnScale = Instance.new("UIScale")
WarnScale.Scale = 0.85
WarnScale.Parent = FrameWarning
local WarnStroke = Instance.new("UIStroke")
WarnStroke.Thickness = 2
WarnStroke.Color = Color3.new(1, 1, 1)
WarnStroke.Parent = FrameWarning
local WarnGrad = Instance.new("UIGradient")
WarnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 70)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 170, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 70)),
})
WarnGrad.Parent = WarnStroke

local WarnIcon = newLabel(FrameWarning, "⚠", 26, Theme.Warn, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
WarnIcon.Position = UDim2.new(0, 0, 0, 10)
WarnIcon.Size = UDim2.new(1, 0, 0, 30)
WarnIcon.ZIndex = 52

local WarnTitle = newLabel(FrameWarning, "PERINGATAN", 13, Theme.Text, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
WarnTitle.Position = UDim2.new(0, 0, 0, 42)
WarnTitle.Size = UDim2.new(1, 0, 0, 16)
WarnTitle.ZIndex = 52

local WarningText = newLabel(FrameWarning, "Open gara your PLS :( if not car Mythical will sell", 11,
    Color3.fromRGB(255, 210, 210), Enum.Font.Code, Enum.TextXAlignment.Center)
WarningText.Position = UDim2.new(0.06, 0, 0, 62)
WarningText.Size = UDim2.new(0.88, 0, 0, 36)
WarningText.TextWrapped = true
WarningText.ZIndex = 52

local btnOpenGarage = makeButton(FrameWarning, "forgetten I'll open", 36, Color3.fromRGB(120, 40, 50), Color3.fromRGB(80, 22, 34))
btnOpenGarage.Size = UDim2.new(0.42, 0, 0, 36)
btnOpenGarage.Position = UDim2.new(0.06, 0, 1, -50)
btnOpenGarage.ZIndex = 52
btnOpenGarage.TextSize = 11

local btnConfirmSell = makeButton(FrameWarning, "yeh sell car", 36, Color3.fromRGB(40, 150, 90), Color3.fromRGB(26, 100, 62))
btnConfirmSell.Size = UDim2.new(0.42, 0, 0, 36)
btnConfirmSell.Position = UDim2.new(0.52, 0, 1, -50)
btnConfirmSell.ZIndex = 52
btnConfirmSell.TextSize = 11

local function showWarning()
    Overlay.Visible = true
    WarnScale.Scale = 0.85
    tween(Overlay, SMOOTH, {BackgroundTransparency = 0.45})
    tween(WarnScale, BOUNCY, {Scale = 1})
end
local function hideWarning()
    tween(WarnScale, FAST, {Scale = 0.9})
    local t = tween(Overlay, FAST, {BackgroundTransparency = 1})
    t.Completed:Once(function() Overlay.Visible = false end)
end

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

btnClickSell.MouseButton1Click:Connect(showWarning)

btnOpenGarage.MouseButton1Click:Connect(function()
    hideWarning()
    local runtimeGui = player.PlayerGui:FindFirstChild("RuntimeGui")
    local garageBtn = runtimeGui and runtimeGui:FindFirstChild("SideBar") and runtimeGui.SideBar:FindFirstChild("Garage")
    if garageBtn and getconnections then
        for _, conn in ipairs(getconnections(garageBtn.Activated)) do conn:Fire() end
        for _, conn in ipairs(getconnections(garageBtn.MouseButton1Click)) do conn:Fire() end
    end
end)

btnConfirmSell.MouseButton1Click:Connect(function()
    hideWarning()
    notify("Selling filtered cars...", Theme.Bad)
    task.spawn(sellFilteredCars)
end)

-- =====================================================================
--  PAGE 4: TELEPORT
-- =====================================================================
makeSection(pageTp, "Lokasi Cepat", 1)
local tpSpots = {
    {name="Suburbs 1", x=-2403, y=5, z=223},
    {name="Suburbs 2", x=-142, y=-25, z=952},
    {name="Suburbs 3", x=1863, y=5, z=-534},
}
for i, sp in ipairs(tpSpots) do
    local b = makeButton(pageTp, "📍   Teleport  →  " .. sp.name, 36, Color3.fromRGB(34, 34, 52), Color3.fromRGB(26, 26, 40), 1 + i)
    b.MouseButton1Click:Connect(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.CFrame = CFrame.new(sp.x, sp.y + 3, sp.z)
            notify("Teleported: " .. sp.name, Theme.Good)
        else
            notify("Character tidak ditemukan", Theme.Bad)
        end
    end)
end

-- =====================================================================
--  PAGE 5: INFO
-- =====================================================================
makeSection(pageInfo, "Tentang", 1)
local function infoCard(order, head, body, color)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 56)
    f.BackgroundColor3 = Theme.Card
    f.LayoutOrder = order
    f.Parent = pageInfo
    corner(f, 10)
    stroke(f, Theme.Line, 1, 0.5)
    local acc = Instance.new("Frame")
    acc.Size = UDim2.new(0, 3, 1, -16)
    acc.Position = UDim2.new(0, 8, 0, 8)
    acc.BackgroundColor3 = color
    acc.BorderSizePixel = 0
    acc.Parent = f
    corner(acc, 2)
    local h = newLabel(f, head, 12, Theme.Text, Enum.Font.GothamBold)
    h.Position = UDim2.new(0, 22, 0, 8)
    h.Size = UDim2.new(1, -30, 0, 14)
    local b = newLabel(f, body, 10, Theme.SubText, Enum.Font.GothamMedium)
    b.Position = UDim2.new(0, 22, 0, 24)
    b.Size = UDim2.new(1, -30, 0, 26)
    b.TextWrapped = true
    b.TextYAlignment = Enum.TextYAlignment.Top
end
infoCard(2, "Auto Farm", "Loop: beli semua zona → repair semua → jual rarity 0-2.", Theme.Good)
infoCard(3, "Filter Beli / Jual", "Aktifkan switch rarity di tab Buy / Sell Setup sebelum menekan tombol.", Theme.Accent2)
infoCard(4, "Shortcut", "LeftCtrl = tampil / sembunyi. Tombol  –  = roll-up minimize.", Theme.Gold)
infoCard(5, "Peringatan Jual", "Buka Garage dulu agar nama mobil terbaca. Mobil Mythical bisa ikut terjual jika tidak.", Theme.Bad)

-- =====================================================================
--  AUTO FARM LOGIC (ASLI)
-- =====================================================================
local autoActive = false

local function repairAll()
    if not RemoteFixCar then return end
    for s = 1, 40 do
        for _ = 1, 15 do RemoteFixCar:FireServer(tostring(s)) end
        task.wait(0.01)
    end
end

btnRepairAll.MouseButton1Click:Connect(function()
    notify("Repairing all cars...", Theme.Accent2)
    task.spawn(repairAll)
end)

btnRollCard.MouseButton1Click:Connect(function()
    if RemoteRollCard then
        notify("Rolling card...", Theme.Gold)
        task.spawn(function()
            for i = 1, 20 do RemoteRollCard:FireServer(tostring(i)); task.wait(0.02) end
        end)
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
    while alive and task.wait(0.5) do
        if autoActive then
            for _, z in ipairs(zones) do
                if not autoActive then break end
                -- Fungsi asli buyAllFromZone(zone) tanpa filter rarity
                if RemoteBuyCar then
                    for s = 1, 40 do RemoteBuyCar:FireServer(z, tostring(s)); task.wait(0.01) end
                end
            end
            if autoActive then repairAll(); task.wait(0.2) end
            if autoActive then sellLow(); task.wait(0.2) end
        end
    end
end)

local function renderFarm()
    local on = autoActive
    tween(FarmKnob, BOUNCY, {Position = on and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)})
    tween(FarmSwitch, FAST, {BackgroundColor3 = on and Theme.Good or Theme.Line})
    tween(FarmStroke, FAST, {Color = on and Theme.Good or Theme.Bad})
    tween(StatusDot, FAST, {BackgroundColor3 = on and Theme.Good or Theme.Bad})
    FarmState.Text = on and "● ON" or "● OFF"
    tween(FarmState, FAST, {TextColor3 = on and Theme.Good or Theme.Bad})
    FarmGrad.Color = on
        and ColorSequence.new(Color3.fromRGB(20, 44, 34), Color3.fromRGB(18, 26, 28))
        or  ColorSequence.new(Color3.fromRGB(40, 22, 32), Color3.fromRGB(22, 18, 28))
    StatusText.Text = on and "Auto Farm: Running" or "Auto Farm: Idle"
end

FarmSwitch.MouseButton1Click:Connect(function()
    autoActive = not autoActive
    renderFarm()
    notify(autoActive and "Safe Auto Farm  ON" or "Safe Auto Farm  OFF", autoActive and Theme.Good or Theme.Bad)
end)

-- =====================================================================
--  MINIMIZE (ROLL-UP), TOGGLE PILL, CLOSE
-- =====================================================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 120, 0, 34)
ToggleBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleBtn.BackgroundColor3 = Theme.Panel
ToggleBtn.AutoButtonColor = false
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.Text = "⚡  VURA HUB"
ToggleBtn.TextColor3 = Theme.Text
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ScreenGui
corner(ToggleBtn, 17)
local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.new(1, 1, 1)
ToggleStroke.Parent = ToggleBtn
local ToggleGrad = BorderGrad:Clone()
ToggleGrad.Parent = ToggleStroke
local ToggleScale = Instance.new("UIScale")
ToggleScale.Parent = ToggleBtn
ToggleBtn.MouseEnter:Connect(function() tween(ToggleScale, FAST, {Scale = 1.06}) end)
ToggleBtn.MouseLeave:Connect(function() tween(ToggleScale, FAST, {Scale = 1}) end)

local isMinimized = false
local function toggleMinimize()
    isMinimized = not isMinimized
    local h = isMinimized and (HEADER_H + 2) or WIN_H
    tween(MainFrame, SMOOTH, {Size = UDim2.new(0, WIN_W, 0, h)})
    tween(Shadow, SMOOTH, {Size = UDim2.new(0, WIN_W + 70, 0, h + 70)})
    MinBtn.Text = isMinimized and "+" or "–"
    HeaderLine.Visible = not isMinimized
end
MinBtn.MouseButton1Click:Connect(toggleMinimize)
ToggleBtn.MouseButton1Click:Connect(toggleMinimize)

local function cleanup()
    alive = false
    autoActive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
end

CloseBtn.MouseButton1Click:Connect(function()
    tween(WinScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
    tween(Shadow, FAST, {ImageTransparency = 1})
    task.wait(0.28)
    cleanup()
    ScreenGui:Destroy()
end)
ScreenGui.Destroying:Connect(cleanup)

-- Toggle visible via LeftCtrl
track(UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.LeftControl then
        local show = not MainFrame.Visible
        MainFrame.Visible = show
        Shadow.Visible = show
        if not show then
            Overlay.Visible = false
        end
    end
end))

-- =====================================================================
--  ANIMASI LOOP (satu koneksi untuk semua gradient)
-- =====================================================================
track(RunService.RenderStepped:Connect(function(dt)
    local rot = (os.clock() * 90) % 360
    BorderGrad.Rotation = rot
    ToggleGrad.Rotation = rot
    WarnGrad.Rotation = (rot * 1.5) % 360
    TitleGrad.Offset = Vector2.new(math.sin(os.clock() * 1.5) * 0.25, 0)
end))

-- =====================================================================
--  INTRO ANIMATION
-- =====================================================================
local baseScale = WinScale.Scale
WinScale.Scale = 0.01
MainFrame.BackgroundTransparency = 1
tween(MainFrame, SMOOTH, {BackgroundTransparency = 0})
tween(WinScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = baseScale})

renderFarm()
currentTab = nil
setTab("Main Menu")
task.delay(0.6, function() notify("Welcome to VURA Hub ⚡", Theme.Accent) end)
