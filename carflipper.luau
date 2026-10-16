-- ==========================================
-- VURA | CAR FLIPPER (PREMIUM EXECUTOR UI)
-- ==========================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Mencegah Duplikasi UI
if PlayerGui:FindFirstChild("VuraCarFlipper") then
	PlayerGui.VuraCarFlipper:Destroy()
end

-- ==========================================
-- 1. DATA & KONFIGURASI GAME
-- ==========================================
local carList = {
	{ id = "city_hatch", name = "City Hatch", basePrice = 4500, minLevel = 1, weight = 12 },
	{ id = "old_sedan", name = "Old Sedan", basePrice = 7500, minLevel = 1, weight = 12 },
	{ id = "pickup", name = "Work Pickup", basePrice = 12000, minLevel = 2, weight = 9 },
	{ id = "wagon", name = "Family Wagon", basePrice = 16000, minLevel = 3, weight = 8 },
	{ id = "muscle", name = "Muscle GT", basePrice = 28000, minLevel = 4, weight = 6 },
	{ id = "sport_coupe", name = "Sport Coupe", basePrice = 45000, minLevel = 6, weight = 4 },
	{ id = "classic_roadster", name = "Classic Roadster", basePrice = 70000, minLevel = 8, weight = 3 },
	{ id = "supercar", name = "Hyper GT", basePrice = 140000, minLevel = 11, weight = 2 },
}

local tasks = {
	wash = { id = "wash", costPct = 0.012 },
	dents = { id = "dents", costPct = 0.06 },
}

local Config = {
	StartCash = 7500,
	StartSlots = 3,
	StockSize = 6,
	StockRefreshSeconds = 90,
	DealerDiscountMin = 0.80,
	DealerDiscountMax = 1.00,
	DealerAssumedEngine = 0.35,
	StatRanges = {
		dirt = { min = 0.30, max = 1.00 },
		dents = { min = 0.00, max = 0.85 },
		rust = { min = 0.00, max = 0.90 },
		engine = { min = 0.05, max = 0.90 },
	},
	ValueWeights = { dirt = 0.05, dents = 0.20, rust = 0.25, engine = 0.30 },
	ShowroomBonus = 0.10,
	PaintBonus = 0.05,
	Cars = {},
	Tasks = tasks
}

for _, def in ipairs(carList) do Config.Cars[def.id] = def end

local PlayerData = { Cash = Config.StartCash, Slots = Config.StartSlots, Garage = {} }
local DealerStock = {}

local function calculateRealValue(carData)
	local basePrice = Config.Cars[carData.carId].basePrice
	local penalty = (carData.dirt * Config.ValueWeights.dirt) + (carData.dents * Config.ValueWeights.dents) + (carData.rust * Config.ValueWeights.rust) + (carData.engine * Config.ValueWeights.engine)
	local val = basePrice * (1 - penalty)
	if carData.dirt <= 0.05 and carData.dents <= 0.05 and carData.rust <= 0.05 and carData.engine <= 0.05 then val = val + (basePrice * Config.ShowroomBonus) end
	return math.floor(val)
end

local function generateDealerCars()
	DealerStock = {}
	for i = 1, Config.StockSize do
		local rCar = carList[math.random(1, #carList)]
		local function getS(s) return Config.StatRanges[s].min + math.random() * (Config.StatRanges[s].max - Config.StatRanges[s].min) end
		local penalty = (getS("dirt") * Config.ValueWeights.dirt) + (getS("dents") * Config.ValueWeights.dents) + (getS("rust") * Config.ValueWeights.rust) + (Config.DealerAssumedEngine * Config.ValueWeights.engine)
		local val = rCar.basePrice * (1 - penalty)
		local disc = Config.DealerDiscountMin + math.random() * (Config.DealerDiscountMax - Config.DealerDiscountMin)
		table.insert(DealerStock, {
			uid = HttpService:GenerateGUID(false), carId = rCar.id, name = rCar.name, price = math.floor(val * disc),
			dirt = getS("dirt"), dents = getS("dents"), rust = getS("rust"), engine = getS("engine"), isPainted = false
		})
	end
end

-- ==========================================
-- 2. SISTEM UI (DESAIN CLAY PREMIUM)
-- ==========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VuraCarFlipper"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Main Panel (Dibuat lebih kompak agar terkesan mahal)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 360)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.new(1, 1, 1) -- Warna dasar putih untuk UIGradient
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true -- Penting untuk efek minimize
MainFrame.Parent = ScreenGui

local MainGradient = Instance.new("UIGradient", MainFrame)
MainGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(110, 30, 180)), -- Ungu Premium
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(15, 15, 20))    -- Hitam Elegan
}
MainGradient.Rotation = 45
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Border 3D List luar
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(140, 80, 220)
MainStroke.Thickness = 2

-- Fungsi Pembantu Animasi
local function AnimateHover(btn, isHover)
	local sizeObj = isHover and UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset + 4, btn.Size.Y.Scale, btn.Size.Y.Offset + 4) or UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset - 4, btn.Size.Y.Scale, btn.Size.Y.Offset - 4)
	TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = sizeObj}):Play()
end

local function Make3DText(label)
	local stroke = Instance.new("UIStroke", label)
	stroke.Color = Color3.fromRGB(20, 20, 20)
	stroke.Thickness = 1.5
end

-- Header / TopBar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Position = UDim2.new(0.03, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Vura | Car Flipper"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextXAlignment = Enum.TextXAlignment.Left
Make3DText(Title)

local InfoBar = Instance.new("TextLabel", TopBar)
InfoBar.Size = UDim2.new(0.5, 0, 1, 0)
InfoBar.Position = UDim2.new(0.2, 0, 0, 0)
InfoBar.BackgroundTransparency = 1
InfoBar.Text = "Uang: $0 | Garasi: 0/0"
InfoBar.Font = Enum.Font.GothamBold
InfoBar.TextSize = 14
InfoBar.TextColor3 = Color3.fromRGB(200, 255, 150)
InfoBar.TextXAlignment = Enum.TextXAlignment.Center
Make3DText(InfoBar)

-- Tombol Kontrol (Min & Close)
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.TextSize = 20
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)
Make3DText(MinBtn)

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 16
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
Make3DText(CloseBtn)

-- Animasi Minimize
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	local newSize = isMinimized and UDim2.new(0, 520, 0, 40) or UDim2.new(0, 520, 0, 360)
	TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = newSize}):Play()
end)

-- Garis Pemisah
local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(0.94, 0, 0, 2)
Line.Position = UDim2.new(0.03, 0, 0, 42)
Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Line.BackgroundTransparency = 0.7

-- Area Content
local DealerScroll = Instance.new("ScrollingFrame", MainFrame)
DealerScroll.Size = UDim2.new(0.46, 0, 1, -55)
DealerScroll.Position = UDim2.new(0.02, 0, 0, 48)
DealerScroll.BackgroundTransparency = 1
DealerScroll.ScrollBarThickness = 3
local UIList1 = Instance.new("UIListLayout", DealerScroll)
UIList1.Padding = UDim.new(0, 8)

local GarageScroll = Instance.new("ScrollingFrame", MainFrame)
GarageScroll.Size = UDim2.new(0.48, 0, 1, -55)
GarageScroll.Position = UDim2.new(0.50, 0, 0, 48)
GarageScroll.BackgroundTransparency = 1
GarageScroll.ScrollBarThickness = 3
local UIList2 = Instance.new("UIListLayout", GarageScroll)
UIList2.Padding = UDim.new(0, 8)

-- ==========================================
-- UI KONFIRMASI KELUAR (MODAL)
-- ==========================================
local ConfirmOverlay = Instance.new("Frame", ScreenGui)
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 1
ConfirmOverlay.Visible = false

local ConfirmBox = Instance.new("Frame", ConfirmOverlay)
ConfirmBox.Size = UDim2.new(0, 300, 0, 150)
ConfirmBox.Position = UDim2.new(0.5, -150, 0.5, -50)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
ConfirmBox.ClipsDescendants = true
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", ConfirmBox).Color = Color3.fromRGB(150, 100, 255)
Instance.new("UIStroke", ConfirmBox).Thickness = 2

local CTitle = Instance.new("TextLabel", ConfirmBox)
CTitle.Size = UDim2.new(1, 0, 0, 60)
CTitle.BackgroundTransparency = 1
CTitle.Text = "Tutup Vura Flipper?"
CTitle.Font = Enum.Font.GothamBlack
CTitle.TextSize = 18
CTitle.TextColor3 = Color3.new(1, 1, 1)
Make3DText(CTitle)

local BtnYes = Instance.new("TextButton", ConfirmBox)
BtnYes.Size = UDim2.new(0.4, 0, 0, 40)
BtnYes.Position = UDim2.new(0.07, 0, 0.6, 0)
BtnYes.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
BtnYes.Text = "YA"
BtnYes.Font = Enum.Font.GothamBold
BtnYes.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", BtnYes).CornerRadius = UDim.new(0, 8)

local BtnNo = Instance.new("TextButton", ConfirmBox)
BtnNo.Size = UDim2.new(0.4, 0, 0, 40)
BtnNo.Position = UDim2.new(0.53, 0, 0.6, 0)
BtnNo.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
BtnNo.Text = "BATAL"
BtnNo.Font = Enum.Font.GothamBold
BtnNo.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", BtnNo).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseButton1Click:Connect(function()
	ConfirmOverlay.Visible = true
	TweenService:Create(ConfirmOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
	ConfirmBox.Position = UDim2.new(0.5, -150, 0.5, 0)
	TweenService:Create(ConfirmBox, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.5, -75)}):Play()
end)

BtnNo.MouseButton1Click:Connect(function()
	local tween = TweenService:Create(ConfirmOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1})
	tween:Play()
	tween.Completed:Connect(function() ConfirmOverlay.Visible = false end)
end)

BtnYes.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- ==========================================
-- 3. LOGIC & RENDER FUNGSI
-- ==========================================
local UpdateUI

local function BuyCar(uid)
	if #PlayerData.Garage >= PlayerData.Slots then return end
	for i, car in ipairs(DealerStock) do
		if car.uid == uid and PlayerData.Cash >= car.price then
			PlayerData.Cash -= car.price
			table.insert(PlayerData.Garage, car)
			table.remove(DealerStock, i)
			UpdateUI()
			break
		end
	end
end

local function SellCar(uid)
	for i, car in ipairs(PlayerData.Garage) do
		if car.uid == uid then
			PlayerData.Cash += calculateRealValue(car)
			table.remove(PlayerData.Garage, i)
			UpdateUI()
			break
		end
	end
end

local function RepairCar(uid, taskType)
	for _, car in ipairs(PlayerData.Garage) do
		if car.uid == uid then
			local cost = math.floor(Config.Cars[car.carId].basePrice * Config.Tasks[taskType].costPct)
			if PlayerData.Cash >= cost then
				PlayerData.Cash -= cost
				if taskType == "wash" then car.dirt = 0 else car.dents = 0 end
				UpdateUI()
			end
			break
		end
	end
end

local function CreateBtn(parent, text, color, pos, size)
	local b = Instance.new("TextButton", parent)
	b.Size = size
	b.Position = pos
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = color
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	Make3DText(b)
	b.MouseEnter:Connect(function() AnimateHover(b, true) end)
	b.MouseLeave:Connect(function() AnimateHover(b, false) end)
	return b
end

UpdateUI = function()
	InfoBar.Text = "$ " .. PlayerData.Cash .. " | Garasi " .. #PlayerData.Garage .. "/" .. PlayerData.Slots
	
	for _, c in pairs(DealerScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, car in ipairs(DealerStock) do
		local f = Instance.new("Frame", DealerScroll)
		f.Size = UDim2.new(1, -8, 0, 65)
		f.BackgroundColor3 = Color3.fromRGB(45, 35, 60)
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
		
		local lbl = Instance.new("TextLabel", f)
		lbl.Size = UDim2.new(0.65, 0, 1, 0)
		lbl.Position = UDim2.new(0.05, 0, 0, 0)
		lbl.Text = "<b>" .. car.name .. "</b>\n<font color='#00ff00'>$" .. car.price .. "</font>\nMesin: " .. math.floor((1 - car.engine)*100) .. "%"
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.BackgroundTransparency = 1
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		Make3DText(lbl)
		
		local bBtn = CreateBtn(f, "BELI", Color3.fromRGB(50, 180, 80), UDim2.new(0.68, 0, 0.25, 0), UDim2.new(0.28, 0, 0.5, 0))
		bBtn.MouseButton1Click:Connect(function() BuyCar(car.uid) end)
	end

	for _, c in pairs(GarageScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, car in ipairs(PlayerData.Garage) do
		local f = Instance.new("Frame", GarageScroll)
		f.Size = UDim2.new(1, -8, 0, 110)
		f.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
		
		local est = calculateRealValue(car)
		local lbl = Instance.new("TextLabel", f)
		lbl.Size = UDim2.new(0.9, 0, 0.45, 0)
		lbl.Position = UDim2.new(0.05, 0, 0.05, 0)
		lbl.Text = "<b>" .. car.name .. "</b> | Val: <font color='#00ff00'>$".. est .."</font>\nKotor: " .. math.floor(car.dirt*100) .. "% | Penyok: " .. math.floor(car.dents*100) .. "%"
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.BackgroundTransparency = 1
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		Make3DText(lbl)
		
		local sBtn = CreateBtn(f, "JUAL", Color3.fromRGB(200, 60, 60), UDim2.new(0.05, 0, 0.5, 0), UDim2.new(0.9, 0, 0.22, 0))
		sBtn.MouseButton1Click:Connect(function() SellCar(car.uid) end)
		
		local wCost = math.floor(Config.Cars[car.carId].basePrice * Config.Tasks.wash.costPct)
		local wBtn = CreateBtn(f, "Cuci ($"..wCost..")", Color3.fromRGB(40, 140, 200), UDim2.new(0.05, 0, 0.75, 0), UDim2.new(0.43, 0, 0.2, 0))
		wBtn.MouseButton1Click:Connect(function() RepairCar(car.uid, "wash") end)
		
		local dCost = math.floor(Config.Cars[car.carId].basePrice * Config.Tasks.dents.costPct)
		local dBtn = CreateBtn(f, "Ketok ($"..dCost..")", Color3.fromRGB(200, 130, 30), UDim2.new(0.52, 0, 0.75, 0), UDim2.new(0.43, 0, 0.2, 0))
		dBtn.MouseButton1Click:Connect(function() RepairCar(car.uid, "dents") end)
	end
end

-- ==========================================
-- MULAI GAME
-- ==========================================
generateDealerCars()
UpdateUI()

task.spawn(function()
	while task.wait(Config.StockRefreshSeconds) do
		generateDealerCars()
		UpdateUI()
	end
end)
