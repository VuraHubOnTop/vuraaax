-- ============================================================
--  VURA RGB HUB  |  Roblox UI Framework (LocalScript)
--  Tab disesuaikan dengan fitur "Riding a Pet V2"
--  Tabs: Auto | ESP | Player | Config | Info
--  Original fitur: @unrandom_tk (V1)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- Hapus GUI lama (memicu cleanup lama)
for _, v in ipairs(PlayerGui:GetChildren()) do
	if v.Name == "VuraRgbHub" then
		v:Destroy()
	end
end

-- ============================================================
-- KONSTANTA
-- ============================================================
local WIN_W, WIN_H, HEADER_H = 540, 350, 44
local FOOTER_H = 24
local SIDEBAR_W = 132
local MARGIN = 10
local SHADOW_DY = -29
local SUBTITLE = "Premium Hub"
local CONFIG_FILE = "VuraHub_RidingAPet.json"

-- ============================================================
-- THEME & TWEEN PRESETS
-- ============================================================
local T = {
	Bg = Color3.fromRGB(11, 11, 16),
	Panel = Color3.fromRGB(17, 17, 25),
	Card = Color3.fromRGB(23, 23, 34),
	CardHover = Color3.fromRGB(32, 32, 47),
	Line = Color3.fromRGB(48, 48, 68),
	Text = Color3.fromRGB(238, 238, 248),
	SubText = Color3.fromRGB(150, 150, 175),
	Accent = Color3.fromRGB(145, 95, 255),
	Accent2 = Color3.fromRGB(70, 200, 255),
	Gold = Color3.fromRGB(255, 205, 110),
	Pink = Color3.fromRGB(255, 90, 170),
	Good = Color3.fromRGB(60, 210, 130),
	Bad = Color3.fromRGB(235, 70, 90),
	Warn = Color3.fromRGB(255, 170, 60),
}

local TI = {
	FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	SMOOTH = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	BOUNCY = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 96, 255)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(70, 200, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 205, 110)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 90, 170)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(145, 96, 255)),
})

-- ============================================================
-- KONEKSI & CLEANUP
-- ============================================================
local connections = {}
local cleanupHooks = {}
local alive = true
local cleaned = false

local function keep(conn)
	connections[#connections + 1] = conn
	return conn
end

local function onCleanup(fn)
	cleanupHooks[#cleanupHooks + 1] = fn
end

local function cleanup()
	if cleaned then return end
	cleaned = true
	alive = false
	for _, fn in ipairs(cleanupHooks) do
		pcall(fn)
	end
	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
end

-- ============================================================
-- HELPER UI
-- ============================================================
local function tween(obj, info, props)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or T.Line
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function padding(parent, l, t, r, b)
	local p = Instance.new("UIPadding")
	t = t or l
	r = r or l
	b = b or t
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = parent
	return p
end

local function gradient(parent, seq, rotation)
	local g = Instance.new("UIGradient")
	if typeof(seq) == "table" then
		local kp = {}
		for i, c in ipairs(seq) do
			kp[i] = ColorSequenceKeypoint.new((i - 1) / (#seq - 1), c)
		end
		g.Color = ColorSequence.new(kp)
	else
		g.Color = seq
	end
	g.Rotation = rotation or 0
	g.Parent = parent
	return g
end

local function newLabel(parent, text, size, font, color, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Text = text
	l.TextSize = size or 12
	l.Font = font or Enum.Font.Gotham
	l.TextColor3 = color or T.Text
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = UDim2.new(1, 0, 1, 0)
	l.Parent = parent
	if props then
		for k, v in pairs(props) do
			l[k] = v
		end
	end
	return l
end

-- ============================================================
-- STATE & CONFIG
-- ============================================================
local S = {
	ESP = true,
	RareAlert = false,
	FPSBoost = false,
	Filter = "",
	SpeedVal = 16,
	JumpVal = 50,
	FlySpeed = 5,
	Fly = false,
	Noclip = false,
	AntiAFK = true,
	AutoCollect = false,
	AutoHatch = false,
	AutoPlace = false,
}

local function getHumanoid()
	local c = LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

-- Simpan nilai asli humanoid (dipulihkan saat cleanup)
local origWS, origJP, origUseJP = 16, 50, true
do
	local h = getHumanoid()
	if h then
		origWS = h.WalkSpeed
		origJP = h.JumpPower
		origUseJP = h.UseJumpPower
		S.SpeedVal = math.clamp(math.floor(origWS + 0.5), 1, 1000)
		S.JumpVal = math.clamp(math.floor(origJP + 0.5), 1, 1000)
	end
end

local function hasFS()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function SaveConfig()
	if not hasFS() then return false end
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(S)
	end)
	if not ok then return false end
	local wrote = pcall(writefile, CONFIG_FILE, encoded)
	return wrote
end

local function LoadConfig()
	if not hasFS() then return false end
	local exists = false
	pcall(function() exists = isfile(CONFIG_FILE) end)
	if not exists then return false end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(CONFIG_FILE))
	end)
	if ok and type(data) == "table" then
		for k, v in pairs(data) do
			if S[k] ~= nil and type(v) == type(S[k]) then
				S[k] = v
			end
		end
		return true
	end
	return false
end

pcall(LoadConfig)

-- ============================================================
-- GUI ROOT
-- ============================================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "VuraRgbHub"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999
Gui.Parent = PlayerGui
Gui.Destroying:Connect(cleanup)

-- Kalibrasi: apakah Position offset ikut di-scale oleh UIScale milik sendiri?
local posScaled = true
pcall(function()
	local probe = Instance.new("Frame")
	probe.BackgroundTransparency = 1
	probe.Size = UDim2.fromOffset(10, 10)
	probe.Position = UDim2.fromOffset(200, 0)
	local us = Instance.new("UIScale")
	us.Scale = 0.5
	us.Parent = probe
	probe.Parent = Gui
	task.wait(0.1)
	local x = probe.AbsolutePosition.X
	probe:Destroy()
	if math.abs(x - 200) < math.abs(x - 100) then
		posScaled = false
	end
end)

local function guiSize()
	local s = Gui.AbsoluteSize
	if s.X < 2 or s.Y < 2 then
		local cam = Workspace.CurrentCamera
		local inset = GuiService:GetGuiInset()
		s = Vector2.new(cam.ViewportSize.X, cam.ViewportSize.Y - inset.Y)
	end
	return s
end

-- ============================================================
-- KOMPONEN REUSABLE
-- ============================================================
local uiSetters = {}

local function makeDraggable(handle, target, scaleObj, shadow, onEnd, onStart)
	local dragging = false
	local dragInput, dragStart, startPos, startShadow

	keep(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if onStart then onStart() end
			dragging = true
			dragInput = input
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = target.Position
			startShadow = shadow and shadow.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if c then c:Disconnect() end
					if dragging then
						dragging = false
						if onEnd then onEnd() end
					end
				end
			end)
		end
	end))

	keep(UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput then
			local div = posScaled and math.max(scaleObj.Scale, 0.01) or 1
			local d = (Vector2.new(input.Position.X, input.Position.Y) - dragStart) / div
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
			if shadow and startShadow then
				shadow.Position = UDim2.new(startShadow.X.Scale, startShadow.X.Offset + d.X,
					startShadow.Y.Scale, startShadow.Y.Offset + d.Y)
			end
		end
	end))
end

local function makeRow(parent, height, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, height)
	row.BackgroundColor3 = T.Card
	row.BorderSizePixel = 0
	row.LayoutOrder = order or 0
	row.Parent = parent
	corner(row, 8)
	local st = stroke(row, T.Line, 1)
	return row, st
end

local function bindRowHover(hit, row)
	keep(hit.MouseEnter:Connect(function()
		tween(row, TI.FAST, {BackgroundColor3 = T.CardHover})
	end))
	keep(hit.MouseLeave:Connect(function()
		tween(row, TI.FAST, {BackgroundColor3 = T.Card})
	end))
end

local function newHit(parent, zindex)
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.ZIndex = zindex or 5
	hit.Parent = parent
	return hit
end

local function safeCall(fn, arg)
	if not fn then return end
	local ok, err = pcall(fn, arg)
	if not ok then
		warn("[VuraHub] " .. tostring(err))
	end
end

-- Switch (track + knob), return fungsi setVisual(on, animate)
local function buildSwitch(parent, tw, th, kd, pad)
	local trackF = Instance.new("Frame")
	trackF.Size = UDim2.fromOffset(tw, th)
	trackF.AnchorPoint = Vector2.new(1, 0.5)
	trackF.Position = UDim2.new(1, -10, 0.5, 0)
	trackF.BackgroundColor3 = T.Line
	trackF.BorderSizePixel = 0
	trackF.Parent = parent
	corner(trackF, th / 2)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(kd, kd)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Position = UDim2.new(0, pad, 0.5, 0)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.Parent = trackF
	corner(knob, kd / 2)

	return function(on, animate)
		local x = on and (tw - kd - pad) or pad
		local col = on and T.Good or T.Line
		local pos = UDim2.new(0, x, 0.5, 0)
		if animate then
			tween(knob, TI.BOUNCY, {Position = pos})
			tween(trackF, TI.FAST, {BackgroundColor3 = col})
		else
			knob.Position = pos
			trackF.BackgroundColor3 = col
		end
	end
end

local function makeToggle(parent, dict, key, label, color, order, onChange)
	local row = makeRow(parent, 32, order)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(8, 8)
	dot.Position = UDim2.new(0, 12, 0.5, -4)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	dot.Parent = row
	corner(dot, 4)

	newLabel(row, label, 12, Enum.Font.GothamMedium, T.Text, {
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -90, 1, 0),
	})

	local setVisual = buildSwitch(row, 38, 20, 14, 3)
	setVisual(dict[key], false)

	local hit = newHit(row, 5)
	bindRowHover(hit, row)

	local function set(v)
		dict[key] = v
		setVisual(v, true)
		safeCall(onChange, v)
	end

	keep(hit.MouseButton1Click:Connect(function()
		set(not dict[key])
	end))

	uiSetters[key] = set
	return row, set
end

-- Kartu besar dengan switch besar
local function makeCard(parent, dict, key, title, desc, color, order, onChange)
	local card, st = makeRow(parent, 78, order)

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 3, 1, -24)
	accentBar.Position = UDim2.new(0, 0, 0, 12)
	accentBar.BackgroundColor3 = color
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card
	corner(accentBar, 2)

	newLabel(card, title, 14, Enum.Font.GothamBold, T.Text, {
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(1, -100, 0, 18),
	})
	newLabel(card, desc, 11, Enum.Font.Gotham, T.SubText, {
		Position = UDim2.new(0, 16, 0, 30),
		Size = UDim2.new(1, -100, 0, 28),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	local status = newLabel(card, "○ IDLE", 10, Enum.Font.GothamBold, T.SubText, {
		Position = UDim2.new(0, 16, 1, -18),
		Size = UDim2.new(0, 120, 0, 12),
	})

	local setVisual = buildSwitch(card, 54, 28, 22, 3)

	local function paint(on, animate)
		setVisual(on, animate)
		status.Text = on and "● ACTIVE" or "○ IDLE"
		status.TextColor3 = on and T.Good or T.SubText
		if animate then
			tween(st, TI.FAST, {Color = on and color or T.Line})
		else
			st.Color = on and color or T.Line
		end
	end
	paint(dict[key], false)

	local hit = newHit(card, 5)
	bindRowHover(hit, card)

	local function set(v)
		dict[key] = v
		paint(v, true)
		safeCall(onChange, v)
	end

	keep(hit.MouseButton1Click:Connect(function()
		set(not dict[key])
	end))

	uiSetters[key] = set
	return card, set
end

local function makeSlider(parent, dict, key, label, minV, maxV, color, order, onChange)
	local row = makeRow(parent, 50, order)

	newLabel(row, label, 12, Enum.Font.GothamMedium, T.Text, {
		Position = UDim2.new(0, 12, 0, 7),
		Size = UDim2.new(0.6, 0, 0, 16),
	})
	local valLbl = newLabel(row, tostring(dict[key]), 12, Enum.Font.GothamBold, color, {
		Position = UDim2.new(0.6, 0, 0, 7),
		Size = UDim2.new(0.4, -12, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local bar = Instance.new("Frame")
	bar.Position = UDim2.new(0, 12, 0, 33)
	bar.Size = UDim2.new(1, -24, 0, 6)
	bar.BackgroundColor3 = T.Bg
	bar.BorderSizePixel = 0
	bar.Parent = row
	corner(bar, 3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bar
	corner(fill, 3)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.Parent = bar
	corner(knob, 7)

	local function setVal(v, silent)
		v = math.clamp(math.floor(v + 0.5), minV, maxV)
		dict[key] = v
		local p = (v - minV) / (maxV - minV)
		fill.Size = UDim2.new(p, 0, 1, 0)
		knob.Position = UDim2.new(p, 0, 0.5, 0)
		valLbl.Text = tostring(v)
		if not silent then
			safeCall(onChange, v)
		end
	end
	setVal(dict[key], true)

	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Position = UDim2.new(0, 6, 0, 24)
	hit.Size = UDim2.new(1, -12, 0, 24)
	hit.ZIndex = 5
	hit.Parent = row

	local dragging, dragInput = false, nil

	local function updateFromX(x)
		local w = bar.AbsoluteSize.X
		if w < 1 then return end
		local p = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
		setVal(minV + p * (maxV - minV))
	end

	local function setScrolling(enabled)
		if parent:IsA("ScrollingFrame") then
			parent.ScrollingEnabled = enabled
		end
	end

	keep(hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			setScrolling(false)
			updateFromX(input.Position.X)
		end
	end))
	keep(UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then
			updateFromX(input.Position.X)
		end
	end))
	keep(UIS.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input == dragInput) then
			dragging = false
			setScrolling(true)
		end
	end))

	uiSetters[key] = function(v)
		setVal(v)
	end
	return row
end

local function makeInput(parent, dict, key, placeholder, order, onChange)
	local row, st = makeRow(parent, 32, order)
	local box = Instance.new("TextBox")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Position = UDim2.new(0, 12, 0, 0)
	box.Size = UDim2.new(1, -24, 1, 0)
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = T.SubText
	box.Text = dict[key]
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextColor3 = T.Text
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = row

	keep(box.Focused:Connect(function()
		tween(st, TI.FAST, {Color = T.Accent})
	end))
	keep(box.FocusLost:Connect(function()
		tween(st, TI.FAST, {Color = T.Line})
		dict[key] = box.Text
		safeCall(onChange, box.Text)
	end))

	uiSetters[key] = function(v)
		box.Text = v
		dict[key] = v
		safeCall(onChange, v)
	end
	return row
end

local function makeSection(parent, txt, order)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 20)
	f.LayoutOrder = order or 0
	f.Parent = parent

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 0, 12)
	bar.Position = UDim2.new(0, 2, 0.5, -6)
	bar.BackgroundColor3 = T.Accent
	bar.BorderSizePixel = 0
	bar.Parent = f
	corner(bar, 2)

	newLabel(f, string.upper(txt), 11, Enum.Font.GothamBold, T.SubText, {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -12, 1, 0),
	})
	return f
end

local function makeNote(parent, text, order)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.BackgroundColor3 = T.Panel
	f.BorderSizePixel = 0
	f.LayoutOrder = order or 0
	f.Parent = parent
	corner(f, 8)
	padding(f, 10, 8, 10, 8)
	local l = newLabel(f, text, 11, Enum.Font.Gotham, T.SubText, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	return f, l
end

local function makeInfoRow(parent, key, val, order)
	local row = makeRow(parent, 28, order)
	newLabel(row, key, 11, Enum.Font.GothamBold, T.Gold, {
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
	})
	local v = newLabel(row, val, 11, Enum.Font.Gotham, T.Text, {
		Position = UDim2.new(0.4, 0, 0, 0),
		Size = UDim2.new(0.6, -12, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	return row, v
end

-- Tombol: background Frame terpisah (gradient tidak mewarnai teks)
local function makeButton(parent, text, height, c1, c2, order, callback)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.new(1, 0, 0, height)
	holder.LayoutOrder = order or 0
	holder.Parent = parent

	local bg = Instance.new("Frame")
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.new(0.5, 0, 0.5, 0)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(1, 1, 1)
	bg.BorderSizePixel = 0
	bg.Parent = holder
	corner(bg, 8)
	gradient(bg, {c1, c2}, 0)
	local st = stroke(bg, T.Line, 1)

	local press = Instance.new("UIScale")
	press.Scale = 1
	press.Parent = bg

	local label = newLabel(bg, text, 12, Enum.Font.GothamBold, T.Text, {
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local hit = newHit(holder, 5)

	keep(hit.MouseEnter:Connect(function()
		tween(st, TI.FAST, {Color = T.Accent})
		tween(label, TI.FAST, {TextColor3 = Color3.new(1, 1, 1)})
	end))
	keep(hit.MouseLeave:Connect(function()
		tween(st, TI.FAST, {Color = T.Line})
		tween(label, TI.FAST, {TextColor3 = T.Text})
		tween(press, TI.FAST, {Scale = 1})
	end))
	keep(hit.MouseButton1Down:Connect(function()
		tween(press, TI.FAST, {Scale = 0.96})
	end))
	keep(hit.MouseButton1Up:Connect(function()
		tween(press, TI.FAST, {Scale = 1})
	end))
	if callback then
		keep(hit.MouseButton1Click:Connect(function()
			safeCall(callback)
		end))
	end
	return holder, hit, label
end

-- ============================================================
-- WINDOW: SHADOW, MAINFRAME, STRUKTUR
-- ============================================================
local toggleMinimize, showWarning, setHidden, refreshLayout
local moveWindow, captureOpenPosition, clampedOpenPosition, cancelPosTweens

local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5028857084"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.35
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(24, 24, 276, 276)
Shadow.AnchorPoint = Vector2.new(0.5, 0)
Shadow.Size = UDim2.fromOffset(WIN_W + 70, WIN_H + 70)
Shadow.ZIndex = 1
Shadow.Parent = Gui
local ShadowScale = Instance.new("UIScale")
ShadowScale.Scale = 0.01
ShadowScale.Parent = Shadow

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0)
MainFrame.Size = UDim2.fromOffset(WIN_W, WIN_H)
MainFrame.BackgroundColor3 = T.Bg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.ZIndex = 2
MainFrame.Parent = Gui
corner(MainFrame, 14)
local MainScale = Instance.new("UIScale")
MainScale.Scale = 0.01
MainScale.Parent = MainFrame

keep(MainScale:GetPropertyChangedSignal("Scale"):Connect(function()
	ShadowScale.Scale = MainScale.Scale
end))

-- Border RGB animasi
local BorderStroke = stroke(MainFrame, Color3.new(1, 1, 1), 2)
local BorderGrad = gradient(BorderStroke, RAINBOW, 0)

-- Glow
local Glow = Instance.new("ImageLabel")
Glow.Name = "Glow"
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = T.Accent
Glow.ImageTransparency = 0.88
Glow.ScaleType = Enum.ScaleType.Slice
Glow.SliceCenter = Rect.new(24, 24, 276, 276)
Glow.Position = UDim2.new(0, -20, 0, -40)
Glow.Size = UDim2.new(1, 40, 0, 150)
Glow.ZIndex = 1
Glow.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, HEADER_H)
Header.BackgroundColor3 = T.Panel
Header.BorderSizePixel = 0
Header.Active = true
Header.ZIndex = 2
Header.Parent = MainFrame

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3 = T.Line
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Header

local LogoBadge = Instance.new("Frame")
LogoBadge.Size = UDim2.fromOffset(28, 28)
LogoBadge.Position = UDim2.new(0, 12, 0.5, -14)
LogoBadge.BackgroundColor3 = Color3.new(1, 1, 1)
LogoBadge.BorderSizePixel = 0
LogoBadge.Parent = Header
corner(LogoBadge, 8)
gradient(LogoBadge, {T.Accent, T.Accent2}, 45)
newLabel(LogoBadge, "⚡", 15, Enum.Font.GothamBold, Color3.new(1, 1, 1), {
	TextXAlignment = Enum.TextXAlignment.Center,
})

local Title = newLabel(Header, "Vura | Ride A Pet", 15, Enum.Font.GothamBlack, Color3.new(1, 1, 1), {
	Position = UDim2.new(0, 48, 0, 5),
	Size = UDim2.new(0, 200, 0, 20),
})
local TitleGrad = gradient(Title, {Color3.new(1, 1, 1), T.Gold}, 0)

newLabel(Header, SUBTITLE, 10, Enum.Font.Gotham, T.SubText, {
	Position = UDim2.new(0, 48, 0, 25),
	Size = UDim2.new(0, 220, 0, 12),
})

local function headerButton(text, color, xOff)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(26, 26)
	b.Position = UDim2.new(1, xOff, 0.5, -13)
	b.BackgroundColor3 = T.Card
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = color
	b.Parent = Header
	corner(b, 8)
	keep(b.MouseEnter:Connect(function()
		tween(b, TI.FAST, {BackgroundColor3 = color, TextColor3 = Color3.new(1, 1, 1)})
	end))
	keep(b.MouseLeave:Connect(function()
		tween(b, TI.FAST, {BackgroundColor3 = T.Card, TextColor3 = color})
	end))
	return b
end

local MinBtn = headerButton("–", T.Warn, -66)
local CloseBtn = headerButton("✕", T.Bad, -36)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Position = UDim2.new(0, 0, 0, HEADER_H)
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 0, WIN_H - HEADER_H - FOOTER_H)
Sidebar.BackgroundColor3 = T.Panel
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame
padding(Sidebar, 8, 8, 8, 8)
do
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 4)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = Sidebar
end

-- Content
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Position = UDim2.new(0, SIDEBAR_W, 0, HEADER_H)
ContentContainer.Size = UDim2.new(1, -SIDEBAR_W, 0, WIN_H - HEADER_H - FOOTER_H)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.ClipsDescendants = true
ContentContainer.ZIndex = 2
ContentContainer.Parent = MainFrame

-- Footer
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Position = UDim2.new(0, 0, 0, WIN_H - FOOTER_H)
Footer.Size = UDim2.new(1, 0, 0, FOOTER_H)
Footer.BackgroundColor3 = T.Panel
Footer.BorderSizePixel = 0
Footer.ZIndex = 2
Footer.Parent = MainFrame

local FooterLine = Instance.new("Frame")
FooterLine.Size = UDim2.new(1, 0, 0, 1)
FooterLine.BackgroundColor3 = T.Line
FooterLine.BorderSizePixel = 0
FooterLine.Parent = Footer

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(8, 8)
StatusDot.Position = UDim2.new(0, 12, 0.5, -4)
StatusDot.BackgroundColor3 = T.Good
StatusDot.BorderSizePixel = 0
StatusDot.Parent = Footer
corner(StatusDot, 4)

local StatusText = newLabel(Footer, "Ready • " .. LP.DisplayName, 10, Enum.Font.GothamMedium, T.SubText, {
	Position = UDim2.new(0, 26, 0, 0),
	Size = UDim2.new(0.6, -26, 1, 0),
})
newLabel(Footer, "LeftCtrl: show / hide", 10, Enum.Font.Gotham, T.SubText, {
	Position = UDim2.new(0.6, 0, 0, 0),
	Size = UDim2.new(0.4, -12, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Right,
})

local function setStatus(text, color)
	StatusText.Text = text
	tween(StatusDot, TI.FAST, {BackgroundColor3 = color or T.Good})
end

-- Toast
local Toast = Instance.new("Frame")
Toast.Name = "Toast"
Toast.AnchorPoint = Vector2.new(0.5, 1)
Toast.Position = UDim2.new(0.5, 0, 1, 40)
Toast.Size = UDim2.fromOffset(280, 30)
Toast.BackgroundColor3 = T.Card
Toast.BorderSizePixel = 0
Toast.ZIndex = 20
Toast.Parent = MainFrame
corner(Toast, 8)
local ToastStroke = stroke(Toast, T.Accent, 1)
local ToastLabel = newLabel(Toast, "", 12, Enum.Font.GothamBold, T.Text, {
	TextXAlignment = Enum.TextXAlignment.Center,
})

local toastToken = 0
local function notify(text, color)
	toastToken += 1
	local my = toastToken
	ToastLabel.Text = text
	ToastStroke.Color = color or T.Accent
	tween(Toast, TI.SMOOTH, {Position = UDim2.new(0.5, 0, 1, -34)})
	task.delay(2, function()
		if my == toastToken and alive then
			tween(Toast, TI.SMOOTH, {Position = UDim2.new(0.5, 0, 1, 40)})
		end
	end)
end

-- ============================================================
-- POSISI & UKURAN WINDOW
-- ============================================================
local baseScale = 1
local minimized, hidden = false, false
local logicalCX, logicalTop = 0, 0
local openRel = Vector2.new(0.5, 0.1)
local posTweens = {}
local lastVS = Vector2.new(0, 0)

local function posDiv()
	return posScaled and math.max(MainScale.Scale, 0.01) or 1
end
local function pxToOff(v) return v / posDiv() end
local function offToPx(v) return v * posDiv() end

local function computeBaseScale()
	local vs = guiSize()
	local s = math.min((vs.X - MARGIN * 2) / WIN_W, (vs.Y - MARGIN * 2) / WIN_H)
	return math.clamp(s, 0.55, 1)
end

local function heightPx()
	return (minimized and (HEADER_H + 2) or WIN_H) * baseScale
end

local function clampPos(cx, top, hPx)
	local vs = guiSize()
	local halfW = WIN_W * baseScale / 2
	local minX, maxX = halfW + MARGIN, vs.X - halfW - MARGIN
	if maxX < minX then
		cx = vs.X / 2
	else
		cx = math.clamp(cx, minX, maxX)
	end
	local minY, maxY = MARGIN, vs.Y - hPx - MARGIN
	if maxY < minY then
		top = MARGIN
	else
		top = math.clamp(top, minY, maxY)
	end
	return cx, top
end

local function guiSizeNow()
	return guiSize()
end

local function windowPosition(cx, top)
	local ccx, ctop = clampPos(cx, top, heightPx())
	return UDim2.fromOffset(pxToOff(ccx), pxToOff(ctop)), ccx, ctop
end

cancelPosTweens = function()
	for _, tw in ipairs(posTweens) do
		pcall(function() tw:Cancel() end)
	end
	table.clear(posTweens)
end

moveWindow = function(cx, top, animate)
	local pos, ccx, ctop = windowPosition(cx, top)
	logicalCX, logicalTop = ccx, ctop
	local spos = UDim2.fromOffset(pos.X.Offset, pos.Y.Offset + SHADOW_DY)
	cancelPosTweens()
	if animate then
		posTweens[1] = tween(MainFrame, TI.SMOOTH, {Position = pos})
		posTweens[2] = tween(Shadow, TI.SMOOTH, {Position = spos})
	else
		MainFrame.Position = pos
		Shadow.Position = spos
	end
end

captureOpenPosition = function()
	local vs = guiSizeNow()
	openRel = Vector2.new(logicalCX / vs.X, logicalTop / vs.Y)
end

clampedOpenPosition = function()
	local vs = guiSizeNow()
	return clampPos(openRel.X * vs.X, openRel.Y * vs.Y, WIN_H * baseScale)
end

-- Jaga posisi piksel saat scale berubah (intro, hide/show)
keep(MainScale:GetPropertyChangedSignal("Scale"):Connect(function()
	if posScaled and logicalCX ~= 0 then
		cancelPosTweens()
		local px, py = pxToOff(logicalCX), pxToOff(logicalTop)
		MainFrame.Position = UDim2.fromOffset(px, py)
		Shadow.Position = UDim2.fromOffset(px, py + SHADOW_DY)
	end
end))

refreshLayout = function(force)
	local vs = guiSizeNow()
	if not force and (vs - lastVS).Magnitude < 1 then return end
	lastVS = vs
	baseScale = computeBaseScale()
	if not hidden then
		MainScale.Scale = baseScale
	end
	if minimized then
		moveWindow(openRel.X * vs.X, MARGIN, false)
	else
		local cx, top = clampedOpenPosition()
		moveWindow(cx, top, false)
	end
end

toggleMinimize = function()
	minimized = not minimized
	MinBtn.Text = minimized and "+" or "–"
	local h = minimized and (HEADER_H + 2) or WIN_H
	tween(MainFrame, TI.SMOOTH, {Size = UDim2.fromOffset(WIN_W, h)})
	tween(Shadow, TI.SMOOTH, {Size = UDim2.fromOffset(WIN_W + 70, h + 70)})
	if minimized then
		captureOpenPosition()
		moveWindow(logicalCX, MARGIN, true)
	else
		local cx, top = clampedOpenPosition()
		moveWindow(cx, top, true)
	end
end

local hideToken = 0
setHidden = function(h)
	if h == hidden then return end
	hidden = h
	hideToken += 1
	local my = hideToken
	if h then
		local tw = tween(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.01})
		tw.Completed:Connect(function()
			if my == hideToken and hidden then
				MainFrame.Visible = false
				Shadow.Visible = false
			end
		end)
	else
		MainFrame.Visible = true
		Shadow.Visible = true
		tween(MainScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = baseScale})
	end
end

local function resetWindowPosition()
	if minimized then toggleMinimize() end
	local vs = guiSizeNow()
	moveWindow(vs.X / 2, (vs.Y - WIN_H * baseScale) / 2, true)
	captureOpenPosition()
end

local function onDragEnd()
	local cx = offToPx(MainFrame.Position.X.Offset)
	local top = offToPx(MainFrame.Position.Y.Offset)
	moveWindow(cx, top, true)
	if not minimized then
		captureOpenPosition()
	end
end

makeDraggable(Header, MainFrame, MainScale, Shadow, onDragEnd, cancelPosTweens)

-- ============================================================
-- MODAL WARNING
-- ============================================================
local Overlay = Instance.new("TextButton")
Overlay.Name = "Overlay"
Overlay.Text = ""
Overlay.AutoButtonColor = false
Overlay.Active = true
Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
Overlay.BackgroundTransparency = 1
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 50
Overlay.Visible = false
do
	local inset = GuiService:GetGuiInset()
	Overlay.Position = UDim2.fromOffset(0, -inset.Y)
	Overlay.Size = UDim2.new(1, 0, 1, inset.Y)
end
Overlay.Parent = Gui

local FrameWarning = Instance.new("Frame")
FrameWarning.AnchorPoint = Vector2.new(0.5, 0.5)
FrameWarning.Position = UDim2.new(0.5, 0, 0.5, 0)
FrameWarning.Size = UDim2.fromOffset(320, 170)
FrameWarning.BackgroundColor3 = T.Panel
FrameWarning.BorderSizePixel = 0
FrameWarning.Active = true
FrameWarning.Parent = Overlay
corner(FrameWarning, 14)
local WarnScale = Instance.new("UIScale")
WarnScale.Scale = 0.85
WarnScale.Parent = FrameWarning

local WarnStroke = stroke(FrameWarning, Color3.new(1, 1, 1), 2)
local WarnGrad = gradient(WarnStroke, {T.Bad, T.Warn, T.Bad}, 0)

newLabel(FrameWarning, "⚠", 36, Enum.Font.GothamBold, T.Warn, {
	Position = UDim2.new(0, 0, 0, 6),
	Size = UDim2.new(1, 0, 0, 42),
	TextXAlignment = Enum.TextXAlignment.Center,
})
local WarnTitle = newLabel(FrameWarning, "", 15, Enum.Font.GothamBold, T.Text, {
	Position = UDim2.new(0, 0, 0, 50),
	Size = UDim2.new(1, 0, 0, 20),
	TextXAlignment = Enum.TextXAlignment.Center,
})
local WarnMsg = newLabel(FrameWarning, "", 11, Enum.Font.Gotham, T.SubText, {
	Position = UDim2.new(0, 20, 0, 72),
	Size = UDim2.new(1, -40, 0, 40),
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Top,
})

local WarnButtons = Instance.new("Frame")
WarnButtons.BackgroundTransparency = 1
WarnButtons.Position = UDim2.new(0, 20, 0, 120)
WarnButtons.Size = UDim2.new(1, -40, 0, 34)
WarnButtons.Parent = FrameWarning
do
	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.Padding = UDim.new(0, 8)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = WarnButtons
end

local modalBase = 1
local warnToken = 0
local warnConfirm = nil

local function hideWarning()
	warnToken += 1
	local my = warnToken
	tween(Overlay, TI.FAST, {BackgroundTransparency = 1})
	tween(WarnScale, TI.FAST, {Scale = 0.85 * modalBase})
	task.delay(0.17, function()
		if my == warnToken then
			Overlay.Visible = false
		end
	end)
end

local CancelHolder = makeButton(WarnButtons, "Batal", 34, T.CardHover, T.Card, 1, hideWarning)
CancelHolder.Size = UDim2.new(0.5, -4, 1, 0)

local _, _, ConfirmLabel
local ConfirmHolder
ConfirmHolder, _, ConfirmLabel = makeButton(WarnButtons, "Ya", 34, T.Bad, T.Warn, 2, function()
	local f = warnConfirm
	hideWarning()
	if f then f() end
end)
ConfirmHolder.Size = UDim2.new(0.5, -4, 1, 0)

showWarning = function(titleText, msgText, confirmText, onConfirm)
	warnToken += 1
	warnConfirm = onConfirm
	WarnTitle.Text = titleText
	WarnMsg.Text = msgText
	ConfirmLabel.Text = confirmText
	local vs = guiSizeNow()
	modalBase = math.clamp(math.min((vs.X - 20) / 320, (vs.Y - 20) / 170), 0.55, 1)
	Overlay.BackgroundTransparency = 1
	Overlay.Visible = true
	WarnScale.Scale = 0.85 * modalBase
	tween(Overlay, TI.FAST, {BackgroundTransparency = 0.45})
	tween(WarnScale, TI.BOUNCY, {Scale = modalBase})
end

keep(Overlay.MouseButton1Click:Connect(hideWarning))

keep(MinBtn.MouseButton1Click:Connect(function()
	toggleMinimize()
end))
keep(CloseBtn.MouseButton1Click:Connect(function()
	showWarning("Tutup VURA Hub?",
		"Semua fitur (ESP, Fly, Noclip, Auto) akan dimatikan dan GUI dihapus.",
		"Ya, Tutup",
		function() Gui:Destroy() end)
end))

-- ============================================================
-- TOGGLE BUTTON (PILL)
-- ============================================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.fromOffset(112, 30)
ToggleBtn.Position = UDim2.fromOffset(12, 10)
ToggleBtn.BackgroundColor3 = T.Panel
ToggleBtn.BorderSizePixel = 0
ToggleBtn.AutoButtonColor = false
ToggleBtn.Text = "⚡ VURA HUB"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.TextColor3 = T.Text
ToggleBtn.ZIndex = 3
ToggleBtn.Parent = Gui
corner(ToggleBtn, 15)
local ToggleStroke = stroke(ToggleBtn, Color3.new(1, 1, 1), 2)
local ToggleGrad = gradient(ToggleStroke, RAINBOW, 90)
local ToggleScale = Instance.new("UIScale")
ToggleScale.Scale = 1
ToggleScale.Parent = ToggleBtn

keep(ToggleBtn.MouseEnter:Connect(function()
	tween(ToggleScale, TI.FAST, {Scale = 1.06})
end))
keep(ToggleBtn.MouseLeave:Connect(function()
	tween(ToggleScale, TI.FAST, {Scale = 1})
end))
keep(ToggleBtn.MouseButton1Click:Connect(function()
	setHidden(not hidden)
end))

keep(UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.LeftControl then
		setHidden(not hidden)
	end
end))

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local tabs = {}
local tabCount = 0
local currentTab = nil

local function createPage(name, icon)
	tabCount += 1

	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. name
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = T.CardHover
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.LayoutOrder = tabCount
	btn.Parent = Sidebar
	corner(btn, 8)

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 0, 0.5, 0)
	bar.Size = UDim2.new(0, 3, 0, 0)
	bar.BackgroundColor3 = T.Accent
	bar.BorderSizePixel = 0
	bar.Parent = btn
	corner(bar, 2)

	local lbl = newLabel(btn, icon .. "  " .. name, 12, Enum.Font.GothamBold, T.SubText, {
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -14, 1, 0),
	})

	local page = Instance.new("ScrollingFrame")
	page.Name = "Page_" .. name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = T.Accent
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.Visible = false
	page.Parent = ContentContainer
	padding(page, 10, 10, 10, 10)
	do
		local lay = Instance.new("UIListLayout")
		lay.Padding = UDim.new(0, 6)
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Parent = page
	end

	tabs[name] = {btn = btn, bar = bar, lbl = lbl, page = page}

	keep(btn.MouseEnter:Connect(function()
		if currentTab ~= name then
			tween(btn, TI.FAST, {BackgroundTransparency = 0.6})
			tween(lbl, TI.FAST, {TextColor3 = T.Text})
		end
	end))
	keep(btn.MouseLeave:Connect(function()
		if currentTab ~= name then
			tween(btn, TI.FAST, {BackgroundTransparency = 1})
			tween(lbl, TI.FAST, {TextColor3 = T.SubText})
		end
	end))
	keep(btn.MouseButton1Click:Connect(function()
		if tabs[name] then
			-- setTab didefinisikan di bawah, dipanggil lewat upvalue saat klik
			local fn = tabs.__setTab
			if fn then fn(name) end
		end
	end))

	return page
end

local function setTab(name)
	local nt = tabs[name]
	if not nt or currentTab == name then return end
	for n, t in pairs(tabs) do
		if n ~= "__setTab" and n ~= name then
			t.page.Visible = false
			tween(t.bar, TI.FAST, {Size = UDim2.new(0, 3, 0, 0)})
			tween(t.btn, TI.FAST, {BackgroundTransparency = 1})
			tween(t.lbl, TI.FAST, {TextColor3 = T.SubText})
		end
	end
	currentTab = name
	nt.page.Position = UDim2.new(0, 0, 0, 14)
	nt.page.Visible = true
	tween(nt.page, TI.SMOOTH, {Position = UDim2.new(0, 0, 0, 0)})
	tween(nt.bar, TI.SMOOTH, {Size = UDim2.new(0, 3, 0, 18)})
	tween(nt.btn, TI.FAST, {BackgroundTransparency = 0})
	tween(nt.lbl, TI.FAST, {TextColor3 = T.Text})
end
tabs.__setTab = setTab

-- ============================================================
-- FITUR: MOVEMENT (Speed, Jump, Fly, Noclip)
-- ============================================================
local FlyBV, FlyBG
local featConn = {}
local noclipParts = {}

local function ApplyMove()
	local h = getHumanoid()
	if h and not S.Fly then
		pcall(function()
			h.UseJumpPower = true
			if h.WalkSpeed ~= S.SpeedVal then h.WalkSpeed = S.SpeedVal end
			if h.JumpPower ~= S.JumpVal then h.JumpPower = S.JumpVal end
		end)
	end
end

local function SetFly(state)
	S.Fly = state
	local root = getRoot()
	local h = getHumanoid()

	-- bersihkan fly lama
	if FlyBV then FlyBV:Destroy() FlyBV = nil end
	if FlyBG then FlyBG:Destroy() FlyBG = nil end
	if featConn.Fly then featConn.Fly:Disconnect() featConn.Fly = nil end

	if not root or not h then return end

	if state then
		h.PlatformStand = true
		FlyBV = Instance.new("BodyVelocity")
		FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		FlyBV.Velocity = Vector3.new(0, 0, 0)
		FlyBV.Parent = root
		FlyBG = Instance.new("BodyGyro")
		FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		FlyBG.P = 9e4
		FlyBG.Parent = root

		featConn.Fly = RunService.RenderStepped:Connect(function()
			if not S.Fly or not FlyBV then return end
			local cam = Workspace.CurrentCamera
			local hum = getHumanoid()
			if not cam or not hum then return end
			local cf = cam.CFrame

			-- MoveDirection: jalan di PC (WASD) dan HP (joystick)
			local md = hum.MoveDirection
			local dir = Vector3.new(0, 0, 0)
			if md.Magnitude > 0 then
				local flatLook = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
				local flatRight = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
				if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
				if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
				local fwd = md:Dot(flatLook)
				local side = md:Dot(flatRight)
				dir = cf.LookVector * fwd + cf.RightVector * side
			end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

			if dir.Magnitude > 0 then
				FlyBV.Velocity = dir.Unit * (S.FlySpeed * 10)
			else
				FlyBV.Velocity = Vector3.new(0, 0, 0)
			end
			FlyBG.CFrame = cf
		end)
	else
		h.PlatformStand = false
		ApplyMove()
	end
end

local function SetNoclip(state)
	S.Noclip = state
	if state then
		if not featConn.Noclip then
			featConn.Noclip = RunService.Stepped:Connect(function()
				if not S.Noclip then return end
				local ch = LP.Character
				if ch then
					for _, p in ipairs(ch:GetDescendants()) do
						if p:IsA("BasePart") and p.CanCollide then
							noclipParts[p] = true
							p.CanCollide = false
						end
					end
				end
			end)
		end
	else
		if featConn.Noclip then featConn.Noclip:Disconnect() featConn.Noclip = nil end
		for p in pairs(noclipParts) do
			if p.Parent then p.CanCollide = true end
		end
		table.clear(noclipParts)
	end
end

keep(RunService.Heartbeat:Connect(ApplyMove))
keep(LP.CharacterAdded:Connect(function()
	task.wait(0.4)
	table.clear(noclipParts)
	ApplyMove()
	if S.Fly then SetFly(true) end
end))

-- Anti-AFK
keep(LP.Idled:Connect(function()
	if S.AntiAFK then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end))

-- FPS Boost (bisa dipulihkan)
local fpsSaved = nil
local function applyFPS(on)
	if on then
		if not fpsSaved then
			fpsSaved = {
				Shadows = Lighting.GlobalShadows,
				Fog = Lighting.FogEnd,
				Bright = Lighting.Brightness,
				Post = {},
			}
			pcall(function() fpsSaved.Quality = settings().Rendering.QualityLevel end)
		end
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			Lighting.Brightness = 1
			for _, fx in ipairs(Lighting:GetChildren()) do
				if fx:IsA("PostEffect") then
					if fpsSaved.Post[fx] == nil then fpsSaved.Post[fx] = fx.Enabled end
					fx.Enabled = false
				end
			end
		end)
	elseif fpsSaved then
		local saved = fpsSaved
		fpsSaved = nil
		pcall(function()
			Lighting.GlobalShadows = saved.Shadows
			Lighting.FogEnd = saved.Fog
			Lighting.Brightness = saved.Bright
			for fx, en in pairs(saved.Post) do
				if fx.Parent then fx.Enabled = en end
			end
		end)
		if saved.Quality then
			pcall(function() settings().Rendering.QualityLevel = saved.Quality end)
		end
	end
end

-- ============================================================
-- FITUR: DETEKSI EGG & ESP
-- ============================================================
local IGNORE_PARTS = {
	"horn", "brow", "fur", "button", "eye", "mouth", "leg",
	"arm", "hand", "foot", "head", "torso", "mesh", "fp_",
}
local RARE_KEYWORDS = {"secret", "legendary", "mythic", "godly", "divine", "rainbow", "golden", "rare"}

local function isRare(name)
	local n = name:lower()
	for _, k in ipairs(RARE_KEYWORDS) do
		if n:find(k, 1, true) then return true end
	end
	return false
end

local function isPiece(n)
	n = n:lower()
	-- Egg rare tidak boleh dianggap bagian tubuh ("legendary" mengandung "leg")
	if isRare(n) then return false end
	for _, p in ipairs(IGNORE_PARTS) do
		if n:find(p, 1, true) then return true end
	end
	return false
end

-- Cache kandidat egg (tidak lagi scan seluruh Workspace tiap 0.5-1 detik)
local eggCandidates = {}

local function considerEgg(obj)
	if obj:IsA("Model") then
		local nom = obj.Name:lower()
		if (nom:find("egg", 1, true) or nom:find("huevo", 1, true)) and not isPiece(obj.Name) then
			eggCandidates[obj] = true
		end
	end
end

keep(Workspace.DescendantAdded:Connect(considerEgg))
keep(Workspace.DescendantRemoving:Connect(function(obj)
	eggCandidates[obj] = nil
end))

task.spawn(function()
	local n = 0
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if not alive then return end
		considerEgg(obj)
		n += 1
		if n % 2000 == 0 then task.wait() end
	end
end)

local function getEggs()
	local list = {}
	local filter = S.Filter ~= "" and S.Filter:lower() or nil
	for obj in pairs(eggCandidates) do
		if not obj.Parent then
			eggCandidates[obj] = nil
		else
			local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
			if part and part.Transparency < 1 then
				if not filter or obj.Name:lower():find(filter, 1, true) then
					list[#list + 1] = {
						obj = obj,
						part = part,
						pos = part.Position,
						rare = isRare(obj.Name),
					}
				end
			end
		end
	end
	return list
end

local ESPObjects = {}

local function ClearESP()
	for _, d in pairs(ESPObjects) do
		pcall(function()
			if d.hl then d.hl:Destroy() end
			if d.bill then d.bill:Destroy() end
		end)
	end
	table.clear(ESPObjects)
end

local function MakeESP(obj, part, rare)
	if ESPObjects[obj] then return end
	local d = {}

	local hl = Instance.new("Highlight")
	hl.Adornee = obj
	hl.FillColor = rare and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 255, 255)
	hl.OutlineColor = rare and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 215, 0)
	hl.FillTransparency = 0.4
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = obj
	d.hl = hl

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.new(0, 140, 0, 36)
	bill.AlwaysOnTop = true
	bill.StudsOffset = Vector3.new(0, 3, 0)
	bill.Adornee = part
	bill.Parent = part

	local nameL = Instance.new("TextLabel")
	nameL.Size = UDim2.new(1, 0, 0, 18)
	nameL.BackgroundTransparency = 1
	nameL.Text = (rare and "★ " or "") .. obj.Name
	nameL.Font = Enum.Font.GothamBold
	nameL.TextSize = 12
	nameL.TextColor3 = rare and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 0)
	nameL.TextStrokeTransparency = 0
	nameL.Parent = bill

	local distL = Instance.new("TextLabel")
	distL.Size = UDim2.new(1, 0, 0, 14)
	distL.Position = UDim2.new(0, 0, 0, 18)
	distL.BackgroundTransparency = 1
	distL.Text = "0m"
	distL.Font = Enum.Font.Gotham
	distL.TextSize = 11
	distL.TextColor3 = Color3.new(1, 1, 1)
	distL.TextStrokeTransparency = 0
	distL.Parent = bill

	d.bill, d.distL = bill, distL
	ESPObjects[obj] = d
end

local function sysNotify(text, dur)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "VURA Hub",
			Text = text,
			Duration = dur or 4,
		})
	end)
end

local alertCooldown = {}

local function updateESP()
	local root = getRoot()
	if not root then return end

	local active = {}
	for _, h in ipairs(getEggs()) do
		active[h.obj] = true
		if not ESPObjects[h.obj] then
			MakeESP(h.obj, h.part, h.rare)
		end
		local d = ESPObjects[h.obj]
		if d and d.distL then
			d.distL.Text = math.floor((h.pos - root.Position).Magnitude) .. "m"
		end
		if S.RareAlert and h.rare then
			local last = alertCooldown[h.obj]
			if not last or tick() - last > 30 then
				alertCooldown[h.obj] = tick()
				sysNotify("★ RARE! " .. h.obj.Name, 5)
			end
		end
	end

	for obj, d in pairs(ESPObjects) do
		if not active[obj] or not obj.Parent then
			pcall(function()
				if d.hl then d.hl:Destroy() end
				if d.bill then d.bill:Destroy() end
			end)
			ESPObjects[obj] = nil
		end
	end
end

task.spawn(function()
	while alive do
		task.wait(0.5)
		if alive and S.ESP then
			pcall(updateESP)
		end
	end
end)

-- ============================================================
-- FITUR: TELEPORT, AUTO COLLECT, AUTO HATCH, AUTO PLACE
-- ============================================================
local function getNearestEgg()
	local root = getRoot()
	if not root then return nil end
	local best, bestDist = nil, math.huge
	for _, h in ipairs(getEggs()) do
		local d = (h.pos - root.Position).Magnitude
		if d < bestDist then
			best, bestDist = h, d
		end
	end
	return best
end

local function teleportToEgg()
	local h = getNearestEgg()
	if not h then
		notify("Egg tidak ditemukan", T.Warn)
		return
	end
	local root = getRoot()
	if not root then return end
	root.CFrame = CFrame.new(h.pos + Vector3.new(0, 3, 0))
	notify("Teleport ke " .. h.obj.Name, T.Good)
end

local function scanEggs()
	local list = getEggs()
	local rareCount = 0
	for _, h in ipairs(list) do
		if h.rare then rareCount += 1 end
	end
	notify(#list .. " egg • " .. rareCount .. " rare", T.Accent2)
end

task.spawn(function()
	while alive do
		task.wait(1)
		if alive and S.AutoCollect then
			local root = getRoot()
			if root then
				local h = getNearestEgg()
				if h then
					pcall(function()
						root.CFrame = CFrame.new(h.pos + Vector3.new(0, 2, 0))
					end)
				end
			end
		end
	end
end)

local function findButtonByText(keywords, exclude)
	for _, g in ipairs(PlayerGui:GetDescendants()) do
		if g:IsA("TextButton") and g.Visible and not g:IsDescendantOf(Gui) then
			local txt = g.Text:lower()
			if txt ~= "" then
				local skip = false
				if exclude then
					for _, x in ipairs(exclude) do
						if txt:find(x, 1, true) then skip = true break end
					end
				end
				if not skip then
					for _, k in ipairs(keywords) do
						if txt:find(k, 1, true) then return g end
					end
				end
			end
		end
	end
	return nil
end

local function pressButton(btn)
	pcall(function()
		if type(firesignal) == "function" then
			firesignal(btn.MouseButton1Click)
		elseif type(getconnections) == "function" then
			for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
				pcall(function() c:Fire() end)
			end
		end
	end)
end

task.spawn(function()
	while alive do
		task.wait(2)
		if not alive then break end
		if S.AutoHatch then
			local btn = findButtonByText({"hatch", "eclos", "incub"}, {"time", "auto", "info"})
			if btn then pressButton(btn) end
		end
		if S.AutoPlace then
			local btn = findButtonByText({"equip", "best"}, {"unequip", "un-equip", "deal", "shop", "buy", "robux"})
			if btn then pressButton(btn) end
		end
	end
end)

-- Cleanup semua fitur saat GUI dihapus
onCleanup(function()
	ClearESP()
	if S.Fly then SetFly(false) end
	SetNoclip(false)
	applyFPS(false)
	local h = getHumanoid()
	if h then
		pcall(function()
			h.WalkSpeed = origWS
			h.UseJumpPower = origUseJP
			h.JumpPower = origJP
		end)
	end
end)

-- ============================================================
-- PAGES
-- ============================================================
local PageAuto = createPage("Auto", "🤖")
local PageESP = createPage("ESP", "👁")
local PagePlayer = createPage("Player", "⚡")
local PageConfig = createPage("Config", "💾")
local PageInfo = createPage("Info", "ℹ")

-- ---------- AUTO ----------
makeSection(PageAuto, "Automation", 1)
makeCard(PageAuto, S, "AutoCollect", "Auto Collect Eggs",
	"Teleport otomatis ke egg terdekat setiap 1 detik.", T.Accent, 2,
	function(v)
		setStatus(v and "Auto Collect aktif" or "Ready • " .. LP.DisplayName, v and T.Good or T.Good)
		notify("Auto Collect: " .. (v and "ON" or "OFF"), v and T.Good or T.SubText)
	end)
makeToggle(PageAuto, S, "AutoHatch", "Auto Hatch", T.Accent2, 3, function(v)
	notify("Auto Hatch: " .. (v and "ON" or "OFF"), v and T.Good or T.SubText)
end)
makeToggle(PageAuto, S, "AutoPlace", "Auto Best Pet", T.Gold, 4, function(v)
	notify("Auto Best Pet: " .. (v and "ON" or "OFF"), v and T.Good or T.SubText)
end)
makeSection(PageAuto, "Quick Actions", 5)
makeButton(PageAuto, "📍  Teleport to Nearest Egg", 34, T.Accent, T.Accent2, 6, teleportToEgg)
makeButton(PageAuto, "🔎  Scan Eggs", 34, T.Pink, T.Warn, 7, scanEggs)
makeNote(PageAuto,
	"Auto Hatch & Auto Best Pet bekerja dengan mencari tombol di GUI game. Kalau game memakai remote khusus, fitur ini mungkin tidak jalan.",
	8)

-- ---------- ESP ----------
makeSection(PageESP, "Egg ESP", 1)
makeToggle(PageESP, S, "ESP", "Egg ESP", T.Good, 2, function(v)
	if not v then ClearESP() end
end)
makeToggle(PageESP, S, "RareAlert", "Rare Alert", T.Bad, 3, nil)
makeToggle(PageESP, S, "FPSBoost", "FPS Boost", T.Gold, 4, function(v)
	applyFPS(v)
end)
makeSection(PageESP, "Filter", 5)
makeInput(PageESP, S, "Filter", "Filter egg berdasarkan nama", 6, function()
	ClearESP()
end)

-- ---------- PLAYER ----------
makeSection(PagePlayer, "Movement", 1)
makeSlider(PagePlayer, S, "SpeedVal", "Walk Speed", 1, 1000, T.Accent, 2, function() ApplyMove() end)
makeSlider(PagePlayer, S, "JumpVal", "Jump Power", 1, 1000, T.Accent2, 3, function() ApplyMove() end)
makeSlider(PagePlayer, S, "FlySpeed", "Fly Speed", 1, 50, T.Gold, 4, nil)
makeSection(PagePlayer, "Toggles", 5)
makeToggle(PagePlayer, S, "Fly", "Fly Mode", T.Accent, 6, function(v) SetFly(v) end)
makeToggle(PagePlayer, S, "Noclip", "Noclip", T.Pink, 7, function(v) SetNoclip(v) end)
makeToggle(PagePlayer, S, "AntiAFK", "Anti-AFK", T.Good, 8, nil)

-- ---------- CONFIG ----------
makeSection(PageConfig, "Config", 1)
makeButton(PageConfig, "💾  Save Config", 34, T.Good, T.Accent2, 2, function()
	if SaveConfig() then
		notify("✓ Config saved", T.Good)
	else
		notify("File system tidak didukung", T.Bad)
	end
end)
makeButton(PageConfig, "📂  Load Config", 34, T.Accent, T.Pink, 3, function()
	if LoadConfig() then
		for key, setter in pairs(uiSetters) do
			setter(S[key])
		end
		notify("✓ Config loaded", T.Good)
	else
		notify("Config tidak ditemukan", T.Warn)
	end
end)
makeSection(PageConfig, "Window", 4)
makeButton(PageConfig, "↺  Reset Window Position", 34, T.CardHover, T.Card, 5, resetWindowPosition)
makeNote(PageConfig,
	"Config disimpan ke file " .. CONFIG_FILE .. ". Butuh executor yang mendukung writefile / readfile.",
	6)

-- ---------- INFO ----------
makeSection(PageInfo, "Player", 1)

local AvatarRow = makeRow(PageInfo, 64, 2)
local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.fromOffset(48, 48)
Avatar.Position = UDim2.new(0, 10, 0.5, -24)
Avatar.BackgroundColor3 = T.Bg
Avatar.BorderSizePixel = 0
Avatar.Parent = AvatarRow
corner(Avatar, 24)
stroke(Avatar, T.Accent, 2)
newLabel(AvatarRow, LP.DisplayName, 14, Enum.Font.GothamBold, T.Text, {
	Position = UDim2.new(0, 68, 0, 12),
	Size = UDim2.new(1, -78, 0, 20),
})
newLabel(AvatarRow, "@" .. LP.Name, 11, Enum.Font.Gotham, T.SubText, {
	Position = UDim2.new(0, 68, 0, 34),
	Size = UDim2.new(1, -78, 0, 16),
})

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok and alive then
		Avatar.Image = img
	end
end)

makeInfoRow(PageInfo, "Username", LP.Name, 3)
makeInfoRow(PageInfo, "Display", LP.DisplayName, 4)
makeInfoRow(PageInfo, "User ID", tostring(LP.UserId), 5)
makeInfoRow(PageInfo, "Account Age", tostring(LP.AccountAge) .. " days", 6)
makeSection(PageInfo, "Credits", 7)
makeNote(PageInfo, "Fitur original: @unrandom_tk (V1). UI: VURA RGB Hub.", 8)

-- ============================================================
-- ANIMASI RGB (RenderStepped)
-- ============================================================
keep(RunService.RenderStepped:Connect(function()
	local t = os.clock()
	BorderGrad.Rotation = (t * 90) % 360
	TitleGrad.Offset = Vector2.new(math.sin(t * 2) * 0.35, 0)
	ToggleGrad.Rotation = (t * 90 + 90) % 360
	if Overlay.Visible then
		WarnGrad.Rotation = (t * 120) % 360
	end
end))

-- ============================================================
-- AUTO-FIT (viewport berubah)
-- ============================================================
keep(Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	refreshLayout(false)
end))
do
	local cam = Workspace.CurrentCamera
	if cam then
		keep(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			refreshLayout(false)
		end))
	end
end

-- ============================================================
-- INIT
-- ============================================================
applyFPS(S.FPSBoost)
if S.Fly then SetFly(true) end
if S.Noclip then SetNoclip(true) end
ApplyMove()

setTab("Auto")

do
	local vs = guiSizeNow()
	lastVS = vs
	baseScale = computeBaseScale()
	moveWindow(vs.X / 2, (vs.Y - WIN_H * baseScale) / 2, false)
	captureOpenPosition()
	-- Intro: UIScale 0.01 -> base, Back Out 0.5s
	tween(MainScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = baseScale})
end

print("[VURA RGB HUB] Loaded • tab: Auto, ESP, Player, Config, Info")
