-- ==========================================
-- ⚡ VURA | DATABASE FARM & REMOTE LOGGER ⚡
-- ==========================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local guiParent = (gethui and gethui()) or PlayerGui

for _, p in ipairs({guiParent, PlayerGui}) do
	local old = p:FindFirstChild("VuraServerFarmLogger")
	if old then old:Destroy() end
end

-- ==========================================
-- 1. DATABASE 100% LENGKAP (ID BASE)
-- ==========================================
local carDatabase = {
	-- Rarity 0 (Common)
	["Acad iRVS Sedan"] = 0, ["Acadi RVS Sedan"] = 0, ["Artho G1000"] = 0, ["Bantt Rental"] = 0,
	["Bogdan 2099"] = 0, ["Chiverleta Golde"] = 0, ["Chiverleta Outskirts BT"] = 0, ["Chiverleta Taohra BT"] = 0,
	["DAW 0909"] = 0, ["Deutschotoren C3 B63"] = 0, ["Deutschotoren C5 B21"] = 0, ["Deutschotoren C543"] = 0,
	["Fedsel Coronet"] = 0, ["Fedsel E-Line Cargo"] = 0, ["Hakusho Ciri"] = 0, ["Ivar Manguster"] = 0,
	["Nikken Altimata"] = 0, ["Susuri Vitality"] = 0, ["Volfsen Passo"] = 0, ["Volfsen Rolf"] = 0,

	-- Rarity 1 (Uncommon)
	["Artho G451"] = 1, ["Artho G672"] = 1, ["Artho X723"] = 1, ["Chiverleta Cerano"] = 1,
	["Dawson Hammer JHT8"] = 1, ["Deutschotoren C3E5"] = 1, ["Deutschotoren C560"] = 1, ["Deutschotoren C783"] = 1,
	["Fedsel Expedition"] = 1, ["Fedsel Stallion G3"] = 1, ["Hakusho Concord"] = 1, ["Luxius OJ100"] = 1,
	["Marcalen-Denz B660"] = 1, ["Marcalen-Denz T600"] = 1, ["Mazuta 29"] = 1, ["Mazuta Mint"] = 1,
	["Preischel Crayele"] = 1, ["Quantum H26"] = 1, ["Tokina Karma"] = 1, ["Tokina RP60"] = 1,

	-- Rarity 2 (Rare)
	["Artho G623"] = 2, ["Chiverleta Ceretta X05"] = 2, ["Chiverleta Taohra SVV"] = 2, ["Cryele 222B"] = 2,
	["Dawson Hammer SCV"] = 2, ["Deutschotoren C297x"] = 2, ["Deutschotoren C393"] = 2, ["Fedsel Expedition Hybrid"] = 2,
	["Fedsel Stallion G5"] = 2, ["Land Ranger V500"] = 2, ["Luxius VQ"] = 2, ["Marcalen-Denz K413"] = 2,
	["Mazuta JO4"] = 2, ["Mitta Aydens REO"] = 2, ["Nikken 290S"] = 2, ["Nikken Sinata B21"] = 2,
	["Quantum N500"] = 2, ["Suiba Presse RST"] = 2, ["Tokina Absoluta SR 3.0"] = 2, 

	-- Rarity 3 (Epic / Legend)
	["Artho F9 ST"] = 3, ["Artho G770"] = 3, ["Artho VS600"] = 3, ["Chiverleta Cerano XZ2"] = 3,
	["Chiverleta Ceretta X07"] = 3, ["Chiverleta Imalo 67"] = 3, ["Dawson Competition"] = 3, ["Dawson Hammer"] = 3,
	["Dawson Hammer 70"] = 3, ["Dawson Rhino SCT"] = 3, ["Deserter Grand Prince"] = 3, ["Deutschotoren C2"] = 3,
	["Deutschotoren C3"] = 3, ["Deutschotoren C4 DSG"] = 3, ["Deutschotoren C483"] = 3, ["Deutschotoren C5 600"] = 3,
	["Deutschotoren C873"] = 3, ["Deutschotoren S5"] = 3, ["Deutschotoren U8"] = 3, ["Hakusho MRB Sport"] = 3,
	["Lilia Exima"] = 3, ["Luxius BG600"] = 3, ["Marcalen-Denz VT"] = 3, ["Marcalen-Denz LPS"] = 3,
	["Marcalen-Denz LPS94"] = 3, ["Nikken Starline S340"] = 3, ["Nikken Starline S350"] = 3, ["Preischel 313n"] = 3,
	["Tokina Absoluta SR 2.0"] = 3,
}

-- ==========================================
-- 2. SMART REMOTE CATCHER & LOGGER
-- ==========================================
_G.TargetRemote = nil
_G.IsFarming = false
local isCatching = false
local capturedPath = "Belum ada remote tertangkap"

if hookmetamethod and getnamecallmethod then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if isCatching and (method == "FireServer" or method == "InvokeServer") and not checkcaller() then
			_G.TargetRemote = self
			capturedPath = self:GetFullName()
			isCatching = false 
		end
		return oldNamecall(self, ...)
	end))
end

-- ==========================================
-- 3. UI PREMIUM CLAY & GRID (RESIZABLE)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VuraServerFarmLogger"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 210)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -105)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(130, 80, 220)
Instance.new("UIStroke", MainFrame).Thickness = 1.5

-- Gradien & Tekstur Grid
local grad = Instance.new("UIGradient", MainFrame)
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 20, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 12)),
}
grad.Rotation = 45

local PatternGrid = Instance.new("ImageLabel", MainFrame)
PatternGrid.Size = UDim2.new(1, 0, 1, 0)
PatternGrid.BackgroundTransparency = 1
PatternGrid.Image = "rbxassetid://4743439972"
PatternGrid.ImageTransparency = 0.92
PatternGrid.ScaleType = Enum.ScaleType.Tile
PatternGrid.TileSize = UDim2.new(0, 35, 0, 35)
PatternGrid.ZIndex = 0

-- Header
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.Position = UDim2.new(0.04, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ VURA | Logger & Farm"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(230, 230, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -26, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() _G.IsFarming = false end)

local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(0.92, 0, 0, 1)
Line.Position = UDim2.new(0.04, 0, 0, 30)
Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Line.BackgroundTransparency = 0.85

-- ==========================================
-- 4. TOMBOL KONTROL & LOG BOX
-- ==========================================
local CatchBtn = Instance.new("TextButton", MainFrame)
CatchBtn.Size = UDim2.new(0.85, 0, 0, 28)
CatchBtn.Position = UDim2.new(0.075, 0, 0.2, 0)
CatchBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 30)
CatchBtn.Text = "🎯 1. Tangkap Remote"
CatchBtn.Font = Enum.Font.GothamBold
CatchBtn.TextSize = 11
CatchBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CatchBtn).CornerRadius = UDim.new(0, 6)

local LogBox = Instance.new("TextBox", MainFrame)
LogBox.Size = UDim2.new(0.85, 0, 0, 30)
LogBox.Position = UDim2.new(0.075, 0, 0.38, 0)
LogBox.BackgroundColor3 = Color3.fromRGB(25, 22, 35)
LogBox.Text = "Path Remote akan muncul disini..."
LogBox.Font = Enum.Font.Code
LogBox.TextSize = 10
LogBox.TextColor3 = Color3.fromRGB(100, 255, 200)
LogBox.ClearTextOnFocus = false
LogBox.Editable = false
Instance.new("UICorner", LogBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", LogBox).Color = Color3.fromRGB(70, 60, 100)

local CopyBtn = Instance.new("TextButton", MainFrame)
CopyBtn.Size = UDim2.new(0.85, 0, 0, 24)
CopyBtn.Position = UDim2.new(0.075, 0, 0.57, 0)
CopyBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 120)
CopyBtn.Text = "📋 Salin Path Remote ke Clipboard"
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 10
CopyBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 5)

local StartBtn = Instance.new("TextButton", MainFrame)
StartBtn.Size = UDim2.new(0.85, 0, 0, 32)
StartBtn.Position = UDim2.new(0.075, 0, 0.72, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
StartBtn.Text = "⚡ 2. AUTO BUY (DATABASE) ⚡"
StartBtn.Font = Enum.Font.GothamBlack
StartBtn.TextSize = 11
StartBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 6)

local StatusText = Instance.new("TextLabel", MainFrame)
StatusText.Size = UDim2.new(1, 0, 0, 18)
StatusText.Position = UDim2.new(0, 0, 0.89, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Standby"
StatusText.Font = Enum.Font.GothamMedium
StatusText.TextSize = 10
StatusText.TextColor3 = Color3.fromRGB(180, 180, 200)

-- Fitur Resize Pojok Kanan Bawah
local ResizeHandle = Instance.new("TextButton", MainFrame)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Text = "◢"
ResizeHandle.TextColor3 = Color3.fromRGB(150, 150, 150)
ResizeHandle.TextSize = 14
ResizeHandle.Font = Enum.Font.GothamBlack
ResizeHandle.ZIndex = 10

local resizing, dragStart, startSize = false, nil, nil
ResizeHandle.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		MainFrame.Draggable = false
		dragStart = i.Position
		startSize = MainFrame.Size
	end
end)
UIS.InputChanged:Connect(function(i)
	if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		MainFrame.Size = UDim2.new(0, math.max(280, startSize.X.Offset + d.X), 0, math.max(190, startSize.Y.Offset + d.Y))
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		if resizing then resizing = false; MainFrame.Draggable = true end
	end
end)

-- ==========================================
-- 5. LOGIKA TOMBOL & EKSEKUSI
-- ==========================================
CatchBtn.MouseButton1Click:Connect(function()
	isCatching = true
	CatchBtn.Text = "⏳ Beli 1 Mobil Manual Sekarang!"
	CatchBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
end)

-- Update Log otomatis saat tertangkap
task.spawn(function()
	while task.wait(0.3) do
		if _G.TargetRemote then
			CatchBtn.Text = "✅ REMOTE TERTANGKAP!"
			CatchBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
			LogBox.Text = capturedPath
			StatusText.Text = "Siap disalin dan dikirim ke AI!"
			isCatching = false
		end
	end
end)

-- Tombol Salin otomatis ke Clipboard
CopyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		setclipboard(capturedPath)
		StatusText.Text = "Berhasil disalin! Kirim ke sini ya."
		StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		StatusText.Text = "Executor tidak mendukung clipboard."
		StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end)

StartBtn.MouseButton1Click:Connect(function()
	if not _G.TargetRemote then
		StatusText.Text = "⚠️ Tangkap remote dulu!"
		StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end
	
	_G.IsFarming = not _G.IsFarming
	if _G.IsFarming then
		StartBtn.Text = "🛑 STOP AUTO FARM 🛑"
		StartBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
		StatusText.Text = "Menembak server dengan Database..."
		StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		StartBtn.Text = "⚡ 2. AUTO BUY (DATABASE) ⚡"
		StartBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
		StatusText.Text = "Standby."
		StatusText.TextColor3 = Color3.fromRGB(180, 180, 200)
	end
end)

-- Core Loop Server-Side By ID
task.spawn(function()
	while task.wait(0.1) do
		if _G.IsFarming and _G.TargetRemote then
			for carID, rarity in pairs(carDatabase) do
				if not _G.IsFarming then break end 
				pcall(function()
					if _G.TargetRemote:IsA("RemoteFunction") then
						_G.TargetRemote:InvokeServer(carID)
					else
						_G.TargetRemote:FireServer(carID)
					end
				end)
				task.wait(0.05) 
			end
		end
	end
end)
