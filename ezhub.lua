-- ez_hub_v2_full.lua
-- EZ HUB v2 — Complete, untruncated, FOV circle + color picker

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local hasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")
local hasHookFn = (typeof(hookfunction) == "function")
local hasGetRaw = (typeof(getrawmetatable) == "function")
local hasNewCClosure = (typeof(newcclosure) == "function")

local function log(msg) print("[EZ] " .. tostring(msg)) end
local function warn_(msg) warn("[EZ] " .. tostring(msg)) end
local function safe(name, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn_("FAIL " .. name .. ": " .. tostring(err)) end
    return ok
end

log("Drawing=" .. tostring(hasDrawing) .. " hookfn=" .. tostring(hasHookFn))

-- ================= CONFIG =================
local Config = {
    AimEnabled = false, AimSmoothness = 8, AimFOV = 150,
    AimMaxDist = 500, AimPart = "Head", AimTeamCheck = true,
    AimWallCheck = false, AimHumanize = true,
    ESPEnabled = false, ESPBox = true, ESPName = true,
    ESPDistance = true, ESPHealth = true, ESPTeamCheck = true,
    FOVCircleEnabled = true,
    FOVCircleColor = Color3.fromRGB(255, 50, 50),
    LockIndicatorEnabled = true,
    LockIndicatorColor = Color3.fromRGB(100, 255, 100),
}

local VALID_KEYS = {"EZ-2024", "OLIVIA", "TATER"}

-- ================= SHADOW BYPASS =================
local bypass_active = false
local function init_bypass()
    safe("hook-analytics", function()
        if hasHookFn then
            local A = game:GetService("AnalyticsService")
            if A and A.FireEvent then hookfunction(A.FireEvent, function() end) end
        end
    end)
    safe("hook-namecall", function()
        if not hasGetRaw or not hasNewCClosure then return end
        local mt = getrawmetatable(game)
        if not mt then return end
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if not checkcaller() and (m == "Kick" or m == "FireServer") then
                local s = tostring(self)
                if s:find("AntiCheat") or s:find("Ban") or s:find("Shadow") or s:find("Report") then return end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
    safe("fflag", function()
        if typeof(setfflag) == "function" then pcall(setfflag, "FFlagDisableTelemetry", true) end
    end)
    bypass_active = true
    log("bypass done")
end
init_bypass()

-- ================= DRAWINGS =================
local Drawings = {}
local FOVCircle = nil
local LockIndicator = nil
local espSquareClass = "Square"

local function createDrawing(class, props)
    if not hasDrawing then return nil end
    local ok, d = pcall(function()
        local obj = Drawing.new(class)
        for k, v in pairs(props) do obj[k] = v end
        return obj
    end)
    if ok then return d end
    return nil
end

safe("detect-square", function()
    local test = Drawing.new("Square")
    if not test then espSquareClass = "Rectangle" end
    if test then test:Remove() end
end)

local function initFOVCircle()
    if not hasDrawing then return end
    if FOVCircle then safe("rm-fov", function() FOVCircle:Remove() end) end
    FOVCircle = createDrawing("Circle", {
        Color = Config.FOVCircleColor, Thickness = 1.5, Filled = false,
        NumSides = 64, Visible = Config.FOVCircleEnabled,
        Radius = Config.AimFOV, Position = Camera.ViewportSize / 2,
    })
    log("FOV circle: " .. tostring(FOVCircle ~= nil))
end

local function initLockIndicator()
    if not hasDrawing then return end
    if LockIndicator then safe("rm-lock", function() LockIndicator:Remove() end) end
    LockIndicator = createDrawing("Circle", {
        Color = Config.LockIndicatorColor, Thickness = 2, Filled = false,
        NumSides = 32, Radius = 6, Visible = false,
        Position = Camera.ViewportSize / 2,
    })
    log("Lock indicator: " .. tostring(LockIndicator ~= nil))
end

local function clearESP()
    for _, tbl in pairs(Drawings) do
        for _, d in pairs(tbl) do if d and d.Remove then safe("rm-esp", function() d:Remove() end) end end
    end
    Drawings = {}
end

-- ================= ESP =================
local function getESPData(plr)
    if plr == LocalPlayer or not plr.Character then return nil end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    local head = plr.Character:FindFirstChild("Head")
    if not hum or not root or not head or hum.Health <= 0 then return nil end
    if Config.ESPTeamCheck and plr.Team == LocalPlayer.Team then return nil end
    return hum, root, head
end

local function updateESP()
    if not hasDrawing then return end
    if not Config.ESPEnabled then
        if next(Drawings) then clearESP() end
        return
    end
    local activeNames = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local hum, root, head = getESPData(plr)
        if hum and root and head then
            activeNames[plr.Name] = true
            local tbl = Drawings[plr.Name]
            if not tbl then
                tbl = {}
                Drawings[plr.Name] = tbl
                if Config.ESPBox then
                    tbl.box = createDrawing(espSquareClass, {Thickness = 1, Color = Color3.fromRGB(255, 50, 50), Filled = false})
                    tbl.boxOutline = createDrawing(espSquareClass, {Thickness = 3, Color = Color3.fromRGB(0, 0, 0), Filled = false})
                end
                if Config.ESPName then tbl.name = createDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)}) end
                if Config.ESPDistance then tbl.dist = createDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(200, 200, 200)}) end
                if Config.ESPHealth then tbl.hpBar = createDrawing(espSquareClass, {Thickness = 2, Color = Color3.fromRGB(0, 255, 0), Filled = true}) end
            end
            local headPos = Camera:WorldToViewportPoint(head.Position)
            local rootPos = Camera:WorldToViewportPoint(root.Position)
            if headPos.Z > 0 and rootPos.Z > 0 then
                local height = math.abs(headPos.Y - rootPos.Y)
                local width = height / 2
                if tbl.box then
                    tbl.box.Size = Vector2.new(width, height)
                    tbl.box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
                    tbl.box.Visible = true
                end
                if tbl.boxOutline then
                    tbl.boxOutline.Size = Vector2.new(width + 2, height + 2)
                    tbl.boxOutline.Position = Vector2.new(headPos.X - width / 2 - 1, headPos.Y - 1)
                    tbl.boxOutline.Visible = true
                end
                if tbl.name then
                    tbl.name.Position = Vector2.new(headPos.X, headPos.Y - 16)
                    tbl.name.Text = plr.Name
                    tbl.name.Visible = true
                end
                if tbl.dist then
                    tbl.dist.Position = Vector2.new(headPos.X, headPos.Y + height + 4)
                    tbl.dist.Text = math.floor((root.Position - Camera.CFrame.Position).Magnitude) .. "m"
                    tbl.dist.Visible = true
                end
                if tbl.hpBar then
                    local pct = hum.Health / hum.MaxHealth
                    local barH = height * pct
                    tbl.hpBar.Size = Vector2.new(3, barH)
                    tbl.hpBar.Position = Vector2.new(headPos.X - width / 2 - 6, headPos.Y + (height - barH))
                    tbl.hpBar.Visible = true
                end
            else
                for _, d in pairs(tbl) do if d then d.Visible = false end end
            end
        end
    end
    for name, tbl in pairs(Drawings) do
        if not activeNames[name] then
            for _, d in pairs(tbl) do if d and d.Remove then safe("rm", function() d:Remove() end) end end
            Drawings[name] = nil
        end
    end
end

-- ================= AIM =================
local aimNoiseSeed = os.clock()
local function getClosestTarget()
    local closest, dist = nil, math.huge
    local camPos = Camera.CFrame.Position
    local center = Camera.ViewportSize / 2
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                if Config.AimTeamCheck and plr.Team == LocalPlayer.Team then continue end
                if (root.Position - camPos).Magnitude > Config.AimMaxDist then continue end
                local part = plr.Character:FindFirstChild(Config.AimPart) or root
                if part then
                    local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        if d <= Config.AimFOV and d < dist then
                            if Config.AimWallCheck then
                                local ray = Ray.new(camPos, part.Position - camPos)
                                local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                                if hit and hit:IsDescendantOf(plr.Character) then closest, dist = part, d end
                            else
                                closest, dist = part, d
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function humanizeTarget(targetPos)
    if not Config.AimHumanize then return targetPos end
    local t = (os.clock() - aimNoiseSeed)
    return targetPos + Vector3.new(math.sin(t * 3.1) * 0.15, math.cos(t * 2.7) * 0.15, math.sin(t * 4.3) * 0.1)
end

-- ================= UI =================
local gui, main, tabsContainer, contentContainer
local tabs = {}
local buildMain

local function buildUI()
    local parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    local old = parent:FindFirstChild("EZ_HUB_V2")
    if old then old:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "EZ_HUB_V2"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = parent
    log("GUI created")

    local keyFrame = Instance.new("Frame")
    keyFrame.Size = UDim2.new(0, 280, 0, 180)
    keyFrame.Position = UDim2.new(0.5, -140, 0.5, -90)
    keyFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    keyFrame.BorderSizePixel = 0
    keyFrame.Parent = gui
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 12); kc.Parent = keyFrame

    local kTitle = Instance.new("TextLabel")
    kTitle.Size = UDim2.new(1, 0, 0, 40)
    kTitle.BackgroundTransparency = 1
    kTitle.Text = "🔑 Enter Key"
    kTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    kTitle.Font = Enum.Font.GothamBold
    kTitle.TextSize = 16
    kTitle.Parent = keyFrame

    local kBox = Instance.new("TextBox")
    kBox.Size = UDim2.new(0, 220, 0, 35)
    kBox.Position = UDim2.new(0, 30, 0, 55)
    kBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    kBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    kBox.PlaceholderText = "EZ-2024"
    kBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    kBox.Font = Enum.Font.Gotham
    kBox.TextSize = 13
    kBox.Text = ""
    kBox.Parent = keyFrame
    local kbc = Instance.new("UICorner"); kbc.CornerRadius = UDim.new(0, 8); kbc.Parent = kBox

    local kErr = Instance.new("TextLabel")
    kErr.Size = UDim2.new(1, 0, 0, 20)
    kErr.Position = UDim2.new(0, 0, 0, 95)
    kErr.BackgroundTransparency = 1
    kErr.Text = ""
    kErr.TextColor3 = Color3.fromRGB(255, 80, 80)
    kErr.Font = Enum.Font.Gotham
    kErr.TextSize = 11
    kErr.Parent = keyFrame

    local kBtn = Instance.new("TextButton")
    kBtn.Size = UDim2.new(0, 220, 0, 35)
    kBtn.Position = UDim2.new(0, 30, 0, 125)
    kBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    kBtn.Text = "VERIFY"
    kBtn.TextColor3 = Color3.new(1, 1, 1)
    kBtn.Font = Enum.Font.GothamBold
    kBtn.TextSize = 14
    kBtn.Parent = keyFrame
    local kbc2 = Instance.new("UICorner"); kbc2.CornerRadius = UDim.new(0, 8); kbc2.Parent = kBtn

    kBtn.MouseButton1Click:Connect(function()
        local ok = false
        for _, k in ipairs(VALID_KEYS) do if kBox.Text == k then ok = true break end end
        if ok then
            safe("destroy-key", function() keyFrame:Destroy() end)
            safe("build-main", buildMain)
        else
            kErr.Text = "Invalid key, try again."
            kBox.Text = ""
        end
    end)
end

function buildMain()
    main = Instance.new("Frame")
    main.Size = UDim2.new(0, 340, 0, 460)
    main.Position = UDim2.new(0, 80, 0.5, -230)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = main
    log("Main frame built")

    local dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position; startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end)

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 38)
    titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    titleBar.Parent = main
    local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 12); tbc.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "EZ HUB v2"
    title.TextColor3 = Color3.fromRGB(220, 50, 50)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 24)
    minBtn.Position = UDim2.new(1, -70, 0, 7)
    minBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.new(0, 0, 0)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 12
    minBtn.Parent = titleBar
    local mbc = Instance.new("UICorner"); mbc.CornerRadius = UDim.new(0, 6); mbc.Parent = minBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 24)
    closeBtn.Position = UDim2.new(1, -38, 0, 7)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = titleBar
    local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 6); cbc.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

    local minimized = false
    local sizeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(main, sizeTweenInfo, {Size = UDim2.new(0, 340, 0, 38)}):Play()
            tabsContainer.Visible = false
            contentContainer.Visible = false
        else
            TweenService:Create(main, sizeTweenInfo, {Size = UDim2.new(0, 340, 0, 460)}):Play()
            tabsContainer.Visible = true
            contentContainer.Visible = true
        end
    end)

    tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, -20, 0, 30)
    tabsContainer.Position = UDim2.new(0, 10, 0, 45)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = main

    contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -20, 1, -85)
    contentContainer.Position = UDim2.new(0, 10, 0, 80)
    contentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = main
    local ccc = Instance.new("UICorner"); ccc.CornerRadius = UDim.new(0, 8); ccc.Parent = contentContainer

    local function switchTab(name)
        for tName, tBtn in pairs(tabs) do
            tBtn.BackgroundColor3 = (tName == name) and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(30, 30, 42)
            tBtn.TextColor3 = (tName == name) and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 150)
        end
        for _, child in ipairs(contentContainer:GetChildren()) do
            if child:IsA("ScrollingFrame") then child.Visible = (child.Name == name) end
        end
    end

    local tabNames = {"AIM", "ESP"}
    local tabWidth = (1 / #tabNames)
    for i, name in ipairs(tabNames) do
        local t = Instance.new("TextButton")
        t.Size = UDim2.new(tabWidth, -4, 1, 0)
        t.Position = UDim2.new(tabWidth * (i - 1), 2, 0, 0)
        t.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        t.Text = name
        t.TextColor3 = Color3.fromRGB(150, 150, 150)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 12
        t.Parent = tabsContainer
        local tc2 = Instance.new("UICorner"); tc2.CornerRadius = UDim.new(0, 6); tc2.Parent = t
        tabs[name] = t
        t.MouseButton1Click:Connect(function() switchTab(name) end)
    end

    local function makeScroll(name)
        local s = Instance.new("ScrollingFrame")
        s.Name = name
        s.Size = UDim2.new(1, -10, 1, -10)
        s.Position = UDim2.new(0, 5, 0, 5)
        s.BackgroundTransparency = 1
        s.BorderSizePixel = 0
        s.ScrollBarThickness = 4
        s.CanvasSize = UDim2.new(0, 0, 0, 500)
        s.Visible = false
        s.Parent = contentContainer
        return s
    end

    local aimScroll = makeScroll("AIM")
    local espScroll = makeScroll("ESP")

    local function makeToggle(parent, text, yPos, initial, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.Position = UDim2.new(0, 5, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.Text = "  " .. text .. ": " .. (initial and "ON" or "OFF")
        btn.TextColor3 = initial and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = parent
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
        local state = initial
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = "  " .. text .. ": " .. (state and "ON" or "OFF")
            btn.TextColor3 = state and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
            callback(state)
        end)
    end

    local function makeSlider(parent, text, yPos, minV, maxV, defV, cb)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 15)
        lbl.Position = UDim2.new(0, 5, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Text = text .. ": " .. defV
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = parent

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -10, 0, 8)
        bar.Position = UDim2.new(0, 5, 0, yPos + 20)
        bar.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        bar.Parent = parent
        local bc2 = Instance.new("UICorner"); bc2.CornerRadius = UDim.new(1, 0); bc2.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        fill.Parent = bar
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(fill.Size.X.Scale, -7, 0.5, -7)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.Parent = bar
        local kc2 = Instance.new("UICorner"); kc2.CornerRadius = UDim.new(1, 0); kc2.Parent = knob

        local dragging = false
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                knob.Position = UDim2.new(rel, -7, 0.5, -7)
                local v = math.floor(minV + (maxV - minV) * rel)
                lbl.Text = text .. ": " .. v
                cb(v)
            end
        end)
    end

    local function makeColorPicker(parent, text, yPos, initialColor, cb)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 15)
        lbl.Position = UDim2.new(0, 5, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = parent

        local vals = {initialColor.R * 255, initialColor.G * 255, initialColor.B * 255}
        local curY = yPos + 18
        for i = 1, 3 do
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 50, 0, 24)
            box.Position = UDim2.new(0, 5 + (i - 1) * 55, 0, curY)
            box.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            box.Text = tostring(math.floor(vals[i]))
            box.TextColor3 = Color3.fromRGB(255, 255, 255)
            box.Font = Enum.Font.Gotham
            box.TextSize = 12
            box.Parent = parent
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = box
            box.FocusLost:Connect(function()
                local n = tonumber(box.Text) or 0
                n = math.clamp(n, 0, 255)
                box.Text = tostring(math.floor(n))
                vals[i] = n
                cb(Color3.fromRGB(vals[1], vals[2], vals[3]))
            end)
        end
    end

    local yAim = 5
    makeToggle(aimScroll, "Aim Assist", yAim, Config.AimEnabled, function(v) Config.AimEnabled = v end); yAim = yAim + 38
    makeSlider(aimScroll, "Smoothness", yAim, 1, 20, Config.AimSmoothness, function(v) Config.AimSmoothness = v end); yAim = yAim + 42
    makeSlider(aimScroll, "FOV", yAim, 10, 400, Config.AimFOV, function(v) Config.AimFOV = v end); yAim = yAim + 42
    makeSlider(aimScroll, "Max Distance", yAim, 50, 1000, Config.AimMaxDist, function(v) Config.AimMaxDist = v end); yAim = yAim + 42
    makeToggle(aimScroll, "Humanize Aim", yAim, Config.AimHumanize, function(v) Config.AimHumanize = v end); yAim = yAim + 38
    makeToggle(aimScroll, "Aim Wall Check", yAim, Config.AimWallCheck, function(v) Config.AimWallCheck = v end); yAim = yAim + 38
    makeToggle(aimScroll, "Aim Team Check", yAim, Config.AimTeamCheck, function(v) Config.AimTeamCheck = v end); yAim = yAim + 42
    makeToggle(aimScroll, "FOV Circle", yAim, Config.FOVCircleEnabled, function(v)
        Config.FOVCircleEnabled = v
        if FOVCircle then FOVCircle.Visible = v end
    end); yAim = yAim + 38
    makeColorPicker(aimScroll, "FOV Circle Color (R,G,B)", yAim, Config.FOVCircleColor, function(c)
        Config.FOVCircleColor = c
        if FOVCircle then FOVCircle.Color = c end
    end); yAim = yAim + 48
    makeToggle(aimScroll, "Lock Indicator", yAim, Config.LockIndicatorEnabled, function(v)
        Config.LockIndicatorEnabled = v
        if not v and LockIndicator then LockIndicator.Visible = false end
    end); yAim = yAim + 38
    makeColorPicker(aimScroll, "Lock Indicator Color", yAim, Config.LockIndicatorColor, function(c)
        Config.LockIndicatorColor = c
        if LockIndicator then LockIndicator.Color = c end
    end); yAim = yAim + 52
    aimScroll.CanvasSize = UDim2.new(0, 0, 0, yAim)

    local yEsp = 5
    makeToggle(espScroll, "ESP", yEsp, Config.ESPEnabled, function(v) Config.ESPEnabled = v end); yEsp = yEsp + 38
    makeToggle(espScroll, "ESP Box", yEsp, Config.ESPBox, function(v) Config.ESPBox = v end); yEsp = yEsp + 38
    makeToggle(espScroll, "ESP Name", yEsp, Config.ESPName, function(v) Config.ESPName = v end); yEsp = yEsp + 38
    makeToggle(espScroll, "ESP Distance", yEsp, Config.ESPDistance, function(v) Config.ESPDistance = v end); yEsp = yEsp + 38
    makeToggle(espScroll, "ESP Health", yEsp, Config.ESPHealth, function(v) Config.ESPHealth = v end); yEsp = yEsp + 38
    makeToggle(espScroll, "ESP Team Check", yEsp, Config.ESPTeamCheck, function(v) Config.ESPTeamCheck = v end); yEsp = yEsp + 42
    espScroll.CanvasSize = UDim2.new(0, 0, 0, yEsp)

    switchTab("AIM")
    log("Main UI built")
end

-- ================= KEYBINDS & LOOP =================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift and gui and main then
        main.Visible = not main.Visible
    end
end)

safe("init-fov", initFOVCircle)
safe("init-lock", initLockIndicator)

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        local ok, err = pcall(function()
            FOVCircle.Position = Camera.ViewportSize / 2
            FOVCircle.Radius = Config.AimFOV
            FOVCircle.Visible = Config.FOVCircleEnabled
            FOVCircle.Color = Config.FOVCircleColor
        end)
        if not ok then warn_("FOV update: " .. tostring(err)) end
    end

    local target = nil
    if Config.AimEnabled then
        target = getClosestTarget()
        if target then
            local targetPos = humanizeTarget(target.Position)
            local desired = CFrame.new(Camera.CFrame.Position, targetPos)
            local alpha = math.clamp(1 / (Config.AimSmoothness / 1.8), 0, 1)
            Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
        end
    end

    if LockIndicator then
        local ok, err = pcall(function()
            LockIndicator.Position = Camera.ViewportSize / 2
            LockIndicator.Visible = Config.LockIndicatorEnabled and target ~= nil
            LockIndicator.Color = Config.LockIndicatorColor
        end)
        if not ok then warn_("Lock update: " .. tostring(err)) end
    end

    safe("esp", updateESP)
end)

task.spawn(function()
    while task.wait(10) do
        if bypass_active then safe("re-bypass", init_bypass) end
    end
end)

safe("build-ui", buildUI)
log("EZ HUB v2 loaded.")
