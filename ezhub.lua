-- ============================================================
-- ZENO HUB PREMIUM - URBAN RELOAD (Optimized Build v2.1)
-- Owner: Emy210208 | Keyless | Mobile + PC
-- Ultra low CPU/RAM, adaptive render, lazy load.
-- For authorized testing environments only.
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

if not shared then return warn("No shared, no script.") end

-- ============================================================
-- CONSTANTS
-- ============================================================
local GOLD = Color3.fromRGB(212, 175, 55)
local GOLD_D = Color3.fromRGB(120, 95, 25)
local GOLD_L = Color3.fromRGB(255, 235, 170)
local OWNER = "Emy210208"
local VER = "2.1"
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local LOW_END = IS_MOBILE and (UIS.GamepadEnabled == false)

-- Duplicate guard.
local KEY = "ZenoOpt_" .. tostring(game.GameId)
if shared[KEY] then pcall(function() shared[KEY]() end) end

-- ============================================================
-- DEVICE MODES
-- ============================================================
-- Potato:    0 — skip most work, 0.25s ESP, no tweens
-- Balanced:  1 — default, 0.12s ESP, light tweens
-- High:      2 — full visuals, 60fps target
local MODES = {
	{ name = "Potato",   espRate = 0.25, fovSides = 32, shadows = false },
	{ name = "Balanced", espRate = 0.12, fovSides = 48, shadows = true },
	{ name = "High",     espRate = 0.03, fovSides = 64, shadows = true },
}
local deviceMode = LOW_END and 1 or (IS_MOBILE and 1 or 2)

-- ============================================================
-- STATE
-- ============================================================
local S = {
	aim = false, aimStr = 0.35, aimDist = 500, targetHead = true,
	teamChk = true, visChk = false, smooth = 0.25, aimming = false,
	fovOn = true, fovSize = 150,

	esp = false, espBox = true, espName = true, espHp = true,
	espDist = true, espTeam = true, espCol = {255, 255, 255},

	fpsOn = false, fpsMon = true,
}

local SAVE_FILE = "ZenoHub/opt.json"
pcall(makefolder, "ZenoHub")

local function loadSave()
	if isfile and isfile(SAVE_FILE) then
		local ok, d = pcall(function() return HttpService:JSONDecode(readfile(SAVE_FILE)) end)
		if ok and type(d) == "table" then
			for k, v in pairs(d) do if S[k] ~= nil then S[k] = v end end
		end
	end
end
loadSave()

local function saveNow()
	if not writefile then return end
	local ok, e = pcall(function() return HttpService:JSONEncode(S) end)
	if ok then pcall(writefile, SAVE_FILE, e) end
end

-- ============================================================
-- SAFETY
-- ============================================================
local errLog, shutdown = {}, false
local function err(s, e)
	table.insert(errLog, ("[%s] %s"):format(s, tostring(e)))
	if #errLog > 30 then table.remove(errLog, 1) end
end

local function safe(scope, fn, ...)
	local ok, r = pcall(fn, ...)
	if not ok then err(scope, r) end
	return ok, r
end

-- ============================================================
-- FAST LOADING (no tween spam)
-- ============================================================
local LG = Instance.new("ScreenGui")
LG.Name = "ZenoLoad"
LG.IgnoreGuiInset = true
LG.DisplayOrder = 1001
LG.Parent = (gethui and gethui()) or CoreGui

local LF = Instance.new("Frame")
LF.Size = UDim2.fromOffset(200, 90)
LF.Position = UDim2.new(0.5, -100, 0.5, -45)
LF.BackgroundColor3 = Color3.fromRGB(14, 12, 8)
LF.Parent = LG
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = LF end

local LT = Instance.new("TextLabel")
LT.Size = UDim2.new(1, 0, 0, 24)
LT.Position = UDim2.fromOffset(0, 14)
LT.BackgroundTransparency = 1
LT.Text = "♛ ZENO PREMIUM"
LT.TextColor3 = GOLD_L
LT.Font = Enum.Font.GothamBold
LT.TextSize = 14
LT.Parent = LF

local LS = Instance.new("TextLabel")
LS.Size = UDim2.new(1, 0, 0, 16)
LS.Position = UDim2.fromOffset(0, 40)
LS.BackgroundTransparency = 1
LS.Text = "Loading..."
LS.TextColor3 = Color3.fromRGB(180, 160, 100)
LS.Font = Enum.Font.Gotham
LS.TextSize = 10
LS.Parent = LF

local LBB = Instance.new("Frame")
LBB.Size = UDim2.new(1, -30, 0, 5)
LBB.Position = UDim2.new(0, 15, 1, -16)
LBB.BackgroundColor3 = Color3.fromRGB(40, 36, 24)
LBB.Parent = LF
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = LBB end

local LBF = Instance.new("Frame")
LBF.Size = UDim2.new(0.3, 0, 1, 0)
LBF.BackgroundColor3 = GOLD
LBF.Parent = LBB
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = LBF end

-- ============================================================
-- UI BUILD (deferred, single pass)
-- ============================================================
local function buildUI()
	local GUI = Instance.new("ScreenGui")
	GUI.Name = "ZenoOpt"
	GUI.ResetOnSpawn = false
	GUI.IgnoreGuiInset = true
	GUI.DisplayOrder = 999
	GUI.Parent = (gethui and gethui()) or CoreGui

	-- Float button.
	local FB = Instance.new("TextButton")
	FB.Size = UDim2.fromOffset(54, 54)
	FB.Position = UDim2.new(0, 16, 0.5, -27)
	FB.BackgroundColor3 = Color3.fromRGB(24, 20, 10)
	FB.Text = "♛"
	FB.TextColor3 = GOLD
	FB.Font = Enum.Font.GothamBold
	FB.TextSize = 24
	FB.AutoButtonColor = false
	FB.Parent = GUI
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 27); c.Parent = FB
		local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.2; s.Parent = FB
	end

	-- Main.
	local M = Instance.new("Frame")
	M.Size = UDim2.fromOffset(340, 470)
	M.Position = UDim2.new(0.5, -170, 0.5, -235)
	M.BackgroundColor3 = Color3.fromRGB(12, 10, 8)
	M.BorderSizePixel = 0
	M.Active = true
	M.Visible = false
	M.Parent = GUI
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = M
		local s = Instance.new("UIStroke"); s.Color = GOLD_D; s.Thickness = 1.5; s.Parent = M
	end

	-- Title.
	local TB = Instance.new("Frame")
	TB.Size = UDim2.new(1, 0, 0, 48)
	TB.BackgroundColor3 = Color3.fromRGB(18, 15, 9)
	TB.Parent = M
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = TB end

	local TT = Instance.new("TextLabel")
	TT.Size = UDim2.new(1, -110, 0, 24)
	TT.Position = UDim2.fromOffset(14, 4)
	TT.BackgroundTransparency = 1
	TT.Text = "♛ ZENO HUB PREMIUM"
	TT.TextColor3 = GOLD_L
	TT.Font = Enum.Font.GothamBold
	TT.TextSize = 14
	TT.TextXAlignment = Enum.TextXAlignment.Left
	TT.Parent = TB

	local STT = Instance.new("TextLabel")
	STT.Size = UDim2.new(1, -110, 0, 14)
	STT.Position = UDim2.fromOffset(14, 26)
	STT.BackgroundTransparency = 1
	STT.Text = "Owner: " .. OWNER .. " • " .. MODES[deviceMode + 1].name .. " • v" .. VER
	STT.TextColor3 = Color3.fromRGB(160, 140, 90)
	STT.Font = Enum.Font.Gotham
	STT.TextSize = 9
	STT.TextXAlignment = Enum.TextXAlignment.Left
	STT.Parent = TB

	local CL = Instance.new("TextButton")
	CL.Size = UDim2.fromOffset(30, 30)
	CL.Position = UDim2.new(1, -38, 0, 9)
	CL.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
	CL.Text = "X"
	CL.TextColor3 = GOLD_L
	CL.Font = Enum.Font.GothamBold
	CL.TextSize = 13
	CL.Parent = TB
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = CL end

	-- Tabs.
	local TBAR = Instance.new("Frame")
	TBAR.Size = UDim2.new(1, 0, 0, 36)
	TBAR.Position = UDim2.fromOffset(0, 48)
	TBAR.BackgroundColor3 = Color3.fromRGB(16, 13, 8)
	TBAR.Parent = M
	do
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.Padding = UDim.new(0, 2)
		l.Parent = TBAR
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 6); p.PaddingRight = UDim.new(0, 6); p.PaddingTop = UDim.new(0, 4)
		p.Parent = TBAR
	end

	local Pages, Tabs = {}, {}
	local PC = Instance.new("Frame")
	PC.Size = UDim2.new(1, -12, 1, -100)
	PC.Position = UDim2.fromOffset(6, 90)
	PC.BackgroundTransparency = 1
	PC.Parent = M

	local function setTab(i)
		for k, p in ipairs(Pages) do p.Visible = (k == i) end
		for k, b in ipairs(Tabs) do
			b.BackgroundColor3 = (k == i) and GOLD_D or Color3.fromRGB(28, 24, 14)
			b.TextColor3 = (k == i) and GOLD_L or Color3.fromRGB(190, 170, 120)
		end
	end

	local function newTab(name)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1 / 4, -2, 1, -4)
		b.BackgroundColor3 = Color3.fromRGB(28, 24, 14)
		b.Text = name
		b.TextColor3 = Color3.fromRGB(190, 170, 120)
		b.Font = Enum.Font.GothamSemibold
		b.TextSize = 10
		b.AutoButtonColor = false
		b.Parent = TBAR
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b end
		table.insert(Tabs, b)

		local p = Instance.new("ScrollingFrame")
		p.Size = UDim2.fromScale(1, 1)
		p.BackgroundTransparency = 1
		p.BorderSizePixel = 0
		p.ScrollBarThickness = 2
		p.ScrollBarImageColor3 = GOLD
		p.AutomaticCanvasSize = Enum.AutomaticSize.Y
		p.CanvasSize = UDim2.new(0, 0, 0, 0)
		p.Visible = false
		p.Parent = PC
		do local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 5); l.Parent = p end

		table.insert(Pages, p)
		local i = #Pages
		b.MouseButton1Click:Connect(function() setTab(i) end)
		return p
	end

	local pAim = newTab("AIM")
	local pEsp = newTab("ESP")
	local pFps = newTab("FPS")
	local pSet = newTab("OPT")
	setTab(1)

	-- Widgets.
	local function toggle(parent, txt, def, cb)
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 40)
		r.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
		r.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = r end

		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -70, 1, 0)
		l.Position = UDim2.fromOffset(12, 0)
		l.BackgroundTransparency = 1
		l.Text = txt
		l.TextColor3 = Color3.fromRGB(235, 220, 180)
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = r

		local tr = Instance.new("Frame")
		tr.Size = UDim2.fromOffset(46, 24)
		tr.Position = UDim2.new(1, -58, 0.5, -12)
		tr.BackgroundColor3 = def and GOLD_D or Color3.fromRGB(45, 40, 30)
		tr.Parent = r
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = tr end

		local kn = Instance.new("Frame")
		kn.Size = UDim2.fromOffset(18, 18)
		kn.Position = def and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
		kn.BackgroundColor3 = def and GOLD_L or Color3.fromRGB(200, 190, 160)
		kn.Parent = tr
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 9); c.Parent = kn end

		local h = Instance.new("TextButton")
		h.Size = UDim2.fromScale(1, 1)
		h.BackgroundTransparency = 1
		h.Text = ""
		h.Parent = r

		local e = def
		h.MouseButton1Click:Connect(function()
			e = not e
			if deviceMode >= 1 then
				TweenService:Create(tr, TweenInfo.new(0.12), {
					BackgroundColor3 = e and GOLD_D or Color3.fromRGB(45, 40, 30),
				}):Play()
				TweenService:Create(kn, TweenInfo.new(0.12), {
					Position = e and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
				}):Play()
			else
				tr.BackgroundColor3 = e and GOLD_D or Color3.fromRGB(45, 40, 30)
				kn.Position = e and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
			end
			cb(e)
		end)
		return r
	end

	local function slider(parent, txt, mn, mx, def, dec, cb)
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 50)
		r.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
		r.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = r end

		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -20, 0, 20)
		l.Position = UDim2.fromOffset(12, 4)
		l.BackgroundTransparency = 1
		l.Text = txt .. ": " .. string.format("%." .. dec .. "f", def)
		l.TextColor3 = Color3.fromRGB(235, 220, 180)
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = r

		local b = Instance.new("Frame")
		b.Size = UDim2.new(1, -24, 0, 6)
		b.Position = UDim2.new(0, 12, 0, 32)
		b.BackgroundColor3 = Color3.fromRGB(45, 40, 30)
		b.Parent = r
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = b end

		local f = Instance.new("Frame")
		f.Size = UDim2.new((def - mn) / (mx - mn), 0, 1, 0)
		f.BackgroundColor3 = GOLD
		f.Parent = b
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = f end

		local dg = false
		local function upd(x)
			local rel = math.clamp((x - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
			local v = mn + (mx - mn) * rel
			f.Size = UDim2.new(rel, 0, 1, 0)
			l.Text = txt .. ": " .. string.format("%." .. dec .. "f", v)
			cb(v)
		end
		b.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dg = true; upd(i.Position.X)
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				upd(i.Position.X)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dg = false
			end
		end)
		return r
	end

	local function cycle(parent, txt, opts, def, cb)
		local r = Instance.new("Frame")
		r.Size = UDim2.new(1, 0, 0, 40)
		r.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
		r.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = r end

		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -110, 1, 0)
		l.Position = UDim2.fromOffset(12, 0)
		l.BackgroundTransparency = 1
		l.Text = txt
		l.TextColor3 = Color3.fromRGB(235, 220, 180)
		l.Font = Enum.Font.Gotham
		l.TextSize = 12
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = r

		local bt = Instance.new("TextButton")
		bt.Size = UDim2.fromOffset(88, 28)
		bt.Position = UDim2.new(1, -98, 0.5, -14)
		bt.BackgroundColor3 = GOLD_D
		bt.Text = def
		bt.TextColor3 = GOLD_L
		bt.Font = Enum.Font.GothamBold
		bt.TextSize = 11
		bt.AutoButtonColor = false
		bt.Parent = r
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = bt end

		local ix = 1
		for i, v in ipairs(opts) do if v == def then ix = i break end end
		bt.MouseButton1Click:Connect(function()
			ix = ix % #opts + 1
			bt.Text = opts[ix]
			cb(opts[ix])
		end)
		return r
	end

	-- AIM.
	toggle(pAim, "Aim Assist", S.aim, function(v) S.aim = v end)
	cycle(pAim, "Target", {"Head", "Body"}, S.targetHead and "Head" or "Body", function(v) S.targetHead = (v == "Head") end)
	toggle(pAim, "Team Check", S.teamChk, function(v) S.teamChk = v end)
	toggle(pAim, "Visibility", S.visChk, function(v) S.visChk = v end)
	slider(pAim, "Strength", 0, 1, S.aimStr, 2, function(v) S.aimStr = v end)
	slider(pAim, "Smoothness", 0.05, 1, S.smooth, 2, function(v) S.smooth = v end)
	slider(pAim, "Distance", 50, 1000, S.aimDist, 0, function(v) S.aimDist = v end)
	toggle(pAim, "FOV Circle", S.fovOn, function(v) S.fovOn = v end)
	slider(pAim, "FOV Size", 50, 400, S.fovSize, 0, function(v) S.fovSize = v end)

	-- ESP.
	toggle(pEsp, "Player ESP", S.esp, function(v) S.esp = v end)
	toggle(pEsp, "Box", S.espBox, function(v) S.espBox = v end)
	toggle(pEsp, "Name", S.espName, function(v) S.espName = v end)
	toggle(pEsp, "Health", S.espHp, function(v) S.espHp = v end)
	toggle(pEsp, "Distance", S.espDist, function(v) S.espDist = v end)
	toggle(pEsp, "Team Check", S.espTeam, function(v) S.espTeam = v end)

	-- FPS.
	toggle(pFps, "FPS Boost", S.fpsOn, function(v)
		S.fpsOn = v
		Lighting.GlobalShadows = not v
		Lighting.Brightness = v and 0.8 or 2
		for _, inst in ipairs(Lighting:GetChildren()) do
			if inst:IsA("PostEffect") then inst.Enabled = not v end
		end
	end)
	toggle(pFps, "FPS Monitor", S.fpsMon, function(v) S.fpsMon = v end)

	local fpsLbl = Instance.new("TextLabel")
	fpsLbl.Size = UDim2.new(1, 0, 0, 40)
	fpsLbl.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
	fpsLbl.Text = "FPS: --"
	fpsLbl.TextColor3 = GOLD_L
	fpsLbl.Font = Enum.Font.GothamBold
	fpsLbl.TextSize = 14
	fpsLbl.Parent = pFps
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = fpsLbl end

	-- OPT (device modes).
	local modeBtns = {}
	local function applyMode(idx)
		deviceMode = idx
		local m = MODES[idx + 1]
		fov.NumSides = m.fovSides
		STT.Text = "Owner: " .. OWNER .. " • " .. m.name .. " • v" .. VER
		for i, b in ipairs(modeBtns) do
			b.BackgroundColor3 = (i - 1 == idx) and GOLD_D or Color3.fromRGB(28, 24, 14)
			b.TextColor3 = (i - 1 == idx) and GOLD_L or Color3.fromRGB(190, 170, 120)
		end
	end

	for i, m in ipairs(MODES) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 36)
		b.BackgroundColor3 = (i - 1 == deviceMode) and GOLD_D or Color3.fromRGB(28, 24, 14)
		b.Text = m.name .. " Mode"
		b.TextColor3 = (i - 1 == deviceMode) and GOLD_L or Color3.fromRGB(190, 170, 120)
		b.Font = Enum.Font.GothamSemibold
		b.TextSize = 12
		b.AutoButtonColor = false
		b.Parent = pSet
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = b end
		table.insert(modeBtns, b)
		b.MouseButton1Click:Connect(function() applyMode(i - 1) end)
	end

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(1, 0, 0, 36)
	saveBtn.BackgroundColor3 = GOLD_D
	saveBtn.Text = "Save Settings"
	saveBtn.TextColor3 = GOLD_L
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.TextSize = 12
	saveBtn.AutoButtonColor = false
	saveBtn.Parent = pSet
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 7); c.Parent = saveBtn end
	saveBtn.MouseButton1Click:Connect(saveNow)

	-- Drag (unified, throttled via InputChanged).
	local function makeDrag(obj, handle)
		local dragging, ds, sp = false, nil, nil
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging, ds, sp = true, i.Position, obj.Position
			end
		end)
		handle.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - ds
				obj.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end
	makeDrag(M, TB)

	-- Float drag/click.
	do
		local ds, sp, moved = nil, nil, false
		FB.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				ds, sp, moved = i.Position, FB.Position, false
			end
		end)
		FB.InputChanged:Connect(function(i)
			if ds and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - ds
				if d.Magnitude > 6 then
					moved = true
					FB.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
				end
			end
		end)
		FB.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				if not moved then M.Visible = not M.Visible end
				ds = nil
			end
		end)
	end

	CL.MouseButton1Click:Connect(function()
		M.Visible = false
		-- Automatic cleanup when UI closed.
		S.aim = false
		S.esp = false
		S.aimming = false
	end)

	-- AIM mobile button.
	local AB = Instance.new("TextButton")
	AB.Size = UDim2.fromOffset(76, 76)
	AB.Position = UDim2.new(1, -100, 1, -180)
	AB.BackgroundColor3 = GOLD_D
	AB.BackgroundTransparency = 0.2
	AB.Text = "AIM"
	AB.TextColor3 = GOLD_L
	AB.Font = Enum.Font.GothamBold
	AB.TextSize = 15
	AB.AutoButtonColor = false
	AB.Visible = IS_MOBILE
	AB.Parent = GUI
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 38); c.Parent = AB
		local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.3; s.Parent = AB
	end

	do
		local ds, sp, moved = nil, nil, false
		AB.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then
				ds, sp, moved = i.Position, AB.Position, false
			end
		end)
		AB.InputChanged:Connect(function(i)
			if ds and i.UserInputType == Enum.UserInputType.Touch then
				local d = i.Position - ds
				if d.Magnitude > 8 then
					moved = true
					AB.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
				end
			end
		end)
		AB.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch then
				if not moved then
					S.aimming = not S.aimming
					AB.BackgroundColor3 = S.aimming and Color3.fromRGB(170, 45, 45) or GOLD_D
				end
				ds = nil
			end
		end)
	end

	return GUI, M, AB, fpsLbl, TB
end

-- ============================================================
-- LAUNCH
-- ============================================================
local GUI, M, AB, fpsLbl, TB = buildUI()
LBF.Size = UDim2.new(0.7, 0, 1, 0)
LS.Text = "Almost ready..."
task.wait(0.1)
pcall(function() LG:Destroy() end)

-- ============================================================
-- DRAWINGS (reused, minimized)
-- ============================================================
local fov = Drawing.new("Circle")
fov.Thickness = 1
fov.Color = Color3.fromRGB(255, 225, 120)
fov.Transparency = 0.6
fov.Filled = false
fov.NumSides = MODES[deviceMode + 1].fovSides
fov.Visible = false

local ESPCache = {}
local function newESP()
	local o = {
		box = Drawing.new("Square"),
		name = Drawing.new("Text"),
		dist = Drawing.new("Text"),
		hpBg = Drawing.new("Square"),
		hpFg = Drawing.new("Square"),
	}
	o.box.Thickness = 1
	o.name.Size = 13; o.name.Center = true; o.name.Outline = true; o.name.Font = Drawing.Fonts.Plex
	o.dist.Size = 11; o.dist.Center = true; o.dist.Outline = true; o.dist.Font = Drawing.Fonts.Plex
	o.hpBg.Filled = true; o.hpFg.Filled = true
	return o
end
local function delESP(o)
	pcall(function() o.box:Remove() end)
	pcall(function() o.name:Remove() end)
	pcall(function() o.dist:Remove() end)
	pcall(function() o.hpBg:Remove() end)
	pcall(function() o.hpFg:Remove() end)
end

local function setup(p) ESPCache[p] = newESP() end
for _, p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(p)
	local o = ESPCache[p]
	if o then delESP(o); ESPCache[p] = nil end
end)

-- ============================================================
-- HELPERS
-- ============================================================
local function sameTeam(p)
	if not S.teamChk then return false end
	if not p.Team or not LP.Team then return false end
	return p.Team == LP.Team
end

local function vis(part)
	if not S.visChk then return true end
	local prm = RaycastParams.new()
	prm.FilterType = Enum.RaycastFilterType.Exclude
	prm.FilterDescendantsInstances = { LP.Character, part.Parent }
	return workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, prm) == nil
end

local function getTarget()
	local org = IS_MOBILE and Camera.ViewportSize / 2
		or Vector2.new(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y)
	local best, bestD = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		if sameTeam(p) then continue end
		local ch = p.Character
		if not ch then continue end
		local part = S.targetHead and ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if not (part and hum and hum.Health > 0) then continue end
		if (Camera.CFrame.Position - part.Position).Magnitude > S.aimDist then continue end
		local sp, on = Camera:WorldToViewportPoint(part.Position)
		if not on then continue end
		local sd = (Vector2.new(sp.X, sp.Y) - org).Magnitude
		if sd <= S.fovSize and sd < bestD and vis(part) then
			best, bestD = part, sd
		end
	end
	return best
end

-- ============================================================
-- THROTTLED UPDATE (independent of RenderStepped)
-- ============================================================
local acc, fpsAcc, fpsCount, curFps = 0, 0, 0, 0
local lastPingT = 0

-- AIM uses RenderStepped (needs per-frame lerp) but is a no-op when off.
local aimConn = RunService.RenderStepped:Connect(function(dt)
	if shutdown then return end
	if S.fovOn and S.aim then
		fov.Position = Camera.ViewportSize / 2
		fov.Radius = S.fovSize
		fov.Visible = true
	else
		fov.Visible = false
	end

	if S.aim and S.aimming then
		local t = getTarget()
		if t then
			local des = CFrame.new(Camera.CFrame.Position, t.Position)
			local sf = 1 - math.clamp(S.smooth, 0.01, 1) + S.aimStr * 0.15
			Camera.CFrame = Camera.CFrame:Lerp(des, math.clamp(sf, 0.02, 1))
		end
	end
end)

-- ESP + FPS + save use Heartbeat with adaptive throttle.
local espConn = RunService.Heartbeat:Connect(function(dt)
	if shutdown then return end
	acc = acc + dt
	fpsAcc = fpsAcc + dt
	fpsCount = fpsCount + 1

	-- FPS counter (1Hz, no heavy reads).
	if fpsAcc >= 1 then
		curFps = fpsCount
		fpsAcc, fpsCount = 0, 0
		if S.fpsMon and fpsLbl then
			fpsLbl.Text = "FPS: " .. curFps
		end
	end

	-- ESP update throttled.
	local rate = MODES[deviceMode + 1].espRate
	if acc < rate then return end
	acc = 0

	if not S.esp then
		-- Hide all once, cheap.
		for _, o in pairs(ESPCache) do
			if o.box.Visible then
				o.box.Visible, o.name.Visible, o.dist.Visible = false, false, false
				o.hpBg.Visible, o.hpFg.Visible = false, false
			end
		end
		return
	end

	local col = Color3.fromRGB(S.espCol[1], S.espCol[2], S.espCol[3])
	for p, o in pairs(ESPCache) do
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")

		if not ch or not hrp or not hum or hum.Health <= 0 or (S.espTeam and sameTeam(p)) then
			if o.box.Visible then
				o.box.Visible, o.name.Visible, o.dist.Visible = false, false, false
				o.hpBg.Visible, o.hpFg.Visible = false, false
			end
			continue
		end

		local sp, on = Camera:WorldToViewportPoint(hrp.Position)
		if not on then
			if o.box.Visible then
				o.box.Visible, o.name.Visible, o.dist.Visible = false, false, false
				o.hpBg.Visible, o.hpFg.Visible = false, false
			end
			continue
		end

		local headSp = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 1.5, 0))
		local feetSp = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
		local h = math.abs(feetSp.Y - headSp.Y)
		local w = h * 0.5
		local bx = sp.X - w / 2
		local by = headSp.Y

		if S.espBox then
			o.box.Size = Vector2.new(w, h)
			o.box.Position = Vector2.new(bx, by)
			o.box.Color = col
			o.box.Visible = true
		else
			o.box.Visible = false
		end

		if S.espName then
			o.name.Text = p.Name
			o.name.Position = Vector2.new(sp.X, headSp.Y - 16)
			o.name.Color = col
			o.name.Visible = true
		else
			o.name.Visible = false
		end

		if S.espDist then
			o.dist.Text = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude) .. "m"
			o.dist.Position = Vector2.new(sp.X, feetSp.Y + 3)
			o.dist.Color = col
			o.dist.Visible = true
		else
			o.dist.Visible = false
		end

		if S.espHp then
			local hp = hum.Health / math.max(hum.MaxHealth, 1)
			o.hpBg.Size = Vector2.new(3, h)
			o.hpBg.Position = Vector2.new(bx - 6, by)
			o.hpBg.Color = Color3.fromRGB(20, 20, 20)
			o.hpBg.Visible = true
			o.hpFg.Size = Vector2.new(3, h * hp)
			o.hpFg.Position = Vector2.new(bx - 6, by + h * (1 - hp))
			o.hpFg.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
			o.hpFg.Visible = true
		else
			o.hpBg.Visible, o.hpFg.Visible = false, false
		end
	end
end)

-- ============================================================
-- SAVE LOOP (every 15s, cheap)
-- ============================================================
local saveConn = task.spawn(function()
	while not shutdown do
		task.wait(15)
		saveNow()
	end
end)

-- ============================================================
-- CLEANUP (auto when UI hidden or re-executed)
-- ============================================================
local function cleanup()
	if shutdown then return end
	shutdown = true
	pcall(function() aimConn:Disconnect() end)
	pcall(function() espConn:Disconnect() end)
	pcall(function() GUI:Destroy() end)
	pcall(function() fov:Remove() end)
	for p, o in pairs(ESPCache) do delESP(o); ESPCache[p] = nil end
	pcall(saveNow)
end
shared[KEY] = cleanup

if IS_MOBILE then
	-- Auto cleanup when player leaves or game closes.
	pcall(function()
		game:BindToClose(cleanup)
	end)
end

warn(("[ZENO HUB] Optimized v%s | %s | Mode: %s"):format(VER, OWNER, MODES[deviceMode + 1].name))
