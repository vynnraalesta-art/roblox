--[[
    Universal Cheat v5.0 — Full Overhaul + Enhanced ESP + FPS Features
    vynnraalesta-art/roblox-scripts
    Aimbot | Silent Aim | ESP | Triggerbot | Magic Bullet | Rapid Fire | Spinbot
    BHop | Fly | Speed | Kill All | Auto-Strafe | Crosshair | Hitmarker | FOV
    Xeno/Hydrogen/Delta — no Drawing/metamethod
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local pg = LP:WaitForChild("PlayerGui")

repeat task.wait() until LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
print("[UCv5] Ready")

-- ===== STATE =====
local Toggles = {
    Aimbot = false, Triggerbot = false, MagicBullet = false,
    SilentAim = false, RapidFire = false, KillAll = false,
    ESP = false, NoRecoil = false, TeamCheck = true,
    VisCheck = true, AutoReload = false, BHop = false,
    Speed = false, Fly = false, FOVCircle = true,
    ESPBox = true, ESPSkeleton = true, ESPHealth = true, ESPDistance = true,
    FOVChanger = false, ThirdPerson = false, Crosshair = false,
    BulletTracers = false, AutoStrafe = false, Hitmarker = false,
    Spinbot = false, SpectatorList = false, WeaponSpecific = false,
    ConfigSaveLoad = false,
}
local Colors = {
    Enemy = Color3.fromRGB(255, 40, 40), Team = Color3.fromRGB(40, 255, 40), Neutral = Color3.fromRGB(255, 200, 40),
    Crosshair = Color3.fromRGB(0, 255, 0), Tracer = Color3.fromRGB(255, 255, 255), Hitmarker = Color3.fromRGB(255, 50, 50),
}
local Sliders = {
    AimbotFOV = 200, Smoothness = 5, TriggerDelay = 250,
    SpeedVal = 50, FlySpeed = 50, PredictTime = 0.15,
    SilentAimFOV = 200, RapidFireCPS = 10, FOVChanger = 70,
    ThirdPersonDist = 10, CrosshairSize = 20, TracerDuration = 0.3,
    StrafeSpeed = 10, SpinbotSpeed = 30, KillAllRange = 200,
}
local Dropdowns = {AimbotPart = "Head", ESPMode = "Box + Skel", SilentAimPart = "Head", TargetPriority = "Crosshair", CrosshairStyle = "Crosshair", SpinbotAxis = "Y", TracerColor = "White"}
local Connections = {}
local ESPObjects = {}
local Lib = {_cleanup = {}}
local SliderDrags = {} -- shared drag tracking per slider key
local sharedInputEnded = UIS.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    for ck, drag in pairs(SliderDrags) do
        if drag.active then
            drag.active = false
            if drag.conn then drag.conn:Disconnect(); drag.conn = nil end
        end
    end
end)
table.insert(Lib._cleanup, function() pcall(function() sharedInputEnded:Disconnect() end) end)
local PlayerCache = {}
local TeamPollThread = nil
local TeamPollActive = false

-- ===== UTILITY =====
local function getCamera() return Workspace.CurrentCamera end
local function randomStr(n)
    local t = {}
    for _ = 1, n do t[#t+1] = string.char(math.random(65, 90)) end
    return table.concat(t)
end
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- ===== RESPAWN (menu persists, only features reconnect) =====
local function disconnectFeatures()
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
end

local function reinitFeatures()
    disconnectFeatures()
    if Toggles.Aimbot then toggleAimbot(true) end
    if Toggles.MagicBullet then toggleMagicBullet(true) end
    if Toggles.SilentAim then toggleSilentAim(true) end
    if Toggles.RapidFire then toggleRapidFire(true) end
    if Toggles.Triggerbot then toggleTriggerbot(true) end
    if Toggles.NoRecoil then toggleNoRecoil(true) end
    if Toggles.BHop then toggleBHop(true) end
    if Toggles.Speed then toggleSpeed(true) end
    if Toggles.Fly then toggleFly(true) end
    if Toggles.FOVChanger then toggleFOVChanger(true) end
    if Toggles.ThirdPerson then toggleThirdPerson(true) end
    if Toggles.Spinbot then toggleSpinbot(true) end
    if Toggles.AutoStrafe then toggleAutoStrafe(true) end
    if Toggles.ESP then
        toggleESP(false); toggleESP(true)
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(0.3)
    reinitFeatures()
end)
LP.CharacterRemoving:Connect(function() disconnectFeatures() end)

-- ===== TARGETING =====
local function isAlive(plr)
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isVisible(plr, cam)
    local char = plr.Character
    if not char then return false end
    local part = char:FindFirstChild(Dropdowns.AimbotPart or "Head")
    if not part then return false end
    local _, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {char}
    if LP.Character then table.insert(filter, LP.Character) end
    rp.FilterDescendantsInstances = filter
    local ray = Workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position).Unit * 1000, rp)
    return not (ray and ray.Instance)
end

local function predictPosition(plr, partName)
    local char = plr.Character
    if not char then return nil end
    local part = char:FindFirstChild(partName or "Head")
    if not part then return nil end
    local cache = PlayerCache[plr.UserId]
    local now = tick()
    if not cache then
        PlayerCache[plr.UserId] = {pos = part.Position, time = now}
        return part.Position
    end
    local dt = now - cache.time
    if dt < 0.005 then return part.Position end
    -- Use both position delta and Humanoid.MoveDirection for velocity
    local vel = (part.Position - cache.pos) / dt
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection and hum.MoveDirection.Magnitude > 0 then
        vel = vel * 0.3 + hum.MoveDirection * hum.WalkSpeed * 0.7
    end
    cache.pos = part.Position
    cache.time = now
    local pred = part.Position + vel * (Sliders.PredictTime or 0.15)
    if (pred - part.Position).Magnitude > 20 then
        pred = part.Position + vel.Unit * 20
    end
    return pred
end

local function getClosestPlayer(fov)
    local cam = getCamera()
    if not cam then return nil end
    local closest, best = nil, nil
    local mousePos = UIS:GetMouseLocation()
    local priority = Dropdowns.TargetPriority or "Crosshair"
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if Toggles.TeamCheck and plr.Team and LP.Team and plr.Team == LP.Team then continue end
        if not isAlive(plr) then continue end
        if Toggles.VisCheck and not isVisible(plr, cam) then continue end
        local predPos = predictPosition(plr, Dropdowns.AimbotPart or "Head")
        if not predPos then continue end
        local pos, onScreen = cam:WorldToViewportPoint(predPos)
        if not onScreen then continue end
        local score = getPriorityScore(plr, cam, mousePos, priority)
        if best == nil or score < best then
            best = score
            closest = plr
        end
    end
    -- If using FOV-based filtering, check the closest is within FOV
    if closest and fov then
        local predPos = predictPosition(closest, Dropdowns.AimbotPart or "Head")
        if predPos then
            local pos, onScreen = cam:WorldToViewportPoint(predPos)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist > fov then return nil end
            end
        end
    end
    return closest
end

-- ===== FOV CIRCLE =====
local FOVCircle = {}
local function toggleFOVCircle(state)
    if not state then
        for _, o in ipairs(FOVCircle) do pcall(function() o:Destroy() end) end
        FOVCircle = {}
        return
    end
    if #FOVCircle > 0 then return end
    local r = Sliders.AimbotFOV or 200
    local sg = Instance.new("ScreenGui")
    sg.Name = "UC_FOV"
    sg.Parent = pg
    table.insert(FOVCircle, sg)
    -- 4 arc segments to form a ring (avoids opaque center issue)
    for i = 1, 4 do
        local arc = Instance.new("Frame", sg)
        arc.Size = UDim2.new(0, r * 2, 0, r * 2)
        arc.Position = UDim2.new(0.5, -r, 0.5, -r)
        arc.BackgroundTransparency = 1
        arc.BorderSizePixel = 0
        arc.ZIndex = 10
        arc.Rotation = (i - 1) * 90
        arc.ClipsDescendants = true
        local ring = Instance.new("Frame", arc)
        ring.Size = UDim2.new(1, 0, 1, 0)
        ring.BackgroundColor3 = rgb(255, 255, 255)
        ring.BackgroundTransparency = 0.85
        ring.BorderSizePixel = 0
        ring.ZIndex = 10
        Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
        local hole = Instance.new("Frame", ring)
        hole.Size = UDim2.new(1, -4, 1, -4)
        hole.Position = UDim2.new(0, 2, 0, 2)
        hole.BackgroundColor3 = rgb(0, 0, 0)
        hole.BackgroundTransparency = 1
        hole.BorderSizePixel = 0
        hole.ZIndex = 11
        Instance.new("UICorner", hole).CornerRadius = UDim.new(1, 0)
        table.insert(FOVCircle, arc)
    end
end

local function updateFOVCircle()
    if #FOVCircle == 0 then return end
    local r = Sliders.AimbotFOV or 200
    for i = 2, #FOVCircle do
        local arc = FOVCircle[i]
        arc.Size = UDim2.new(0, r * 2, 0, r * 2)
        arc.Position = UDim2.new(0.5, -r, 0.5, -r)
    end
end

-- ===== AIMBOT =====
local function toggleAimbot(state)
    if Connections.Aimbot then Connections.Aimbot:Disconnect(); Connections.Aimbot = nil end
    if not state then return end
    Connections.Aimbot = RunService.RenderStepped:Connect(function()
        if not Toggles.Aimbot then return end
        local cam = getCamera()
        if not cam then return end
        local target = getClosestPlayer(Sliders.AimbotFOV)
        if not target then return end
        local predPos = predictPosition(target, Dropdowns.AimbotPart or "Head")
        if not predPos then return end
        local tp, vis = cam:WorldToScreenPoint(predPos)
        if not vis then return end
        local mp = UIS:GetMouseLocation()
        local dx, dy = tp.X - mp.X, tp.Y - mp.Y
        local smooth = Sliders.Smoothness or 5
        pcall(function()
            if mousemoverel then mousemoverel(math.floor(dx / smooth), math.floor(dy / smooth))
            elseif mousemoveabs then mousemoveabs(math.floor(mp.X + dx / smooth), math.floor(mp.Y + dy / smooth)) end
        end)
        cam.CFrame = smooth <= 1 and CFrame.new(cam.CFrame.Position, predPos) or cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, predPos), 1 / smooth)
    end)
end

-- ===== MAGIC BULLET =====
local function toggleMagicBullet(state)
    if Connections.MagicBullet then Connections.MagicBullet:Disconnect(); Connections.MagicBullet = nil end
    if not state then return end
    Connections.MagicBullet = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not Toggles.MagicBullet then return end
        local cam = getCamera()
        if not cam then return end
        local target = getClosestPlayer(9999)
        if not target then return end
        local hp = predictPosition(target, "Head")
        if not hp then return end
        local tp, vis = cam:WorldToScreenPoint(hp)
        if not vis then return end
        pcall(function()
            if mousemoveabs then mousemoveabs(math.floor(tp.X), math.floor(tp.Y))
            elseif mousemoverel then local mp = UIS:GetMouseLocation(); mousemoverel(math.floor(tp.X - mp.X), math.floor(tp.Y - mp.Y)) end
        end)
        cam.CFrame = CFrame.new(cam.CFrame.Position, hp)
    end)
end

-- ===== TRIGGERBOT =====
local triggerCD = 0
local function toggleTriggerbot(state)
    if Connections.Triggerbot then Connections.Triggerbot:Disconnect(); Connections.Triggerbot = nil end
    if not state then return end
    triggerCD = 0
    Connections.Triggerbot = RunService.Heartbeat:Connect(function()
        if not Toggles.Triggerbot then return end
        triggerCD = triggerCD - 1
        if triggerCD > 0 then return end
        local cam = getCamera()
        if not cam then return end
        local target = getClosestPlayer(Sliders.AimbotFOV or 100)
        if not target then return end
        local hp = predictPosition(target, "Head")
        if not hp then return end
        local sp, vis = cam:WorldToViewportPoint(hp)
        if not vis then return end
        if (Vector2.new(sp.X, sp.Y) - UIS:GetMouseLocation()).Magnitude > 50 then return end
        triggerCD = math.floor((Sliders.TriggerDelay or 250) / 16)
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool and Toggles.AutoReload then
            local bp = LP:FindFirstChild("Backpack")
            if bp then
                local bt = bp:FindFirstChildOfClass("Tool")
                if bt then bt.Parent = char; task.wait(0.1); tool = char:FindFirstChildOfClass("Tool") end
            end
        end
        if not tool then return end
        pcall(function()
            for _, rn in ipairs({"Fire","Shoot","RemoteEvent","FireServer"}) do
                local r = tool:FindFirstChild(rn, true)
                if r and r:IsA("RemoteEvent") then r:FireServer() return end
            end
            tool:Activate()
        end)
        pcall(function()
            if mouse1click then mouse1click() end
            if mouse1press then mouse1press() task.wait(0.03) mouse1release() end
        end)
    end)
end

-- ===== ENHANCED ESP =====
local function getESPColour(plr)
    if plr.Team and LP.Team then
        return plr.Team == LP.Team and Colors.Team or Colors.Enemy
    end
    return Colors.Neutral
end

local function getDistance(plr)
    local char = plr.Character
    if not char then return 0 end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 0 end
    return math.floor((root.Position - myRoot.Position).Magnitude)
end

local function removePlayerESP(plr)
    local objs = ESPObjects[plr.UserId]
    if not objs then return end
    for _, o in ipairs(objs.elements or {}) do pcall(function() o:Destroy() end) end
    if objs.healthConn then pcall(function() objs.healthConn:Disconnect() end) end
    if objs.charAddedConn then pcall(function() objs.charAddedConn:Disconnect() end) end
    PlayerCache[plr.UserId] = nil
    ESPObjects[plr.UserId] = nil
end

local function createSkeleton(plr, char, color)
    local parts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}
    local bones = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    }
    local beams = {}
    for _, bone in ipairs(bones) do
        local a, b = char:FindFirstChild(bone[1]), char:FindFirstChild(bone[2])
        if a and b then
            local att0 = Instance.new("Attachment")
            att0.Parent = a
            local att1 = Instance.new("Attachment")
            att1.Parent = b
            local beam = Instance.new("Beam")
            beam.Attachment0 = att0
            beam.Attachment1 = att1
            beam.Color = ColorSequence.new(color)
            beam.Width0 = 0.08
            beam.Width1 = 0.08
            beam.Transparency = NumberSequence.new(0.3)
            beam.FaceCamera = true
            beam.Parent = char
            table.insert(beams, att0)
            table.insert(beams, att1)
            table.insert(beams, beam)
        end
    end
    return beams
end

local function createPlayerESP(plr)
    if plr == LP then return end
    if ESPObjects[plr.UserId] then return end
    if Toggles.TeamCheck and plr.Team and LP.Team and plr.Team == LP.Team then return end
    if not isAlive(plr) then return end
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local espColor = getESPColour(plr)
    local elements = {}
    local mode = Dropdowns.ESPMode or "Box + Skel"

    -- Chams (Highlight)
    if mode == "Box + Skel" or mode == "Chams Only" then
        local hl = Instance.new("Highlight")
        hl.FillColor = espColor
        hl.OutlineColor = rgb(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Parent = char
        table.insert(elements, hl)
    end

    -- Box ESP
    if Toggles.ESPBox and (mode == "Box + Skel" or mode == "Box Only") then
        local box = Instance.new("BillboardGui")
        box.Size = UDim2.new(0, 0, 0, 0)
        box.StudsOffset = Vector3.new(0, 2, 0)
        box.AlwaysOnTop = true
        box.Parent = head
        -- 4 lines forming a box
        for _, pos in ipairs({"Top", "Bottom", "Left", "Right"}) do
            local line = Instance.new("Frame", box)
            line.BackgroundColor3 = espColor
            line.BorderSizePixel = 0
            if pos == "Top" or pos == "Bottom" then
                line.Size = UDim2.new(1, 0, 0, 1)
                if pos == "Bottom" then line.Position = UDim2.new(0, 0, 1, 0) end
            else
                line.Size = UDim2.new(0, 1, 1, 0)
                if pos == "Right" then line.Position = UDim2.new(1, 0, 0, 0) end
            end
            table.insert(elements, line)
        end
        table.insert(elements, box)
    end

    -- Skeleton ESP
    if Toggles.ESPSkeleton and (mode == "Box + Skel" or mode == "Skel Only") then
        local skel = createSkeleton(plr, char, espColor)
        for _, o in ipairs(skel) do table.insert(elements, o) end
    end

    -- Name + Distance + Health tag
    if Toggles.ESPHealth or Toggles.ESPDistance then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 160, 0, 36)
        bb.StudsOffset = Vector3.new(0, 3.2, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        -- Name
        local nl = Instance.new("TextLabel", bb)
        nl.Size = UDim2.new(1, 0, 0, 16)
        nl.BackgroundTransparency = 1
        local dist = getDistance(plr)
        local nameText = plr.Name
        if Toggles.ESPDistance then nameText = nameText .. " [" .. dist .. "m]" end
        nl.Text = nameText
        nl.TextColor3 = espColor
        nl.TextStrokeTransparency = 0.6
        nl.Font = Enum.Font.GothamBold
        nl.TextSize = 12

        if Toggles.ESPHealth then
            -- Health bar bg
            local hbg = Instance.new("Frame", bb)
            hbg.Size = UDim2.new(1, -4, 0, 5)
            hbg.Position = UDim2.new(0, 2, 0, 18)
            hbg.BackgroundColor3 = rgb(30, 30, 30)
            hbg.BorderSizePixel = 0
            -- Health bar fill
            local hb = Instance.new("Frame", hbg)
            hb.Size = UDim2.new(1, 0, 1, 0)
            hb.BackgroundColor3 = rgb(0, 255, 80)
            hb.BorderSizePixel = 0
            -- HP text
            local ht = Instance.new("TextLabel", bb)
            ht.Size = UDim2.new(1, 0, 0, 14)
            ht.Position = UDim2.new(0, 0, 0, 24)
            ht.BackgroundTransparency = 1
            ht.Text = ""
            ht.TextColor3 = rgb(200, 200, 200)
            ht.Font = Enum.Font.Gotham
            ht.TextSize = 10

            -- Health listener
            local healthConn = nil
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local function updateHP()
                    local hp = math.floor(hum.Health)
                    local mhp = math.floor(hum.MaxHealth)
                    local pct = math.clamp(hp / (mhp > 0 and mhp or 100), 0, 1)
                    hb.Size = UDim2.new(pct, 0, 1, 0)
                    hb.BackgroundColor3 = pct > 0.6 and rgb(0, 255, 80) or pct > 0.3 and rgb(255, 200, 0) or rgb(255, 50, 50)
                    ht.Text = "HP: " .. hp .. "/" .. mhp
                end
                healthConn = hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
                updateHP()
            end
        end

        table.insert(elements, bb)
        ESPObjects[plr.UserId] = {
            elements = elements,
            healthConn = Toggles.ESPHealth and healthConn or nil,
            player = plr,
        }
    else
        ESPObjects[plr.UserId] = {elements = elements}
    end
end

local function toggleESP(state)
    if not state then
        TeamPollActive = false
        for _, plr in ipairs(Players:GetPlayers()) do removePlayerESP(plr) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do createPlayerESP(plr) end
end

-- ===== TEAM DETECTION (polling + events) =====
local function teamPoll()
    TeamPollActive = true
    while TeamPollActive and Toggles.ESP and Toggles.TeamCheck do
        task.wait(2)
        if not TeamPollActive or not Toggles.ESP or not Toggles.TeamCheck then break end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            local isTeam = plr.Team and LP.Team and plr.Team == LP.Team
            local hasESP = ESPObjects[plr.UserId] ~= nil
            if isTeam and hasESP then
                removePlayerESP(plr)
            elseif not isTeam and not hasESP then
                createPlayerESP(plr)
            end
        end
    end
end

-- Team change detection for LOCAL player
local function setupTeamWatcher()
    LP:GetPropertyChangedSignal("Team"):Connect(function()
        if not Toggles.ESP or not Toggles.TeamCheck then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            if plr.Team and LP.Team and plr.Team == LP.Team then
                removePlayerESP(plr)
            elseif not ESPObjects[plr.UserId] then
                createPlayerESP(plr)
            end
        end
    end)
end

-- ESP watchers
local plrAdded, plrRemoved = nil, nil
local function setupESPWatchers()
    if plrAdded then pcall(plrAdded.Disconnect, plrAdded) end
    if plrRemoved then pcall(plrRemoved.Disconnect, plrRemoved) end
    plrAdded = Players.PlayerAdded:Connect(function(plr)
        if not Toggles.ESP then return end
        local charAddedConn = plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if Toggles.ESP and not (Toggles.TeamCheck and plr.Team and LP.Team and plr.Team == LP.Team) then
                createPlayerESP(plr)
            end
        end)
        -- Store the connection for cleanup
        if ESPObjects[plr.UserId] then
            ESPObjects[plr.UserId].charAddedConn = charAddedConn
        else
            ESPObjects[plr.UserId] = {charAddedConn = charAddedConn}
        end
        task.wait(0.3)
        if Toggles.ESP and not (Toggles.TeamCheck and plr.Team and LP.Team and plr.Team == LP.Team) then
            createPlayerESP(plr)
        end
    end)
    plrRemoved = Players.PlayerRemoving:Connect(function(plr) removePlayerESP(plr) end)
end
table.insert(Lib._cleanup, function()
    if plrAdded then plrAdded:Disconnect() end
    if plrRemoved then plrRemoved:Disconnect() end
end)

-- ===== NO RECOIL =====
local function toggleNoRecoil(state)
    if Connections.NoRecoil then Connections.NoRecoil:Disconnect(); Connections.NoRecoil = nil end
    if not state then return end
    Connections.NoRecoil = RunService.RenderStepped:Connect(function()
        if not Toggles.NoRecoil then return end
        local cam = getCamera()
        if not cam then return end
        local cf = cam.CFrame
        cam.CFrame = CFrame.new(cf.Position, cf.Position + cf.LookVector)
    end)
end

-- ===== BHOP =====
local function toggleBHop(state)
    if Connections.BHop then Connections.BHop:Disconnect(); Connections.BHop = nil end
    if not state then return end
    Connections.BHop = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode ~= Enum.KeyCode.Space then return end
        if not Toggles.BHop then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum:GetState() == Enum.HumanoidStateType.Freefall then return end
        hum.Jump = true
    end)
end

-- ===== SPEED HACK =====
local function toggleSpeed(state)
    if Connections.Speed then Connections.Speed:Disconnect(); Connections.Speed = nil end
    if not state then
        -- Reset WalkSpeed to default
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        return
    end
    Connections.Speed = RunService.Heartbeat:Connect(function()
        if not Toggles.Speed then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Sliders.SpeedVal or 50 end
    end)
end

-- ===== FLY =====
local function toggleFly(state)
    if Connections.Fly then Connections.Fly:Disconnect(); Connections.Fly = nil end
    if not state then
        -- Reset PlatformStand and velocity
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
        end
        return
    end
    Connections.Fly = RunService.Heartbeat:Connect(function()
        if not Toggles.Fly then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        local spd = Sliders.FlySpeed or 50
        local cam = getCamera()
        if not cam then return end
        local vel = Vector3.new(0, 0, 0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel += cam.CFrame.LookVector * spd end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel -= cam.CFrame.LookVector * spd end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel -= cam.CFrame.RightVector * spd end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel += cam.CFrame.RightVector * spd end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0, spd, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.new(0, spd, 0) end
        hrp.Velocity = vel
    end)
end

-- ===== SILENT AIM =====
local function toggleSilentAim(state)
    if Connections.SilentAim then Connections.SilentAim:Disconnect(); Connections.SilentAim = nil end
    if not state then return end
    Connections.SilentAim = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not Toggles.SilentAim then return end
        local target = getClosestPlayer(Sliders.SilentAimFOV or 200)
        if not target then return end
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end
        local hitPart = target.Character and target.Character:FindFirstChild(Dropdowns.SilentAimPart or "Head")
        if not hitPart then return end
        local originalCF = tool:FindFirstChild("Handle") and tool.Handle.CFrame
        if originalCF then
            local cframe = CFrame.new(tool.Handle.Position, hitPart.Position)
            tool.Handle.CFrame = cframe
            pcall(function()
                for _, rn in ipairs({"Fire","Shoot","RemoteEvent","FireServer"}) do
                    local r = tool:FindFirstChild(rn, true)
                    if r and r:IsA("RemoteEvent") then r:FireServer() return end
                end
                tool:Activate()
            end)
            task.wait(0.05)
            pcall(function() tool.Handle.CFrame = originalCF end)
        end
    end)
end

-- ===== RAPID FIRE =====
local rapidFireTimer = 0
local function toggleRapidFire(state)
    if Connections.RapidFire then Connections.RapidFire:Disconnect(); Connections.RapidFire = nil end
    if not state then return end
    rapidFireTimer = 0
    Connections.RapidFire = RunService.Heartbeat:Connect(function(dt)
        if not Toggles.RapidFire then return end
        rapidFireTimer = rapidFireTimer - dt
        if rapidFireTimer > 0 then return end
        if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        local cps = Sliders.RapidFireCPS or 10
        rapidFireTimer = 1 / cps
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end
        pcall(function()
            for _, rn in ipairs({"Fire","Shoot","RemoteEvent","FireServer"}) do
                local r = tool:FindFirstChild(rn, true)
                if r and r:IsA("RemoteEvent") then r:FireServer() return end
            end
            tool:Activate()
        end)
        pcall(function()
            if mouse1press then mouse1press() task.wait(0.02) mouse1release() end
        end)
    end)
end

-- ===== TARGET PRIORITY (modifies getClosestPlayer logic) =====
local function getPriorityScore(plr, cam, mousePos, priority)
    local char = plr.Character
    if not char then return 99999 end
    if priority == "Health" then
        local hum = char:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health or 99999
    elseif priority == "Distance" then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHrp then return (hrp.Position - myHrp.Position).Magnitude end
        return 99999
    elseif priority == "Threat" then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHrp then
            local dist = (hrp.Position - myHrp.Position).Magnitude
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hp = hum and hum.Health or 100
            return dist / math.max(hp, 1) * 10
        end
        return 99999
    else -- Crosshair (default)
        local predPos = predictPosition(plr, Dropdowns.AimbotPart or "Head")
        if not predPos then return 99999 end
        local pos, onScreen = cam:WorldToViewportPoint(predPos)
        if not onScreen then return 99999 end
        return (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
    end
end

-- ===== SPINBOT =====
local function toggleSpinbot(state)
    if Connections.Spinbot then Connections.Spinbot:Disconnect(); Connections.Spinbot = nil end
    if not state then return end
    Connections.Spinbot = RunService.Heartbeat:Connect(function()
        if not Toggles.Spinbot then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local speed = math.rad(Sliders.SpinbotSpeed or 30)
        local axis = Dropdowns.SpinbotAxis or "Y"
        if axis == "Y" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, speed, 0)
        elseif axis == "X" then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(speed, 0, 0)
        else
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0, speed)
        end
    end)
end

-- ===== FOV CHANGER =====
local function toggleFOVChanger(state)
    if Connections.FOVChanger then Connections.FOVChanger:Disconnect(); Connections.FOVChanger = nil end
    if not state then return end
    Connections.FOVChanger = RunService.Heartbeat:Connect(function()
        if not Toggles.FOVChanger then return end
        local cam = getCamera()
        if cam then cam.FieldOfView = Sliders.FOVChanger or 70 end
    end)
end

-- ===== THIRD PERSON =====
local function toggleThirdPerson(state)
    if Connections.ThirdPerson then Connections.ThirdPerson:Disconnect(); Connections.ThirdPerson = nil end
    if not state then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
        end
        return
    end
    Connections.ThirdPerson = RunService.Heartbeat:Connect(function()
        if not Toggles.ThirdPerson then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local dist = Sliders.ThirdPersonDist or 10
        hum.CameraOffset = Vector3.new(0, 0, -dist)
    end)
end

-- ===== CUSTOM CROSSHAIR =====
local CrosshairGui = nil
local function toggleCrosshair(state)
    if CrosshairGui then CrosshairGui:Destroy(); CrosshairGui = nil end
    if not state then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "UC_Crosshair"
    sg.Parent = pg
    sg.IgnoreGuiInset = true
    CrosshairGui = sg
    local style = Dropdowns.CrosshairStyle or "Crosshair"
    local size = Sliders.CrosshairSize or 20
    local color = Colors.Crosshair
    local center = Instance.new("Frame", sg)
    center.Size = UDim2.new(0, size, 0, size)
    center.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
    center.BackgroundTransparency = 1
    center.BorderSizePixel = 0
    center.ZIndex = 100
    if style == "Crosshair" then
        for _, rot in ipairs({0, 90}) do
            local line = Instance.new("Frame", center)
            line.Size = UDim2.new(0, size, 0, 2)
            line.Position = UDim2.new(0, 0, 0.5, -1)
            line.Rotation = rot
            line.BackgroundColor3 = color
            line.BorderSizePixel = 0
            line.ZIndex = 100
        end
    elseif style == "Dot" then
        local dot = Instance.new("Frame", center)
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.Position = UDim2.new(0.5, -2, 0.5, -2)
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        dot.ZIndex = 100
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    elseif style == "Circle" then
        local circle = Instance.new("Frame", center)
        circle.Size = UDim2.new(0, size/2, 0, size/2)
        circle.Position = UDim2.new(0.5, -size/4, 0.5, -size/4)
        circle.BackgroundTransparency = 1
        circle.BorderSizePixel = 2
        circle.BorderColor3 = color
        circle.ZIndex = 100
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    elseif style == "T-Shape" then
        for i, rot in ipairs({0, 90, 180}) do
            local line = Instance.new("Frame", center)
            line.Size = UDim2.new(0, size/2, 0, 2)
            line.Position = UDim2.new(0.5, 0, 0.5, -1)
            line.Rotation = rot
            line.AnchorPoint = Vector2.new(0, 0.5)
            line.BackgroundColor3 = color
            line.BorderSizePixel = 0
            line.ZIndex = 100
        end
    end
end

-- ===== BULLET TRACERS =====
local TracerBeams = {}
local function toggleBulletTracers(state)
    if Connections.BulletTracers then Connections.BulletTracers:Disconnect(); Connections.BulletTracers = nil end
    if not state then
        for _, b in ipairs(TracerBeams) do pcall(function() b:Destroy() end) end
        TracerBeams = {}
        return
    end
    Connections.BulletTracers = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not Toggles.BulletTracers then return end
        local cam = getCamera()
        if not cam then return end
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        local startPos = (tool and tool:FindFirstChild("Handle")) and tool.Handle.Position or cam.CFrame.Position
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {char}
        local ray = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 1000, rp)
        local endPos = ray and ray.Position or cam.CFrame.Position + cam.CFrame.LookVector * 500
        local att0 = Instance.new("Attachment")
        att0.WorldPosition = startPos
        att0.Parent = Workspace.Terrain
        local att1 = Instance.new("Attachment")
        att1.WorldPosition = endPos
        att1.Parent = Workspace.Terrain
        local beam = Instance.new("Beam")
        beam.Attachment0 = att0
        beam.Attachment1 = att1
        beam.Color = ColorSequence.new(Colors.Tracer)
        beam.Width0 = 0.15
        beam.Width1 = 0.08
        beam.Transparency = NumberSequence.new(0.2)
        beam.FaceCamera = true
        beam.Parent = Workspace.Terrain
        table.insert(TracerBeams, att0)
        table.insert(TracerBeams, att1)
        table.insert(TracerBeams, beam)
        local dur = Sliders.TracerDuration or 0.3
        local ok, err = pcall(function() task.delay(dur, function()
            pcall(function() att0:Destroy() att1:Destroy() beam:Destroy() end)
        end) end)
        if not ok then
            local co = coroutine.create(function()
                task.wait(dur)
                pcall(function() att0:Destroy() att1:Destroy() beam:Destroy() end)
            end)
            coroutine.resume(co)
        end
    end)
end

-- ===== AUTO STRAFE =====
local strafeDir = 1
local strafeTimer = 0
local function toggleAutoStrafe(state)
    if Connections.AutoStrafe then Connections.AutoStrafe:Disconnect(); Connections.AutoStrafe = nil end
    if not state then return end
    strafeTimer = 0
    Connections.AutoStrafe = RunService.Heartbeat:Connect(function(dt)
        if not Toggles.AutoStrafe then return end
        strafeTimer = strafeTimer - dt
        if strafeTimer > 0 then return end
        local spd = Sliders.StrafeSpeed or 10
        strafeTimer = 1 / spd
        strafeDir = -strafeDir
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if strafeDir == 1 then
            hum.Move = Vector3.new(1, 0, 0)
        else
            hum.Move = Vector3.new(-1, 0, 0)
        end
    end)
end

-- ===== HITMARKER =====
local function toggleHitmarker(state)
    if Connections.Hitmarker then Connections.Hitmarker:Disconnect(); Connections.Hitmarker = nil end
    if not state then return end
    local lastHealth = {}
    Connections.Hitmarker = RunService.Heartbeat:Connect(function()
        if not Toggles.Hitmarker then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            if Toggles.TeamCheck and plr.Team and LP.Team and plr.Team == LP.Team then continue end
            local char = plr.Character
            if not char then continue end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then continue end
            local uid = plr.UserId
            local prev = lastHealth[uid] or hum.Health
            if hum.Health < prev then
                -- Hit detected!
                local sg = Instance.new("ScreenGui")
                sg.Name = "UC_Hitmarker"
                sg.Parent = pg
                sg.IgnoreGuiInset = true
                local hit = Instance.new("TextLabel", sg)
                hit.Size = UDim2.new(0, 40, 0, 40)
                hit.Position = UDim2.new(0.5, -20, 0.5, -20)
                hit.BackgroundTransparency = 1
                hit.Text = "✕"
                hit.TextColor3 = Colors.Hitmarker
                hit.Font = Enum.Font.GothamBold
                hit.TextSize = 24
                hit.ZIndex = 200
                local ok, err = pcall(function() task.delay(0.15, function() pcall(function() sg:Destroy() end) end) end)
                if not ok then coroutine.wrap(function() task.wait(0.15) pcall(function() sg:Destroy() end) end)() end
            end
            lastHealth[uid] = hum.Health
        end
    end)
end

-- ===== KILL ALL =====
local function executeKillAll()
    if not Toggles.KillAll then return end
    local cam = getCamera()
    if not cam then return end
    local range = Sliders.KillAllRange or 200
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if Toggles.TeamCheck and plr.Team and LP.Team and plr.Team == LP.Team then continue end
        if not isAlive(plr) then continue end
        local char = plr.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then continue end
        if (hrp.Position - myHrp.Position).Magnitude > range then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        -- Aim at target
        cam.CFrame = CFrame.new(cam.CFrame.Position, head.Position)
        -- Fire
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function()
                for _, rn in ipairs({"Fire","Shoot","RemoteEvent","FireServer"}) do
                    local r = tool:FindFirstChild(rn, true)
                    if r and r:IsA("RemoteEvent") then r:FireServer() return end
                end
                tool:Activate()
            end)
        end
        task.wait(0.05)
    end
end

-- ===== SPECTATOR LIST =====
local SpecListGui = nil
local function toggleSpectatorList(state)
    if SpecListGui then SpecListGui:Destroy(); SpecListGui = nil end
    if Connections.SpectatorList then Connections.SpectatorList:Disconnect(); Connections.SpectatorList = nil end
    if not state then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "UC_SpecList"
    sg.Parent = pg
    SpecListGui = sg
    local bg = Instance.new("Frame", sg)
    bg.Size = UDim2.new(0, 180, 0, 120)
    bg.Position = UDim2.new(1, -190, 0, 30)
    bg.BackgroundColor3 = rgb(0, 0, 0)
    bg.BackgroundTransparency = 0.6
    bg.BorderSizePixel = 0
    bg.ZIndex = 50
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Spectators"
    title.TextColor3 = rgb(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.ZIndex = 51
    local list = Instance.new("TextLabel", bg)
    list.Size = UDim2.new(1, -8, 1, -24)
    list.Position = UDim2.new(0, 4, 0, 22)
    list.BackgroundTransparency = 1
    list.Text = "Scanning..."
    list.TextColor3 = rgb(180, 180, 200)
    list.Font = Enum.Font.Gotham
    list.TextSize = 11
    list.TextXAlignment = Enum.TextXAlignment.Left
    list.TextYAlignment = Enum.TextYAlignment.Top
    list.ZIndex = 51
    Connections.SpectatorList = RunService.Heartbeat:Connect(function()
        if not Toggles.SpectatorList then return end
        local myChar = LP.Character
        if not myChar then list.Text = "No character"; return end
        local myHead = myChar:FindFirstChild("Head")
        if not myHead then list.Text = "No head"; return end
        local names = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LP then continue end
            local char = plr.Character
            if not char then continue end
            local camPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if not camPart then continue end
            local lookDir = camPart.CFrame.LookVector
            local toMe = (myHead.Position - camPart.Position).Unit
            local dot = lookDir:Dot(toMe)
            if dot > 0.6 then -- ~53 degree cone
                local dist = math.floor((myHead.Position - camPart.Position).Magnitude)
                table.insert(names, plr.Name .. " [" .. dist .. "m]")
            end
        end
        list.Text = #names > 0 and table.concat(names, "\n") or "No spectators"
    end)
end

-- ===== WEAPON-SPECIFIC SETTINGS =====
local WeaponProfiles = {
    ["sniper"] = {fov = 400, smooth = 1, predict = 0.2},
    ["rifle"] = {fov = 200, smooth = 3, predict = 0.15},
    ["smg"] = {fov = 250, smooth = 3, predict = 0.12},
    ["shotgun"] = {fov = 150, smooth = 4, predict = 0.1},
    ["pistol"] = {fov = 200, smooth = 5, predict = 0.15},
    ["melee"] = {fov = 50, smooth = 1, predict = 0.05},
    ["default"] = {fov = 200, smooth = 5, predict = 0.15},
}
local function toggleWeaponSpecific(state)
    if Connections.WeaponSpecific then Connections.WeaponSpecific:Disconnect(); Connections.WeaponSpecific = nil end
    if not state then return end
    Connections.WeaponSpecific = RunService.Heartbeat:Connect(function()
        if not Toggles.WeaponSpecific then return end
        local char = LP.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end
        local name = tool.Name:lower()
        local profile = "default"
        for k, _ in pairs(WeaponProfiles) do
            if name:find(k) then profile = k; break end
        end
        local wp = WeaponProfiles[profile]
        Sliders.AimbotFOV = wp.fov
        Sliders.Smoothness = wp.smooth
        Sliders.PredictTime = wp.predict
    end)
end

-- ===== CONFIG SYSTEM =====
local function saveConfig()
    local cfg = {Toggles = Toggles, Sliders = Sliders, Dropdowns = Dropdowns}
    local json = ""
    local function encode(t, depth)
        depth = depth or 0
        local indent = string.rep("  ", depth)
        local parts = {}
        for k, v in pairs(t) do
            local key = type(k) == "string" and string.format("%q", k) or tostring(k)
            local val
            if type(v) == "table" then
                val = encode(v, depth + 1)
            elseif type(v) == "boolean" then
                val = v and "true" or "false"
            elseif type(v) == "number" then
                val = tostring(v)
            elseif type(v) == "string" then
                val = string.format("%q", v)
            else
                val = "nil"
            end
            table.insert(parts, indent .. "  " .. key .. " = " .. val)
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
    end
    json = "return " .. encode(cfg)
    pcall(function() writefile("UCv5_config.lua", json) end)
    print("[UCv5] Config saved to UCv5_config.lua")
end

local function loadConfig()
    local ok, data = pcall(function() return readfile("UCv5_config.lua") end)
    if not ok or not data then
        print("[UCv4] No config file found")
        return
    end
    local ok2, cfg = pcall(function() return loadstring(data)() end)
    if not ok2 or not cfg then
        print("[UCv4] Config file corrupted")
        return
    end
    if cfg.Toggles then for k, v in pairs(cfg.Toggles) do Toggles[k] = v end end
    if cfg.Sliders then for k, v in pairs(cfg.Sliders) do Sliders[k] = v end end
    if cfg.Dropdowns then for k, v in pairs(cfg.Dropdowns) do Dropdowns[k] = v end end
    print("[UCv5] Config loaded from UCv5_config.lua")
end
local guiName = "UCv5_" .. randomStr(8)
local old = pg:FindFirstChild(guiName)
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = guiName
SG.Parent = pg

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 580, 0, 440)
Main.Position = UDim2.new(0.5, -290, 0.5, -220)
Main.BackgroundColor3 = rgb(10, 10, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = SG
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Title bar
local TB = Instance.new("Frame", Main)
TB.Size = UDim2.new(1, 0, 0, 38)
TB.BackgroundColor3 = rgb(18, 18, 30)
TB.BorderSizePixel = 0
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)

local TL = Instance.new("TextLabel", TB)
TL.Size = UDim2.new(1, -80, 1, 0)
TL.Position = UDim2.new(0, 12, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "Universal Cheat v5.0"
TL.TextColor3 = rgb(255, 255, 255)
TL.Font = Enum.Font.GothamBold
TL.TextSize = 14
TL.TextXAlignment = Enum.TextXAlignment.Left

-- Rainbow title (sin-wave fallback, no fromHSV)
local hueVal = 0
local rc = RunService.Heartbeat:Connect(function()
    hueVal = (hueVal + 0.005) % 1
    local r = math.sin(hueVal * math.pi * 2) * 0.5 + 0.5
    local g = math.sin((hueVal + 0.33) * math.pi * 2) * 0.5 + 0.5
    local b = math.sin((hueVal + 0.66) * math.pi * 2) * 0.5 + 0.5
    TL.TextColor3 = Color3.new(r, g, b)
end)
table.insert(Lib._cleanup, function() pcall(function() rc:Disconnect() end) end)

-- Minimize
local MinBtn = Instance.new("TextButton", TB)
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Position = UDim2.new(1, -52, 0, 8)
MinBtn.BackgroundColor3 = rgb(60, 60, 80)
MinBtn.Text = "_"
MinBtn.TextColor3 = rgb(200, 200, 200)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    SideBar.Visible = not minimized
    ContentArea.Visible = not minimized
    Main.Size = minimized and UDim2.new(0, 300, 0, 38) or UDim2.new(0, 580, 0, 440)
end)

-- Close
local CB = Instance.new("TextButton", TB)
CB.Size = UDim2.new(0, 22, 0, 22)
CB.Position = UDim2.new(1, -26, 0, 8)
CB.BackgroundColor3 = rgb(180, 40, 40)
CB.Text = "X"
CB.TextColor3 = rgb(255, 255, 255)
CB.Font = Enum.Font.GothamBold
CB.TextSize = 11
CB.BorderSizePixel = 0
Instance.new("UICorner", CB).CornerRadius = UDim.new(0, 5)
CB.MouseButton1Click:Connect(function()
    TeamPollActive = false
    if TeamPollThread then pcall(task.cancel, TeamPollThread); TeamPollThread = nil end
    for _, fn in ipairs(Lib._cleanup) do pcall(fn) end
    for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
    toggleESP(false)
    toggleFOVCircle(false)
    -- Cleanup extra GUIs
    if CrosshairGui then CrosshairGui:Destroy(); CrosshairGui = nil end
    if SpecListGui then SpecListGui:Destroy(); SpecListGui = nil end
    SG:Destroy()
end)

-- Sidebar
local SideBar = Instance.new("Frame", Main)
SideBar.Size = UDim2.new(0, 130, 1, -38)
SideBar.Position = UDim2.new(0, 0, 0, 38)
SideBar.BackgroundColor3 = rgb(14, 14, 24)
SideBar.BorderSizePixel = 0
local sbLayout = Instance.new("UIListLayout", SideBar)
sbLayout.Padding = UDim.new(0, 2)
sbLayout.SortOrder = Enum.SortOrder.LayoutOrder

local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, -130, 1, -38)
ContentArea.Position = UDim2.new(0, 130, 0, 38)
ContentArea.BackgroundColor3 = rgb(13, 13, 20)
ContentArea.BorderSizePixel = 0

-- Tab system
local tabs = {}
local function switchTab(idx)
    for i, t in ipairs(tabs) do
        t.content.Visible = (i == idx)
        t.btn.BackgroundColor3 = (i == idx) and rgb(45, 45, 65) or rgb(14, 14, 24)
        t.btn.TextColor3 = (i == idx) and rgb(255, 255, 255) or rgb(150, 150, 180)
    end
end

local function makeTab(name, icon, order)
    local btn = Instance.new("TextButton", SideBar)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = rgb(14, 14, 24)
    btn.Text = "  " .. icon .. " " .. name
    btn.TextColor3 = rgb(150, 150, 180)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local cnt = Instance.new("ScrollingFrame", ContentArea)
    cnt.Size = UDim2.new(1, -16, 1, -16)
    cnt.Position = UDim2.new(0, 8, 0, 8)
    cnt.BackgroundTransparency = 1
    cnt.BorderSizePixel = 0
    cnt.ScrollBarThickness = 4
    cnt.ScrollBarImageColor3 = rgb(70, 70, 100)
    cnt.Visible = false
    local lo = Instance.new("UIListLayout", cnt)
    lo.Padding = UDim.new(0, 6)
    lo.SortOrder = Enum.SortOrder.LayoutOrder
    lo:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cnt.CanvasSize = UDim2.new(0, 0, 0, lo.AbsoluteContentSize.Y + 10)
    end)
    local idx = #tabs + 1
    btn.MouseButton1Click:Connect(function() switchTab(idx) end)
    table.insert(tabs, {btn = btn, content = cnt})
    return cnt
end

local function makeSec(parent, title)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 26)
    f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = "  " .. title
    l.TextColor3 = rgb(110, 110, 160)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    return f
end

local function makeToggle(parent, name, default, callback)
    local ck = name:gsub("%s+", "")
    Toggles[ck] = default
    local c = Instance.new("Frame", parent)
    c.Size = UDim2.new(1, 0, 0, 30)
    c.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", c)
    lbl.Size = UDim2.new(1, -55, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. name
    lbl.TextColor3 = rgb(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local t = Instance.new("TextButton", c)
    t.Size = UDim2.new(0, 40, 0, 18)
    t.Position = UDim2.new(1, -47, 0.5, -9)
    t.BackgroundColor3 = default and rgb(0, 200, 100) or rgb(65, 65, 85)
    t.Text = ""
    t.BorderSizePixel = 0
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 9)
    t.MouseButton1Click:Connect(function()
        Toggles[ck] = not Toggles[ck]
        t.BackgroundColor3 = Toggles[ck] and rgb(0, 200, 100) or rgb(65, 65, 85)
        if callback then callback(Toggles[ck]) end
    end)
    return t
end

local function makeSlider(parent, name, min, max, default, step)
    local ck = name:gsub("%s+", "")
    Sliders[ck] = default
    step = step or 1
    local c = Instance.new("Frame", parent)
    c.Size = UDim2.new(1, 0, 0, 48)
    c.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", c)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. name .. ": " .. default
    lbl.TextColor3 = rgb(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local s = Instance.new("Frame", c)
    s.Size = UDim2.new(1, -20, 0, 6)
    s.Position = UDim2.new(0, 10, 0, 28)
    s.BackgroundColor3 = rgb(45, 45, 65)
    s.BorderSizePixel = 0
    Instance.new("UICorner", s).CornerRadius = UDim.new(0, 3)
    local pct = (default - min) / (max - min)
    local fill = Instance.new("Frame", s)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = rgb(0, 140, 255)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
    local knob = Instance.new("TextButton", s)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = rgb(255, 255, 255)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local dragging, conn = false, nil
    SliderDrags[ck] = {active = false, conn = nil}
    knob.MouseButton1Down:Connect(function()
        if SliderDrags[ck].active then return end
        SliderDrags[ck].active = true
        SliderDrags[ck].conn = RunService.RenderStepped:Connect(function()
            local mx = UIS:GetMouseLocation().X
            local p = math.clamp((mx - s.AbsolutePosition.X) / s.AbsoluteSize.X, 0, 1)
            local v = min + (max - min) * p
            if step == 50 then v = math.floor(v / step + 0.5) * step
            elseif step == 1 then v = math.floor(v + 0.5)
            elseif step == 0.01 then v = math.floor(v * 100 + 0.5) / 100
            elseif step == 0.05 then v = math.floor(v * 20 + 0.5) / 20
            else v = math.floor(v / step + 0.5) * step end
            fill.Size = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, -7, 0.5, -7)
            lbl.Text = "  " .. name .. ": " .. v
            Sliders[ck] = v
            if ck == "AimbotFOV" and Toggles.FOVCircle then updateFOVCircle() end
        end)
    end)
    return c
end

local function makeDropdown(parent, name, options, default, callback)
    local ck = name:gsub("%s+", "")
    Dropdowns[ck] = default
    local d = Instance.new("Frame", parent)
    d.Size = UDim2.new(1, 0, 0, 30)
    d.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", d)
    lbl.Size = UDim2.new(1, -135, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. name .. ": " .. default
    lbl.TextColor3 = rgb(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local idx = 1
    for i, opt in ipairs(options) do if opt == default then idx = i; break end end
    local btn = Instance.new("TextButton", d)
    btn.Size = UDim2.new(0, 125, 0, 22)
    btn.Position = UDim2.new(1, -130, 0.5, -11)
    btn.BackgroundColor3 = rgb(35, 35, 55)
    btn.Text = "  " .. default .. " ▼"
    btn.TextColor3 = rgb(220, 220, 240)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        Dropdowns[ck] = options[idx]
        lbl.Text = "  " .. name .. ": " .. options[idx]
        btn.Text = "  " .. options[idx] .. " ▼"
        if callback then callback(options[idx]) end
    end)
    return d
end

-- ===== BUILD TABS =====

-- Aimbot
local aimbot = makeTab("Aimbot", "X", 1)
makeSec(aimbot, "Aim")
makeToggle(aimbot, "Aimbot", false, toggleAimbot)
makeToggle(aimbot, "Magic Bullet", false, toggleMagicBullet)
makeToggle(aimbot, "Triggerbot", false, toggleTriggerbot)
makeToggle(aimbot, "Silent Aim", false, toggleSilentAim)
makeToggle(aimbot, "No Recoil", false, toggleNoRecoil)
makeToggle(aimbot, "FOV Circle", true, toggleFOVCircle)
makeSec(aimbot, "Settings")
makeSlider(aimbot, "Aimbot FOV", 50, 800, 200, 50)
makeSlider(aimbot, "Silent Aim FOV", 50, 800, 200, 50)
makeSlider(aimbot, "Smoothness", 1, 20, 5, 1)
makeSlider(aimbot, "Trigger Delay", 50, 1000, 250, 50)
makeSlider(aimbot, "Predict Time", 0.05, 0.5, 0.15, 0.01)
makeDropdown(aimbot, "Aimbot Part", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head")
makeDropdown(aimbot, "Silent Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head")
makeDropdown(aimbot, "Target Priority", {"Crosshair", "Distance", "Health", "Threat"}, "Crosshair")
makeSec(aimbot, "Filter")
makeToggle(aimbot, "Team Check", true, function()
    if Toggles.ESP then toggleESP(false); toggleESP(true) end
end)
makeToggle(aimbot, "Vis Check", true, function() end)
makeToggle(aimbot, "Auto Reload", false, function() end)
makeToggle(aimbot, "Weapon Specific", false, toggleWeaponSpecific)

-- Rage
local rage = makeTab("Rage", "!", 2)
makeSec(rage, "Rage Features")
makeToggle(rage, "Rapid Fire", false, toggleRapidFire)
makeToggle(rage, "Spinbot", false, toggleSpinbot)
makeToggle(rage, "Auto Strafe", false, toggleAutoStrafe)
makeToggle(rage, "Kill All", false, function(state)
    if state then executeKillAll() end
    -- Reset toggle immediately (one-shot)
    task.wait(0.1)
    Toggles.KillAll = false
end)
makeSec(rage, "Settings")
makeSlider(rage, "Rapid Fire CPS", 1, 30, 10, 1)
makeSlider(rage, "Spinbot Speed", 5, 200, 30, 5)
makeSlider(rage, "Strafe Speed", 1, 30, 10, 1)
makeSlider(rage, "Kill All Range", 50, 1000, 200, 50)
makeDropdown(rage, "Spinbot Axis", {"Y", "X", "Z"}, "Y")

-- Visuals
local visuals = makeTab("Visuals", "O", 3)
makeSec(visuals, "ESP")
makeToggle(visuals, "ESP", false, function(state)
    toggleESP(state)
    if state then
        setupESPWatchers()
        TeamPollActive = true
        local ok, err = pcall(function() TeamPollThread = task.spawn(teamPoll) end)
        if not ok then TeamPollThread = coroutine.wrap(teamPoll)(); TeamPollThread = nil end
    else
        TeamPollActive = false
        if TeamPollThread then pcall(task.cancel, TeamPollThread); TeamPollThread = nil end
    end
end)
makeToggle(visuals, "ESP Box", true, function() if Toggles.ESP then toggleESP(false); toggleESP(true) end end)
makeToggle(visuals, "ESP Skeleton", true, function() if Toggles.ESP then toggleESP(false); toggleESP(true) end end)
makeToggle(visuals, "ESP Health", true, function() if Toggles.ESP then toggleESP(false); toggleESP(true) end end)
makeToggle(visuals, "ESP Distance", true, function() if Toggles.ESP then toggleESP(false); toggleESP(true) end end)
makeDropdown(visuals, "ESP Mode", {"Box + Skel", "Box Only", "Skel Only", "Chams Only"}, "Box + Skel", function()
    if Toggles.ESP then toggleESP(false); toggleESP(true) end
end)
makeSec(visuals, "View")
makeToggle(visuals, "FOV Changer", false, toggleFOVChanger)
makeToggle(visuals, "Third Person", false, toggleThirdPerson)
makeToggle(visuals, "Crosshair", false, toggleCrosshair)
makeToggle(visuals, "Bullet Tracers", false, toggleBulletTracers)
makeToggle(visuals, "Hitmarker", false, toggleHitmarker)
makeToggle(visuals, "Spectator List", false, toggleSpectatorList)
makeSec(visuals, "View Settings")
makeSlider(visuals, "FOV Changer", 30, 150, 70, 1)
makeSlider(visuals, "Third Person Dist", 3, 30, 10, 1)
makeSlider(visuals, "Crosshair Size", 8, 50, 20, 2)
makeSlider(visuals, "Tracer Duration", 0.1, 2, 0.3, 0.05)
makeDropdown(visuals, "Crosshair Style", {"Crosshair", "Dot", "Circle", "T-Shape"}, "Crosshair", function()
    if Toggles.Crosshair then toggleCrosshair(false); toggleCrosshair(true) end
end)
makeDropdown(visuals, "Tracer Color", {"White", "Red", "Green", "Blue", "Yellow", "Cyan"}, "White", function(opt)
    local map = {White = rgb(255,255,255), Red = rgb(255,50,50), Green = rgb(50,255,50), Blue = rgb(50,50,255), Yellow = rgb(255,255,50), Cyan = rgb(50,255,255)}
    Colors.Tracer = map[opt] or rgb(255,255,255)
end)

-- Movement
local movement = makeTab("Movement", ">", 4)
makeSec(movement, "Hacks")
makeToggle(movement, "BHop", false, toggleBHop)
makeToggle(movement, "Speed", false, toggleSpeed)
makeToggle(movement, "Fly", false, toggleFly)
makeSec(movement, "Settings")
makeSlider(movement, "Speed Val", 16, 500, 50, 1)
makeSlider(movement, "Fly Speed", 10, 200, 50, 1)

-- Misc
local misc = makeTab("Misc", "=", 5)
makeSec(misc, "Config")
local cfgBtn = Instance.new("TextButton", misc)
cfgBtn.Size = UDim2.new(1, -20, 0, 30)
cfgBtn.Position = UDim2.new(0, 10, 0, 30)
cfgBtn.BackgroundColor3 = rgb(35, 35, 55)
cfgBtn.Text = "Save Config"
cfgBtn.TextColor3 = rgb(220, 220, 240)
cfgBtn.Font = Enum.Font.Gotham
cfgBtn.TextSize = 13
cfgBtn.BorderSizePixel = 0
Instance.new("UICorner", cfgBtn).CornerRadius = UDim.new(0, 5)
cfgBtn.MouseButton1Click:Connect(saveConfig)

local loadBtn = Instance.new("TextButton", misc)
loadBtn.Size = UDim2.new(1, -20, 0, 30)
loadBtn.Position = UDim2.new(0, 10, 0, 66)
loadBtn.BackgroundColor3 = rgb(35, 35, 55)
loadBtn.Text = "Load Config"
loadBtn.TextColor3 = rgb(220, 220, 240)
loadBtn.Font = Enum.Font.Gotham
loadBtn.TextSize = 13
loadBtn.BorderSizePixel = 0
Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 5)
loadBtn.MouseButton1Click:Connect(loadConfig)

makeSec(misc, "About")
local info = Instance.new("TextLabel", misc)
info.Size = UDim2.new(1, 0, 0, 260)
info.BackgroundTransparency = 1
info.Text = "github.com/vynnraalesta-art/roblox-scripts\n\nv5.0 Changelog:\n- Fixed 3 syntax errors\n- Fixed healthConn scoping\n- Fixed pg ordering bug\n- Fixed slider connection leak\n- Fixed ESP restart on respawn\n- Fixed MoveDirection nil check\n- Fixed BHop check\n- Added Silent Aim\n- Added Rapid Fire\n- Added Target Priority\n- Added Spinbot\n- Added FOV Changer\n- Added Third Person\n- Added Custom Crosshair\n- Added Bullet Tracers\n- Added Auto-Strafe\n- Added Hitmarker\n- Added Kill All\n- Added Spectator List\n- Added Weapon-Specific\n- Added Config System\n- 5-tab GUI restructure\n\nINSERT to toggle"
info.TextColor3 = rgb(130, 130, 160)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top

-- Watermark
local WM = Instance.new("TextLabel", pg)
WM.Size = UDim2.new(0, 230, 0, 20)
WM.Position = UDim2.new(0, 8, 0, 8)
WM.BackgroundTransparency = 1
WM.Text = "Universal Cheat v5.0 | INSERT | github.com/vynnraalesta-art"
WM.TextColor3 = rgb(170, 170, 200)
WM.Font = Enum.Font.Gotham
WM.TextSize = 11
WM.TextXAlignment = Enum.TextXAlignment.Left
WM.TextStrokeTransparency = 0.7

-- ===== FINALIZE =====
switchTab(1)
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
    end
end)
setupTeamWatcher()

print("[UCv5] Loaded | INSERT toggle | github.com/vynnraalesta-art/roblox-scripts")