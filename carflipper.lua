-- ==========================================
-- VURA | CAR FLIPPER HUB v2 (REAL: Remote Spy + Auto Farm)
-- ==========================================
-- Cara pakai singkat:
-- 1. Buka tab "Remote", nyalakan Spy.
-- 2. Lakukan aksi di game SEKALI secara manual (beli mobil / flip / jual).
-- 3. Remote-nya muncul di daftar -> tekan [FARM] atau [BUY] untuk memilihnya.
-- 4. Di tab "Farm", nyalakan Auto Farm / Auto Buy. Script akan memanggil
--    remote ASLI game dengan argumen persis seperti yang kamu lakukan.
-- ==========================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local guiParent = (gethui and gethui()) or PlayerGui

for _, p in ipairs({guiParent, PlayerGui}) do
	local old = p:FindFirstChild("VuraCarFlipper")
	if old then old:Destroy() end
end

-- ==========================================
-- STATE
-- ==========================================
local S = {
	farm = false, buy = false, prompt = false, collect = false,
	afk = true, speedOn = false, infJump = false, spy = true,
	farmDelay = 0.5, buyDelay = 1, range = 40, speed = 50,
}
local Sel = {farm = nil, buy = nil}
local Log = {}
local alive = true

local function hrp()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- UANG ASLI
-- ==========================================
local moneyNames = {"uang", "cash", "money", "coin", "gold", "dollar", "$"}
local function getRealMoney()
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		for _, st in ipairs(ls:GetChildren()) do
			local n = st.Name:lower()
			for _, k in ipairs(moneyNames) do
				if n:find(k, 1, true) and typeof(st.Value) == "number" then return st.Value end
			end
		end
		for _, st in ipairs(ls:GetChildren()) do -- fallback: stat angka pertama
			if typeof(st.Value) == "number" then return st.Value end
		end
	end
	for _, k in ipairs({"Cash", "Money", "Coins"}) do -- fallback: Attribute
		local a = player:GetAttribute(k)
		if typeof(a) == "number" then return a end
	end
	return nil
end

local function fmt(n)
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (r:gsub("^%.", ""))
end

-- ==========================================
-- REMOTE SPY (hook asli)
-- ==========================================
local refreshLog -- forward
local noisy = {"move", "camera", "ping", "heartbeat", "mouse", "input", "replicat", "cframe", "look"}
local function isNoisy(name)
	name = name:lower()
	for _, w in ipairs(noisy) do
		if name:find(w, 1, true) then return true end
	end
	return false
end

local function argStr(t)
	local parts = {}
	for i = 1, math.min(t.n, 4) do
		local ok, s = pcall(tostring, t[i])
		parts[#parts + 1] = ok and s or "?"
	end
	local out = table.concat(parts, ", ")
	return #out > 38 and out:sub(1, 38) .. ".." or out
end

local function record(remote, args)
	if isNoisy(remote.Name) then return end
	local key = remote:GetFullName()
	for i, e in ipairs(Log) do
		if e.key == key then
			e.args = args; e.count += 1
			if refreshLog then refreshLog() end
			return
		end
	end
	table.insert(Log, 1, {key = key, remote = remote, args = args, count = 1})
	if #Log > 40 then table.remove(Log) end
	if refreshLog then refreshLog() end
end

local hookOK = false
if hookmetamethod and getnamecallmethod then
	local oldNC
	local hook = function(self, ...)
		local m = getnamecallmethod()
		if S.spy and (m == "FireServer" or m == "InvokeServer")
			and typeof(self) == "Instance" and not (checkcaller and checkcaller()) then
			task.defer(record, self, table.pack(...))
		end
		return oldNC(self, ...)
	end
	local ok = pcall(function()
		oldNC = hookmetamethod(game, "__namecall", newcclosure and newcclosure(hook) or hook)
	end)
	hookOK = ok
end

local function fireEntry(e)
	if not e or not e.remote or not e.remote.Parent then return false end
	local ok = pcall(function()
		if e.remote:IsA("RemoteFunction") then
			e.remote:InvokeServer(unpack(e.args, 1, e.args.n))
		else
			e.remote:FireServer(unpack(e.args, 1, e.args.n))
		end
	end)
	return ok
end

-- ==========================================
-- UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VuraCarFlipper"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 290)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(80, 50, 120)
stroke.Thickness = 1.5
local grad = Instance.new("UIGradient", MainFrame)
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 45)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 12)),
}
grad.Rotation = 45

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0.4, 0, 1, 0)
Title.Position = UDim2.new(0.03, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Vura | Auto Flipper"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(200, 200, 220)
Title.TextXAlignment = Enum.TextXAlignment.Left

local UangLabel = Instance.new("TextLabel", TopBar)
UangLabel.Size = UDim2.new(0.45, 0, 1, 0)
UangLabel.Position = UDim2.new(0.4, 0, 0, 0)
UangLabel.BackgroundTransparency = 1
UangLabel.Text = "$..."
UangLabel.Font = Enum.Font.GothamBold
UangLabel.TextSize = 12
UangLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
UangLabel.TextXAlignment = Enum.TextXAlignment.Right

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 12
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Tab bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(0.94, 0, 0, 24)
TabBar.Position = UDim2.new(0.03, 0, 0, 34)
TabBar.BackgroundTransparency = 1
local tl = Instance.new("UIListLayout", TabBar)
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 4)

local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(0.94, 0, 1, -68)
Content.Position = UDim2.new(0.03, 0, 0, 62)
Content.BackgroundTransparency = 1

local pages, tabBtns = {}, {}
local function newPage(name)
	local p = Instance.new("ScrollingFrame", Content)
	p.Size = UDim2.new(1, 0, 1, 0)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.ScrollBarThickness = 2
	p.CanvasSize = UDim2.new()
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	p.Visible = false
	local l = Instance.new("UIListLayout", p)
	l.Padding = UDim.new(0, 5)
	pages[name] = p

	local b = Instance.new("TextButton", TabBar)
	b.Size = UDim2.new(0, 80, 1, 0)
	b.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
	b.Text = name
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	tabBtns[name] = b
	b.MouseButton1Click:Connect(function()
		for n, pg in pairs(pages) do
			pg.Visible = (n == name)
			tabBtns[n].BackgroundColor3 = (n == name) and Color3.fromRGB(90, 55, 150) or Color3.fromRGB(35, 30, 50)
		end
	end)
	return p
end

local function label(page, text)
	local l = Instance.new("TextLabel", page)
	l.Size = UDim2.new(1, -8, 0, 22)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 11
	l.TextColor3 = Color3.fromRGB(190, 190, 210)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	return l
end

local function toggle(page, text, key, cb)
	local b = Instance.new("TextButton", page)
	b.Size = UDim2.new(1, -8, 0, 30)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	local function paint()
		b.Text = text .. ": " .. (S[key] and "ON" or "OFF")
		b.BackgroundColor3 = S[key] and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(60, 40, 50)
	end
	paint()
	b.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		paint()
		if cb then cb(S[key]) end
	end)
end

local function button(page, text, cb, color)
	local b = Instance.new("TextButton", page)
	b.Size = UDim2.new(1, -8, 0, 28)
	b.BackgroundColor3 = color or Color3.fromRGB(60, 50, 100)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.MouseButton1Click:Connect(cb)
	return b
end

local function input(page, text, key)
	local f = Instance.new("Frame", page)
	f.Size = UDim2.new(1, -8, 0, 28)
	f.BackgroundTransparency = 1
	local l = Instance.new("TextLabel", f)
	l.Size = UDim2.new(0.65, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 11
	l.TextColor3 = Color3.fromRGB(190, 190, 210)
	l.TextXAlignment = Enum.TextXAlignment.Left
	local t = Instance.new("TextBox", f)
	t.Size = UDim2.new(0.33, 0, 1, 0)
	t.Position = UDim2.new(0.67, 0, 0, 0)
	t.BackgroundColor3 = Color3.fromRGB(30, 28, 40)
	t.Text = tostring(S[key])
	t.Font = Enum.Font.GothamBold
	t.TextSize = 12
	t.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", t).CornerRadius = UDim.new(0, 5)
	t.FocusLost:Connect(function()
		local n = tonumber(t.Text)
		if n and n >= 0 then S[key] = n else t.Text = tostring(S[key]) end
	end)
end

local FarmPage = newPage("Farm")
local RemotePage = newPage("Remote")
local MiscPage = newPage("Misc")

-- ---------- FARM ----------
local StatusLbl = label(FarmPage, "")
StatusLbl.Size = UDim2.new(1, -8, 0, 34)
local function updateStatus()
	StatusLbl.Text = "FARM remote: " .. (Sel.farm and Sel.farm.remote.Name or "belum dipilih")
		.. "\nBUY remote: " .. (Sel.buy and Sel.buy.remote.Name or "belum dipilih")
end
updateStatus()
toggle(FarmPage, "Auto Farm (replay remote FARM)", "farm")
toggle(FarmPage, "Auto Buy (replay remote BUY)", "buy")
toggle(FarmPage, "Auto Prompt (E / ProximityPrompt)", "prompt")
toggle(FarmPage, "Auto Collect (coin/cash/money dekat)", "collect")
input(FarmPage, "Delay Farm (detik)", "farmDelay")
input(FarmPage, "Delay Buy (detik)", "buyDelay")
input(FarmPage, "Jarak Prompt/Collect (stud)", "range")
local EarnLbl = label(FarmPage, "Pendapatan: -")

-- ---------- REMOTE ----------
toggle(RemotePage, "Remote Spy", "spy")
label(RemotePage, hookOK and "Hook aktif. Lakukan aksi di game, lalu pilih remote-nya."
	or "Executor kamu tidak mendukung hookmetamethod. Spy tidak jalan.")
button(RemotePage, "Hapus Log", function() Log = {}; refreshLog() end, Color3.fromRGB(110, 50, 50))
local LogHolder = Instance.new("Frame", RemotePage)
LogHolder.Size = UDim2.new(1, -8, 0, 0)
LogHolder.AutomaticSize = Enum.AutomaticSize.Y
LogHolder.BackgroundTransparency = 1
local ll = Instance.new("UIListLayout", LogHolder)
ll.Padding = UDim.new(0, 4)

local pending = false
refreshLog = function()
	if pending then return end
	pending = true
	task.delay(0.25, function()
		pending = false
		if not alive then return end
		for _, c in ipairs(LogHolder:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		for _, e in ipairs(Log) do
			local row = Instance.new("Frame", LogHolder)
			row.Size = UDim2.new(1, 0, 0, 38)
			row.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
			local t = Instance.new("TextLabel", row)
			t.Size = UDim2.new(0.58, 0, 1, 0)
			t.Position = UDim2.new(0.02, 0, 0, 0)
			t.BackgroundTransparency = 1
			t.Text = e.remote.Name .. " x" .. e.count .. "\n(" .. argStr(e.args) .. ")"
			t.Font = Enum.Font.Gotham
			t.TextSize = 10
			t.TextColor3 = Color3.new(1, 1, 1)
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.TextWrapped = true
			for i, kind in ipairs({"farm", "buy"}) do
				local b = Instance.new("TextButton", row)
				b.Size = UDim2.new(0.18, 0, 0.6, 0)
				b.Position = UDim2.new(0.61 + (i - 1) * 0.19, 0, 0.2, 0)
				b.Text = kind:upper()
				b.Font = Enum.Font.GothamBold
				b.TextSize = 10
				b.TextColor3 = Color3.new(1, 1, 1)
				b.BackgroundColor3 = (Sel[kind] == e) and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(70, 55, 110)
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
				b.MouseButton1Click:Connect(function()
					Sel[kind] = e
					updateStatus()
					refreshLog()
				end)
			end
		end
	end)
end

-- ---------- MISC ----------
toggle(MiscPage, "Anti AFK", "afk")
toggle(MiscPage, "Speed Hack", "speedOn")
input(MiscPage, "WalkSpeed", "speed")
toggle(MiscPage, "Infinite Jump", "infJump")
button(MiscPage, "Hapus UI & Matikan Semua", function()
	alive = false
	ScreenGui:Destroy()
end, Color3.fromRGB(110, 50, 50))
label(MiscPage, "fireproximityprompt: " .. (fireproximityprompt and "OK" or "tidak ada")
	.. " | firetouchinterest: " .. (firetouchinterest and "OK" or "tidak ada"))

-- default tab
pages.Farm.Visible = true
tabBtns.Farm.BackgroundColor3 = Color3.fromRGB(90, 55, 150)

-- ---------- RESIZE ----------
local ResizeHandle = Instance.new("TextButton", MainFrame)
ResizeHandle.Size = UDim2.new(0, 22, 0, 22)
ResizeHandle.Position = UDim2.new(1, -22, 1, -22)
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
		MainFrame.Size = UDim2.new(0, math.max(300, startSize.X.Offset + d.X), 0, math.max(220, startSize.Y.Offset + d.Y))
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		if resizing then resizing = false; MainFrame.Draggable = true end
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	alive = false
	ScreenGui:Destroy()
end)

-- ==========================================
-- LOOP NYATA
-- ==========================================

-- Uang asli + pendapatan
local startMoney, startT = nil, os.clock()
task.spawn(function()
	while alive do
		local m = getRealMoney()
		if m then
			startMoney = startMoney or m
			UangLabel.Text = "Uang Asli: $" .. fmt(m)
			local gained = m - startMoney
			local mins = math.max((os.clock() - startT) / 60, 0.01)
			EarnLbl.Text = ("Pendapatan: %s$%s  (~%s$/menit)"):format(gained < 0 and "-" or "+", fmt(math.abs(gained)), fmt(gained / mins))
		else
			UangLabel.Text = "Uang: tidak terbaca"
		end
		task.wait(0.5)
	end
end)

-- Auto Farm (replay remote asli)
task.spawn(function()
	while alive do
		if S.farm and Sel.farm then fireEntry(Sel.farm) end
		task.wait(math.max(S.farmDelay, 0.05))
	end
end)

-- Auto Buy (replay remote asli)
task.spawn(function()
	while alive do
		if S.buy and Sel.buy then fireEntry(Sel.buy) end
		task.wait(math.max(S.buyDelay, 0.1))
	end
end)

-- Auto Prompt + Auto Collect
local prompts, pickups, lastScan = {}, {}, 0
local pickWords = {"coin", "cash", "money", "collect", "pickup", "reward", "drop"}
local function scan()
	prompts, pickups = {}, {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			prompts[#prompts + 1] = d
		elseif d:IsA("BasePart") and d:FindFirstChild("TouchInterest") then
			local n = d.Name:lower()
			for _, w in ipairs(pickWords) do
				if n:find(w, 1, true) then pickups[#pickups + 1] = d; break end
			end
		end
	end
end

local function posOf(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Attachment") then return inst.WorldPosition end
	if inst:IsA("Model") then return inst:GetPivot().Position end
end

task.spawn(function()
	while alive do
		if S.prompt or S.collect then
			if os.clock() - lastScan > 3 then lastScan = os.clock(); pcall(scan) end
			local root = hrp()
			if root then
				if S.prompt and fireproximityprompt then
					for _, p in ipairs(prompts) do
						if p.Parent and p.Enabled then
							local pos = posOf(p.Parent)
							if pos and (pos - root.Position).Magnitude <= S.range then
								pcall(fireproximityprompt, p)
							end
						end
					end
				end
				if S.collect and firetouchinterest then
					for _, part in ipairs(pickups) do
						if part.Parent and (part.Position - root.Position).Magnitude <= S.range then
							pcall(function()
								firetouchinterest(root, part, 0)
								firetouchinterest(root, part, 1)
							end)
						end
					end
				end
			end
		end
		task.wait(0.3)
	end
end)

-- Anti AFK
player.Idled:Connect(function()
	if S.afk and alive then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- Speed hack
RunService.Heartbeat:Connect(function()
	if not alive or not S.speedOn then return end
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = S.speed end
end)

-- Infinite jump
UIS.JumpRequest:Connect(function()
	if alive and S.infJump then
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)
