--[[
    Troll Menu - OBROLAN SUARA DANAU
    Features: Clone Avatar, Fake Donasi Robux, Control Player, Fling, Spam
    Xeno Executor compatible
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Toggles = {}
local Sliders = {}
local Connections = {}
local espObjects = {}
local controlledPlayer = nil
local controlConn = nil

-- Dynamic camera (for respawn safety)
local function getCamera()
    return Workspace.CurrentCamera
end

-- ===== UTILITY =====
local function getClosestPlayer(fov)
    local closest = nil
    local shortestDist = fov or math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local cam = getCamera()
    if not cam then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, visible = cam:WorldToViewportPoint(head.Position)
                if visible then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

local function getTargetPlayer()
    local target = getClosestPlayer(9999)
    return target
end

-- ===== FEATURE: CLONE AVATAR =====
local function cloneAvatar()
    local target = getTargetPlayer()
    if not target then
        print("[Troll] No target player found!")
        return
    end
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        print("[Troll] No humanoid found!")
        return
    end
    -- Method 1: HumanoidDescription (best for clothing)
    pcall(function()
        local desc = humanoid:GetAppliedDescription()
        local targetHumanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if targetHumanoid then
            local targetDesc = targetHumanoid:GetAppliedDescription()
            -- Copy clothing
            humanoid:ApplyDescription(targetDesc)
            print("[Troll] Cloned avatar from " .. target.Name)
        end
    end)
    -- Method 2: Copy accessories directly
    pcall(function()
        if target.Character then
            local targetHead = target.Character:FindFirstChild("Head")
            local myHead = LocalPlayer.Character:FindFirstChild("Head")
            if targetHead and myHead then
                -- Copy accessories from target's head
                for _, child in ipairs(targetHead:GetChildren()) do
                    if child:IsA("Accessory") then
                        -- Check if we already have this accessory
                        local existing = myHead:FindFirstChild(child.Name)
                        if not existing then
                            local clone = child:Clone()
                            clone.Parent = myHead
                        end
                    end
                end
                print("[Troll] Copied accessories from " .. target.Name)
            end
        end
    end)
end

-- ===== FEATURE: FAKE DONASI ROBUX =====
local function showFakeDonation()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    
    -- Remove old donation UI
    local old = pg:FindFirstChild("FakeDonation")
    if old then old:Destroy() end
    
    local target = getTargetPlayer()
    local targetName = target and target.Name or "Player"
    local amounts = {100, 500, 1000, 5000, 10000, 50000, 100000}
    local amount = amounts[math.random(1, #amounts)]
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "FakeDonation"
    sg.Parent = pg
    
    -- Main container
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 350, 0, 200)
    main.Position = UDim2.new(0.5, -175, 0.5, -100)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    
    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 12)
    
    -- Top bar (Robux green)
    local topBar = Instance.new("Frame", main)
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
    topBar.BorderSizePixel = 0
    
    local topCorner = Instance.new("UICorner", topBar)
    topCorner.CornerRadius = UDim.new(0, 12)
    
    -- Robux icon
    local icon = Instance.new("TextLabel", topBar)
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 15, 0.5, -20)
    icon.BackgroundTransparency = 1
    icon.Text = "R$"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 24
    
    -- Title
    local title = Instance.new("TextLabel", topBar)
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 60, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "DONASI ROBUX"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Amount display
    local amountLabel = Instance.new("TextLabel", main)
    amountLabel.Size = UDim2.new(1, 0, 0, 40)
    amountLabel.Position = UDim2.new(0, 0, 0, 60)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Text = "R$ " .. amount
    amountLabel.TextColor3 = Color3.fromRGB(0, 200, 100)
    amountLabel.Font = Enum.Font.GothamBold
    amountLabel.TextSize = 32
    
    -- From label
    local fromLabel = Instance.new("TextLabel", main)
    fromLabel.Size = UDim2.new(1, 0, 0, 25)
    fromLabel.Position = UDim2.new(0, 0, 0, 105)
    fromLabel.BackgroundTransparency = 1
    fromLabel.Text = "Dari: " .. LocalPlayer.Name
    fromLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    fromLabel.Font = Enum.Font.Gotham
    fromLabel.TextSize = 14
    
    -- To label
    local toLabel = Instance.new("TextLabel", main)
    toLabel.Size = UDim2.new(1, 0, 0, 25)
    toLabel.Position = UDim2.new(0, 0, 0, 130)
    toLabel.BackgroundTransparency = 1
    toLabel.Text = "Ke: " .. targetName
    toLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    toLabel.Font = Enum.Font.Gotham
    toLabel.TextSize = 14
    
    -- Progress bar
    local progressBg = Instance.new("Frame", main)
    progressBg.Size = UDim2.new(1, -40, 0, 8)
    progressBg.Position = UDim2.new(0, 20, 0, 165)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    progressBg.BorderSizePixel = 0
    
    local progressCorner = Instance.new("UICorner", progressBg)
    progressCorner.CornerRadius = UDim.new(0, 4)
    
    local progressFill = Instance.new("Frame", progressBg)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    progressFill.BorderSizePixel = 0
    
    local fillCorner = Instance.new("UICorner", progressFill)
    fillCorner.CornerRadius = UDim.new(0, 4)
    
    -- Status
    local statusLabel = Instance.new("TextLabel", main)
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0, 175)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Memproses..."
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    
    -- Animate
    local tween = TweenService:Create(progressFill, TweenInfo.new(2, Enum.EasingStyle.Linear), {
        Size = UDim2.new(1, 0, 1, 0)
    })
    tween:Play()
    
    task.delay(0.5, function()
        statusLabel.Text = "Mengirim Robux..."
    end)
    
    task.delay(1.5, function()
        statusLabel.Text = "Hampir selesai..."
    end)
    
    -- Completion
    tween.Completed:Connect(function()
        statusLabel.Text = "BERHASIL! ✓"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        
        -- Success flash
        local flash = Instance.new("Frame", sg)
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        flash.BackgroundTransparency = 0.8
        flash.BorderSizePixel = 0
        flash.ZIndex = 10
        
        task.delay(0.3, function()
            flash:Destroy()
        end)
        
        task.delay(3, function()
            sg:Destroy()
        end)
    end)
    
    print("[Troll] Fake donation shown: R$" .. amount .. " to " .. targetName)
end

-- ===== FEATURE: CONTROL PLAYER =====
local function toggleControlPlayer(state)
    if controlConn then
        controlConn:Disconnect()
        controlConn = nil
    end
    if not state then
        controlledPlayer = nil
        return
    end
    
    controlledPlayer = getTargetPlayer()
    if not controlledPlayer then
        print("[Troll] No target player to control!")
        Toggles.ControlPlayer = false
        return
    end
    print("[Troll] Controlling: " .. controlledPlayer.Name)
    
    controlConn = RunService.Heartbeat:Connect(function()
        if not Toggles.ControlPlayer then return end
        if not controlledPlayer or not controlledPlayer.Character then
            -- Target left, try to find new one
            controlledPlayer = getTargetPlayer()
            if not controlledPlayer then return end
        end
        
        local targetHRP = controlledPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP or not myHRP then return end
        
        -- Move target to follow local player
        local offset = Vector3.new(3, 0, 3) -- offset behind
        local myCF = myHRP.CFrame
        local targetPos = myCF.Position + (myCF.LookVector * -3) + Vector3.new(0, 0, 0)
        
        -- Teleport target to position
        pcall(function()
            targetHRP.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.atan2(myCF.LookVector.X, myCF.LookVector.Z), 0)
        end)
        
        -- Also disable their movement
        local targetHumanoid = controlledPlayer.Character:FindFirstChildOfClass("Humanoid")
        if targetHumanoid then
            targetHumanoid.WalkSpeed = 0
            targetHumanoid.JumpPower = 0
        end
    end)
end

-- ===== FEATURE: FLING PLAYER =====
local function flingPlayer()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local power = Sliders.FlingPower or 5000
    local directions = {
        Vector3.new(0, power, 0),
        Vector3.new(power, power, 0),
        Vector3.new(-power, power, 0),
        Vector3.new(0, power, power),
        Vector3.new(0, power, -power),
        Vector3.new(power * 2, power, power * 2),
    }
    local dir = directions[math.random(1, #directions)]
    
    pcall(function()
        hrp.Velocity = dir
        hrp.RotVelocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
    end)
    print("[Troll] Flung " .. target.Name)
end

-- ===== FEATURE: FAKE KICK MESSAGE =====
local function fakeKickMessage()
    local target = getTargetPlayer()
    local targetName = target and target.Name or "Player"
    
    local msg = Instance.new("Message")
    msg.Text = targetName .. " has been kicked from the game: Reason: Exploiting/Cheating"
    msg.Parent = Workspace
    task.delay(5, function() msg:Destroy() end)
    print("[Troll] Fake kick message for " .. targetName)
end

-- ===== FEATURE: SPAM SOUND =====
local function spamSound()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Create annoying sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9120386436" -- earrape sound
    sound.Volume = 5
    sound.Looped = true
    sound.Parent = head
    sound:Play()
    
    task.delay(3, function()
        pcall(function() sound:Destroy() end)
    end)
    print("[Troll] Sound spam on " .. target.Name)
end

-- ===== FEATURE: FREEZE PLAYER =====
local function toggleFreezePlayer(state)
    if Connections.Freeze then
        Connections.Freeze:Disconnect()
        Connections.Freeze = nil
    end
    
    if not state then return end
    
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    
    local targetName = target.Name
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local frozenPos = targetHRP.Position
    local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
    
    print("[Troll] Freezing: " .. targetName)
    
    Connections.Freeze = RunService.Heartbeat:Connect(function()
        if not Toggles.FreezePlayer then return end
        pcall(function()
            if targetHRP and targetHRP.Parent then
                targetHRP.CFrame = CFrame.new(frozenPos)
                targetHRP.Velocity = Vector3.zero
                targetHRP.RotVelocity = Vector3.zero
            end
            if targetHumanoid then
                targetHumanoid.WalkSpeed = 0
                targetHumanoid.JumpPower = 0
            end
        end)
    end)
end

-- ===== FEATURE: TP TO ME =====
local function tpToMe()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not targetHRP then return end
    
    pcall(function()
        targetHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -3)
    end)
    print("[Troll] Teleported " .. target.Name .. " to you")
end

-- ===== FEATURE: SPIN PLAYER =====
local function toggleSpinPlayer(state)
    if Connections.Spin then
        Connections.Spin:Disconnect()
        Connections.Spin = nil
    end
    
    if not state then return end
    
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local angle = 0
    Connections.Spin = RunService.Heartbeat:Connect(function()
        if not Toggles.SpinPlayer then return end
        angle = angle + 0.5
        pcall(function()
            if targetHRP and targetHRP.Parent then
                targetHRP.CFrame = targetHRP.CFrame * CFrame.Angles(0, 0.5, 0)
                targetHRP.RotVelocity = Vector3.new(0, 20, 0)
            end
        end)
    end)
end

-- ===== FEATURE: FAKE CHAT =====
local function fakeChat()
    local messages = {
        "WKWKWK AKU HACKER",
        "AKU PUNYA ADMIN",
        "AKU BISA KICK KAMU",
        "ROBUX AKU 100M NIH",
        "AKU PUNYA SS SCRIPT NIH",
        "GAK USAH SOMBONG",
        "AKU BISA LIHAT CHAT KAMU",
        "AWAS KENA HACK",
    }
    local msg = messages[math.random(1, #messages)]
    
    -- Try TextChatService (new Roblox chat)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        local channels = TextChatService:FindFirstChild("TextChannels")
        if channels then
            local general = channels:FindFirstChild("RBXGeneral")
            if general then
                general:SendAsync(msg)
                print("[Troll] Sent chat: " .. msg)
                return
            end
        end
    end)
    
    -- Try legacy Chat service
    pcall(function()
        local Chat = game:GetService("Chat")
        if Chat then
            Chat:Chat(LocalPlayer.Character.Head, msg, Enum.ChatColor.Blue)
            print("[Troll] Sent legacy chat: " .. msg)
        end
    end)
    
    print("[Troll] Chat attempt: " .. msg)
end

-- ===== FEATURE: ADMIN COMMAND EXPLOIT =====
local function adminCommand(cmd)
    pcall(function()
        local adminFolder = ReplicatedStorage:FindFirstChild("Basic Admin Essentials")
        if adminFolder then
            local event = adminFolder:FindFirstChild("Essentials Event")
            if event then
                event:FireServer(cmd)
                print("[Troll] Admin command sent: " .. cmd)
            else
                print("[Troll] Essentials Event not found!")
            end
        else
            print("[Troll] Admin folder not found!")
        end
    end)
end

local function adminKick()
    local target = getTargetPlayer()
    if target then
        adminCommand(":kick " .. target.Name)
    end
end

local function adminFling()
    local target = getTargetPlayer()
    if target then
        adminCommand(":fling " .. target.Name)
    end
end

local function adminFreeze()
    local target = getTargetPlayer()
    if target then
        adminCommand(":freeze " .. target.Name)
    end
end

-- ===== FEATURE: KILL PLAYER =====
local function killPlayer()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid.Health = 0
            humanoid:Destroy()
        end)
    end
    -- BreakJoints as fallback
    pcall(function()
        target.Character:BreakJoints()
    end)
    print("[Troll] Killed " .. target.Name)
end

-- ===== FEATURE: EXPLODE PLAYER =====
local function explodePlayer()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    -- Flung all parts
    for _, part in ipairs(target.Character:GetDescendants()) do
        pcall(function()
            if part:IsA("BasePart") then
                part.Velocity = Vector3.new(
                    math.random(-100, 100),
                    math.random(50, 200),
                    math.random(-100, 100)
                )
                part.RotVelocity = Vector3.new(
                    math.random(-50, 50),
                    math.random(-50, 50),
                    math.random(-50, 50)
                )
            end
        end)
    end
    pcall(function() target.Character:BreakJoints() end)
    print("[Troll] Exploded " .. target.Name)
end

-- ===== FEATURE: TINY/GIANT PLAYER =====
local function tinyPlayer()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.Size = Vector3.new(0.5, 0.5, 0.5)
        end)
    end
    -- Scale all parts
    for _, part in ipairs(target.Character:GetDescendants()) do
        pcall(function()
            if part:IsA("BasePart") then
                part.Size = part.Size * 0.3
            end
        end)
    end
    print("[Troll] Shrunk " .. target.Name)
end

local function giantPlayer()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp.Size = Vector3.new(6, 6, 6)
        end)
    end
    for _, part in ipairs(target.Character:GetDescendants()) do
        pcall(function()
            if part:IsA("BasePart") then
                part.Size = part.Size * 3
            end
        end)
    end
    print("[Troll] Enlarged " .. target.Name)
end

-- ===== FEATURE: ROCKET PLAYER =====
local function rocketPlayer()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        hrp.Velocity = Vector3.new(0, 5000, 0)
        hrp.RotVelocity = Vector3.new(100, 100, 100)
    end)
    print("[Troll] Rocketed " .. target.Name)
end

-- ===== FEATURE: MOON WALK =====
local function moonWalk()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = -32
        end)
    end
    print("[Troll] Moon walk on " .. target.Name)
end

-- ===== FEATURE: JAIL PLAYER =====
local function jailPlayer()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local jail = Instance.new("Part")
    jail.Size = Vector3.new(6, 8, 6)
    jail.CFrame = hrp.CFrame
    jail.Anchored = true
    jail.Transparency = 0.3
    jail.Color = Color3.fromRGB(50, 50, 50)
    jail.Material = Enum.Material.Metal
    jail.Parent = Workspace
    
    -- Jail bars
    for i = 0, 3 do
        local angle = i * math.pi / 2
        local bar = Instance.new("Part")
        bar.Size = Vector3.new(0.3, 8, 0.3)
        bar.CFrame = jail.CFrame * CFrame.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
        bar.Anchored = true
        bar.Color = Color3.fromRGB(100, 100, 100)
        bar.Material = Enum.Material.Metal
        bar.Parent = Workspace
        task.delay(10, function() pcall(function() bar:Destroy() end) end)
    end
    
    task.delay(10, function() pcall(function() jail:Destroy() end) end)
    print("[Troll] Jailed " .. target.Name)
end

-- ===== FEATURE: RAINBOW PLAYER =====
local rainbowConns = {}
local function toggleRainbow(state)
    for _, conn in pairs(rainbowConns) do pcall(function() conn:Disconnect() end) end
    rainbowConns = {}
    if not state then return end
    
    local target = getTargetPlayer()
    if not target or not target.Character then
        Toggles.RainbowPlayer = false
        return
    end
    
    local hue = 0
    local conn = RunService.Heartbeat:Connect(function()
        if not Toggles.RainbowPlayer then return end
        if not target.Character then
            -- Target left, stop
            return
        end
        hue = (hue + 0.02) % 1
        local color = Color3.fromHSV(hue, 1, 1)
        for _, part in ipairs(target.Character:GetDescendants()) do
            pcall(function()
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Color = color
                end
            end)
        end
    end)
    rainbowConns[1] = conn
    print("[Troll] Rainbow on " .. target.Name)
end

-- ===== FEATURE: INVISIBLE SELF =====
local function toggleInvisible(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        pcall(function()
            if part:IsA("BasePart") then
                part.Transparency = state and 0.9 or 0
            end
            if part:IsA("Accessory") then
                part.Handle.Transparency = state and 0.9 or 0
            end
        end)
    end
    print("[Troll] Invisible: " .. tostring(state))
end

-- ===== FEATURE: NOCLIP =====
local function toggleNoclip(state)
    if Connections.Noclip then
        Connections.Noclip:Disconnect()
        Connections.Noclip = nil
    end
    if not state then return end
    
    Connections.Noclip = RunService.Stepped:Connect(function()
        if not Toggles.Noclip then return end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                pcall(function()
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end)
            end
        end
    end)
    print("[Troll] Noclip: " .. tostring(state))
end

-- ===== FEATURE: GOD MODE =====
local function toggleGod(state)
    if Connections.God then
        Connections.God:Disconnect()
        Connections.God = nil
    end
    if not state then return end
    
    Connections.God = RunService.Heartbeat:Connect(function()
        if not Toggles.GodMode then return end
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)
    print("[Troll] God Mode: " .. tostring(state))
end

-- ===== FEATURE: LAG SWITCH =====
local function toggleLagSwitch(state)
    if Connections.LagSwitch then
        Connections.LagSwitch:Disconnect()
        Connections.LagSwitch = nil
    end
    if not state then return end
    
    local lagToggle = false
    Connections.LagSwitch = RunService.Heartbeat:Connect(function()
        if not Toggles.LagSwitch then return end
        lagToggle = not lagToggle
        if lagToggle then
            -- Hang for a moment
            local start = tick()
            while tick() - start < 0.3 do end
        end
    end)
    print("[Troll] Lag Switch: " .. tostring(state))
end

-- ===== FEATURE: CONFUSE CAMERA =====
local function confuseCamera()
    local cam = getCamera()
    if not cam then return end
    -- Flip camera upside down
    cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.pi)
    task.delay(2, function()
        pcall(function()
            cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.pi)
        end)
    end)
    print("[Troll] Camera confused!")
end

-- ===== FEATURE: SPAM PARTS =====
local function spamParts()
    local target = getTargetPlayer()
    if not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for i = 1, 20 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1, 1, 1)
        part.CFrame = hrp.CFrame * CFrame.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
        part.Anchored = false
        part.CanCollide = true
        part.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
        part.Parent = Workspace
        task.delay(3, function() pcall(function() part:Destroy() end) end)
    end
    print("[Troll] Spammed parts on " .. target.Name)
end

-- ===== FEATURE: FLASHBANG =====
local function flashbang()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    
    local old = pg:FindFirstChild("Flashbang")
    if old then old:Destroy() end
    
    local sg = Instance.new("ScreenGui", pg)
    sg.Name = "Flashbang"
    
    local flash = Instance.new("Frame", sg)
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flash.BackgroundTransparency = 0
    flash.BorderSizePixel = 0
    flash.ZIndex = 99
    
    -- Fade out
    for i = 0, 10 do
        task.wait(0.1)
        flash.BackgroundTransparency = i / 10
    end
    sg:Destroy()
    print("[Troll] Flashbang!")
end

-- ===== FEATURE: EARTHQUAKE =====
local earthquakeConn = nil
local function toggleEarthquake(state)
    if earthquakeConn then
        earthquakeConn:Disconnect()
        earthquakeConn = nil
    end
    if not state then return end
    
    earthquakeConn = RunService.Heartbeat:Connect(function()
        if not Toggles.Earthquake then return end
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.CFrame = hrp.CFrame * CFrame.new(
                        math.random(-3, 3) / 10,
                        math.random(-1, 1) / 10,
                        math.random(-3, 3) / 10
                    )
                end)
            end
        end
    end)
    print("[Troll] Earthquake: " .. tostring(state))
end
local function createWindow(title)
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then
        repeat task.wait() until LocalPlayer:FindFirstChildOfClass("PlayerGui")
        pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title
    local old = pg:FindFirstChild(title)
    if old then old:Destroy() end
    ScreenGui.Parent = pg
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 580, 0, 420)
    Main.Position = UDim2.new(0.5, -290, 0.5, -210)
    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner", Main)
    UICorner.CornerRadius = UDim.new(0, 8)
    
    -- Title bar
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    TitleBar.BorderSizePixel = 0
    
    local TitleCorner = Instance.new("UICorner", TitleBar)
    TitleCorner.CornerRadius = UDim.new(0, 8)
    
    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 2)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.BorderSizePixel = 0
    
    local CloseCorner = Instance.new("UICorner", CloseBtn)
    CloseCorner.CornerRadius = UDim.new(0, 4)
    
    CloseBtn.MouseButton1Click:Connect(function()
        for _, conn in pairs(Connections) do
            pcall(function() conn:Disconnect() end)
        end
        if controlConn then controlConn:Disconnect() end
        ScreenGui:Destroy()
    end)
    
    -- Tab sidebar
    local TabContainer = Instance.new("Frame", Main)
    TabContainer.Size = UDim2.new(0, 130, 1, -35)
    TabContainer.Position = UDim2.new(0, 0, 0, 35)
    TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TabContainer.BorderSizePixel = 0
    
    -- Content area
    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size = UDim2.new(1, -130, 1, -35)
    ContentArea.Position = UDim2.new(0, 130, 0, 35)
    ContentArea.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ContentArea.BorderSizePixel = 0
    
    local tabs, currentTab = {}, nil
    
    local function createTab(name, icon)
        local btn = Instance.new("TextButton", TabContainer)
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        btn.Text = "  " .. icon .. "  " .. name
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        
        local content = Instance.new("ScrollingFrame", ContentArea)
        content.Size = UDim2.new(1, -20, 1, -20)
        content.Position = UDim2.new(0, 10, 0, 10)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 4
        content.Visible = false
        
        local layout = Instance.new("UIListLayout", content)
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end)
        
        btn.MouseButton1Click:Connect(function()
            if currentTab then currentTab.Visible = false end
            content.Visible = true
            currentTab = content
            for _, t in ipairs(tabs) do t.btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35) end
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        end)
        
        table.insert(tabs, {btn = btn, content = content})
        return content
    end
    
    local function createButton(parent, name, callback)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.Text = "  " .. name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
            task.delay(0.2, function()
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            end)
            callback()
        end)
        
        return btn
    end
    
    local function createToggle(parent, name, callback)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 30)
        container.BackgroundTransparency = 1
        
        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, -50, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "  " .. name
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local toggle = Instance.new("TextButton", container)
        toggle.Size = UDim2.new(0, 40, 0, 20)
        toggle.Position = UDim2.new(1, -45, 0.5, -10)
        toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        toggle.Text = ""
        toggle.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner", toggle)
        corner.CornerRadius = UDim.new(0, 10)
        
        Toggles[name:gsub("%s+", "")] = false
        
        toggle.MouseButton1Click:Connect(function()
            Toggles[name:gsub("%s+", "")] = not Toggles[name:gsub("%s+", "")]
            toggle.BackgroundColor3 = Toggles[name:gsub("%s+", "")]
                and Color3.fromRGB(0, 200, 100)
                or Color3.fromRGB(80, 80, 80)
            if callback then callback(Toggles[name:gsub("%s+", "")]) end
        end)
    end
    
    local function createLabel(parent, text)
        local lbl = Instance.new("TextLabel", parent)
        lbl.Size = UDim2.new(1, 0, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. text
        lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        return lbl
    end
    
    -- ===== BUILD TABS =====
    
    -- Tab 1: Player Troll
    local trollTab = createTab("Player", "🎭")
    createLabel(trollTab, "─ Target: Closest player to crosshair")
    createButton(trollTab, "Clone Avatar", cloneAvatar)
    createButton(trollTab, "TP Target To Me", tpToMe)
    createButton(trollTab, "Fling Player", flingPlayer)
    createButton(trollTab, "Rocket Player", rocketPlayer)
    createButton(trollTab, "Explode Player", explodePlayer)
    createButton(trollTab, "Kill Player", killPlayer)
    createButton(trollTab, "Tiny Player", tinyPlayer)
    createButton(trollTab, "Giant Player", giantPlayer)
    createButton(trollTab, "Moon Walk", moonWalk)
    createButton(trollTab, "Jail Player", jailPlayer)
    createButton(trollTab, "Spam Parts", spamParts)
    createToggle(trollTab, "Control Player", toggleControlPlayer)
    createToggle(trollTab, "Freeze Player", toggleFreezePlayer)
    createToggle(trollTab, "Spin Player", toggleSpinPlayer)
    createToggle(trollTab, "Rainbow Player", toggleRainbow)
    
    -- Tab 2: Visual Pranks
    local visualTab = createTab("Visual", "👁")
    createLabel(visualTab, "─ Fake Notifications")
    createButton(visualTab, "Fake Donasi Robux", showFakeDonation)
    createButton(visualTab, "Fake Chat Message", fakeChat)
    createButton(visualTab, "Fake Kick Message", fakeKickMessage)
    createButton(visualTab, "Spam Sound (3s)", spamSound)
    createButton(visualTab, "Flashbang", flashbang)
    createButton(visualTab, "Confuse Camera", confuseCamera)
    
    -- Tab 3: Self Mods
    local selfTab = createTab("Self", "🦸")
    createLabel(selfTab, "─ Local player mods")
    createToggle(selfTab, "Invisible", toggleInvisible)
    createToggle(selfTab, "Noclip", toggleNoclip)
    createToggle(selfTab, "God Mode", toggleGod)
    createToggle(selfTab, "Lag Switch", toggleLagSwitch)
    createToggle(selfTab, "Earthquake", toggleEarthquake)
    
    -- Tab 4: Admin Exploit
    local adminTab = createTab("Admin", "🔧")
    createLabel(adminTab, "─ BAE Admin Exploit (if perms)")
    createButton(adminTab, "Admin Kick", adminKick)
    createButton(adminTab, "Admin Fling", adminFling)
    createButton(adminTab, "Admin Freeze", adminFreeze)
    
    -- Tab 5: Settings
    local settingsTab = createTab("Settings", "⚙")
    createLabel(settingsTab, "─ INSERT to toggle menu")
    createLabel(settingsTab, "─ Target: closest to crosshair")
    createLabel(settingsTab, "─ Xeno Executor compatible")
    createLabel(settingsTab, "─ 30+ troll features")
    
    -- Activate first tab
    if tabs[1] then
        tabs[1].content.Visible = true
        tabs[1].btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        currentTab = tabs[1].content
    end
    
    -- INSERT toggle
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.Insert then
            Main.Visible = not Main.Visible
        end
    end)
    
    return ScreenGui
end

-- Initialize
local gui = createWindow("Troll Menu - OBROLAN")
print("[Troll Menu] Loaded - Press INSERT to toggle")
print("[Troll Menu] 30+ features: Kill, Explode, Rocket, Jail, Clone, Rainbow, Invisible, Noclip, God, more...")

-- ===== RESPAWN PERSISTENCE =====
LocalPlayer.CharacterRemoving:Connect(function(char)
    print("[Troll] Character died - disconnecting features")
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    if controlConn then
        controlConn:Disconnect()
        controlConn = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    print("[Troll] Character respawned - reinitializing")
    task.wait(0.2)
    if Toggles.ControlPlayer then toggleControlPlayer(true) end
    if Toggles.FreezePlayer then toggleFreezePlayer(true) end
    if Toggles.SpinPlayer then toggleSpinPlayer(true) end
    if Toggles.RainbowPlayer then toggleRainbow(true) end
    if Toggles.Noclip then toggleNoclip(true) end
    if Toggles.GodMode then toggleGod(true) end
    if Toggles.LagSwitch then toggleLagSwitch(true) end
    if Toggles.Earthquake then toggleEarthquake(true) end
    if Toggles.Invisible then toggleInvisible(true) end
end)