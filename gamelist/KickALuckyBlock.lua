--[[
    VuraHub | Kick A Lucky Block
    Gabungan open-source:
    - Probeta v2.0.6        : Auto Farm, Perfect Kick, Auto Steal, ESP, Fly, Noclip, Hitbox, Speed, InfJump, Anti-AFK
    - FARTEZ HUB            : Auto Collect Brainrot, Auto Sell, Auto Upgrade
    - Phantom               : Auto Claim, Anti-Void, Auto Respawn, FPS Cap
    - HoshiHub              : Train Mode
    - Cyraa Hub             : Auto Buy Weight, Auto Equip Weight, Kick Power slider
    - WalkyHub              : Auto Collect Volcano Orbs, Brainrot Filter
    - visionware            : Anti Waves, Collection Delay, Auto Place Best
    - Forge Hub             : FOV Slider, Fullbright, No Fog, Hide Other Players
    Belum aktif (placeholder di UI): Anti-Kick, Auto Rejoin, Server Hop, Auto Predict
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Mouse = LP:GetMouse()

-- Registry koneksi + cleanup instance lama (aman untuk re-execute)
local Env = (type(getgenv) == "function" and getgenv()) or _G
if Env.VuraKALB_Cleanup then pcall(Env.VuraKALB_Cleanup) end
local Connections = {}
local Running = true
local UIRefresh = {}  -- fungsi render tiap kontrol, dipanggil ulang setelah Load Config
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

-- Hapus GUI lama
for _, v in ipairs(PlayerGui:GetChildren()) do
    if v.Name == "VuraKALB" then v:Destroy() end
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    -- Farm
    AutoFarm = false, PerfectKick = false, AutoSteal = false, AutoRebirth = false,
    AutoUpgrade = false, AutoCollect = false, AutoClaim = false, AutoSell = false,
    AutoTrain = false, AutoBuyWeight = false, AutoEquipWeight = false, AutoPlace = false,
    AutoSpin = false, AutoOpen = false, AntiWave = false, FollowWave = false,
    -- Combat
    Hitbox = false, HitboxSize = 2, KickPower = 1, AutoPredict = false,
    -- Movement
    SpeedHack = false, SpeedMult = 2, JumpValue = 50, JumpHack = false, InfJump = false,
    Fly = false, FlySpeed = 50, Noclip = false,
    -- Visual
    ESP = false, Fullbright = false, NoFog = false, HideOtherPlayers = false,
    FOV = 70,
    -- Misc
    AntiAFK = true, AntiKick = false, AntiVoid = false, AutoRespawn = false,
    AutoRejoin = false, FpsCap = false,
    -- Extra
    BrainrotFilter = "", ClaimFilter = "", CollectionDelayCs = 10, TrainMode = "Regular",
}

-- FOV asli kamera, dipulihkan saat Close
local OrigFOV = (Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView) or 70

local CONFIG_FILE = "VuraKALB_Config.json"
local hasFS = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

-- ============================================================
-- THEME & TWEEN
-- ============================================================
local Theme = {
    Bg = Color3.fromRGB(11,11,16), Panel = Color3.fromRGB(17,17,25),
    Card = Color3.fromRGB(23,23,34), CardHover = Color3.fromRGB(32,32,47),
    Line = Color3.fromRGB(48,48,68), Text = Color3.fromRGB(238,238,248),
    SubText = Color3.fromRGB(150,150,175), Accent = Color3.fromRGB(145,95,255),
    Accent2 = Color3.fromRGB(70,200,255), Gold = Color3.fromRGB(255,205,110),
    Good = Color3.fromRGB(60,210,130), Bad = Color3.fromRGB(235,70,90),
    Warn = Color3.fromRGB(255,170,60), Pink = Color3.fromRGB(255,90,170),
}
local FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local BOUNCY = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local RAINBOW = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(145,95,255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(70,200,255)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255,205,110)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255,90,170)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(145,95,255)),
})

-- ============================================================
-- HELPER UI
-- ============================================================
local function tween(obj, info, props) local t=TweenService:Create(obj,info,props); t:Play(); return t end
-- Jalankan callback UI; error dicatat lewat warn, tidak ditelan diam-diam
local function runUI(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[VuraKALB] "..tostring(label)..": "..tostring(err)) end
end
local function corner(obj, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=obj; return c end
local function stroke(obj, color, thickness, transparency)
    local s=Instance.new("UIStroke"); s.Color=color or Theme.Line; s.Thickness=thickness or 1
    s.Transparency=transparency or 0; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=obj; return s
end
local function padding(obj,l,t,r,b)
    local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,l); p.PaddingTop=UDim.new(0,t)
    p.PaddingRight=UDim.new(0,r); p.PaddingBottom=UDim.new(0,b); p.Parent=obj; return p
end
local function gradient(obj,c0,c1,rot)
    local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c0,c1); g.Rotation=rot or 90; g.Parent=obj; return g
end
local function newLabel(parent,text,size,color,font,alignX)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Font=font or Enum.Font.GothamMedium
    l.Text=text; l.TextSize=size or 12; l.TextColor3=color or Theme.Text
    l.TextXAlignment=alignX or Enum.TextXAlignment.Left; l.Parent=parent; return l
end

-- ============================================================
-- SCREEN GUI & MAIN WINDOW
-- ============================================================
local WIN_W, WIN_H, HEADER_H = 560, 400, 44
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VuraKALB"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.AnchorPoint = Vector2.new(0.5,0)
Shadow.Position = UDim2.new(0.5,0,0.5,-35)
Shadow.Size = UDim2.new(0,WIN_W+70,0,WIN_H+70)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5028857084"
Shadow.ImageColor3 = Color3.new(0,0,0)
Shadow.ImageTransparency = 0.35
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(24,24,276,276)
Shadow.ZIndex = 0
Shadow.Parent = ScreenGui
local ShadowScale = Instance.new("UIScale"); ShadowScale.Parent = Shadow

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.AnchorPoint = Vector2.new(0.5,0)
MainFrame.Position = UDim2.new(0.5,0,0.5,0)
MainFrame.Size = UDim2.new(0,WIN_W,0,WIN_H)
MainFrame.BackgroundColor3 = Theme.Bg
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
corner(MainFrame, 14)
gradient(MainFrame, Color3.fromRGB(16,14,26), Color3.fromRGB(9,9,14), 135)

-- UIScale auto-fit
local WinScale = Instance.new("UIScale"); WinScale.Parent = MainFrame
local function updateScale()
    local cam = Workspace.CurrentCamera; if not cam then return end
    local vp = cam.ViewportSize
    WinScale.Scale = math.clamp(math.min(vp.X/(WIN_W+40), vp.Y/(WIN_H+40)), 0.55, 1)
    ShadowScale.Scale = WinScale.Scale
end
-- Ikuti kamera aktif: kalau game mengganti CurrentCamera, skala jendela tetap terupdate
local scaleConn
local function bindCamera()
    if scaleConn then scaleConn:Disconnect(); scaleConn = nil end
    local cam = Workspace.CurrentCamera
    if cam then scaleConn = connect(cam:GetPropertyChangedSignal("ViewportSize"), updateScale) end
    updateScale()
end
bindCamera()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)

-- RGB Border
local BorderStroke = Instance.new("UIStroke")
BorderStroke.Thickness = 2
BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
BorderStroke.Color = Color3.new(1,1,1)
BorderStroke.Parent = MainFrame
local BorderGrad = Instance.new("UIGradient")
BorderGrad.Color = RAINBOW
BorderGrad.Parent = BorderStroke

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,HEADER_H)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = MainFrame

local LogoBadge = Instance.new("Frame")
LogoBadge.Size = UDim2.new(0,28,0,28)
LogoBadge.Position = UDim2.new(0,14,0.5,-14)
LogoBadge.BackgroundColor3 = Theme.Accent
LogoBadge.Parent = Header
corner(LogoBadge,8)
gradient(LogoBadge, Theme.Accent, Theme.Accent2, 45)
newLabel(LogoBadge, "⚡", 15, Color3.new(1,1,1), Enum.Font.GothamBlack, Enum.TextXAlignment.Center).Size = UDim2.new(1,0,1,0)

-- JUDUL SUDAH DI-PATCH: VuraHub | Kick A Lucky Block
local Title = newLabel(Header, "VuraHub | Kick A Lucky Block", 13, Theme.Text, Enum.Font.GothamBlack)
Title.Position = UDim2.new(0,50,0,5)
Title.Size = UDim2.new(1,-130,0,18)
Title.TextTruncate = Enum.TextTruncate.AtEnd
gradient(Title, Theme.Text, Theme.Gold, 0)

local SubTitle = newLabel(Header, "Premium Hub • Vura", 10, Theme.SubText, Enum.Font.GothamMedium)
SubTitle.Position = UDim2.new(0,50,0,24)
SubTitle.Size = UDim2.new(1,-130,0,12)

local function headerButton(text,xOffset,color)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,26,0,26); b.Position=UDim2.new(1,xOffset,0.5,-13)
    b.BackgroundColor3=Theme.Card; b.AutoButtonColor=false; b.Font=Enum.Font.GothamBlack
    b.Text=text; b.TextSize=13; b.TextColor3=Theme.SubText; b.Parent=Header
    corner(b,8)
    local s=stroke(b,Theme.Line,1)
    b.MouseEnter:Connect(function()
        tween(b,FAST,{BackgroundColor3=color,TextColor3=Color3.new(1,1,1)})
        tween(s,FAST,{Color=color})
    end)
    b.MouseLeave:Connect(function()
        tween(b,FAST,{BackgroundColor3=Theme.Card,TextColor3=Theme.SubText})
        tween(s,FAST,{Color=Theme.Line})
    end)
    return b
end
local MinBtn = headerButton("–",-66,Theme.Warn)
local CloseBtn = headerButton("✕",-34,Theme.Bad)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size=UDim2.new(1,-28,0,1); HeaderLine.Position=UDim2.new(0,14,0,HEADER_H)
HeaderLine.BackgroundColor3=Theme.Line; HeaderLine.BackgroundTransparency=0.4; HeaderLine.BorderSizePixel=0
HeaderLine.Parent=MainFrame

-- Drag
local function makeDraggable(handle,target,scaleObj,shadow)
    local dragging,dragStart,startPos=false,nil,nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=target.Position
            local c; c=input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false; c:Disconnect() end
            end)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local s=scaleObj and scaleObj.Scale or 1
            local d=(input.Position-dragStart)/s
            target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            if shadow then shadow.Position=UDim2.new(target.Position.X.Scale,target.Position.X.Offset,target.Position.Y.Scale,target.Position.Y.Offset-35) end
        end
    end)
end
makeDraggable(Header,MainFrame,WinScale,Shadow)

-- Toast
local Toast=Instance.new("Frame")
Toast.AnchorPoint=Vector2.new(0.5,1); Toast.Position=UDim2.new(0.5,0,1,40)
Toast.Size=UDim2.new(0,250,0,30); Toast.BackgroundColor3=Theme.Card; Toast.ZIndex=20; Toast.Parent=MainFrame
corner(Toast,10)
local ToastStroke=stroke(Toast,Theme.Accent,1.2)
local ToastLabel=newLabel(Toast,"",11,Theme.Text,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
ToastLabel.Size=UDim2.new(1,0,1,0); ToastLabel.ZIndex=21
local toastToken=0
local function notify(text,color)
    toastToken+=1; local my=toastToken
    ToastLabel.Text=text; ToastStroke.Color=color or Theme.Accent
    Toast.Position=UDim2.new(0.5,0,1,40)
    tween(Toast,BOUNCY,{Position=UDim2.new(0.5,0,1,-34)})
    task.delay(2,function()
        if toastToken==my and Toast.Parent then
            tween(Toast,SMOOTH,{Position=UDim2.new(0.5,0,1,40)})
        end
    end)
end

-- Footer
local Footer=Instance.new("Frame")
Footer.Size=UDim2.new(1,-28,0,22); Footer.Position=UDim2.new(0,14,1,-28)
Footer.BackgroundTransparency=1; Footer.Parent=MainFrame
local StatusDot=Instance.new("Frame")
StatusDot.Size=UDim2.new(0,8,0,8); StatusDot.Position=UDim2.new(0,0,0.5,-4)
StatusDot.BackgroundColor3=Theme.Bad; StatusDot.Parent=Footer
corner(StatusDot,4)
local StatusText=newLabel(Footer,"Auto Farm: Idle",10,Theme.SubText,Enum.Font.GothamMedium)
StatusText.Position=UDim2.new(0,14,0,0); StatusText.Size=UDim2.new(0.5,0,1,0)
local HintText=newLabel(Footer,"LeftCtrl • Show / Hide",10,Theme.SubText,Enum.Font.GothamMedium,Enum.TextXAlignment.Right)
HintText.Position=UDim2.new(0.5,0,0,0); HintText.Size=UDim2.new(0.5,0,1,0)

-- Sidebar & Content
local BODY_TOP=HEADER_H+10
local BODY_BOTTOM=34

local Sidebar=Instance.new("Frame")
Sidebar.Size=UDim2.new(0,132,1,-(BODY_TOP+BODY_BOTTOM)); Sidebar.Position=UDim2.new(0,12,0,BODY_TOP)
Sidebar.BackgroundColor3=Theme.Panel; Sidebar.Parent=MainFrame
corner(Sidebar,12); stroke(Sidebar,Theme.Line,1,0.5); padding(Sidebar,6,6,6,6)
local SidebarLayout=Instance.new("UIListLayout")
SidebarLayout.Padding=UDim.new(0,4); SidebarLayout.SortOrder=Enum.SortOrder.LayoutOrder; SidebarLayout.Parent=Sidebar

local ContentContainer=Instance.new("Frame")
ContentContainer.Size=UDim2.new(1,-(12+132+10+12),1,-(BODY_TOP+BODY_BOTTOM))
ContentContainer.Position=UDim2.new(0,12+132+10,0,BODY_TOP)
ContentContainer.BackgroundColor3=Theme.Panel; ContentContainer.ClipsDescendants=true; ContentContainer.Parent=MainFrame
corner(ContentContainer,12); stroke(ContentContainer,Theme.Line,1,0.5)

-- ============================================================
-- KOMPONEN UI
-- ============================================================
local function makeButton(parent,text,height,c1,c2,order,callback)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,height); holder.BackgroundTransparency=1; holder.LayoutOrder=order or 0; holder.Parent=parent
    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.new(1,1,1); bg.Parent=holder
    corner(bg,9)
    gradient(bg,c1 or Theme.Card,c2 or (c1 or Theme.Card):Lerp(Color3.new(0,0,0),0.25),90)
    local st=stroke(bg,Theme.Line,1,0.3)
    local label=newLabel(bg,text,12,Theme.Text,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
    label.Size=UDim2.new(1,0,1,0)
    local press=Instance.new("UIScale"); press.Parent=bg
    local hit=Instance.new("TextButton")
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""; hit.AutoButtonColor=false; hit.Parent=holder
    hit.MouseEnter:Connect(function()
        tween(st,FAST,{Color=Theme.Accent,Transparency=0})
        tween(label,FAST,{TextColor3=Color3.new(1,1,1)})
    end)
    hit.MouseLeave:Connect(function()
        tween(st,FAST,{Color=Theme.Line,Transparency=0.3})
        tween(label,FAST,{TextColor3=Theme.Text})
        tween(press,FAST,{Scale=1})
    end)
    hit.MouseButton1Down:Connect(function() tween(press,FAST,{Scale=0.96}) end)
    hit.MouseButton1Up:Connect(function() tween(press,BOUNCY,{Scale=1}) end)
    if callback then hit.MouseButton1Click:Connect(function() runUI(text, callback) end) end
    return holder,hit
end

local function makeSection(parent,txt,order)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1; f.LayoutOrder=order or 0; f.Parent=parent
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0,3,0,12); bar.Position=UDim2.new(0,0,0.5,-6); bar.BackgroundColor3=Theme.Accent
    bar.BorderSizePixel=0; bar.Parent=f
    corner(bar,2)
    local l=newLabel(f,string.upper(txt),10,Theme.SubText,Enum.Font.GothamBlack)
    l.Position=UDim2.new(0,10,0,0); l.Size=UDim2.new(1,-10,1,0)
    return f
end

local function makeToggle(parent,dict,key,label,color,order,onChange)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=Theme.Card; row.LayoutOrder=order or 0; row.Parent=parent
    corner(row,9)
    local rs=stroke(row,Theme.Line,1,0.5)
    local dot=Instance.new("Frame")
    dot.Size=UDim2.new(0,8,0,8); dot.Position=UDim2.new(0,10,0.5,-4); dot.BackgroundColor3=color or Theme.Accent
    dot.Parent=row; corner(dot,4)
    local lbl=newLabel(row,label,11,Theme.Text,Enum.Font.GothamMedium)
    lbl.Position=UDim2.new(0,26,0,0); lbl.Size=UDim2.new(1,-90,1,0)
    local track=Instance.new("TextButton")
    track.Size=UDim2.new(0,38,0,20); track.Position=UDim2.new(1,-48,0.5,-10)
    track.AutoButtonColor=false; track.Text=""; track.BackgroundColor3=Theme.Line; track.Parent=row
    corner(track,10)
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14); knob.Position=UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3=Color3.fromRGB(235,235,245); knob.Parent=track
    corner(knob,7)
    local function render(animate)
        local on=dict[key]
        local info=animate and BOUNCY or TweenInfo.new(0)
        tween(knob,info,{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
        tween(track,FAST,{BackgroundColor3=on and Theme.Good or Theme.Line})
        tween(rs,FAST,{Color=on and Theme.Good or Theme.Line,Transparency=on and 0.4 or 0.5})
    end
    render(false)
    table.insert(UIRefresh, function() render(false) end)
    track.MouseButton1Click:Connect(function()
        dict[key]=not dict[key]
        render(true)
        if onChange then runUI(label,onChange,dict[key]) end
    end)
    row.MouseEnter:Connect(function() tween(row,FAST,{BackgroundColor3=Theme.CardHover}) end)
    row.MouseLeave:Connect(function() tween(row,FAST,{BackgroundColor3=Theme.Card}) end)
    return row
end

local function makeSlider(parent,dict,key,label,minV,maxV,color,order,onChange)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,46); row.BackgroundColor3=Theme.Card; row.LayoutOrder=order or 0; row.Parent=parent
    corner(row,9); stroke(row,Theme.Line,1,0.5)
    newLabel(row,label,12,Theme.Text,Enum.Font.GothamMedium).Position=UDim2.new(0,12,0,6)
    local valLbl=newLabel(row,tostring(dict[key]),12,color,Enum.Font.GothamBold,Enum.TextXAlignment.Right)
    valLbl.Position=UDim2.new(0.6,0,0,6); valLbl.Size=UDim2.new(0.4,-12,0,16)
    local bar=Instance.new("Frame")
    bar.Position=UDim2.new(0,12,0,30); bar.Size=UDim2.new(1,-24,0,6); bar.BackgroundColor3=Theme.Bg; bar.Parent=row
    corner(bar,3)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=color; fill.Parent=bar
    corner(fill,3)
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(0,0,0.5,0); knob.BackgroundColor3=Color3.new(1,1,1); knob.Parent=bar
    corner(knob,7)
    local hit=Instance.new("TextButton")
    hit.BackgroundTransparency=1; hit.Text=""; hit.AutoButtonColor=false
    hit.Size=UDim2.new(1,0,1,0); hit.Parent=row
    local function setVal(v,silent)
        v=math.clamp(math.floor(v+0.5),minV,maxV); dict[key]=v
        local p=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,0); valLbl.Text=tostring(v)
        if not silent and onChange then runUI(label,onChange,v) end
    end
    setVal(dict[key],true)
    table.insert(UIRefresh, function() setVal(dict[key],true) end)
    local dragging=false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            local w=bar.AbsoluteSize.X
            if w>0 then
                local p=math.clamp((input.Position.X-bar.AbsolutePosition.X)/w,0,1)
                setVal(minV+p*(maxV-minV))
            end
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local w=bar.AbsoluteSize.X
            if w>0 then
                local p=math.clamp((input.Position.X-bar.AbsolutePosition.X)/w,0,1)
                setVal(minV+p*(maxV-minV))
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    return row
end

local function makeInput(parent,dict,key,placeholder,order,onChange)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,32); row.BackgroundColor3=Theme.Card; row.LayoutOrder=order or 0; row.Parent=parent
    corner(row,9); local st=stroke(row,Theme.Line,1,0.5)
    local box=Instance.new("TextBox")
    box.BackgroundTransparency=1; box.BorderSizePixel=0
    box.Position=UDim2.new(0,12,0,0); box.Size=UDim2.new(1,-24,1,0)
    box.PlaceholderText=placeholder; box.PlaceholderColor3=Theme.SubText
    box.Text=dict[key] or ""; box.ClearTextOnFocus=false
    box.Font=Enum.Font.Gotham; box.TextSize=12; box.TextColor3=Theme.Text
    box.TextXAlignment=Enum.TextXAlignment.Left; box.Parent=row
    table.insert(UIRefresh, function() box.Text=dict[key] or "" end)
    box.Focused:Connect(function() tween(st,FAST,{Color=Theme.Accent}) end)
    box.FocusLost:Connect(function()
        tween(st,FAST,{Color=Theme.Line})
        dict[key]=box.Text
        if onChange then runUI(placeholder,onChange,box.Text) end
    end)
    return row
end

-- Tabs
local pages,tabButtons={}, {}
local currentTab=nil
local function setTab(name)
    if currentTab==name then return end
    currentTab=name
    for n,p in pairs(pages) do
        local tb=tabButtons[n]
        local active=(n==name)
        tween(tb.Button,FAST,{BackgroundTransparency=active and 0 or 1})
        tween(tb.Bar,SMOOTH,{Size=active and UDim2.new(0,3,0,18) or UDim2.new(0,3,0,0)})
        tween(tb.Label,FAST,{TextColor3=active and Theme.Text or Theme.SubText})
        if active then
            p.Visible=true
            p.Position=UDim2.new(0,0,0,14)
            tween(p,SMOOTH,{Position=UDim2.new(0,0,0,0)})
        else
            p.Visible=false
        end
    end
end

local tabOrder=0
local function createPage(name,icon)
    tabOrder+=1
    local page=Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.ScrollBarThickness=3; page.ScrollBarImageColor3=Theme.Accent
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.CanvasSize=UDim2.new(0,0,0,0)
    page.Visible=false; page.Parent=ContentContainer
    padding(page,10,10,12,10)
    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,6); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=page
    pages[name]=page

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,36); btn.BackgroundColor3=Theme.Card
    btn.BackgroundTransparency=1; btn.AutoButtonColor=false; btn.Text=""
    btn.LayoutOrder=tabOrder; btn.Parent=Sidebar
    corner(btn,9)
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(0,3,0,0); bar.AnchorPoint=Vector2.new(0,0.5)
    bar.Position=UDim2.new(0,2,0.5,0); bar.BackgroundColor3=Theme.Accent
    bar.BorderSizePixel=0; bar.Parent=btn
    corner(bar,2)
    gradient(bar,Theme.Accent,Theme.Accent2,90)
    local ic=newLabel(btn,icon,14,Theme.Text,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
    ic.Position=UDim2.new(0,10,0,0); ic.Size=UDim2.new(0,22,1,0)
    local lbl=newLabel(btn,name,11,Theme.SubText,Enum.Font.GothamBold)
    lbl.Position=UDim2.new(0,36,0,0); lbl.Size=UDim2.new(1,-40,1,0)
    tabButtons[name]={Button=btn,Bar=bar,Label=lbl}
    btn.MouseEnter:Connect(function()
        if currentTab~=name then tween(btn,FAST,{BackgroundTransparency=0.6}) end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab~=name then tween(btn,FAST,{BackgroundTransparency=1}) end
    end)
    btn.MouseButton1Click:Connect(function() setTab(name) end)
    return page
end

-- ============================================================
-- LOGIKA GAME (gabungan semua sumber)
-- ============================================================

-- Cache scan: 1x GetDescendants per ~2 detik. Hasil dipisah per jenis supaya fitur lain
-- tidak perlu memproses string nama lagi. Karakter pemain tidak ikut masuk daftar.
local Cache = {
    Blocks = {},         -- part bernama "lucky"
    Brainrots = {},      -- model target Auto Collect (brainrot/cash/ore/volcano)
    BrainrotOnly = {},   -- model bernama "brainrot" (untuk ESP)
    Buttons = {}, ButtonText = {},
    WorldAt = 0, GuiAt = 0,
}

-- Diisi setelah tsunamiActive & antiWave terdefinisi: true bila posisi karakter sedang
-- diatur fitur lain (Follow Wave, atau baru saja kabur dari gelombang).
local movementLocked = function() return false end

local function scanWorld(force)
    local gap = force and 0.5 or 2
    if os.clock() - Cache.WorldAt < gap then return end
    Cache.WorldAt = os.clock()
    local blocks, brain, brainOnly = {}, {}, {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            if v.Name:lower():find("lucky") then blocks[#blocks+1] = v end
        elseif v:IsA("Model") and not Players:GetPlayerFromCharacter(v) then
            local n = v.Name:lower()
            local isBrain = n:find("brainrot") ~= nil
            if isBrain then brainOnly[#brainOnly+1] = v end
            if isBrain or n:find("cash") or n:find("%f[%a]ore%f[%A]") or n:find("volcano") then
                brain[#brain+1] = v
            end
        end
    end
    Cache.Blocks, Cache.Brainrots, Cache.BrainrotOnly = blocks, brain, brainOnly
end

-- Teks tombol dihitung sekali per scan (maks 2 detik basi), bukan tiap pemanggilan fitur.
local function scanGui(force)
    local gap = force and 0.5 or 2
    if os.clock() - Cache.GuiAt < gap then return end
    Cache.GuiAt = os.clock()
    local list, texts = {}, {}
    for _, v in ipairs(PlayerGui:GetDescendants()) do
        -- TextButton dan ImageButton (mis. tombol "Bonus"); ImageButton tidak punya teks, hanya nama
        if v:IsA("GuiButton") and not v:IsDescendantOf(ScreenGui) then
            list[#list+1] = v
            texts[v] = v.Name:lower().." "..(v:IsA("TextButton") and v.Text:lower() or "")
        end
    end
    Cache.Buttons, Cache.ButtonText = list, texts
end

-- Helper: cari blok terdekat (pakai cache)
local function getNearestBlock()
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    scanWorld()
    local nearest,shortest=nil,math.huge
    for _,v in ipairs(Cache.Blocks) do
        if v.Parent then
            local dist=(hrp.Position-v.Position).Magnitude
            if dist<shortest then shortest=dist; nearest=v end
        end
    end
    return nearest
end

-- Remote kick asli: ReplicatedStorage.Shared.Packages.Network.rev_KickEvent:FireServer(strength)
local KickEvent
local function getKickEvent()
    if KickEvent and KickEvent.Parent then return KickEvent end
    local shared=ReplicatedStorage:FindFirstChild("Shared")
    local packages=shared and shared:FindFirstChild("Packages")
    local network=packages and packages:FindFirstChild("Network")
    KickEvent=network and network:FindFirstChild("rev_KickEvent")
    return KickEvent
end

local function fireKickRemote()
    local ev=getKickEvent()
    if ev then
        pcall(function() ev:FireServer(State.KickPower or 1) end)
    else
        -- fallback kalau remote tidak ditemukan
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(Mouse.X,Mouse.Y))
    end
end

-- Area teleport sebelum kick: workspace.Areas.KickReady
local function kickAreaPosition()
    local areas=Workspace:FindFirstChild("Areas")
    local a=areas and areas:FindFirstChild("KickReady")
    if not a then return nil end
    if a:IsA("BasePart") then return a.Position end
    if a:IsA("Model") then return a:GetPivot().Position end
    local part=a:FindFirstChildWhichIsA("BasePart",true)
    return part and part.Position
end

-- force=true: selalu teleport; false: hanya bila jarak > 15 stud
local function teleportToKickArea(force)
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local pos=kickAreaPosition()
    if not hrp or not pos then return false end
    if force or (hrp.Position-pos).Magnitude>15 then
        hrp.CFrame=CFrame.new(pos+Vector3.new(0,4,0))
    end
    return true
end

-- Tampil di layar hanya bila seluruh induk sampai PlayerGui terlihat
local function isShown(obj)
    local o = obj
    while o and o ~= PlayerGui do
        if o:IsA("GuiObject") and not o.Visible then return false end
        if o:IsA("ScreenGui") and not o.Enabled then return false end
        o = o.Parent
    end
    return o == PlayerGui
end

-- Perfect Kick: dicek tiap Heartbeat (bukan tiap 0.5 detik) supaya zona tidak terlewat.
-- Hanya bereaksi saat meter tampil; menembak kick otomatis ditangani Auto Farm.
-- PerfectZone & Bar di-cache (dicari ulang bila hilang); nama sesuai kode game.
local lastPerfect=0
local pkZone, pkBar
local function perfectKick()
    if not (pkZone and pkBar and pkZone:IsDescendantOf(PlayerGui) and pkBar:IsDescendantOf(PlayerGui)) then
        pkZone, pkBar = nil, nil
        local kickMeter=PlayerGui:FindFirstChild("KickMeter")
        if not kickMeter then return end
        local zone=kickMeter:FindFirstChild("PerfectZone",true)
        local bar=kickMeter:FindFirstChild("Bar",true)
        if not zone or not bar then return end
        pkZone, pkBar = zone, bar
    end
    local zone, bar = pkZone, pkBar
    if not isShown(bar) then return end
    -- posisi tengah indikator vs rentang zona perfect (sama-sama piksel layar)
    local bx=bar.AbsolutePosition.X+bar.AbsoluteSize.X/2
    local z0=zone.AbsolutePosition.X
    local z1=z0+zone.AbsoluteSize.X
    if bx>=z0 and bx<=z1 and os.clock()-lastPerfect>0.4 then
        lastPerfect=os.clock()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(Mouse.X,Mouse.Y))
    end
end
connect(RunService.Heartbeat, function()
    if State.PerfectKick then pcall(perfectKick) end
end)

-- Jalan ke posisi dan tunggu sampai tiba, timeout, atau abort() bernilai true
local function moveTo(hum, pos, timeout, abort)
    local done=false
    local c=hum.MoveToFinished:Connect(function() done=true end)
    hum:MoveTo(pos)
    local t0=os.clock()
    while not done and Running and hum.Parent and os.clock()-t0<(timeout or 5)
        and not (abort and abort()) do
        task.wait(0.1)
    end
    c:Disconnect()
end

-- Auto Collect (Probeta + WalkyHub) - jalan sendiri, tidak tergantung Auto Farm
local warnedTouch=false
local function collectBrainrots()
    if type(firetouchinterest)~="function" then
        if not warnedTouch then
            warnedTouch=true
            notify("Executor tidak mendukung firetouchinterest",Theme.Bad)
        end
        return
    end
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    scanWorld()
    local filter=(State.BrainrotFilter or ""):lower()
    for _,v in ipairs(Cache.Brainrots) do
        if not (Running and State.AutoCollect) then return end   -- toggle dimatikan / Close di tengah pass
        if v.Parent and (filter=="" or v.Name:lower():find(filter,1,true)) then
            -- firetouchinterest butuh BasePart, bukan objek TouchInterest
            local part
            local ti=v:FindFirstChildWhichIsA("TouchTransmitter",true)
            if ti and ti.Parent:IsA("BasePart") then
                part=ti.Parent
            else
                part=v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart",true)
            end
            if part then
                pcall(firetouchinterest,hrp,part,0)
                task.wait((State.CollectionDelayCs or 5)/100)
                pcall(firetouchinterest,hrp,part,1)
            end
        end
    end
end

-- Auto Steal: part "lucky" yang Parent-nya punya "Owner" dengan Value bukan kita (sesuai kode game).
-- Satu target terdekat per siklus.
-- Pemilik blok: objek "Owner" (ValueBase) di Parent part, atau attribute "Owner".
-- Mengembalikan (nilai, ada). Objek bernama Owner yang bukan ValueBase tidak di-index .Value.
local function readOwner(container)
    local o=container:FindFirstChild("Owner")
    if o and o:IsA("ValueBase") then return o.Value, true end
    local attr=container:GetAttribute("Owner")
    if attr~=nil then return attr, true end
    return nil, false
end

local function ownedByMe(v)
    return v==LP.Name or v==LP or v==LP.UserId or v==LP.DisplayName
end

-- Mengembalikan true bila ada target dan aksi dijalankan.
-- Blok tanpa pemilik (Owner kosong) dilewati: tidak ada yang bisa dicuri.
local function autoSteal()
    local char=LP.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return false end
    scanWorld()
    local target,best=nil,math.huge
    for _,v in ipairs(Cache.Blocks) do
        local parent=v.Parent
        if parent then
            local val,has=readOwner(parent)
            if has and val~=nil and val~="" and not ownedByMe(val) then
                local d=(hrp.Position-v.Position).Magnitude
                if d<best then best=d; target=v end
            end
        end
    end
    if not target then return false end
    moveTo(hum,target.Position+Vector3.new(0,3,0),5,function()
        return not State.AutoSteal or movementLocked()
    end)
    if State.AutoSteal and not movementLocked() then fireKickRemote() end
    return true
end

-- ---------- Klik tombol GUI (menggantikan ClickDetector:Click yang tidak ada) ----------
local GuiService = game:GetService("GuiService")
local LastClick = setmetatable({}, { __mode = "k" })

-- Hanya menembak SATU event per klik (Activated bila game memakainya, jika tidak MouseButton1Click),
-- supaya aksi seperti buy/sell tidak terhitung dua kali. Bila tombol tidak punya koneksi sama sekali
-- (game membaca input lain), jatuh ke klik virtual.
local function clickButton(btn)
    local ev = btn.MouseButton1Click
    if type(getconnections) == "function" then
        local ok, found = pcall(function()
            if #getconnections(btn.Activated) > 0 then return btn.Activated end
            if #getconnections(btn.MouseButton1Click) > 0 then return btn.MouseButton1Click end
            return nil
        end)
        if ok then ev = found end   -- nil = tidak ada koneksi
    end
    if ev then
        if type(firesignal) == "function" and pcall(firesignal, ev) then return true end
        if type(getconnections) == "function" then
            local ok = pcall(function()
                for _, c in ipairs(getconnections(ev)) do c:Fire() end
            end)
            if ok then return true end
        end
    end
    -- klik virtual di tengah tombol
    local ok = pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local inset = GuiService:GetGuiInset()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2 + inset
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    return ok
end

-- match(t) menerima teks gabungan "nama teks" (lowercase, dari cache scanGui). Cooldown 1 detik per tombol.
local function pressButtons(match)
    scanGui()
    local now = os.clock()
    for _, btn in ipairs(Cache.Buttons) do
        local t = Cache.ButtonText[btn]
        if t and match(t) and now - (LastClick[btn] or 0) >= 1
            and btn.Parent and btn.Visible and isShown(btn) then
            LastClick[btn] = now
            clickButton(btn)
        end
    end
end

-- Auto Rebirth: remote rev_RebirthRequest (folder Network yang sama dengan rev_KickEvent), di-cache,
-- cooldown 3 detik. Bila remote tidak ditemukan, jatuh ke tombol GUI "rebirth".
-- Nama remote dan argumennya berasal dari script lain, belum diverifikasi di game ini.
local RebirthRemote, lastRebirth = nil, 0
local function getRebirthRemote()
    if RebirthRemote and RebirthRemote.Parent then return RebirthRemote end
    local shared=ReplicatedStorage:FindFirstChild("Shared")
    local packages=shared and shared:FindFirstChild("Packages")
    local network=packages and packages:FindFirstChild("Network")
    RebirthRemote=network and network:FindFirstChild("rev_RebirthRequest")
    return RebirthRemote
end

local function autoRebirth()
    if os.clock()-lastRebirth<3 then return end
    lastRebirth=os.clock()
    local r=getRebirthRemote()
    if r and r:IsA("RemoteEvent") then
        pcall(function() r:FireServer() end)
    elseif r and r:IsA("RemoteFunction") then
        task.spawn(pcall, function() r:InvokeServer() end)
    else
        pressButtons(function(t) return t:find("rebirth") end)
    end
end

-- Auto Upgrade (Probeta + FARTEZ)
local function autoUpgrade()
    pressButtons(function(t) return t:find("upgrade") or t:find("upg") end)
end

-- Auto Claim: (a) tombol GUI "claim"/"collect", (b) pad di plot milik kita.
-- Plot = anak Workspace.Plots yang Owner-nya (ValueBase atau attribute) adalah kita; hasilnya di-cache.
-- Pad = tiap anak plot.Buttons (part, atau part dari Model). Kolom "Claim pad name filter"
-- (tab Misc) bila diisi membatasi pad ke nama yang mengandung teks itu; kosong = semua pad.
-- Cooldown 1 detik per pad, touch dimulai lalu diakhiri dengan jeda singkat.
local myPlot
local lastPadTouch = setmetatable({}, { __mode = "k" })

local function findMyPlot()
    if myPlot and myPlot.Parent then return myPlot end
    myPlot = nil
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, item in ipairs(plots:GetChildren()) do
        local val, has = readOwner(item)
        if has and ownedByMe(val) then myPlot = item; break end
    end
    return myPlot
end

local function autoClaim()
    pressButtons(function(t) return t:find("claim") or t:find("collect") end)

    if type(firetouchinterest) ~= "function" then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local plot = hrp and findMyPlot()
    local buttons = plot and plot:FindFirstChild("Buttons")
    if not buttons then return end

    local filter = (State.ClaimFilter or ""):lower()
    local now = os.clock()
    for _, slot in ipairs(buttons:GetChildren()) do
        if not (Running and State.AutoClaim) then return end
        -- part sentuh: slot itu sendiri, atau untuk Model: PrimaryPart / part ber-TouchTransmitter / part pertama
        local part
        if slot:IsA("BasePart") then
            part = slot
        elseif slot:IsA("Model") then
            local tt = slot:FindFirstChildWhichIsA("TouchTransmitter", true)
            part = slot.PrimaryPart
                or (tt and tt.Parent:IsA("BasePart") and tt.Parent)
                or slot:FindFirstChildWhichIsA("BasePart", true)
        end
        if part and now - (lastPadTouch[part] or 0) >= 1
            and (filter == "" or slot.Name:lower():find(filter, 1, true)) then
            lastPadTouch[part] = now
            pcall(firetouchinterest, hrp, part, 0)
            task.wait(0.05)
            pcall(firetouchinterest, hrp, part, 1)
        end
    end
end

-- Auto Sell (FARTEZ + Phantom)
local function autoSell()
    pressButtons(function(t) return t:find("sell") or t:find("jual") end)
end

-- Auto Train (WalkyHub)
local function autoTrain()
    if State.TrainMode=="Stealth" then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(Mouse.X,Mouse.Y))
    else
        pressButtons(function(t) return t:find("train") or t:find("bonus") end)
    end
end

-- Auto Buy Weight (Cyraa)
local function autoBuyWeight()
    pressButtons(function(t) return (t:find("buy") or t:find("beli")) and t:find("weight") end)
end

-- Auto Equip Weight (Cyraa)
local function autoEquipWeight()
    pressButtons(function(t) return (t:find("equip") or t:find("pakai")) and t:find("weight") end)
end

-- Auto Place Best (visionware + HoshiHub)
local function autoPlaceBest()
    pressButtons(function(t)
        return (t:find("place") or t:find("taruh")) and (t:find("best") or t:find("terbaik"))
    end)
end

-- Auto Spin / Open Lucky Block (visionware)
local function autoOpenLucky()
    pressButtons(function(t) return t:find("open") or t:find("spin") end)
end

-- Status game: ReplicatedStorage.Modules.HandlerLoader.GameHandler (.Status == "Tsunami" saat gelombang aktif)
local GameHandler, handlerTriedAt = nil, -10
local function getGameHandler()
    if GameHandler then return GameHandler end
    if os.clock()-handlerTriedAt<5 then return nil end   -- coba ulang tiap 5 detik bila gagal
    handlerTriedAt=os.clock()
    local modules=ReplicatedStorage:FindFirstChild("Modules")
    local loader=modules and modules:FindFirstChild("HandlerLoader")
    local mod=loader and loader:FindFirstChild("GameHandler")
    if mod and mod:IsA("ModuleScript") then
        local ok,res=pcall(require,mod)
        if ok and type(res)=="table" then GameHandler=res end
    end
    return GameHandler
end

local function tsunamiActive()
    local h=getGameHandler()
    return h~=nil and h.Status=="Tsunami"
end

-- Part gelombang: workspace.Waves -> Model pertama -> Part pertama
-- Model pertama dicek tiap panggilan (sama seperti kode game); part-nya di-cache per model.
local waveCacheModel, wavePartCache
local function currentWavePart()
    local wf=Workspace:FindFirstChild("Waves")
    local model=wf and wf:FindFirstChildWhichIsA("Model")
    if not model then waveCacheModel, wavePartCache = nil, nil; return nil end
    if waveCacheModel==model and wavePartCache and wavePartCache.Parent then return wavePartCache end
    waveCacheModel=model
    wavePartCache=model:FindFirstChildWhichIsA("BasePart")
    return wavePartCache
end

-- Anti Wave (visionware): hanya saat Tsunami. Bila gelombang dalam radius 45 stud
-- (dihitung dari tepi part), pindah ke KickReady (atau naik 30 stud bila area tidak ada).
local lastWaveEscape=0
local function antiWave()
    if State.FollowWave then return end   -- Follow Wave yang mengatur posisi
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local wave=currentWavePart()
    if not hrp or not wave then return end
    local h=getGameHandler()
    if h and h.Status~="Tsunami" then return end   -- handler ada tapi bukan Tsunami: abaikan
    if os.clock()-lastWaveEscape<1.5 then return end
    local reach=math.max(wave.Size.X,wave.Size.Y,wave.Size.Z)/2
    if (wave.Position-hrp.Position).Magnitude-reach<45 then
        lastWaveEscape=os.clock()
        if not teleportToKickArea(true) then
            hrp.CFrame=hrp.CFrame+Vector3.new(0,30,0)
        end
    end
end

-- Prioritas gerak karakter: Follow Wave > Anti Wave (2 detik setelah kabur) > Steal > Farm.
-- Steal dan Farm memeriksa ini sebelum memindahkan karakter.
movementLocked = function()
    if State.FollowWave and tsunamiActive() then return true end
    return os.clock()-lastWaveEscape<2
end

-- Follow Wave: selama Tsunami, posisikan karakter 80 stud (minimal; lebih jauh bila gelombang lebar)
-- di sumbu X dari gelombang, menghadap gelombang. Satu koneksi tetap (tercatat di Connections);
-- berhenti sendiri saat bukan Tsunami.
connect(RunService.RenderStepped, function()
    if not State.FollowWave or not tsunamiActive() then return end
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local wave=currentWavePart()
    if not hrp or not wave then return end
    local reach=math.max(wave.Size.X,wave.Size.Y,wave.Size.Z)/2
    local off=math.max(80,reach+30)
    hrp.CFrame=CFrame.new(wave.Position+Vector3.new(off,0,0), wave.Position)
    hrp.AssemblyLinearVelocity=Vector3.zero
end)

-- ESP
local EspObjects={}
local ESP_MAX = 28   -- Roblox hanya merender maks 31 Highlight sekaligus
local function createESP(adornee,color)
    local hl=Instance.new("Highlight")
    hl.Adornee=adornee; hl.FillColor=color; hl.OutlineColor=Color3.new(1,1,1)
    hl.FillTransparency=0.4; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent=adornee
    return hl
end

local function clearESP()
    for obj,hl in pairs(EspObjects) do
        if hl then hl:Destroy() end
        EspObjects[obj]=nil
    end
end

local function adorneePos(a)
    return a:IsA("Model") and a:GetPivot().Position or a.Position
end

-- Hanya ESP_MAX target terdekat yang di-highlight; sisanya dilepas.
local function updateESP()
    if not State.ESP then clearESP(); return end
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local origin=hrp and hrp.Position or Vector3.zero
    scanWorld()

    local cand={}
    local function add(obj,adornee,color)
        if adornee and adornee.Parent then
            cand[#cand+1]={obj=obj,adornee=adornee,color=color,d=(adorneePos(adornee)-origin).Magnitude}
        end
    end
    for _,v in ipairs(Cache.Blocks) do add(v,v,Color3.fromRGB(0,255,0)) end
    for _,v in ipairs(Cache.BrainrotOnly) do add(v,v,Color3.fromRGB(255,0,0)) end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character then add(plr,plr.Character,Color3.fromRGB(0,0,255)) end
    end
    table.sort(cand,function(a,b) return a.d<b.d end)

    local wanted={}
    for i=1,math.min(#cand,ESP_MAX) do wanted[cand[i].obj]=cand[i] end

    -- lepas highlight yang tidak lagi diinginkan / adornee-nya sudah hilang (respawn, block dihapus)
    for obj,hl in pairs(EspObjects) do
        local w=wanted[obj]
        if not w or not hl or hl.Parent==nil or hl.Adornee~=w.adornee then
            if hl then hl:Destroy() end
            EspObjects[obj]=nil
        end
    end
    for obj,w in pairs(wanted) do
        if not EspObjects[obj] then EspObjects[obj]=createESP(w.adornee,w.color) end
    end
end

-- Fly
local FlyBV,FlyBG
local function setFly(on)
    State.Fly=on
    local char=LP.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if FlyBV then FlyBV:Destroy() FlyBV=nil end
    if FlyBG then FlyBG:Destroy() FlyBG=nil end
    if not hrp or not hum then return end
    if on then
        hum.PlatformStand=true
        FlyBV=Instance.new("BodyVelocity")
        FlyBV.MaxForce=Vector3.new(9e9,9e9,9e9)
        FlyBV.Velocity=Vector3.zero
        FlyBV.Parent=hrp
        FlyBG=Instance.new("BodyGyro")
        FlyBG.MaxTorque=Vector3.new(9e9,9e9,9e9)
        FlyBG.P=9e4
        FlyBG.CFrame=hrp.CFrame
        FlyBG.Parent=hrp
    else
        hum.PlatformStand=false
    end
end

connect(RunService.RenderStepped, function()
    if State.Fly and FlyBV and FlyBG then
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local move=Vector3.zero
        local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            -- MoveDirection sudah vektor dunia (relatif kamera); jangan dikalikan lagi dengan vektor kamera
            local md=hum.MoveDirection
            if md.Magnitude>0 then
                move=md
                -- maju/mundur mengikuti kemiringan kamera, jadi bisa naik/turun tanpa tombol (juga di HP)
                local look=cam.CFrame.LookVector
                local flat=Vector3.new(look.X,0,look.Z)
                if flat.Magnitude>0.01 then
                    move=md+Vector3.yAxis*(look.Y/flat.Magnitude)*md:Dot(flat.Unit)
                end
                if move.Magnitude>1 then move=move.Unit end
            end
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move+=Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move-=Vector3.yAxis end
        FlyBV.Velocity=move*State.FlySpeed
        FlyBG.CFrame=cam.CFrame
    end
end)

-- Noclip (daftar part di-cache, refresh tiap 1 detik atau saat karakter ganti)
local NoclipParts, NoclipChar, NoclipAt = {}, nil, 0
connect(RunService.Stepped, function()
    local char = LP.Character
    if State.Noclip and char then
        if char ~= NoclipChar or os.clock() - NoclipAt > 1 then
            NoclipChar, NoclipAt = char, os.clock()
            local list = {}
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then list[#list+1] = v end
            end
            NoclipParts = list
        end
        for _, v in ipairs(NoclipParts) do
            if v.CanCollide then v.CanCollide = false end
        end
    end
end)

-- Infinite Jump
connect(UserInputService.JumpRequest, function()
    if State.InfJump and LP.Character then
        local hum=LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Speed & Jump (nilai asli disimpan per humanoid dan dipulihkan saat toggle dimatikan)
local OrigStats = setmetatable({}, { __mode = "k" })
local function getHum()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end
local function cacheOrig(hum)
    if not OrigStats[hum] then
        OrigStats[hum] = { Walk = hum.WalkSpeed, Jump = hum.JumpPower, UseJP = hum.UseJumpPower }
    end
    return OrigStats[hum]
end
local function applySpeedJump()
    local hum=getHum(); if not hum then return end
    cacheOrig(hum)
    -- pengali dari nilai ASLI yang tersimpan (bukan dari WalkSpeed saat ini), jadi aman dipanggil berulang
    if State.SpeedHack then hum.WalkSpeed=OrigStats[hum].Walk*State.SpeedMult end
    if State.JumpHack then
        hum.UseJumpPower=true
        hum.JumpPower=State.JumpValue
    end
end
local function restoreSpeedJump()
    local hum=getHum(); if not hum then return end
    local o=cacheOrig(hum)
    if not State.SpeedHack then hum.WalkSpeed=o.Walk end
    if not State.JumpHack then
        hum.UseJumpPower=o.UseJP
        hum.JumpPower=o.Jump
    end
end
connect(LP.CharacterAdded, function(char)
    -- tunggu bagian karakter benar-benar ada (bukan sekadar delay tetap)
    if not char:WaitForChild("Humanoid",10) or not char:WaitForChild("HumanoidRootPart",10) then return end
    if not Running then return end
    applySpeedJump()
    if State.Fly then setFly(true) end
end)

-- Anti-AFK
connect(LP.Idled, function()
    if State.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Anti-Kick (Phantom)
-- (Tidak bisa diimplementasikan langsung; hanya placeholder)

-- Anti-Void (Phantom)
connect(RunService.Heartbeat, function()
    if State.AntiVoid and LP.Character then
        local hrp=LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y < -50 then
            -- utamakan area KickReady (posisi pasti valid di map); (0,50,0) hanya cadangan
            local p=kickAreaPosition() or Vector3.new(0,46,0)
            hrp.CFrame=CFrame.new(p+Vector3.new(0,4,0))
            hrp.AssemblyLinearVelocity=Vector3.zero
        end
    end
end)

-- Auto Respawn: sekarang lewat loop utama (klik tombol "Respawn" di GUI game bila muncul)

-- FPS Cap (Phantom)
local OrigQuality
local function applyFpsCap(on)
    pcall(function()
        local r=settings().Rendering
        if OrigQuality==nil then OrigQuality=r.QualityLevel end
        r.QualityLevel = on and Enum.QualityLevel.Level01 or OrigQuality
    end)
end

-- Fullbright / No Fog (Forge Hub) - nilai asli Lighting disimpan dan dipulihkan
local OrigLighting = {
    Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
    GlobalShadows=Lighting.GlobalShadows, FogEnd=Lighting.FogEnd,
}
local FBApplied, FogApplied = false, false
local function applyVisuals()
    if State.Fullbright then
        FBApplied=true
        Lighting.Brightness=2
        Lighting.ClockTime=12
        Lighting.GlobalShadows=false
    elseif FBApplied then
        FBApplied=false
        Lighting.Brightness=OrigLighting.Brightness
        Lighting.ClockTime=OrigLighting.ClockTime
        Lighting.GlobalShadows=OrigLighting.GlobalShadows
    end
    if State.NoFog then
        FogApplied=true
        Lighting.FogEnd=9e9
    elseif FogApplied then
        FogApplied=false
        Lighting.FogEnd=OrigLighting.FogEnd
    end
end

-- Hide Other Players (Forge Hub)
local function setOthersHidden(hidden)
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character then
            for _,v in ipairs(plr.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.LocalTransparencyModifier=hidden and 1 or 0 end
            end
        end
    end
end
local function hideOtherPlayers() setOthersHidden(true) end
local function showOtherPlayers() setOthersHidden(false) end

-- Hitbox: skala dari ukuran asli (bukan ukuran absolut), hanya part "lucky", bisa dipulihkan
local OrigSize = setmetatable({}, { __mode = "k" })
local function applyHitbox()
    for _,v in ipairs(Cache.Blocks) do
        if v.Parent then
            if not OrigSize[v] then OrigSize[v]=v.Size end
            v.Size=OrigSize[v]*State.HitboxSize
        end
    end
end
local function restoreHitbox()
    for part,size in pairs(OrigSize) do
        if part.Parent then part.Size=size end
        OrigSize[part]=nil
    end
end

-- Server Hop (Phantom)
local function serverHop()
    -- Placeholder: butuh HTTP request; bisa disesuaikan
    notify("Server hop not implemented", Theme.Warn)
end

-- Terapkan ulang seluruh State ke game (dipakai setelah Load Config)
local function applyAllState()
    pcall(setFly, State.Fly)
    applySpeedJump(); restoreSpeedJump()
    applyFpsCap(State.FpsCap)
    local cam=Workspace.CurrentCamera
    if cam then cam.FieldOfView=State.FOV end
    applyVisuals()
    if not State.HideOtherPlayers then showOtherPlayers() end
    if not State.Hitbox then restoreHitbox() end
    pcall(updateESP)
end

-- ============================================================
-- LOOP UTAMA (tiap fitur dibungkus pcall; error dilog sekali lalu lanjut)
-- ============================================================
local ErrLogged = {}
local function safe(name, cond, fn)
    if not Running or not cond then return end   -- setelah Close, tidak ada fitur yang jalan lagi
    local ok, err = pcall(fn)
    if not ok and not ErrLogged[name] then
        ErrLogged[name] = true
        warn("[VuraKALB] "..name..": "..tostring(err))
    end
end

-- Tiap kelompok fitur punya loop sendiri, jadi fitur lambat (jalan ke target, jeda collect)
-- tidak menahan fitur lain, terutama Anti Wave.
local function spawnLoop(interval, step)
    task.spawn(function()
        while Running do
            local ok, err = pcall(step)
            if not ok then warn("[VuraKALB] loop: "..tostring(err)) end
            task.wait(interval)
        end
    end)
end

local function getChar()
    local char=LP.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    return hum, hrp
end

-- 1) Anti Wave: loop cepat sendiri (cooldown kabur 1.5 detik ada di antiWave)
spawnLoop(0.2, function()
    safe("AntiWave", State.AntiWave, antiWave)
end)

-- 2) Aksi yang memindahkan karakter: Steal lebih prioritas daripada Farm, dan keduanya
-- mengalah selama Follow Wave / baru kabur dari gelombang (lihat movementLocked).
spawnLoop(0.5, function()
    local hum, hrp = getChar()
    if not hum or not hrp or movementLocked() then return end
    local stole = false
    safe("AutoSteal", State.AutoSteal, function() stole = autoSteal() end)
    if stole then return end
    safe("AutoFarm", State.AutoFarm, function()
        if teleportToKickArea(false) then
            fireKickRemote()
        else
            -- area KickReady tidak ditemukan: jalan ke block terdekat lalu kick
            local block=getNearestBlock()
            if block then
                moveTo(hum,block.Position+Vector3.new(0,3,0),6,function()
                    return not State.AutoFarm or movementLocked()
                end)
                if State.AutoFarm and not movementLocked() then fireKickRemote() end
            end
        end
        task.wait(0.2)
    end)
end)

-- 3) Auto Collect (tidak memindahkan karakter, hanya firetouchinterest)
spawnLoop(0.5, function()
    if getChar() then
        safe("AutoCollect", State.AutoCollect, collectBrainrots)
    end
end)

-- 4) Fitur yang menekan tombol GUI
spawnLoop(0.5, function()
    safe("AutoRespawn", State.AutoRespawn, function()
        pressButtons(function(t) return t:find("respawn") end)
    end)
    local _, hrp = getChar()
    if not hrp then return end
    safe("AutoRebirth", State.AutoRebirth, autoRebirth)
    safe("AutoUpgrade", State.AutoUpgrade, autoUpgrade)
    safe("AutoClaim", State.AutoClaim, autoClaim)
    safe("AutoSell", State.AutoSell, autoSell)
    safe("AutoTrain", State.AutoTrain, autoTrain)
    safe("AutoBuyWeight", State.AutoBuyWeight, autoBuyWeight)
    safe("AutoEquipWeight", State.AutoEquipWeight, autoEquipWeight)
    safe("AutoPlace", State.AutoPlace, autoPlaceBest)
    safe("AutoOpen", State.AutoSpin or State.AutoOpen, autoOpenLucky)
end)

-- 5) Visual, hitbox, status
spawnLoop(0.5, function()
    local _, hrp = getChar()
    safe("Status", true, function()
        StatusDot.BackgroundColor3 = State.AutoFarm and Theme.Good or Theme.Bad
        StatusText.Text = "Auto Farm: "..(State.AutoFarm and "Running" or "Idle")
    end)
    safe("Visuals", true, applyVisuals)
    if not hrp then return end
    safe("ScanWorld", State.ESP or State.Hitbox, function() scanWorld() end)
    safe("ESP", State.ESP, updateESP)
    safe("Hitbox", State.Hitbox, applyHitbox)
    safe("SpeedJump", State.SpeedHack or State.JumpHack, applySpeedJump)
    safe("HideOtherPlayers", State.HideOtherPlayers, hideOtherPlayers)
end)

-- ============================================================
-- PAGES
-- ============================================================
local PageFarm=createPage("Farm","🚀")
local PageCombat=createPage("Combat","⚔")
local PageMovement=createPage("Movement","🏃")
local PageVisual=createPage("Visual","👁")
local PageMisc=createPage("Misc","⚙")
local PageConfig=createPage("Config","💾")

-- FARM
makeSection(PageFarm,"Automation",1)
makeToggle(PageFarm,State,"AutoFarm","Auto Farm (Kick + Collect)",Theme.Accent,2,function(v)
    notify("Auto Farm: "..(v and "ON" or "OFF"),v and Theme.Good or Theme.SubText)
end)
makeToggle(PageFarm,State,"AutoCollect","Auto Collect Brainrots/Cash/Ores",Theme.Accent2,3,nil)
makeToggle(PageFarm,State,"PerfectKick","Perfect Kick",Theme.Gold,4,nil)
makeToggle(PageFarm,State,"AutoSteal","Auto Steal Blocks",Theme.Bad,5,nil)
makeToggle(PageFarm,State,"AutoRebirth","Auto Rebirth",Theme.Good,6,nil)
makeToggle(PageFarm,State,"AutoUpgrade","Auto Upgrade",Theme.Warn,7,nil)
makeToggle(PageFarm,State,"AutoClaim","Auto Claim",Theme.Accent,8,nil)
makeToggle(PageFarm,State,"AutoSell","Auto Sell",Theme.Bad,9,nil)
makeToggle(PageFarm,State,"AutoTrain","Auto Train",Theme.Accent2,10,nil)
makeToggle(PageFarm,State,"AutoBuyWeight","Auto Buy Weight",Theme.Gold,11,nil)
makeToggle(PageFarm,State,"AutoEquipWeight","Auto Equip Weight",Theme.Pink,12,nil)
makeToggle(PageFarm,State,"AutoPlace","Auto Place Best",Theme.Accent,13,nil)
makeToggle(PageFarm,State,"AutoSpin","Auto Spin/Open Lucky Block",Theme.Warn,14,nil)
makeToggle(PageFarm,State,"AntiWave","Anti Waves (saat Tsunami)",Theme.Bad,15,nil)
makeToggle(PageFarm,State,"FollowWave","Follow Wave (saat Tsunami)",Theme.Accent2,16,nil)
makeButton(PageFarm,"📍  Teleport to Nearest Block",34,Color3.fromRGB(34,34,52),Color3.fromRGB(26,26,40),17,function()
    local block=getNearestBlock()
    if block and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CFrame=block.CFrame+Vector3.new(0,5,0)
        notify("Teleported to block",Theme.Good)
    else
        notify("Block not found",Theme.Bad)
    end
end)

makeButton(PageFarm,"🎯  Teleport to Kick Area",34,Color3.fromRGB(34,34,52),Color3.fromRGB(26,26,40),18,function()
    if teleportToKickArea(true) then
        notify("Teleported to KickReady",Theme.Good)
    else
        notify("workspace.Areas.KickReady not found",Theme.Bad)
    end
end)

-- COMBAT
makeSection(PageCombat,"Hitbox & Kick",1)
makeSlider(PageCombat,State,"HitboxSize","Hitbox Size (x ukuran asli)",1,10,Theme.Warn,2,nil)
makeToggle(PageCombat,State,"Hitbox","Enable Hitbox Expander",Theme.Warn,3,function(v) if not v then restoreHitbox() end end)
makeSlider(PageCombat,State,"KickPower","Kick Power (strength kick)",1,500,Theme.Bad,4,nil)
makeToggle(PageCombat,State,"AutoPredict","Auto Predict (belum aktif)",Theme.Accent2,5,nil)

-- MOVEMENT
makeSection(PageMovement,"Movement",1)
makeSlider(PageMovement,State,"SpeedMult","Walk Speed (x kecepatan asli)",1,10,Theme.Accent,2,function(v)
    if State.SpeedHack then applySpeedJump() end
end)
makeSlider(PageMovement,State,"JumpValue","Jump Power",50,500,Theme.Accent2,3,applySpeedJump)
makeSlider(PageMovement,State,"FlySpeed","Fly Speed",10,200,Theme.Gold,4,nil)
makeToggle(PageMovement,State,"SpeedHack","Speed Hack",Theme.Accent,5,function() applySpeedJump(); restoreSpeedJump() end)
makeToggle(PageMovement,State,"Fly","Fly Mode",Theme.Gold,6,function(v) setFly(v) end)
makeToggle(PageMovement,State,"Noclip","Noclip",Theme.Pink,7,nil)
makeToggle(PageMovement,State,"InfJump","Infinite Jump",Theme.Accent2,8,nil)
makeToggle(PageMovement,State,"JumpHack","Jump Hack",Theme.Accent2,9,function() applySpeedJump(); restoreSpeedJump() end)

-- VISUAL
makeSection(PageVisual,"ESP",1)
makeToggle(PageVisual,State,"ESP","Enable ESP",Theme.Good,2,function(v)
    if not v then
        for obj,hl in pairs(EspObjects) do
            if hl then hl:Destroy() end
            EspObjects[obj]=nil
        end
    end
end)
makeSection(PageVisual,"Environment",3)
makeToggle(PageVisual,State,"Fullbright","Fullbright",Theme.Gold,4,function() applyVisuals() end)
makeToggle(PageVisual,State,"NoFog","No Fog",Theme.SubText,5,function() applyVisuals() end)
makeToggle(PageVisual,State,"HideOtherPlayers","Hide Other Players",Theme.Bad,6,function(v) if not v then showOtherPlayers() end end)
makeSlider(PageVisual,State,"FOV","FOV",30,120,Theme.Accent2,7,function(v)
    local cam=Workspace.CurrentCamera
    if cam then cam.FieldOfView=v end
end)

-- MISC
makeSection(PageMisc,"Utility",1)
makeToggle(PageMisc,State,"AntiAFK","Anti-AFK",Theme.Good,2,nil)
makeToggle(PageMisc,State,"AntiKick","Anti-Kick (belum aktif)",Theme.Bad,3,nil)
makeToggle(PageMisc,State,"AntiVoid","Anti-Void",Theme.Pink,4,nil)
makeToggle(PageMisc,State,"AutoRespawn","Auto Respawn (klik tombol Respawn)",Theme.Accent,5,nil)
makeToggle(PageMisc,State,"AutoRejoin","Auto Rejoin (belum aktif)",Theme.Warn,6,nil)
makeToggle(PageMisc,State,"FpsCap","FPS Cap / Boost",Theme.Gold,7,applyFpsCap)
makeButton(PageMisc,"🌐  Server Hop (belum aktif)",34,Color3.fromRGB(34,34,52),Color3.fromRGB(26,26,40),8,serverHop)
makeSection(PageMisc,"Filter",9)
makeInput(PageMisc,State,"BrainrotFilter","Brainrot name filter",10,nil)
makeInput(PageMisc,State,"ClaimFilter","Claim pad name filter (kosong = semua pad)",12,nil)
makeSlider(PageMisc,State,"CollectionDelayCs","Collection Delay (x0.01s)",1,50,Theme.Accent2,11,nil)

-- CONFIG
makeSection(PageConfig,"Config",1)
makeButton(PageConfig,"💾  Save Config",34,Color3.fromRGB(34,34,52),Color3.fromRGB(26,26,40),2,function()
    if hasFS then
        local ok,encoded=pcall(function() return HttpService:JSONEncode(State) end)
        if ok then
            pcall(writefile,CONFIG_FILE,encoded)
            notify("Config saved",Theme.Good)
        else
            notify("Failed to save",Theme.Bad)
        end
    else
        notify("Executor doesn't support writefile",Theme.Bad)
    end
end)
makeButton(PageConfig,"📂  Load Config",34,Color3.fromRGB(34,34,52),Color3.fromRGB(26,26,40),3,function()
    if hasFS and isfile(CONFIG_FILE) then
        local ok,data=pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data)=="table" then
            for k,v in pairs(data) do
                if State[k]~=nil and type(v)==type(State[k]) then State[k]=v end
            end
            for _,refresh in ipairs(UIRefresh) do pcall(refresh) end  -- segarkan tampilan toggle/slider
            applyAllState()                                          -- terapkan efeknya ke game
            notify("Config loaded",Theme.Good)
        else
            notify("Config rusak / tidak terbaca",Theme.Bad)
        end
    else
        notify("Config not found",Theme.Warn)
    end
end)

-- ============================================================
-- MINIMIZE & CLOSE
-- ============================================================
local isMinimized=false
local function toggleMinimize()
    isMinimized=not isMinimized
    local h=isMinimized and (HEADER_H+2) or WIN_H
    tween(MainFrame,SMOOTH,{Size=UDim2.new(0,WIN_W,0,h)})
    tween(Shadow,SMOOTH,{Size=UDim2.new(0,WIN_W+70,0,h+70)})
    MinBtn.Text=isMinimized and "+" or "–"
    HeaderLine.Visible=not isMinimized
end
MinBtn.MouseButton1Click:Connect(toggleMinimize)

-- Toggle Button (pill)
local ToggleBtn=Instance.new("TextButton")
ToggleBtn.Size=UDim2.new(0,160,0,34)
ToggleBtn.Position=UDim2.new(0,15,0,15)
ToggleBtn.BackgroundColor3=Theme.Panel
ToggleBtn.AutoButtonColor=false
ToggleBtn.Font=Enum.Font.GothamBlack
ToggleBtn.Text="⚡  VURA HUB"
ToggleBtn.TextColor3=Theme.Text
ToggleBtn.TextSize=12
ToggleBtn.Parent=ScreenGui
corner(ToggleBtn,17)
local ToggleStroke=Instance.new("UIStroke")
ToggleStroke.Thickness=2
ToggleStroke.Color=Color3.new(1,1,1)
ToggleStroke.Parent=ToggleBtn
local ToggleGrad=Instance.new("UIGradient")
ToggleGrad.Color=RAINBOW
ToggleGrad.Parent=ToggleStroke
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible=not MainFrame.Visible
    Shadow.Visible=MainFrame.Visible
end)

local function Cleanup()
    Running = false
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    pcall(setFly, false)
    State.SpeedHack, State.JumpHack, State.Fullbright, State.NoFog = false, false, false, false
    pcall(applySpeedJump); pcall(restoreSpeedJump)
    pcall(applyVisuals)
    pcall(applyFpsCap, false)
    pcall(showOtherPlayers)
    pcall(restoreHitbox)
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then cam.FieldOfView = OrigFOV end
    end)
    for obj, hl in pairs(EspObjects) do
        pcall(function() hl:Destroy() end)
        EspObjects[obj] = nil
    end
    pcall(function() ScreenGui:Destroy() end)
    if Env.VuraKALB_Cleanup == Cleanup then Env.VuraKALB_Cleanup = nil end
end
Env.VuraKALB_Cleanup = Cleanup

CloseBtn.MouseButton1Click:Connect(Cleanup)

-- Toggle via LeftCtrl
connect(UserInputService.InputBegan, function(input,gp)
    if not gp and input.KeyCode==Enum.KeyCode.LeftControl then
        MainFrame.Visible=not MainFrame.Visible
        Shadow.Visible=MainFrame.Visible
    end
end)

-- ============================================================
-- ANIMASI RGB
-- ============================================================
connect(RunService.RenderStepped, function()
    local r=(os.clock()*90)%360
    ToggleGrad.Rotation=r
    if MainFrame.Visible then BorderGrad.Rotation=r end   -- jendela tersembunyi: tidak perlu dianimasikan
end)

-- ============================================================
-- INIT
-- ============================================================
setTab("Farm")
applySpeedJump()
notify("VuraHub | Kick A Lucky Block Loaded ⚡",Theme.Accent)
