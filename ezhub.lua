-- Services.
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local currentCamera = workspace.CurrentCamera
local localPlayer = playersService.LocalPlayer

-- State.
local state = {
	esp = false,
	tracers = false,
	boxes = false,
	names = false,
	health = false,
	highlight = false,
	aimbot = false,
	silentAim = false,
	noRecoil = false,
	smoothness = 0.25,
	fovRadius = 150,
	showFov = true,
	tracerMode = "Bottom",
	tracerColor = Color3.fromRGB(255, 255, 255),
	aimKey = Enum.UserInputType.MouseButton2,
	aiming = false,
}

-- Drawing helpers.
local function newDrawing(class, props)
	local obj = Drawing.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	return obj
end

-- UI.
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UrbanReload"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = (gethui and gethui()) or coreGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(520, 380)
main.Position = UDim2.new(0.5, -260, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 70)
mainStroke.Thickness = 1
mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
title.BorderSizePixel = 0
title.Text = "  URBAN RELOAD"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = title

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.fromOffset(10, 50)
content.BackgroundTransparency = 1
content.Parent = main

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(0, 120, 1, 0)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
tabBar.BorderSizePixel = 0
tabBar.Parent = content

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 8)
tabBarCorner.Parent = tabBar

local tabList = Instance.new("UIListLayout")
tabList.Padding = UDim.new(0, 4)
tabList.Parent = tabBar

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 8)
tabPadding.PaddingLeft = UDim.new(0, 6)
tabPadding.PaddingRight = UDim.new(0, 6)
tabPadding.Parent = tabBar

local pages = {}
local tabButtons = {}

local pageContainer = Instance.new("Frame")
pageContainer.Size = UDim2.new(1, -130, 1, 0)
pageContainer.Position = UDim2.fromOffset(130, 0)
pageContainer.BackgroundTransparency = 1
pageContainer.Parent = content

local function createTab(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(200, 200, 210)
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 13
	btn.Parent = tabBar

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = pageContainer

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.Parent = page

	table.insert(pages, page)
	table.insert(tabButtons, btn)

	btn.MouseButton1Click:Connect(function()
		for _, p in ipairs(pages) do p.Visible = false end
		for _, b in ipairs(tabButtons) do
			b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
			b.TextColor3 = Color3.fromRGB(200, 200, 210)
		end
		page.Visible = true
		btn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)

	return page
end

local espPage = createTab("ESP")
local aimPage = createTab("Aimbot")
local settingsPage = createTab("Settings")

tabButtons[1].BackgroundColor3 = Color3.fromRGB(50, 90, 160)
tabButtons[1].TextColor3 = Color3.fromRGB(255, 255, 255)
pages[1].Visible = true

local function createToggle(parent, text, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	row.Parent = parent

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Position = UDim2.fromOffset(12, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(44, 22)
	btn.Position = UDim2.new(1, -56, 0.5, -11)
	btn.BackgroundColor3 = default and Color3.fromRGB(50, 140, 90) or Color3.fromRGB(60, 60, 70)
	btn.Text = default and "ON" or "OFF"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = row

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 11)
	bc.Parent = btn

	local enabled = default
	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		btn.BackgroundColor3 = enabled and Color3.fromRGB(50, 140, 90) or Color3.fromRGB(60, 60, 70)
		btn.Text = enabled and "ON" or "OFF"
		callback(enabled)
	end)

	return row
end

local function createSlider(parent, text, min, max, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	row.Parent = parent

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 20)
	label.Position = UDim2.fromOffset(12, 6)
	label.BackgroundTransparency = 1
	label.Text = text .. ": " .. tostring(default)
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 6)
	bar.Position = UDim2.new(0, 12, 0, 34)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	bar.Parent = row

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 3)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(80, 130, 220)
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = fill

	local value = default
	local dragging = false

	local function update(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		value = min + (max - min) * rel
		fill.Size = UDim2.new(rel, 0, 1, 0)
		label.Text = text .. ": " .. string.format("%.2f", value)
		callback(value)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input.Position.X)
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

local function createDropdown(parent, text, options, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	row.Parent = parent

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -110, 1, 0)
	label.Position = UDim2.fromOffset(12, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local cycleBtn = Instance.new("TextButton")
	cycleBtn.Size = UDim2.fromOffset(90, 22)
	cycleBtn.Position = UDim2.new(1, -102, 0.5, -11)
	cycleBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
	cycleBtn.Text = default
	cycleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cycleBtn.Font = Enum.Font.GothamBold
	cycleBtn.TextSize = 11
	cycleBtn.Parent = row

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = cycleBtn

	local idx = 1
	for i, v in ipairs(options) do
		if v == default then idx = i break end
	end

	cycleBtn.MouseButton1Click:Connect(function()
		idx = idx % #options + 1
		cycleBtn.Text = options[idx]
		callback(options[idx])
	end)

	return row
end

local function createColorPicker(parent, text, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	row.Parent = parent

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 6)
	rc.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Position = UDim2.fromOffset(12, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local preview = Instance.new("Frame")
	preview.Size = UDim2.fromOffset(44, 22)
	preview.Position = UDim2.new(1, -56, 0.5, -11)
	preview.BackgroundColor3 = default
	preview.BorderSizePixel = 0
	preview.Parent = row

	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 6)
	pc.Parent = preview

	preview.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local colors = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(255, 80, 80),
				Color3.fromRGB(80, 200, 255),
				Color3.fromRGB(120, 255, 120),
				Color3.fromRGB(255, 255, 80),
				Color3.fromRGB(255, 100, 255),
				Color3.fromRGB(255, 160, 40),
			}
			local cur = 1
			for i, c in ipairs(colors) do
				if c == preview.BackgroundColor3 then cur = i break end
			end
			cur = cur % #colors + 1
			preview.BackgroundColor3 = colors[cur]
			callback(colors[cur])
		end
	end)

	return row
end

-- ESP page.
createToggle(espPage, "ESP Enabled", false, function(v) state.esp = v end)
createToggle(espPage, "Tracers", false, function(v) state.tracers = v end)
createToggle(espPage, "Boxes", false, function(v) state.boxes = v end)
createToggle(espPage, "Names", false, function(v) state.names = v end)
createToggle(espPage, "Health Bar", false, function(v) state.health = v end)
createToggle(espPage, "Highlight", false, function(v) state.highlight = v end)
createDropdown(espPage, "Tracer Origin", {"Bottom", "Top", "Center"}, "Bottom", function(v) state.tracerMode = v end)
createColorPicker(espPage, "Tracer Color", Color3.fromRGB(255, 255, 255), function(c) state.tracerColor = c end)

-- Aimbot page.
createToggle(aimPage, "Aimbot Enabled", false, function(v) state.aimbot = v end)
createToggle(aimPage, "Silent Aim", false, function(v) state.silentAim = v end)
createToggle(aimPage, "No Recoil", false, function(v) state.noRecoil = v end)
createToggle(aimPage, "Show FOV Circle", true, function(v) state.showFov = v end)
createSlider(aimPage, "Smoothness", 0.05, 1, 0.25, function(v) state.smoothness = v end)
createSlider(aimPage, "FOV Radius", 50, 500, 150, function(v) state.fovRadius = v end)

-- Settings page.
local keyRow = Instance.new("Frame")
keyRow.Size = UDim2.new(1, 0, 0, 34)
keyRow.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
keyRow.Parent = settingsPage

local keyRowCorner = Instance.new("UICorner")
keyRowCorner.CornerRadius = UDim.new(0, 6)
keyRowCorner.Parent = keyRow

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(1, -20, 1, 0)
keyLabel.Position = UDim2.fromOffset(12, 0)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "Aimbot Key: Right Mouse"
keyLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
keyLabel.Font = Enum.Font.Gotham
keyLabel.TextSize = 13
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.Parent = keyRow

local keyBtn = Instance.new("TextButton")
keyBtn.Size = UDim2.fromOffset(90, 22)
keyBtn.Position = UDim2.new(1, -102, 0.5, -11)
keyBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
keyBtn.Text = "Rebind"
keyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBtn.Font = Enum.Font.GothamBold
keyBtn.TextSize = 11
keyBtn.Parent = keyRow

local keyBtnCorner = Instance.new("UICorner")
keyBtnCorner.CornerRadius = UDim.new(0, 6)
keyBtnCorner.Parent = keyBtn

local waitingForBind = false
keyBtn.MouseButton1Click:Connect(function()
	waitingForBind = true
	keyBtn.Text = "Press key..."
end)

-- Mobile AIM button (fixed: proper touch hold).
local touchBtn = Instance.new("TextButton")
touchBtn.Size = UDim2.fromOffset(80, 80)
touchBtn.Position = UDim2.new(1, -110, 1, -160)
touchBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
touchBtn.BackgroundTransparency = 0.35
touchBtn.Text = "AIM"
touchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
touchBtn.Font = Enum.Font.GothamBold
touchBtn.TextSize = 16
touchBtn.Active = true
touchBtn.Parent = screenGui

local touchBtnCorner = Instance.new("UICorner")
touchBtnCorner.CornerRadius = UDim.new(0, 40)
touchBtnCorner.Parent = touchBtn

local touchStroke = Instance.new("UIStroke")
touchStroke.Color = Color3.fromRGB(255, 255, 255)
touchStroke.Thickness = 2
touchStroke.Transparency = 0.5
touchStroke.Parent = touchBtn

-- Manual drag for mobile (Draggable unreliable on touch).
local dragStart, startPos = nil, nil
touchBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		state.aiming = true
		touchBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		dragStart = input.Position
		startPos = touchBtn.Position
	end
end)

touchBtn.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch and dragStart then
		local delta = input.Position - dragStart
		if delta.Magnitude > 8 then
			-- It's a drag, cancel aiming.
			state.aiming = false
			touchBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
			touchBtn.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end
end)

touchBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		state.aiming = false
		touchBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
		dragStart = nil
	end
end)

-- FOV circle drawing.
local fovCircle = newDrawing("Circle", {
	Thickness = 1,
	Color = Color3.fromRGB(255, 255, 255),
	Transparency = 0.6,
	Visible = false,
	Filled = false,
	NumSides = 64,
})

-- ESP objects.
local espObjects = {}
local highlightMap = {}

local function createESP(player)
	local objs = {
		tracer = newDrawing("Line", {Thickness = 1, Color = state.tracerColor, Transparency = 1, Visible = false}),
		box = newDrawing("Square", {Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Visible = false}),
		name = newDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Visible = false, Font = Drawing.Fonts.Plex}),
		healthBg = newDrawing("Square", {Thickness = 0, Color = Color3.fromRGB(0, 0, 0), Transparency = 1, Visible = false, Filled = true}),
		healthFg = newDrawing("Square", {Thickness = 0, Color = Color3.fromRGB(0, 255, 100), Transparency = 1, Visible = false, Filled = true}),
	}
	espObjects[player] = objs
end

local function removeESP(player)
	local objs = espObjects[player]
	if objs then
		for _, o in pairs(objs) do pcall(function() o:Remove() end) end
		espObjects[player] = nil
	end
	local h = highlightMap[player]
	if h then
		pcall(function() h:Destroy() end)
		highlightMap[player] = nil
	end
end

local function updateHighlight(player)
	if not state.highlight or player == localPlayer then
		if highlightMap[player] then
			pcall(function() highlightMap[player]:Destroy() end)
			highlightMap[player] = nil
		end
		return
	end
	local character = player.Character
	if not character then return end
	if highlightMap[player] then return end
	local hl = Instance.new("Highlight")
	hl.Name = "UrbanReloadHL"
	hl.FillColor = Color3.fromRGB(255, 80, 80)
	hl.FillTransparency = 0.5
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.Parent = character
	highlightMap[player] = hl
end

for _, player in ipairs(playersService:GetPlayers()) do
	createESP(player)
end

playersService.PlayerAdded:Connect(createESP)
playersService.PlayerRemoving:Connect(removeESP)

-- Silent aim hook (namecall redirect on FireServer / Raycast).
-- Placeholder hook: game-specific. Skipped in generic build.
local function enableSilentAim()
	-- Silent aim requires game-specific raycast/remote hooks.
	-- Generic fallback: no-op.
end

-- Close.
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
	for player, objs in pairs(espObjects) do
		for _, o in pairs(objs) do pcall(function() o:Remove() end) end
	end
	for _, h in pairs(highlightMap) do pcall(function() h:Destroy() end) end
	pcall(function() fovCircle:Remove() end)
end)

-- Input.
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if waitingForBind and not gameProcessed then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			state.aimKey = input.UserInputType
			keyLabel.Text = "Aimbot Key: " .. (input.UserInputType == Enum.UserInputType.MouseButton2 and "Right Mouse" or "Left Mouse")
			keyBtn.Text = "Rebind"
			waitingForBind = false
		elseif input.KeyCode ~= Enum.KeyCode.Unknown then
			state.aimKey = input.KeyCode
			keyLabel.Text = "Aimbot Key: " .. input.KeyCode.Name
			keyBtn.Text = "Rebind"
			waitingForBind = false
		end
		return
	end
	if gameProcessed then return end
	if state.aimKey and (input.UserInputType == state.aimKey or input.KeyCode == state.aimKey) then
		state.aiming = true
	end
end)

userInputService.InputEnded:Connect(function(input)
	if state.aimKey and (input.UserInputType == state.aimKey or input.KeyCode == state.aimKey) then
		state.aiming = false
	end
end)

-- Render loop.
runService.RenderStepped:Connect(function()
	-- FOV circle centered on viewport (screen center), not mouse.
	if state.aimbot and state.showFov then
		fovCircle.Position = currentCamera.ViewportSize / 2
		fovCircle.Radius = state.fovRadius
		fovCircle.Visible = true
	else
		fovCircle.Visible = false
	end

	-- Aimbot: use viewport center for mobile, mouse for desktop.
	if state.aimbot and state.aiming then
		local isMobile = userInputService.TouchEnabled and not userInputService.KeyboardEnabled
		local origin = isMobile and (currentCamera.ViewportSize / 2)
			or Vector2.new(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)

		local closest, closestDist = nil, math.huge
		for _, player in ipairs(playersService:GetPlayers()) do
			if player == localPlayer then continue end
			local character = player.Character
			if not character then continue end
			local hrp = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChild("Humanoid")
			if not (hrp and humanoid and humanoid.Health > 0) then continue end
			local screenPos, onScreen = currentCamera:WorldToViewportPoint(hrp.Position)
			if not onScreen then continue end
			local dist = (Vector2.new(screenPos.X, screenPos.Y) - origin).Magnitude
			if dist <= state.fovRadius and dist < closestDist then
				closest = hrp
				closestDist = dist
			end
		end

		if closest then
			local desired = CFrame.new(currentCamera.CFrame.Position, closest.Position)
			currentCamera.CFrame = currentCamera.CFrame:Lerp(desired, state.smoothness)
		end
	end

	-- No Recoil placeholder.
	if state.noRecoil then
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then end
	end

	-- ESP rendering.
	for player, objs in pairs(espObjects) do
		objs.tracer.Color = state.tracerColor

		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChild("Humanoid")

		if not state.esp or not hrp or not humanoid or humanoid.Health <= 0 then
			objs.tracer.Visible = false
			objs.box.Visible = false
			objs.name.Visible = false
			objs.healthBg.Visible = false
			objs.healthFg.Visible = false
			continue
		end

		local hrpPos, onScreen = currentCamera:WorldToViewportPoint(hrp.Position)
		local headPos = currentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 1.5, 0))
		local feetPos = currentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

		if not onScreen then
			objs.tracer.Visible = false
			objs.box.Visible = false
			objs.name.Visible = false
			objs.healthBg.Visible = false
			objs.healthFg.Visible = false
			continue
		end

		local screenPos = Vector2.new(hrpPos.X, hrpPos.Y)
		local screenHead = Vector2.new(headPos.X, headPos.Y)
		local screenFeet = Vector2.new(feetPos.X, feetPos.Y)

		local height = math.abs(screenFeet.Y - screenHead.Y)
		local width = height * 0.5
		local boxPos = Vector2.new(screenPos.X - width / 2, screenHead.Y)

		-- Tracer with selectable origin.
		if state.tracers then
			local origin
			if state.tracerMode == "Top" then
				origin = Vector2.new(currentCamera.ViewportSize.X / 2, 0)
			elseif state.tracerMode == "Center" then
				origin = currentCamera.ViewportSize / 2
			else
				origin = Vector2.new(currentCamera.ViewportSize.X / 2, currentCamera.ViewportSize.Y)
			end
			objs.tracer.From = origin
			objs.tracer.To = screenPos
			objs.tracer.Visible = true
		else
			objs.tracer.Visible = false
		end

		if state.boxes then
			objs.box.Size = Vector2.new(width, height)
			objs.box.Position = boxPos
			objs.box.Visible = true
		else
			objs.box.Visible = false
		end

		if state.names then
			objs.name.Text = player.Name
			objs.name.Position = Vector2.new(screenPos.X, screenHead.Y - 16)
			objs.name.Visible = true
		else
			objs.name.Visible = false
		end

		if state.health then
			local hp = humanoid.Health / humanoid.MaxHealth
			local barH = height
			objs.healthBg.Size = Vector2.new(3, barH)
			objs.healthBg.Position = Vector2.new(boxPos.X - 7, boxPos.Y)
			objs.healthBg.Visible = true
			objs.healthFg.Size = Vector2.new(3, barH * hp)
			objs.healthFg.Position = Vector2.new(boxPos.X - 7, boxPos.Y + barH * (1 - hp))
			objs.healthFg.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
			objs.healthFg.Visible = true
		else
			objs.healthBg.Visible = false
			objs.healthFg.Visible = false
		end

		updateHighlight(player)
	end
end)
