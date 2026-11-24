-- ============================================================
-- ZENO HUB - URBAN RELOAD  |  PREMIUM KEYLESS
-- Owner: Emy210208
-- Mobile-friendly, keyless, premium UI (Delta compatible)
-- For authorized testing environments only.
-- ============================================================

-- Services.
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")
local coreGui = game:GetService("CoreGui")
local stats = game:GetService("Stats")
local httpService = game:GetService("HttpService")
local tweenService = game:GetService("TweenService")
local currentCamera = workspace.CurrentCamera
local localPlayer = playersService.LocalPlayer

if not shared then
	return warn("No shared, no script.")
end

-- ============================================================
-- PREMIUM KEYLESS SYSTEM
-- ============================================================
local SCRIPT_VERSION = 1.3
local OWNER_NAME = "Emy210208"
local PRODUCT_NAME = "ZENO HUB PREMIUM"

local executorName = "Unknown"
pcall(function()
	local n = identifyexecutor()
	if n then executorName = n end
end)

-- Owner authentication (identity match, not a gate — display only).
local viewerName = "Guest"
pcall(function()
	if localPlayer then viewerName = localPlayer.Name end
end)
local isOwner = (viewerName == OWNER_NAME)

-- One-Time Initialization / Duplicate protection.
local INIT_KEY = "ZenoHub_Premium_" .. tostring(game.GameId)
if shared[INIT_KEY] then
	pcall(function() shared[INIT_KEY].cleanup() end)
end

-- ============================================================
-- SAFETY / EXECUTION PROTECTION
-- ============================================================
local REQUIRED_FUNCS = { "Drawing", "getgenv", "identifyexecutor" }
local function checkSafeExecution()
	local missing = {}
	for _, fn in ipairs(REQUIRED_FUNCS) do
		if not _G[fn] and not getgenv()[fn] then table.insert(missing, fn) end
	end
	if #missing > 0 then return false, "Missing: " .. table.concat(missing, ", ") end
	return true, "OK"
end

local function checkCompatibility()
	local ok, err = pcall(function()
		local _ = table.create and table.create(1)
		local _ = math.clamp and math.clamp(1, 0, 2)
	end)
	if not ok then return false, "Luau: " .. tostring(err) end
	return true, "OK"
end

local errorLog, criticalShutdown = {}, false

local function logError(scope, err)
	local entry = string.format("[%s] %s", scope, tostring(err))
	table.insert(errorLog, entry)
	if #errorLog > 50 then table.remove(errorLog, 1) end
	warn("[ZENO HUB] " .. entry)
end

local function triggerCriticalShutdown(reason)
	if criticalShutdown then return end
	criticalShutdown = true
	logError("CRITICAL", reason)
	warn("[ZENO HUB] Critical error. Shutting down.")
	if shared[INIT_KEY] and shared[INIT_KEY].cleanup then
		pcall(shared[INIT_KEY].cleanup)
	end
end

local function safeCall(scope, fn, ...)
	local ok, r = pcall(fn, ...)
	if not ok then logError(scope, r) end
	return ok, r
end

-- ============================================================
-- PERSISTENCE
-- ============================================================
local SAVE_FOLDER = "ZenoHub"
local SAVE_FILE = SAVE_FOLDER .. "/premiumSettings.json"
pcall(makefolder, SAVE_FOLDER)

local function loadSettings()
	if isfile and isfile(SAVE_FILE) then
		local ok, d = pcall(function() return httpService:JSONDecode(readfile(SAVE_FILE)) end)
		if ok and type(d) == "table" then return d end
	end
	return {}
end

local function saveSettings(tbl)
	if not writefile then return end
	local ok, enc = pcall(function() return httpService:JSONEncode(tbl) end)
	if ok then pcall(writefile, SAVE_FILE, enc) end
end

local saved = loadSettings()

-- ============================================================
-- STATE
-- ============================================================
local state = {
	aimEnabled = saved.aimEnabled or false,
	aimStrength = saved.aimStrength or 0.35,
	fovEnabled = saved.fovEnabled or true,
	fovSize = saved.fovSize or 150,
	targetPart = saved.targetPart or "Head",
	teamCheck = saved.teamCheck ~= false,
	visCheck = saved.visCheck ~= false,
	aimSmooth = saved.aimSmooth or 0.25,
	aimDistance = saved.aimDistance or 500,
	aiming = false,

	espEnabled = saved.espEnabled or false,
	espBox = saved.espBox or true,
	espSkeleton = saved.espSkeleton or false,
	espName = saved.espName or true,
	espHealth = saved.espHealth or true,
	espDistance = saved.espDistance or true,
	espTeamCheck = saved.espTeamCheck ~= false,
	espColor = saved.espColor or {255, 255, 255},

	reloadReminder = saved.reloadReminder ~= false,
	recoilControl = saved.recoilControl or false,

	fpsBoost = saved.fpsBoost or false,
	lowGraphics = saved.lowGraphics or false,
	lowMemory = saved.lowMemory or false,
	antiLag = saved.antiLag or false,
	batterySaver = saved.batterySaver or false,
	smoothGameplay = saved.smoothGameplay or false,
	fpsMonitor = saved.fpsMonitor or true,
	pingMonitor = saved.pingMonitor or true,

	-- Premium-only extras.
	premiumAimPrediction = saved.premiumAimPrediction or false,
	premiumStreamerMode = saved.premiumStreamerMode or false,
	premiumAutoDetect = saved.premiumAutoDetect or true,

	uiColor = saved.uiColor or {212, 175, 55}, -- gold default
	minimized = false,
}

-- ============================================================
-- GOLD THEME
-- ============================================================
local GOLD = Color3.fromRGB(212, 175, 55)
local GOLD_DARK = Color3.fromRGB(120, 95, 25)
local GOLD_LIGHT = Color3.fromRGB(255, 225, 120)

local function uiColor3()
	return Color3.fromRGB(state.uiColor[1], state.uiColor[2], state.uiColor[3])
end

-- ============================================================
-- SMOOTH LOADING ANIMATION
-- ============================================================
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "ZenoHubPremiumLoading"
loadingGui.ResetOnSpawn = false
loadingGui.IgnoreGuiInset = true
loadingGui.DisplayOrder = 1001
loadingGui.Parent = (gethui and gethui()) or coreGui

local loadingFrame = Instance.new("Frame")
loadingFrame.Size = UDim2.fromOffset(240, 140)
loadingFrame.Position = UDim2.new(0.5, -120, 0.5, -70)
loadingFrame.BackgroundColor3 = Color3.fromRGB(14, 12, 8)
loadingFrame.Parent = loadingGui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = loadingFrame
	local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.2; s.Parent = loadingFrame
end

local crown = Instance.new("TextLabel")
crown.Size = UDim2.new(1, 0, 0, 26)
crown.Position = UDim2.fromOffset(0, 10)
crown.BackgroundTransparency = 1
crown.Text = "♛"
crown.TextColor3 = GOLD
crown.Font = Enum.Font.GothamBold
crown.TextSize = 22
crown.Parent = loadingFrame

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(1, 0, 0, 26)
loadingTitle.Position = UDim2.fromOffset(0, 36)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = PRODUCT_NAME
loadingTitle.TextColor3 = Color3.fromRGB(255, 240, 200)
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.TextSize = 15
loadingTitle.Parent = loadingFrame

local loadingOwner = Instance.new("TextLabel")
loadingOwner.Size = UDim2.new(1, 0, 0, 16)
loadingOwner.Position = UDim2.fromOffset(0, 62)
loadingOwner.BackgroundTransparency = 1
loadingOwner.Text = "Owner: " .. OWNER_NAME
loadingOwner.TextColor3 = Color3.fromRGB(180, 160, 100)
loadingOwner.Font = Enum.Font.Gotham
loadingOwner.TextSize = 11
loadingOwner.Parent = loadingFrame

local loadingStatus = Instance.new("TextLabel")
loadingStatus.Size = UDim2.new(1, -20, 0, 16)
loadingStatus.Position = UDim2.new(0, 10, 1, -40)
loadingStatus.BackgroundTransparency = 1
loadingStatus.Text = "Initializing premium modules..."
loadingStatus.TextColor3 = Color3.fromRGB(200, 190, 160)
loadingStatus.Font = Enum.Font.Gotham
loadingStatus.TextSize = 10
loadingStatus.Parent = loadingFrame

local loadingBarBg = Instance.new("Frame")
loadingBarBg.Size = UDim2.new(1, -40, 0, 6)
loadingBarBg.Position = UDim2.new(0, 20, 1, -22)
loadingBarBg.BackgroundColor3 = Color3.fromRGB(40, 36, 24)
loadingBarBg.Parent = loadingFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = loadingBarBg end

local loadingBarFill = Instance.new("Frame")
loadingBarFill.Size = UDim2.new(0, 0, 1, 0)
loadingBarFill.BackgroundColor3 = GOLD
loadingBarFill.Parent = loadingBarBg
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = loadingBarFill end

local function setLoadingProgress(pct, text)
	tweenService:Create(loadingBarFill, TweenInfo.new(0.25), { Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0) }):Play()
	if text then loadingStatus.Text = text end
end

setLoadingProgress(0.15, "Verifying environment...")
local safeOk, safeMsg = checkSafeExecution()
local compatOk, compatMsg = checkCompatibility()
if not safeOk then logError("SafeExec", safeMsg) end
if not compatOk then logError("Compat", compatMsg) end

-- ============================================================
-- PREMIUM UI BUILD
-- ============================================================
local function buildUI()
	setLoadingProgress(0.4, "Building premium UI...")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZenoHubPremium"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999
	screenGui.Parent = (gethui and gethui()) or coreGui

	-- Premium status indicator.
	local statusPill = Instance.new("Frame")
	statusPill.Size = UDim2.fromOffset(190, 30)
	statusPill.Position = UDim2.new(1, -200, 0, 12)
	statusPill.BackgroundColor3 = Color3.fromRGB(20, 18, 10)
	statusPill.BackgroundTransparency = 0.1
	statusPill.Parent = screenGui
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 15); c.Parent = statusPill
		local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 1.5; s.Transparency = 0.25; s.Parent = statusPill
	end

	local statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.fromOffset(8, 8)
	statusDot.Position = UDim2.new(0, 12, 0.5, -4)
	statusDot.BackgroundColor3 = GOLD
	statusDot.Parent = statusPill
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = statusDot end

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -30, 1, 0)
	statusLabel.Position = UDim2.fromOffset(26, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "PREMIUM • " .. executorName
	statusLabel.TextColor3 = Color3.fromRGB(255, 235, 170)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 11
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = statusPill

	local function setStatus(text, ok)
		statusLabel.Text = text
		statusDot.BackgroundColor3 = ok and GOLD or Color3.fromRGB(220, 80, 80)
	end

	-- Floating open button.
	local floatBtn = Instance.new("TextButton")
	floatBtn.Size = UDim2.fromOffset(58, 58)
	floatBtn.Position = UDim2.new(0, 20, 0.5, -29)
	floatBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 10)
	floatBtn.Text = "♛"
	floatBtn.TextColor3 = GOLD_LIGHT
	floatBtn.Font = Enum.Font.GothamBold
	floatBtn.TextSize = 26
	floatBtn.AutoButtonColor = false
	floatBtn.Parent = screenGui
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 29); c.Parent = floatBtn
		local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.15; s.Parent = floatBtn
	end

	-- Pulse animation on floating button.
	task.spawn(function()
		while floatBtn.Parent do
			task.wait(1.6)
			pcall(function()
				tweenService:Create(floatBtn, TweenInfo.new(0.8), {
					BackgroundColor3 = Color3.fromRGB(60, 50, 20),
				}):Play()
			end)
			task.wait(0.8)
			pcall(function()
				tweenService:Create(floatBtn, TweenInfo.new(0.8), {
					BackgroundColor3 = Color3.fromRGB(24, 20, 10),
				}):Play()
			end)
		end
	end)

	-- Main window.
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(360, 520)
	main.Position = UDim2.new(0.5, -180, 0.5, -260)
	main.BackgroundColor3 = Color3.fromRGB(12, 10, 8)
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Active = true
	main.Parent = screenGui
	main.Visible = false
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = main
		local s = Instance.new("UIStroke"); s.Color = GOLD_DARK; s.Thickness = 1.5; s.Parent = main
	end

	-- Title bar.
	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 52)
	titleBar.BackgroundColor3 = Color3.fromRGB(18, 15, 9)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = main
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = titleBar end

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -140, 0, 24)
	titleText.Position = UDim2.fromOffset(16, 6)
	titleText.BackgroundTransparency = 1
	titleText.Text = "♛ ZENO HUB PREMIUM"
	titleText.TextColor3 = GOLD_LIGHT
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 15
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar

	local subtitleText = Instance.new("TextLabel")
	subtitleText.Size = UDim2.new(1, -140, 0, 14)
	subtitleText.Position = UDim2.fromOffset(16, 28)
	subtitleText.BackgroundTransparency = 1
	subtitleText.Text = "Keyless • Owner: " .. OWNER_NAME .. " • v" .. SCRIPT_VERSION
	subtitleText.TextColor3 = Color3.fromRGB(160, 140, 90)
	subtitleText.Font = Enum.Font.Gotham
	subtitleText.TextSize = 9
	subtitleText.TextXAlignment = Enum.TextXAlignment.Left
	subtitleText.Parent = titleBar

	-- Premium badge.
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(76, 22)
	badge.Position = UDim2.new(1, -160, 0, 8)
	badge.BackgroundColor3 = GOLD_DARK
	badge.Text = "PREMIUM"
	badge.TextColor3 = GOLD_LIGHT
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.Parent = titleBar
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = badge end

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.fromOffset(30, 30)
	minBtn.Position = UDim2.new(1, -76, 0, 11)
	minBtn.BackgroundColor3 = Color3.fromRGB(50, 42, 20)
	minBtn.Text = "−"
	minBtn.TextColor3 = GOLD_LIGHT
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 18
	minBtn.Parent = titleBar
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = minBtn end

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(30, 30)
	closeBtn.Position = UDim2.new(1, -38, 0, 11)
	closeBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 240, 200)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = titleBar
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = closeBtn end

	-- Tab bar.
	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, 0, 0, 42)
	tabBar.Position = UDim2.fromOffset(0, 52)
	tabBar.BackgroundColor3 = Color3.fromRGB(16, 13, 8)
	tabBar.BorderSizePixel = 0
	tabBar.Parent = main
	do
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.Padding = UDim.new(0, 2)
		l.Parent = tabBar
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 6); p.PaddingRight = UDim.new(0, 6); p.PaddingTop = UDim.new(0, 6)
		p.Parent = tabBar
	end

	local pages, tabButtons = {}, {}

	local pageContainer = Instance.new("Frame")
	pageContainer.Size = UDim2.new(1, -16, 1, -110)
	pageContainer.Position = UDim2.fromOffset(8, 102)
	pageContainer.BackgroundTransparency = 1
	pageContainer.Parent = main

	local function setActiveTab(index)
		for i, p in ipairs(pages) do p.Visible = (i == index) end
		for i, b in ipairs(tabButtons) do
			b.BackgroundColor3 = (i == index) and GOLD_DARK or Color3.fromRGB(28, 24, 14)
			b.TextColor3 = (i == index) and GOLD_LIGHT or Color3.fromRGB(190, 170, 120)
		end
	end

	local function createTab(name)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1 / 7, -2, 1, -6)
		btn.BackgroundColor3 = Color3.fromRGB(28, 24, 14)
		btn.Text = name
		btn.TextColor3 = Color3.fromRGB(190, 170, 120)
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 9
		btn.AutoButtonColor = false
		btn.Parent = tabBar
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn end
		table.insert(tabButtons, btn)

		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.fromScale(1, 1)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 2
		page.ScrollBarImageColor3 = GOLD
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.Parent = pageContainer
		do local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 6); l.Parent = page end

		table.insert(pages, page)
		local idx = #pages
		btn.MouseButton1Click:Connect(function() setActiveTab(idx) end)
		return page
	end

	local aimPage = createTab("AIM")
	local visualPage = createTab("ESP")
	local weaponPage = createTab("WPN")
	local perfPage = createTab("FPS")
	local secPage = createTab("SEC")
	local premiumPage = createTab("♛ PRO")
	local miscPage = createTab("MISC")
	setActiveTab(1)

	-- ============================================================
	-- WIDGETS (gold-themed)
	-- ============================================================
	local function createToggle(parent, text, default, callback)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
		row.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row end

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -70, 1, 0)
		label.Position = UDim2.fromOffset(14, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(235, 220, 180)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local track = Instance.new("Frame")
		track.Size = UDim2.fromOffset(50, 26)
		track.Position = UDim2.new(1, -64, 0.5, -13)
		track.BackgroundColor3 = default and GOLD_DARK or Color3.fromRGB(45, 40, 30)
		track.Parent = row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 13); c.Parent = track end

		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(20, 20)
		knob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
		knob.BackgroundColor3 = default and GOLD_LIGHT or Color3.fromRGB(200, 190, 160)
		knob.Parent = track
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = knob end

		local hit = Instance.new("TextButton")
		hit.Size = UDim2.fromScale(1, 1)
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.Parent = row

		local enabled = default
		hit.MouseButton1Click:Connect(function()
			enabled = not enabled
			tweenService:Create(track, TweenInfo.new(0.18), {
				BackgroundColor3 = enabled and GOLD_DARK or Color3.fromRGB(45, 40, 30),
			}):Play()
			tweenService:Create(knob, TweenInfo.new(0.18), {
				Position = enabled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
				BackgroundColor3 = enabled and GOLD_LIGHT or Color3.fromRGB(200, 190, 160),
			}):Play()
			callback(enabled)
		end)
		return row
	end

	local function createSlider(parent, text, min, max, default, decimals, callback)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 58)
		row.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
		row.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row end

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 0, 22)
		label.Position = UDim2.fromOffset(14, 6)
		label.BackgroundTransparency = 1
		label.Text = text .. ": " .. string.format("%." .. decimals .. "f", default)
		label.TextColor3 = Color3.fromRGB(235, 220, 180)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, -28, 0, 6)
		bar.Position = UDim2.new(0, 14, 0, 38)
		bar.BackgroundColor3 = Color3.fromRGB(45, 40, 30)
		bar.Parent = row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = bar end

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
		fill.BackgroundColor3 = GOLD
		fill.Parent = bar
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 3); c.Parent = fill end

		local dragging = false
		local function update(x)
			local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local v = min + (max - min) * rel
			fill.Size = UDim2.new(rel, 0, 1, 0)
			label.Text = text .. ": " .. string.format("%." .. decimals .. "f", v)
			callback(v)
		end
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; update(input.Position.X)
			end
		end)
		userInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				update(input.Position.X)
			end
		end)
		userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		return row
	end

	local function createCycle(parent, text, options, default, callback)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
		row.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row end

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -120, 1, 0)
		label.Position = UDim2.fromOffset(14, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(235, 220, 180)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(96, 30)
		btn.Position = UDim2.new(1, -108, 0.5, -15)
		btn.BackgroundColor3 = GOLD_DARK
		btn.Text = default
		btn.TextColor3 = GOLD_LIGHT
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.AutoButtonColor = false
		btn.Parent = row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn end

		local idx = 1
		for i, v in ipairs(options) do if v == default then idx = i break end end
		btn.MouseButton1Click:Connect(function()
			idx = idx % #options + 1
			btn.Text = options[idx]
			callback(options[idx])
		end)
		return row
	end

	local function createColorRow(parent, text, rgb, callback)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
		row.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row end

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -70, 1, 0)
		label.Position = UDim2.fromOffset(14, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(235, 220, 180)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local swatch = Instance.new("TextButton")
		swatch.Size = UDim2.fromOffset(44, 26)
		swatch.Position = UDim2.new(1, -58, 0.5, -13)
		swatch.BackgroundColor3 = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
		swatch.Text = ""
		swatch.AutoButtonColor = false
		swatch.Parent = row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = swatch end

		local palette = {
			{255, 255, 255}, {212, 175, 55}, {255, 225, 120}, {255, 80, 80},
			{80, 200, 255}, {120, 255, 120}, {255, 100, 255}, {140, 120, 255},
		}
		local curIdx = 1
		for i, c in ipairs(palette) do
			if c[1] == rgb[1] and c[2] == rgb[2] and c[3] == rgb[3] then curIdx = i break end
		end
		swatch.MouseButton1Click:Connect(function()
			curIdx = curIdx % #palette + 1
			local c = palette[curIdx]
			swatch.BackgroundColor3 = Color3.fromRGB(c[1], c[2], c[3])
			callback(c)
		end)
		return row
	end

	local function createSection(parent, name)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 22)
		lbl.BackgroundTransparency = 1
		lbl.Text = "◆ " .. string.upper(name)
		lbl.TextColor3 = GOLD
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = parent
		return lbl
	end

	local function createButton(parent, text, color, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 40)
		btn.BackgroundColor3 = color or GOLD_DARK
		btn.Text = text
		btn.TextColor3 = GOLD_LIGHT
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.AutoButtonColor = false
		btn.Parent = parent
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn end
		btn.MouseButton1Click:Connect(function() safeCall("button:" .. text, callback) end)
		return btn
	end

	-- ============================================================
	-- AIM
	-- ============================================================
	createSection(aimPage, "Aim Assist")
	createToggle(aimPage, "Aim Assist", state.aimEnabled, function(v) state.aimEnabled = v end)
	createCycle(aimPage, "Target Part", {"Head", "Body"}, state.targetPart, function(v) state.targetPart = v end)
	createToggle(aimPage, "Team Check", state.teamCheck, function(v) state.teamCheck = v end)
	createToggle(aimPage, "Visibility Check", state.visCheck, function(v) state.visCheck = v end)
	createSlider(aimPage, "Aim Strength", 0, 1, state.aimStrength, 2, function(v) state.aimStrength = v end)
	createSlider(aimPage, "Aim Smoothness", 0.05, 1, state.aimSmooth, 2, function(v) state.aimSmooth = v end)
	createSlider(aimPage, "Aim Distance", 50, 1000, state.aimDistance, 0, function(v) state.aimDistance = v end)
	createSection(aimPage, "FOV")
	createToggle(aimPage, "FOV Circle", state.fovEnabled, function(v) state.fovEnabled = v end)
	createSlider(aimPage, "FOV Size", 50, 500, state.fovSize, 0, function(v) state.fovSize = v end)

	-- ============================================================
	-- ESP
	-- ============================================================
	createSection(visualPage, "Visuals")
	createToggle(visualPage, "Player ESP", state.espEnabled, function(v) state.espEnabled = v end)
	createToggle(visualPage, "Box ESP", state.espBox, function(v) state.espBox = v end)
	createToggle(visualPage, "Skeleton ESP", state.espSkeleton, function(v) state.espSkeleton = v end)
	createToggle(visualPage, "Name ESP", state.espName, function(v) state.espName = v end)
	createToggle(visualPage, "Health Bar", state.espHealth, function(v) state.espHealth = v end)
	createToggle(visualPage, "Distance ESP", state.espDistance, function(v) state.espDistance = v end)
	createToggle(visualPage, "Team Check", state.espTeamCheck, function(v) state.espTeamCheck = v end)
	createColorRow(visualPage, "ESP Color", state.espColor, function(c) state.espColor = c end)

	-- ============================================================
	-- WEAPON
	-- ============================================================
	createSection(weaponPage, "Weapon")
	createToggle(weaponPage, "Reload Reminder", state.reloadReminder, function(v) state.reloadReminder = v end)
	createToggle(weaponPage, "Recoil Control", state.recoilControl, function(v) state.recoilControl = v end)

	local weaponInfo = Instance.new("TextLabel")
	weaponInfo.Size = UDim2.new(1, 0, 0, 90)
	weaponInfo.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
	weaponInfo.Text = "Weapon: N/A\nAmmo: N/A\nStatus: Idle"
	weaponInfo.TextColor3 = Color3.fromRGB(210, 195, 155)
	weaponInfo.Font = Enum.Font.Gotham
	weaponInfo.TextSize = 12
	weaponInfo.TextXAlignment = Enum.TextXAlignment.Left
	weaponInfo.TextYAlignment = Enum.TextYAlignment.Top
	weaponInfo.Parent = weaponPage
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = weaponInfo
		local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 14); p.PaddingTop = UDim.new(0, 12); p.Parent = weaponInfo
	end

	-- ============================================================
	-- FPS
	-- ============================================================
	createSection(perfPage, "FPS Boost")
	createToggle(perfPage, "FPS Boost", state.fpsBoost, function(v) state.fpsBoost = v end)
	createToggle(perfPage, "Low Graphics", state.lowGraphics, function(v) state.lowGraphics = v end)
	createToggle(perfPage, "Low Memory Mode", state.lowMemory, function(v) state.lowMemory = v end)
	createToggle(perfPage, "Anti-Lag", state.antiLag, function(v) state.antiLag = v end)
	createToggle(perfPage, "Battery Saver", state.batterySaver, function(v) state.batterySaver = v end)
	createToggle(perfPage, "Smooth Gameplay", state.smoothGameplay, function(v) state.smoothGameplay = v end)
	createSection(perfPage, "Monitor")
	createToggle(perfPage, "FPS Monitor", state.fpsMonitor, function(v) state.fpsMonitor = v end)
	createToggle(perfPage, "Ping Monitor", state.pingMonitor, function(v) state.pingMonitor = v end)

	-- ============================================================
	-- SEC
	-- ============================================================
	createSection(secPage, "Execution")
	local execInfo = Instance.new("TextLabel")
	execInfo.Size = UDim2.new(1, 0, 0, 110)
	execInfo.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
	execInfo.Text = string.format(
		"Product: %s\nOwner: %s\nViewer: %s\nExecutor: %s\nKeyless: YES\nScript v%.1f",
		PRODUCT_NAME, OWNER_NAME, viewerName, executorName, SCRIPT_VERSION
	)
	execInfo.TextColor3 = Color3.fromRGB(210, 195, 155)
	execInfo.Font = Enum.Font.Gotham
	execInfo.TextSize = 11
	execInfo.TextXAlignment = Enum.TextXAlignment.Left
	execInfo.TextYAlignment = Enum.TextYAlignment.Top
	execInfo.Parent = secPage
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = execInfo
		local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 14); p.PaddingTop = UDim.new(0, 10); p.Parent = execInfo
	end

	createButton(secPage, "Run Self-Check", GOLD_DARK, function()
		local ok1, msg1 = checkSafeExecution()
		local ok2, msg2 = checkCompatibility()
		local allOk = ok1 and ok2
		setStatus(allOk and "PREMIUM • Checks OK" or "PREMIUM • Check failed", allOk)
		execInfo.Text = string.format(
			"Product: %s\nOwner: %s\nViewer: %s\nExecutor: %s\nSafe: %s\nCompat: %s\nErrors: %d",
			PRODUCT_NAME, OWNER_NAME, viewerName, executorName,
			ok1 and "OK" or msg1, ok2 and "OK" or msg2, #errorLog
		)
	end)

	createButton(secPage, "View Error Log", Color3.fromRGB(60, 50, 30), function()
		if #errorLog == 0 then setStatus("No errors", true)
		else
			setStatus(#errorLog .. " error(s)", false)
			for _, e in ipairs(errorLog) do warn(e) end
		end
	end)

	createButton(secPage, "Emergency Stop", Color3.fromRGB(170, 45, 45), function()
		triggerCriticalShutdown("User pressed Emergency Stop")
	end)

	-- ============================================================
	-- PREMIUM TAB
	-- ============================================================
	createSection(premiumPage, "Premium Status")

	local premiumBanner = Instance.new("TextLabel")
	premiumBanner.Size = UDim2.new(1, 0, 0, 86)
	premiumBanner.BackgroundColor3 = Color3.fromRGB(30, 25, 12)
	premiumBanner.Text = string.format(
		"♛ PREMIUM ACTIVE ♛\nOwner: %s\nViewer: %s (%s)\nNo key • No password",
		OWNER_NAME, viewerName, isOwner and "Owner" or "Premium User"
	)
	premiumBanner.TextColor3 = GOLD_LIGHT
	premiumBanner.Font = Enum.Font.GothamBold
	premiumBanner.TextSize = 12
	premiumBanner.Parent = premiumPage
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = premiumBanner
		local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 1; s.Transparency = 0.3; s.Parent = premiumBanner
	end

	createSection(premiumPage, "Premium Features")
	createToggle(premiumPage, "Aim Prediction (Premium)", state.premiumAimPrediction, function(v)
		state.premiumAimPrediction = v
		if v then setStatus("Premium: Aim Prediction ON", true) end
	end)
	createToggle(premiumPage, "Streamer Mode", state.premiumStreamerMode, function(v)
		state.premiumStreamerMode = v
		subtitleText.Text = v
			and ("Keyless • PREMIUM • v" .. SCRIPT_VERSION)
			or ("Keyless • Owner: " .. OWNER_NAME .. " • v" .. SCRIPT_VERSION)
	end)
	createToggle(premiumPage, "Auto Performance Detect", state.premiumAutoDetect, function(v)
		state.premiumAutoDetect = v
	end)

	createButton(premiumPage, "Unlock Premium Boost", GOLD_DARK, function()
		state.fpsBoost = true
		state.lowGraphics = true
		setStatus("Premium Boost applied", true)
	end)

	createButton(premiumPage, "Owner Info", Color3.fromRGB(60, 50, 30), function()
		setStatus("Owner: " .. OWNER_NAME, true)
	end)

	-- ============================================================
	-- MISC
	-- ============================================================
	createSection(miscPage, "UI Accent")
	createColorRow(miscPage, "Accent Color", state.uiColor, function(c)
		state.uiColor = c
		floatBtn.TextColor3 = uiColor3()
	end)

	local perfLabel = Instance.new("TextLabel")
	perfLabel.Size = UDim2.new(1, 0, 0, 60)
	perfLabel.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
	perfLabel.Text = "FPS: --\nPing: --"
	perfLabel.TextColor3 = Color3.fromRGB(210, 195, 155)
	perfLabel.Font = Enum.Font.Gotham
	perfLabel.TextSize = 13
	perfLabel.TextXAlignment = Enum.TextXAlignment.Left
	perfLabel.TextYAlignment = Enum.TextYAlignment.Top
	perfLabel.Parent = miscPage
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = perfLabel
		local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 14); p.PaddingTop = UDim.new(0, 10); p.Parent = perfLabel
	end

	createSection(miscPage, "About")
	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, 0, 0, 72)
	info.BackgroundColor3 = Color3.fromRGB(20, 17, 10)
	info.Text = string.format("%s v%.1f\nOwner: %s\nKeyless • Mobile • Delta\nAuthorized testing only.", PRODUCT_NAME, SCRIPT_VERSION, OWNER_NAME)
	info.TextColor3 = Color3.fromRGB(180, 165, 130)
	info.Font = Enum.Font.Gotham
	info.TextSize = 11
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.Parent = miscPage
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = info
		local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 14); p.PaddingTop = UDim.new(0, 10); p.Parent = info
	end

	-- ============================================================
	-- DRAG + INTERACTION
	-- ============================================================
	local function makeDraggable(obj, handle)
		local dragging, dragStart, startPos = false, nil, nil
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = input.Position; startPos = obj.Position
			end
		end)
		handle.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragStart
				obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end
	makeDraggable(main, titleBar)

	do
		local ds, sp, moved = nil, nil, false
		floatBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				ds = input.Position; sp = floatBtn.Position; moved = false
			end
		end)
		floatBtn.InputChanged:Connect(function(input)
			if ds and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - ds
				if d.Magnitude > 6 then
					moved = true
					floatBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
				end
			end
		end)
		floatBtn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if not moved then
					main.Visible = not main.Visible
					if main.Visible then
						main.Size = UDim2.fromOffset(360, 520)
						pcall(function()
							tweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
								Size = UDim2.fromOffset(360, 520),
							}):Play()
						end)
					end
				end
				ds = nil
			end
		end)
	end

	minBtn.MouseButton1Click:Connect(function()
		state.minimized = not state.minimized
		pageContainer.Visible = not state.minimized
		tabBar.Visible = not state.minimized
		main.Size = state.minimized and UDim2.fromOffset(360, 52) or UDim2.fromOffset(360, 520)
	end)

	closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

	-- Mobile aim button.
	local aimBtn = Instance.new("TextButton")
	aimBtn.Size = UDim2.fromOffset(84, 84)
	aimBtn.Position = UDim2.new(1, -110, 1, -190)
	aimBtn.BackgroundColor3 = GOLD_DARK
	aimBtn.BackgroundTransparency = 0.2
	aimBtn.Text = "AIM"
	aimBtn.TextColor3 = GOLD_LIGHT
	aimBtn.Font = Enum.Font.GothamBold
	aimBtn.TextSize = 16
	aimBtn.AutoButtonColor = false
	aimBtn.Active = true
	aimBtn.Visible = false
	aimBtn.Parent = screenGui
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 42); c.Parent = aimBtn
		local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.3; s.Parent = aimBtn
	end
	if userInputService.TouchEnabled then aimBtn.Visible = true end

	do
		local ds, sp, moved = nil, nil, false
		aimBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				ds = input.Position; sp = aimBtn.Position; moved = false
			end
		end)
		aimBtn.InputChanged:Connect(function(input)
			if ds and input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - ds
				if d.Magnitude > 8 then
					moved = true
					aimBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
				end
			end
		end)
		aimBtn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				if not moved then
					state.aiming = not state.aiming
					aimBtn.BackgroundColor3 = state.aiming and Color3.fromRGB(170, 45, 45) or GOLD_DARK
				end
				ds = nil
			end
		end)
	end

	-- ============================================================
	-- DRAWINGS
	-- ============================================================
	local fovCircle = Drawing.new("Circle")
	fovCircle.Thickness = 1
	fovCircle.Color = GOLD_LIGHT
	fovCircle.Transparency = 0.6
	fovCircle.Filled = false
	fovCircle.NumSides = 64
	fovCircle.Visible = false

	local espObjects = {}
	local function createESP(player)
		espObjects[player] = {
			box = Drawing.new("Square"),
			name = Drawing.new("Text"),
			distance = Drawing.new("Text"),
			healthBg = Drawing.new("Square"),
			healthFg = Drawing.new("Square"),
			lines = {
				head = Drawing.new("Line"), torso = Drawing.new("Line"),
				lArm = Drawing.new("Line"), rArm = Drawing.new("Line"),
				lLeg = Drawing.new("Line"), rLeg = Drawing.new("Line"),
			},
		}
		local o = espObjects[player]
		o.box.Thickness = 1
		o.name.Size = 14; o.name.Center = true; o.name.Outline = true; o.name.Font = Drawing.Fonts.Plex
		o.distance.Size = 12; o.distance.Center = true; o.distance.Outline = true; o.distance.Font = Drawing.Fonts.Plex
		o.healthBg.Filled = true
		o.healthFg.Filled = true
		for _, l in pairs(o.lines) do l.Thickness = 1 end
	end
	local function removeESP(player)
		local o = espObjects[player]
		if not o then return end
		pcall(function() o.box:Remove() end)
		pcall(function() o.name:Remove() end)
		pcall(function() o.distance:Remove() end)
		pcall(function() o.healthBg:Remove() end)
		pcall(function() o.healthFg:Remove() end)
		for _, l in pairs(o.lines) do pcall(function() l:Remove() end) end
		espObjects[player] = nil
	end
	for _, p in ipairs(playersService:GetPlayers()) do createESP(p) end
	playersService.PlayerAdded:Connect(createESP)
	playersService.PlayerRemoving:Connect(removeESP)

	-- ============================================================
	-- LOGIC
	-- ============================================================
	local function isSameTeam(p)
		if not state.teamCheck then return false end
		if not p.Team or not localPlayer.Team then return false end
		return p.Team == localPlayer.Team
	end

	local function isVisible(part)
		if not state.visCheck then return true end
		local origin = currentCamera.CFrame.Position
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { localPlayer.Character, part.Parent }
		return workspace:Raycast(origin, part.Position - origin, params) == nil
	end

	local function getAimTarget()
		local origin = userInputService.TouchEnabled and currentCamera.ViewportSize / 2
			or Vector2.new(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
		local best, bestDist = nil, math.huge
		for _, player in ipairs(playersService:GetPlayers()) do
			if player == localPlayer then continue end
			if isSameTeam(player) then continue end
			local char = player.Character
			if not char then continue end
			local targetPart = state.targetPart == "Head" and char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if not (targetPart and humanoid and humanoid.Health > 0) then continue end
			if (currentCamera.CFrame.Position - targetPart.Position).Magnitude > state.aimDistance then continue end
			local sp, onScreen = currentCamera:WorldToViewportPoint(targetPart.Position)
			if not onScreen then continue end
			local sd = (Vector2.new(sp.X, sp.Y) - origin).Magnitude
			if sd <= state.fovSize and sd < bestDist and isVisible(targetPart) then
				best, bestDist = targetPart, sd
			end
		end
		return best
	end

	local defaultLighting = {
		Brightness = lighting.Brightness,
		GlobalShadows = lighting.GlobalShadows,
		EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
	}
	local function applyFPSBoost(on)
		lighting.GlobalShadows = not on and defaultLighting.GlobalShadows or false
		if on then
			lighting.Brightness = 0.8
			lighting.EnvironmentDiffuseScale = 0
			lighting.EnvironmentSpecularScale = 0
		end
	end
	local function applyLowGraphics(on)
		for _, inst in ipairs(lighting:GetChildren()) do
			if inst:IsA("PostEffect") then inst.Enabled = not on end
		end
	end
	local function restoreGraphics()
		lighting.Brightness = defaultLighting.Brightness
		lighting.GlobalShadows = defaultLighting.GlobalShadows
		lighting.EnvironmentDiffuseScale = defaultLighting.EnvironmentDiffuseScale
		lighting.EnvironmentSpecularScale = defaultLighting.EnvironmentSpecularScale
		for _, inst in ipairs(lighting:GetChildren()) do
			if inst:IsA("PostEffect") then inst.Enabled = true end
		end
		state.fpsBoost = false; state.lowGraphics = false
	end
	createButton(perfPage, "Restore Default Graphics", Color3.fromRGB(170, 45, 45), restoreGraphics)

	-- Render loop.
	local frameCount, lastSecond, currentFps = 0, tick(), 0
	local renderConn = runService.RenderStepped:Connect(function()
		if criticalShutdown then return end
		frameCount += 1
		if tick() - lastSecond >= 1 then currentFps = frameCount; frameCount = 0; lastSecond = tick() end

		if state.fovEnabled and state.aimEnabled then
			fovCircle.Position = currentCamera.ViewportSize / 2
			fovCircle.Radius = state.fovSize
			fovCircle.Visible = true
		else fovCircle.Visible = false end

		if state.aimEnabled and state.aiming then
			local target = getAimTarget()
			if target then
				local desired = CFrame.new(currentCamera.CFrame.Position, target.Position)
				local smoothFactor = 1 - math.clamp(state.aimSmooth, 0.01, 1) + state.aimStrength * 0.15
				currentCamera.CFrame = currentCamera.CFrame:Lerp(desired, math.clamp(smoothFactor, 0.02, 1))
			end
		end

		if state.fpsBoost then applyFPSBoost(true) end
		if state.lowGraphics then applyLowGraphics(true) end

		local espColor = Color3.fromRGB(state.espColor[1], state.espColor[2], state.espColor[3])
		for player, o in pairs(espObjects) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			local hidden = not state.espEnabled or not char or not hrp or not humanoid or humanoid.Health <= 0
				or (state.espTeamCheck and isSameTeam(player))
			if hidden then
				o.box.Visible = false; o.name.Visible = false; o.distance.Visible = false
				o.healthBg.Visible = false; o.healthFg.Visible = false
				for _, l in pairs(o.lines) do l.Visible = false end
				continue
			end
			local hrpPos, onScreen = currentCamera:WorldToViewportPoint(hrp.Position)
			local headPos = currentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 1.5, 0))
			local feetPos = currentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
			if not onScreen then
				o.box.Visible = false; o.name.Visible = false; o.distance.Visible = false
				o.healthBg.Visible = false; o.healthFg.Visible = false
				for _, l in pairs(o.lines) do l.Visible = false end
				continue
			end
			local sPos = Vector2.new(hrpPos.X, hrpPos.Y)
			local sHead = Vector2.new(headPos.X, headPos.Y)
			local sFeet = Vector2.new(feetPos.X, feetPos.Y)
			local h = math.abs(sFeet.Y - sHead.Y)
			local w = h * 0.5
			local bPos = Vector2.new(sPos.X - w / 2, sHead.Y)

			if state.espBox then
				o.box.Size = Vector2.new(w, h); o.box.Position = bPos
				o.box.Color = espColor; o.box.Visible = true
			else o.box.Visible = false end
			if state.espName then
				o.name.Text = player.Name
				o.name.Position = Vector2.new(sPos.X, sHead.Y - 18)
				o.name.Color = espColor; o.name.Visible = true
			else o.name.Visible = false end
			if state.espDistance then
				local dist = math.floor((currentCamera.CFrame.Position - hrp.Position).Magnitude)
				o.distance.Text = dist .. "m"
				o.distance.Position = Vector2.new(sPos.X, sFeet.Y + 4)
				o.distance.Color = espColor; o.distance.Visible = true
			else o.distance.Visible = false end
			if state.espHealth then
				local hp = humanoid.Health / math.max(humanoid.MaxHealth, 1)
				o.healthBg.Size = Vector2.new(3, h); o.healthBg.Position = Vector2.new(bPos.X - 7, bPos.Y)
				o.healthBg.Color = Color3.fromRGB(20, 20, 20); o.healthBg.Visible = true
				o.healthFg.Size = Vector2.new(3, h * hp)
				o.healthFg.Position = Vector2.new(bPos.X - 7, bPos.Y + h * (1 - hp))
				o.healthFg.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0); o.healthFg.Visible = true
			else o.healthBg.Visible = false; o.healthFg.Visible = false end

			if state.espSkeleton then
				local function w2s(n)
					local p = char:FindFirstChild(n)
					if not p then return nil end
					local sp, on = currentCamera:WorldToViewportPoint(p.Position)
					if not on then return nil end
					return Vector2.new(sp.X, sp.Y)
				end
				local head = w2s("Head")
				local uT = w2s("UpperTorso") or w2s("Torso")
				local lT = w2s("LowerTorso")
				local lH = w2s("LeftHand") or w2s("Left Arm")
				local rH = w2s("RightHand") or w2s("Right Arm")
				local lF = w2s("LeftFoot") or w2s("Left Leg")
				local rF = w2s("RightFoot") or w2s("Right Leg")
				local function dl(line, a, b)
					if a and b then line.From = a; line.To = b; line.Color = espColor; line.Visible = true
					else line.Visible = false end
				end
				dl(o.lines.head, head, uT); dl(o.lines.torso, uT, lT or uT)
				dl(o.lines.lArm, uT, lH); dl(o.lines.rArm, uT, rH)
				dl(o.lines.lLeg, lT or uT, lF); dl(o.lines.rLeg, lT or uT, rF)
			else
				for _, l in pairs(o.lines) do l.Visible = false end
			end
		end

		if state.fpsMonitor or state.pingMonitor then
			local pt = "--"
			if state.pingMonitor then
				local ok, ping = pcall(function()
					return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
				end)
				if ok and ping then pt = math.floor(ping) .. "ms" end
			end
			perfLabel.Text = string.format("FPS: %s\nPing: %s",
				state.fpsMonitor and tostring(currentFps) or "--", pt)
		end
	end)

	-- Weapon loop.
	task.spawn(function()
		while screenGui.Parent and not criticalShutdown do
			task.wait(0.5)
			local char = localPlayer.Character
			local tool = char and char:FindFirstChildOfClass("Tool")
			if tool then
				weaponInfo.Text = string.format("Weapon: %s\nAmmo: N/A\nStatus: Equipped", tool.Name)
			else
				weaponInfo.Text = "Weapon: N/A\nAmmo: N/A\nStatus: Idle"
			end
		end
	end)

	-- Save loop.
	task.spawn(function()
		while screenGui.Parent and not criticalShutdown do
			task.wait(5)
			saveSettings({
				aimEnabled = state.aimEnabled, aimStrength = state.aimStrength,
				fovEnabled = state.fovEnabled, fovSize = state.fovSize,
				targetPart = state.targetPart, teamCheck = state.teamCheck,
				visCheck = state.visCheck, aimSmooth = state.aimSmooth, aimDistance = state.aimDistance,
				espEnabled = state.espEnabled, espBox = state.espBox, espSkeleton = state.espSkeleton,
				espName = state.espName, espHealth = state.espHealth, espDistance = state.espDistance,
				espTeamCheck = state.espTeamCheck, espColor = state.espColor,
				fpsBoost = state.fpsBoost, lowGraphics = state.lowGraphics, uiColor = state.uiColor,
				premiumAimPrediction = state.premiumAimPrediction,
				premiumStreamerMode = state.premiumStreamerMode,
				premiumAutoDetect = state.premiumAutoDetect,
			})
		end
	end)

	local function cleanup()
		pcall(function() renderConn:Disconnect() end)
		pcall(function() screenGui:Destroy() end)
		pcall(function() fovCircle:Remove() end)
		for p in pairs(espObjects) do removeESP(p) end
		pcall(restoreGraphics)
	end

	return { cleanup = cleanup, setStatus = setStatus }
end

-- ============================================================
-- LOAD → AUTO LAUNCH
-- ============================================================
setLoadingProgress(0.6, "Loading premium modules...")
task.wait(0.2)

local ok, uiRef = pcall(buildUI)
if not ok then
	logError("buildUI", uiRef)
	setLoadingProgress(1, "Build failed.")
	triggerCriticalShutdown("UI build failed: " .. tostring(uiRef))
else
	setLoadingProgress(0.9, "Finalizing premium...")
	task.wait(0.15)
	setLoadingProgress(1, "Premium ready!")

	if uiRef and uiRef.setStatus then
		uiRef.setStatus("PREMIUM • " .. executorName, true)
	end

	-- Fade out.
	tweenService:Create(loadingFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	for _, ch in ipairs(loadingFrame:GetDescendants()) do
		if ch:IsA("TextLabel") then
			pcall(function() tweenService:Create(ch, TweenInfo.new(0.3), { TextTransparency = 1 }):Play() end)
		elseif ch:IsA("Frame") then
			pcall(function() tweenService:Create(ch, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play() end)
		elseif ch:IsA("UIStroke") then
			pcall(function() tweenService:Create(ch, TweenInfo.new(0.3), { Transparency = 1 }):Play() end)
		end
	end
	task.wait(0.35)
	pcall(function() loadingGui:Destroy() end)

	shared[INIT_KEY] = {
		cleanup = function()
			if uiRef and uiRef.cleanup then pcall(uiRef.cleanup) end
		end,
		active = true,
	}
end

warn(string.format("[ZENO HUB PREMIUM] v%.1f | Owner %s | Keyless | Executor %s", SCRIPT_VERSION, OWNER_NAME, executorName))
