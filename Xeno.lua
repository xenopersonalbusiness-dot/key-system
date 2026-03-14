local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "!Xeno Bizzare Lineage",
    LoadingTitle = "Made By xenobouthere on Discord!",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "XenoConfigs",
        FileName = "XenoBLConfig"
    },
    KeySystem = false,
})

-- Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- VARIABLES & CONFIG
--------------------------------------------------------------------------------

-- Toggles
local FarmingArrow = false
local FarmingBoss = false
local FarmingRaid = false 
local SafeMode = false
local RollingStand = false
local AntiAFK = false

-- Targets
local CurrentTargetArrow = nil
local SelectedBosses = {} 

-- Optimization Caches
local DetectedArrows = {} -- Stores arrows so we don't scan workspace every frame

-- Logic States
local IsComboing = false 

-- Position Mode
local PositionMode = "Behind"
local PositionDistance = 3

-- Lists
local StandList = {
    "Red Hot Chili Pepper", "Magician's Red", "The Hand", "Purple Haze",
    "Crazy Diamond", "Gold Experience", "Anubis", "Killer Queen",
    "Weather Report", "Stone Free", "Star Platinum", "The World",
    "King Crimson", "The World High Voltage", "Whitesnake"
}
local DesiredStands = {}

-- ESP Settings
local ESP_Settings = {
    Highlight = false, Box = false, Name = false, Stand = false, Arrow = false,
    Color_Global = Color3.fromRGB(255, 0, 0),
    Color_Text = Color3.fromRGB(255, 255, 255),
    Color_Arrow = Color3.fromRGB(255, 215, 0)
}

local ESP_Cache = {} 
local Arrow_Highlights = {} -- Cache for arrow ESP visuals

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function getController()
    if LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChild("client_character_controller")
    end
    return nil
end

local function getStandName(player)
    if not player or not player:FindFirstChild("PlayerData") then return "None" end
    local slotData = player.PlayerData:FindFirstChild("SlotData")
    if not slotData then return "None" end
    local standVal = slotData:FindFirstChild("Stand")
    if not standVal or not standVal:IsA("StringValue") then return "None" end

    local success, data = pcall(function()
        return HttpService:JSONDecode(standVal.Value)
    end)
    
    if success and data and data.Name then
        return data.Name
    end
    return "None"
end

local function isArrow(obj)
    if obj.Name == "Stand Arrow" then
        if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool") then return true end
    end
    return false
end

local function getArrowPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChild("Handle") end
    if obj:IsA("Tool") then return obj:FindFirstChild("Handle") end
    return nil
end

local function getBoss()
    local live = Workspace:FindFirstChild("Live")
    if live then
        for _, child in pairs(live:GetChildren()) do
            if child:FindFirstChild("Humanoid") and child.Humanoid.Health > 0 and child:FindFirstChild("HumanoidRootPart") then
                for _, selected in pairs(SelectedBosses) do
                    if selected == "Kira" and string.find(child.Name, "Yoshikage Kira") then 
                        return child 
                    end
                    if selected == "Musashi" and string.find(child.Name, "Miyamoto Musashi") then 
                        return child 
                    end
                    if selected == "Okuyasu" and string.find(child.Name, "Okuyasu Nijimura PRIME") then 
                        return child 
                    end
                    if selected == "Stroheim" and string.find(child.Name, "Zombie Rudol von Stroheim") then 
                        return child 
                    end
                end
            end
        end
    end
    return nil
end

local function getRaidTarget()
    local live = Workspace:FindFirstChild("Live")
    local nearest = nil
    local dist = 9999
    
    if live and LocalPlayer.Character then
        local myRoot = getRoot(LocalPlayer.Character)
        if not myRoot then return nil end
        
        for _, child in pairs(live:GetChildren()) do
            -- Ensure it's NOT a real player
            if not Players:GetPlayerFromCharacter(child) then
                -- Skip "Server" and anything with "Hostage" in the name
                local skipThis = false
                if child.Name == "Server" then 
                    skipThis = true 
                end
                if string.find(child.Name, "Hostage") then 
                    skipThis = true 
                end
                
                if not skipThis then
                    if child:FindFirstChild("Humanoid") and child.Humanoid.Health > 0 and child:FindFirstChild("HumanoidRootPart") then
                        local d = (child.HumanoidRootPart.Position - myRoot.Position).Magnitude
                        if d < dist then
                            dist = d
                            nearest = child
                        end
                    end
                end
            end
        end
    end
    return nearest
end

--------------------------------------------------------------------------------
-- POSITION HELPER (Only used when SafeMode is OFF)
--------------------------------------------------------------------------------
local function getNormalPositionCFrame(targetRoot)
    if PositionMode == "Above" then
        return CFrame.new(targetRoot.Position + Vector3.new(0, PositionDistance, 0), targetRoot.Position)
    elseif PositionMode == "Below" then
        return CFrame.new(targetRoot.Position + Vector3.new(0, -PositionDistance, 0), targetRoot.Position)
    else -- Behind (default)
        return targetRoot.CFrame * CFrame.new(0, 0, PositionDistance)
    end
end

--------------------------------------------------------------------------------
-- OPTIMIZATION LOOP (Find Arrows Efficiently)
--------------------------------------------------------------------------------
-- Instead of scanning every frame, we scan every 2 seconds.
task.spawn(function()
    while true do
        local found = {}
        for _, v in pairs(Workspace:GetDescendants()) do
            if isArrow(v) and getArrowPart(v) then
                table.insert(found, v)
            end
        end
        DetectedArrows = found -- Update the global list
        task.wait(2) -- Refresh rate (Lowers CPU usage)
    end
end)

--------------------------------------------------------------------------------
-- ANTI AFK LOOP
--------------------------------------------------------------------------------
task.spawn(function()
    while true do
        if AntiAFK then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
        task.wait(60)
    end
end)

--------------------------------------------------------------------------------
-- TABS
--------------------------------------------------------------------------------

local MainTab = Window:CreateTab("Auto Farm", 4483362458)
local RaidTab = Window:CreateTab("Raid", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

--------------------------------------------------------------------------------
-- AUTO FARM TAB
--------------------------------------------------------------------------------

MainTab:CreateSection("Boss Farming")

MainTab:CreateDropdown({
    Name = "Select Targets",
    Options = {"Kira", "Musashi", "Okuyasu", "Stroheim"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "BossSelect",
    Callback = function(Option) SelectedBosses = Option end,
})

MainTab:CreateToggle({
    Name = "Farm Bosses",
    CurrentValue = false,
    Flag = "BossToggle",
    Callback = function(Value)
        FarmingBoss = Value
        IsComboing = false
    end,
})

MainTab:CreateToggle({
    Name = "Safe Mode",
    CurrentValue = false,
    Flag = "SafeModeToggle",
    Callback = function(Value) SafeMode = Value end,
})

MainTab:CreateSection("Item Farming")

MainTab:CreateToggle({
    Name = "Farm Arrow",
    CurrentValue = false,
    Flag = "ArrowToggle",
    Callback = function(Value)
        FarmingArrow = Value
        CurrentTargetArrow = nil
    end,
})

MainTab:CreateSection("Auto Stand")

MainTab:CreateDropdown({
    Name = "Select Desired Stand(s)",
    Options = StandList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "StandSelect",
    Callback = function(Option) DesiredStands = Option end,
})

MainTab:CreateToggle({
    Name = "Auto Use Arrow",
    CurrentValue = false,
    Flag = "RollToggle",
    Callback = function(Value) RollingStand = Value end,
})

--------------------------------------------------------------------------------
-- RAID TAB
--------------------------------------------------------------------------------

RaidTab:CreateSection("Raid Logic")

RaidTab:CreateToggle({
    Name = "Auto Raid",
    CurrentValue = false,
    Flag = "RaidToggle",
    Callback = function(Value)
        FarmingRaid = Value
        IsComboing = false
    end,
})

RaidTab:CreateToggle({
    Name = "Safe Mode (Raid)",
    CurrentValue = false,
    Flag = "RaidSafeToggle",
    Callback = function(Value) SafeMode = Value end,
})

--------------------------------------------------------------------------------
-- SETTINGS TAB
--------------------------------------------------------------------------------

SettingsTab:CreateSection("Farm Positioning")

SettingsTab:CreateDropdown({
    Name = "Position Mode",
    Options = {"Behind", "Above", "Below"},
    CurrentOption = {"Behind"},
    MultipleOptions = false,
    Flag = "PositionModeSelect",
    Callback = function(Option)
        if type(Option) == "table" then
            PositionMode = Option[1] or "Behind"
        else
            PositionMode = tostring(Option)
        end
    end,
})

SettingsTab:CreateSlider({
    Name = "Position Distance",
    Range = {1, 30},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 3,
    Flag = "PositionDistanceSlider",
    Callback = function(Value)
        PositionDistance = Value
    end,
})

SettingsTab:CreateSection("Misc")

SettingsTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value) 
        AntiAFK = Value 
    end,
})

--------------------------------------------------------------------------------
-- LOGIC LOOPS
--------------------------------------------------------------------------------

-- 1. Auto Stand Roll (Runs independently)
task.spawn(function()
    while true do
        if RollingStand then
            -- Pause if busy farming to prevent glitches
            if FarmingBoss or FarmingRaid then
                -- Wait
            else
                local currentStand = getStandName(LocalPlayer)
                local obtained = false
                for _, desired in pairs(DesiredStands) do
                    if currentStand == desired then 
                        obtained = true 
                        break 
                    end
                end
                
                if obtained then
                    RollingStand = false
                    Rayfield:Notify({Title = "Stand Obtained!", Content = "You got: " .. currentStand, Duration = 6.5, Image = 4483362458})
                else
                    ReplicatedStorage.requests.character.use_item:FireServer("Stand Arrow")
                    task.wait(2.5)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- 2. Movement Loop
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local root = char and getRoot(char)
    if not root then return end

    -- [PRIORITY 1: ARROWS]
    if FarmingArrow then
        -- Check if current target is invalid
        if not CurrentTargetArrow or not CurrentTargetArrow.Parent then
            CurrentTargetArrow = nil
            -- Look in our CACHED list instead of scanning workspace (Fixes lag)
            if #DetectedArrows > 0 then
                CurrentTargetArrow = DetectedArrows[1] -- Grab the first one found
            end
        end

        if CurrentTargetArrow then
            local targetPart = getArrowPart(CurrentTargetArrow)
            if targetPart then
                root.CFrame = targetPart.CFrame
                for _, part in pairs(char:GetChildren()) do 
                    if part:IsA("BasePart") then 
                        part.CanCollide = false 
                    end 
                end
                return 
            end
        end
    end

    -- [PRIORITY 2: BOSSES]
    if FarmingBoss then
        local boss = getBoss()
        if boss then
            local bossRoot = boss.HumanoidRootPart
            
            if SafeMode then
                -- Safe Mode: go up between combos, come down to attack (original behavior)
                if IsComboing then
                    root.CFrame = bossRoot.CFrame * CFrame.new(0, 0, 3)
                else
                    root.CFrame = bossRoot.CFrame * CFrame.new(0, 20, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                end
            else
                -- Normal: stay in chosen position the ENTIRE time (attacking + waiting)
                root.CFrame = getNormalPositionCFrame(bossRoot)
                
                -- Force noclip for Below position
                if PositionMode == "Below" then
                    for _, part in pairs(char:GetChildren()) do 
                        if part:IsA("BasePart") then 
                            part.CanCollide = false 
                        end 
                    end
                end
            end
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
            root.AssemblyAngularVelocity = Vector3.new(0,0,0)
            return
        end
    end

    -- [PRIORITY 3: RAID]
    if FarmingRaid then
        local raidTarget = getRaidTarget()
        if raidTarget then
            local targetRoot = raidTarget.HumanoidRootPart
            
            if SafeMode then
                -- Safe Mode: go up between combos, come down to attack (original behavior)
                if IsComboing then
                    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                else
                    root.CFrame = targetRoot.CFrame * CFrame.new(0, 20, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                end
            else
                -- Normal: stay in chosen position the ENTIRE time (attacking + waiting)
                root.CFrame = getNormalPositionCFrame(targetRoot)
                
                -- Force noclip for Below position
                if PositionMode == "Below" then
                    for _, part in pairs(char:GetChildren()) do 
                        if part:IsA("BasePart") then 
                            part.CanCollide = false 
                        end 
                    end
                end
            end
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
            root.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end
    end
end)

-- 3. Action Loop
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        
        -- Arrow Pickup
        if FarmingArrow and CurrentTargetArrow and CurrentTargetArrow.Parent then
            local prompt = CurrentTargetArrow:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then 
                fireproximityprompt(prompt) 
            end
            
        -- Boss / Raid Attack Logic
        elseif FarmingBoss or FarmingRaid then
            local target = nil
            
            if FarmingBoss then 
                target = getBoss() 
            elseif FarmingRaid then 
                target = getRaidTarget()
            end
            
            local controller = getController()
            
            if target and controller and controller:FindFirstChild("M1") then
                IsComboing = true
                
                -- 5 Hit Combo
                for i = 1, 5 do
                    if FarmingArrow and #DetectedArrows > 0 then 
                        break 
                    end
                    if FarmingBoss and not getBoss() then 
                        break 
                    end
                    if FarmingRaid and not getRaidTarget() then 
                        break 
                    end
                    
                    controller.M1:FireServer(true, false)
                    task.wait(0.35)
                end
                
                IsComboing = false
                
                -- Cooldown
                for i = 1, 22 do 
                    if FarmingArrow and #DetectedArrows > 0 then 
                        break 
                    end
                    task.wait(0.1)
                end
            end
        end
        
        task.wait(0.1)
    end
end)

--------------------------------------------------------------------------------
-- ESP SYSTEM (Optimized)
--------------------------------------------------------------------------------
local function createESPObjects(player)
    if ESP_Cache[player] then return end 
    local objects = {
        Box = Drawing.new("Square"), Name = Drawing.new("Text"), Stand = Drawing.new("Text"), Highlight = Instance.new("Highlight")
    }
    objects.Box.Thickness = 1
    objects.Box.Transparency = 1
    objects.Box.Filled = false
    objects.Name.Size = 14
    objects.Name.Center = true
    objects.Name.Outline = true
    objects.Name.Font = 2
    objects.Stand.Size = 13
    objects.Stand.Center = true
    objects.Stand.Outline = true
    objects.Stand.Font = 2
    objects.Highlight.FillTransparency = 0.5
    objects.Highlight.OutlineTransparency = 0
    ESP_Cache[player] = objects
end

local function removeESPObjects(player)
    local objects = ESP_Cache[player]
    if objects then
        if objects.Box then objects.Box:Remove() end
        if objects.Name then objects.Name:Remove() end
        if objects.Stand then objects.Stand:Remove() end
        if objects.Highlight then objects.Highlight:Destroy() end
        ESP_Cache[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    -- Player ESP
    for player, objects in pairs(ESP_Cache) do
        if player.Parent and player.Character and player.Character.Parent and player.Character.Parent.Name == "Live" and player ~= LocalPlayer then
            local char = player.Character
            local root = getRoot(char)
            if root then
                local vec, onScreen = Camera:WorldToViewportPoint(root.Position)
                local dist = (Camera.CFrame.Position - root.Position).Magnitude

                if ESP_Settings.Highlight then
                    if objects.Highlight.Parent ~= char then objects.Highlight.Parent = char end
                    objects.Highlight.FillColor = ESP_Settings.Color_Global
                    objects.Highlight.OutlineColor = ESP_Settings.Color_Global
                    objects.Highlight.Enabled = true
                else 
                    objects.Highlight.Enabled = false 
                end

                if onScreen then
                    local sizeScale = 1000 / dist
                    local width = 3 * sizeScale
                    local height = 5 * sizeScale
                    
                    if ESP_Settings.Box then
                        objects.Box.Visible = true
                        objects.Box.Size = Vector2.new(width, height)
                        objects.Box.Position = Vector2.new(vec.X - width/2, vec.Y - height/2)
                        objects.Box.Color = ESP_Settings.Color_Global
                    else 
                        objects.Box.Visible = false 
                    end

                    if ESP_Settings.Name then
                        objects.Name.Visible = true
                        objects.Name.Text = player.Name
                        objects.Name.Position = Vector2.new(vec.X, vec.Y - height/2 - 15)
                        objects.Name.Color = ESP_Settings.Color_Text
                    else 
                        objects.Name.Visible = false 
                    end

                    if ESP_Settings.Stand then
                        objects.Stand.Visible = true
                        objects.Stand.Text = getStandName(player)
                        objects.Stand.Position = Vector2.new(vec.X, vec.Y + height/2 + 5)
                        objects.Stand.Color = ESP_Settings.Color_Text
                    else 
                        objects.Stand.Visible = false 
                    end
                else
                    objects.Box.Visible = false
                    objects.Name.Visible = false
                    objects.Stand.Visible = false
                end
            else
                objects.Box.Visible = false
                objects.Name.Visible = false
                objects.Stand.Visible = false
            end
        else
            objects.Box.Visible = false
            objects.Name.Visible = false
            objects.Stand.Visible = false
            objects.Highlight.Enabled = false
        end
    end

    -- Arrow ESP (Highly Optimized)
    if ESP_Settings.Arrow then
        for _, arrow in pairs(DetectedArrows) do
            if arrow and arrow.Parent then
                if not Arrow_Highlights[arrow] then
                    local h = Instance.new("Highlight")
                    h.Parent = arrow
                    h.FillTransparency = 1
                    h.OutlineTransparency = 0
                    h.OutlineColor = ESP_Settings.Color_Arrow
                    Arrow_Highlights[arrow] = h
                else
                    Arrow_Highlights[arrow].OutlineColor = ESP_Settings.Color_Arrow
                end
            end
        end
        
        for arrow, highlight in pairs(Arrow_Highlights) do
            if not arrow or not arrow.Parent then
                highlight:Destroy()
                Arrow_Highlights[arrow] = nil
            end
        end
    else
        for arrow, highlight in pairs(Arrow_Highlights) do
            highlight:Destroy()
            Arrow_Highlights[arrow] = nil
        end
    end
end)

Players.PlayerAdded:Connect(function(plr) 
    plr.CharacterAdded:Connect(function() 
        createESPObjects(plr) 
    end) 
end)

Players.PlayerRemoving:Connect(function(plr) 
    removeESPObjects(plr) 
end)

for _, plr in pairs(Players:GetPlayers()) do 
    if plr ~= LocalPlayer then 
        createESPObjects(plr) 
        plr.CharacterAdded:Connect(function() 
            createESPObjects(plr) 
        end) 
    end 
end

--------------------------------------------------------------------------------
-- UI SETTINGS
--------------------------------------------------------------------------------
ESPTab:CreateSection("Player Visuals")
ESPTab:CreateToggle({Name = "Highlight", CurrentValue = false, Callback = function(v) ESP_Settings.Highlight = v end})
ESPTab:CreateToggle({Name = "Box ESP", CurrentValue = false, Callback = function(v) ESP_Settings.Box = v end})
ESPTab:CreateColorPicker({Name = "Main Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) ESP_Settings.Color_Global = v end})
ESPTab:CreateSection("Text Info")
ESPTab:CreateToggle({Name = "Name ESP", CurrentValue = false, Callback = function(v) ESP_Settings.Name = v end})
ESPTab:CreateToggle({Name = "Stand ESP", CurrentValue = false, Callback = function(v) ESP_Settings.Stand = v end})
ESPTab:CreateColorPicker({Name = "Text Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) ESP_Settings.Color_Text = v end})
ESPTab:CreateSection("Items")
ESPTab:CreateToggle({Name = "Arrow ESP", CurrentValue = false, Callback = function(v) ESP_Settings.Arrow = v end})
ESPTab:CreateColorPicker({Name = "Arrow Color", Color = Color3.fromRGB(255, 215, 0), Callback = function(v) ESP_Settings.Color_Arrow = v end})

Rayfield:LoadConfiguration()