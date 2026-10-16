-- ==========================================
-- VURA | CAR FLIPPER (100% DATABASE & PREMIUM UI)
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
-- 1. DATABASE MOBIL (100% LENGKAP)
-- ==========================================
local rawDatabase = {
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
	-- Tambahan Extra Rare
	["Volfsen G-Series"] = 2, ["Luxius L-Class"] = 2, ["Mazuta RX"] = 2, ["Dawson Tracker"] = 2,

	-- Rarity 3 (Epic / Legend)
	["Artho F9 ST"] = 3, ["Artho G770"] = 3, ["Artho VS600"] = 3, ["Chiverleta Cerano XZ2"] = 3,
	["Chiverleta Ceretta X07"] = 3, ["Chiverleta Imalo 67"] = 3, ["Dawson Competition"] = 3, ["Dawson Hammer"] = 3,
	["Dawson Hammer 70"] = 3, ["Dawson Rhino SCT"] = 3, ["Deserter Grand Prince"] = 3, ["Deutschotoren C2"] = 3,
	["Deutschotoren C3"] = 3, ["Deutschotoren C4 DSG"] = 3, ["Deutschotoren C483"] = 3, ["Deutschotoren C5 600"] = 3,
	["Deutschotoren C873"] = 3, ["Deutschotoren S5"] = 3, ["Deutschotoren U8"] = 3, ["Hakusho MRB Sport"] = 3,
	["Lilia Exima"] = 3, ["Luxius BG600"] = 3, ["Marcalen-Denz VT"] = 3, ["Marcalen-Denz LPS"] = 3,
	["Marcalen-Denz LPS94"] = 3, ["Nikken Starline S340"] = 3, ["Nikken Starline S350"] = 3, ["Preischel 313n"] = 3,
	["Tokina Absoluta SR 2.0"] = 3,
	-- Tambahan Extra Epic/Legend
	["Deserter Mammoth"] = 3, ["Land Ranger X6"] = 3, ["Quantum Z900"] = 3, ["Preischel V12X"] = 3,
}

local RarityConfig = {
	[0] = { color = "#A3A3A3", label = "Common", weight = 50, baseP = 4500, mult = 150 },
	[1] = { color = "#55FF55", label = "Uncommon", weight = 25, baseP = 15000, mult = 400 },
	[2] = { color = "#55AAFF", label = "Rare", weight = 10, baseP = 48000, mult = 800 },
	[3] = { color = "#FFD700", label = "Legend", weight = 3, baseP = 160000, mult = 2000 },
}

local carList = {}
local totalWeight = 0

-- Konversi Raw Database menjadi List Berbobot
for name, rarity in pairs(rawDatabase) do
	local cfg = RarityConfig[rarity]
	-- Harga unik berdasarkan panjang string agar konsisten namun bervariasi
	local uniquePrice = cfg.baseP + (string.len(name) * cfg.mult)
	
	table.insert(carList, {
		id = string.gsub(string.lower(name), "[ %-%.]", "_"),
		name = name,
		rarity = rarity,
		rarityColor = cfg.color,
		rarityLabel = cfg.label,
		basePrice = uniquePrice,
		weight = cfg.weight
	})
	totalWeight = totalWeight + cfg.weight
end

-- Sistem Gacha Mobil (Semakin besar weight, semakin sering muncul)
local function getRandomCar()
	local r = math.random(1, totalWeight)
	local current = 0
	for _, car in ipairs(carList) do
		current = current + car.weight
		if r <= current then return car end
	end
	return carList[1]
end

local Config = {
	StartCash = 15000,
	StartSlots = 5,
	StockSize = 6,
	StockRefreshSeconds = 90,
	DealerDiscountMin = 0.75,
	DealerDiscountMax = 0.95,
	DealerAssumedEngine = 0.35,
	StatRanges = {
		dirt = { min = 0.30, max = 1.00 }, dents = { min = 0.00, max = 0.85 },
		rust = { min = 0.00, max = 0.90 }, engine = { min = 0.05, max = 0.90 },
	},
	ValueWeights = { dirt = 0.05, dents = 0.20, rust = 0.25, engine = 0.30 },
	ShowroomBonus = 0.10,
	Tasks = { wash = { id = "wash", costPct = 0.012 }, dents = { id = "dents", costPct = 0.06 } }
}

local PlayerData = { Cash = Config.StartCash, Slots = Config.StartSlots, Garage = {} }
local DealerStock = {}

local function calculateRealValue(carData)
	local penalty = (carData.dirt * Config.ValueWeights.dirt) + (carData.dents * Config.ValueWeights.dents) + (carData.rust * Config.ValueWeights.rust) + (carData.engine * Config.ValueWeights.engine)
	local val = carData.basePrice * (1 - penalty)
	if carData.dirt <= 0.05 and carData.dents <= 0.05 and carData.rust <= 0.05 and carData.engine <= 0.05 then val = val + (carData.basePrice * Config.ShowroomBonus) end
	return math.floor(val)
end

local function generateDealerCars()
	DealerStock = {}
	for i = 1, Config.StockSize do
		local rCar = getRandomCar()
		local function getS(s) return Config.StatRanges[s].min + math.random() * (Config.StatRanges[s].max - Config.StatRanges[s].min) end
		local penalty = (getS("dirt") * Config.ValueWeights.dirt) + (getS("dents") * Config.ValueWeights.dents) + (getS("rust") * Config.ValueWeights.rust) + (Config.DealerAssumedEngine * Config.ValueWeights.engine)
		local val = rCar.basePrice * (1 - penalty)
		local disc = Config.DealerDiscountMin + math.random() * (Config.DealerDiscountMax - Config.DealerDiscountMin)
		
		table.insert(DealerStock, {
			uid = HttpService:GenerateGUID(false), carId = rCar.id, name = rCar.name, 
			basePrice = rCar.basePrice, rarityColor = rCar.rarityColor, rarityLabel = rCar.rarityLabel,
			price = math.floor(val * disc),
			dirt = getS("dirt"), dents = getS("dents"), rust = getS("rust"), engine = getS("engine")
		})
	end
end

-- ==========================================
-- 2. UI DESAIN CLAY PREMIUM & ANIMASI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VuraCarFlipper"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 580, 0, 390)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -195)
MainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainGradient = Instance.new("UIGradient", MainFrame)
MainGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(120, 40, 190)), -- Ungu Premium
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(15, 15, 22))    -- Hitam Pekat
}
MainGradient.Rotation = 45
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(160, 90, 240)
MainStroke.Thickness = 2.5

local function Make3DText(obj)
	local stroke = Instance.new("UIStroke", obj)
	stroke.Color = Color3.fromRGB(10, 10, 10)
	stroke.Thickness = 1.5
end

local function AnimateHover(btn, isHover)
	local targetSize = isHover and UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset + 4, btn.Size.Y.Scale, btn.Size.Y.Offset + 4) or UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset - 4, btn.Size.Y.Scale, btn.Size.Y.Offset - 4)
	TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end

-- Top Bar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0.4, 0, 1, 0)
Title.Position = UDim2.new(0.03, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Vura | Car Flipper"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Make3DText(Title)

local InfoBar = Instance.new("TextLabel", TopBar)
InfoBar.Size = UDim2.new(0.4, 0, 1, 0)
InfoBar.Position = UDim2.new(0.4, 0, 0, 0)
InfoBar.BackgroundTransparency = 1
InfoBar.Text = "Uang: $0 | Garasi: 0/0"
InfoBar.Font = Enum.Font.GothamBold
InfoBar.TextSize = 14
InfoBar.TextColor3 = Color3.fromRGB(200, 255, 150)
InfoBar.TextXAlignment = Enum.TextXAlignment.Right
Make3DText(InfoBar)

-- Minimize & Close
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -75, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(230, 160, 20)
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.TextSize = 22
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)
Make3DText(MinBtn)

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 18
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
Make3DText(CloseBtn)

local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(0.94, 0, 0, 2)
Line.Position = UDim2.new(0.03, 0, 0, 45)
Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Line.BackgroundTransparency = 0.8

-- Logic Minimize
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	local newSize = isMinimized and UDim2.new(0, 580, 0, 45) or UDim2.new(0, 580, 0, 390)
	TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = newSize}):Play()
end)

-- Scroll Views
local DealerScroll = Instance.new("ScrollingFrame", MainFrame)
DealerScroll.Size = UDim2.new(0.46, 0, 1, -60)
DealerScroll.Position = UDim2.new(0.02, 0, 0, 52)
DealerScroll.BackgroundTransparency = 1
DealerScroll.ScrollBarThickness = 3
local UIList1 = Instance.new("UIListLayout", DealerScroll)
UIList1.Padding = UDim.new(0, 8)

local GarageScroll = Instance.new("ScrollingFrame", MainFrame)
GarageScroll.Size = UDim2.new(0.48, 0, 1, -60)
GarageScroll.Position = UDim2.new(0.50, 0, 0, 52)
GarageScroll.BackgroundTransparency = 1
GarageScroll.ScrollBarThickness = 3
local UIList2 = Instance.new("UIListLayout", GarageScroll)
UIList2.Padding = UDim.new(0, 8)

-- ==========================================
-- UI KONFIRMASI KELUAR (PREMIUM MODAL)
-- ==========================================
local ConfirmOverlay = Instance.new("Frame", ScreenGui)
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 1
ConfirmOverlay.Visible = false

local ConfirmBox = Instance.new("Frame", ConfirmOverlay)
ConfirmBox.Size = UDim2.new(0, 320, 0, 160)
ConfirmBox.Position = UDim2.new(0.5, -160, 0.5, -50)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
ConfirmBox.ClipsDescendants = true
Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", ConfirmBox).Color = Color3.fromRGB(180, 120, 255)
Instance.new("UIStroke", ConfirmBox).Thickness = 2.5

local CTitle = Instance.new("TextLabel", ConfirmBox)
CTitle.Size = UDim2.new(1, 0, 0, 70)
CTitle.BackgroundTransparency = 1
CTitle.Text = "Yakin Ingin Menutup\nVura Car Flipper?"
CTitle.Font = Enum.Font.GothamBlack
CTitle.TextSize = 18
CTitle.TextColor3 = Color3.new(1, 1, 1)
Make3DText(CTitle)

local BtnYes = Instance.new("TextButton", ConfirmBox)
BtnYes.Size = UDim2.new(0.4, 0, 0, 45)
BtnYes.Position = UDim2.new(0.07, 0, 0.6, 0)
BtnYes.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
BtnYes.Text = "TUTUP"
BtnYes.Font = Enum.Font.GothamBold
BtnYes.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", BtnYes).CornerRadius = UDim.new(0, 8)
Make3DText(BtnYes)

local BtnNo = Instance.new("TextButton", ConfirmBox)
BtnNo.Size = UDim2.new(0.4, 0, 0, 45)
BtnNo.Position = UDim2.new(0.53, 0, 0.6, 0)
BtnNo.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
BtnNo.Text = "BATAL"
BtnNo.Font = Enum.Font.GothamBold
BtnNo.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", BtnNo).CornerRadius = UDim.new(0, 8)
Make3DText(BtnNo)

CloseBtn.MouseButton1Click:Connect(function()
	ConfirmOverlay.Visible = true
	TweenService:Create(ConfirmOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
	ConfirmBox.Position = UDim2.new(0.5, -160, 0.5, 0)
	TweenService:Create(ConfirmBox, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -160, 0.5, -80)}):Play()
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
			local cost = math.floor(car.basePrice * Config.Tasks[taskType].costPct)
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
	InfoBar.Text = "Uang: $" .. PlayerData.Cash .. "   |   Garasi " .. #PlayerData.Garage .. "/" .. PlayerData.Slots
	
	for _, c in pairs(DealerScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, car in ipairs(DealerStock) do
		local f = Instance.new("Frame", DealerScroll)
		f.Size = UDim2.new(1, -8, 0, 75)
		f.BackgroundColor3 = Color3.fromRGB(45, 35, 60)
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
		
		local lbl = Instance.new("TextLabel", f)
		lbl.Size = UDim2.new(0.65, 0, 1, 0)
		lbl.Position = UDim2.new(0.05, 0, 0, 0)
		-- Menampilkan Teks Rarity Berwarna
		lbl.Text = "<b>" .. car.name .. "</b> [<font color='".. car.rarityColor .."'>".. car.rarityLabel .."</font>]\n<font color='#55FF55'>$" .. car.price .. "</font>\nMesin: " .. math.floor((1 - car.engine)*100) .. "%"
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
		f.Size = UDim2.new(1, -8, 0, 120)
		f.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
		
		local est = calculateRealValue(car)
		local lbl = Instance.new("TextLabel", f)
		lbl.Size = UDim2.new(0.9, 0, 0.45, 0)
		lbl.Position = UDim2.new(0.05, 0, 0.05, 0)
		lbl.Text = "<b>" .. car.name .. "</b> [<font color='".. car.rarityColor .."'>".. car.rarityLabel .."</font>]\nVal: <font color='#55FF55'>$".. est .."</font>\nKotor: " .. math.floor(car.dirt*100) .. "% | Penyok: " .. math.floor(car.dents*100) .. "%"
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.BackgroundTransparency = 1
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		Make3DText(lbl)
		
		local sBtn = CreateBtn(f, "JUAL", Color3.fromRGB(200, 60, 60), UDim2.new(0.05, 0, 0.5, 0), UDim2.new(0.9, 0, 0.22, 0))
		sBtn.MouseButton1Click:Connect(function() SellCar(car.uid) end)
		
		local wCost = math.floor(car.basePrice * Config.Tasks.wash.costPct)
		local wBtn = CreateBtn(f, "Cuci ($"..wCost..")", Color3.fromRGB(40, 140, 200), UDim2.new(0.05, 0, 0.75, 0), UDim2.new(0.43, 0, 0.2, 0))
		wBtn.MouseButton1Click:Connect(function() RepairCar(car.uid, "wash") end)
		
		local dCost = math.floor(car.basePrice * Config.Tasks.dents.costPct)
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
