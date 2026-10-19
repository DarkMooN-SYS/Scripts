local Game = {}

function Game.Configure(menu)
    if game.PlaceId ~= GameConfig139.PlaceId then
        return false
    end

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local TeleportService = game:GetService("TeleportService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local ScreenGui = menu.Gui
    local Main = menu.Main
    local Theme = menu.Context.Theme
    local IS_MOBILE = menu.Context.IsMobile
    local activeConnections = {}
    local cleanupCallbacks = {}
    local isDestroyed = false

    local function FastTween(object, duration, properties)
        menu.Context.Tween(object, duration, properties)
    end

    local function Notify(title, message, duration)
        if menu.Notify then menu.Notify(title, message, duration) end
    end

    local function CreateTab(name, icon)
        return menu.CreateTab(name, icon, "Experience controls")
    end
    local function CreateSection(parent, title)
        return menu.CreateSection(parent, title)
    end
    local function AddToggle(parent, label, default, callback)
        return menu.AddToggle(parent, label, default, menu.Debug.Wrap(label, callback))
    end
    local function AddSlider(parent, label, minimum, maximum, default, callback)
        return menu.AddSlider(parent, label, minimum, maximum, default, menu.Debug.Wrap(label, callback))
    end
    local function AddButton(parent, label, callback)
        return menu.AddButton(parent, label, menu.Debug.Wrap(label, callback))
    end
    local function AddLabel(parent, text, color)
        local row = menu.AddInfo(parent, text, "")
        if color and row and row.Value then row.Value.TextColor3 = color end
        return row
    end
    local function DestroyUI()
        menu.Destroy()
    end

    menu.AddCleanup(function()
        isDestroyed = true
        for _, callback in ipairs(cleanupCallbacks) do pcall(callback) end
        for _, connection in ipairs(activeConnections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(activeConnections)
    end)
-- PLACE ID: 139542527731344 FEATURE LOGIC (Safe Require)
-- ================================================================

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local SharedStats = nil
local originalStats = {}

pcall(function()
    local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
    local statsMod = sharedFolder and sharedFolder:FindFirstChild("Stats")
    if statsMod and statsMod:IsA("ModuleScript") then
        SharedStats = require(statsMod)
        if SharedStats then
            originalStats.instantPeel = SharedStats.instantPeel
        end
    end
end)

table.insert(cleanupCallbacks, function()
    if SharedStats and originalStats.instantPeel then
        SharedStats.instantPeel = originalStats.instantPeel
    end
end)

-- ================================================================
-- KEY WORLD LOCATIONS
-- ================================================================
local POTATO_PILE_POS = Vector3.new(104.7, 4.0, 17.0)
local CRATE_POS       = Vector3.new(52.9, 4.0, 19.5)
local POWER_BOX_POS   = Vector3.new(14.1, 4.6, 36.3)
local KITCHEN_POS     = Vector3.new(46.4, 4.0, 24.3)

-- ================================================================
-- CORE FARM & INTERACTION FUNCTIONS (ANY-RANGE)
-- ================================================================

local function getTopPotato()
    local pScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if pScripts then
        local ctrl = pScripts:FindFirstChild("Controllers")
        local pileCtrl = ctrl and ctrl:FindFirstChild("PileController")
        if pileCtrl then
            local ok, PileController = pcall(require, pileCtrl)
            if ok and PileController and PileController.clickAtScreen then
                local ok2, clickAt = pcall(debug.getupvalue, PileController.clickAtScreen, 1)
                if ok2 and clickAt then
                    local ok3, state = pcall(debug.getupvalue, clickAt, 1)
                    if ok3 and state and state.partCell then
                        for part, cell in pairs(state.partCell) do
                            if part and part.Parent then
                                local key = state.packKey(cell[1], cell[3])
                                local h = state.heights and state.heights[key]
                                if h and cell[2] == h - 1 then
                                    local tex = state.partTexture and state.partTexture[part] or 1
                                    return part, cell, tex
                                end
                            end
                        end
                        for part, cell in pairs(state.partCell) do
                            if part and part.Parent then
                                local tex = state.partTexture and state.partTexture[part] or 1
                                return part, cell, tex
                            end
                        end
                    end
                end
            end
        end
    end

    local pile = workspace:FindFirstChild("PotatoPile")
    if pile then
        local p = pile:FindFirstChildWhichIsA("MeshPart")
        if p then return p, {0, 0, 0}, 1 end
    end
    return nil, nil, nil
end

local function grabFromPile(returnBack)
    local grabbed = false
    pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local busy = LocalPlayer:GetAttribute("PotatoBusy")
        if busy then return end

        local topPart, topCell, topTex = getTopPotato()
        if not topPart or not topCell then return end

        local originalCF = hrp.CFrame
        local targetCF = topPart.CFrame + Vector3.new(0, 2.5, 0)
        local dist = (hrp.Position - topPart.Position).Magnitude
        local needsTp = dist > 12

        if needsTp then
            hrp.CFrame = targetCF
            task.wait(0.08)
        end

        if Remotes and Remotes:FindFirstChild("RemovePotato") then
            Remotes.RemovePotato:FireServer(topCell[1], topCell[2], topCell[3], topTex)
            grabbed = true
        end

        if needsTp and returnBack then
            task.wait(0.08)
            hrp.CFrame = originalCF
        end
    end)
    return grabbed
end

local function putPotatoesInCrate(returnBack)
    local put = false
    pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local dist = (hrp.Position - CRATE_POS).Magnitude
        local needsTp = dist > 10
        local originalCF = hrp.CFrame

        if needsTp then
            hrp.CFrame = CFrame.new(CRATE_POS)
            task.wait(0.08)
        end

        if Remotes and Remotes:FindFirstChild("CratePut") then
            Remotes.CratePut:FireServer()
            put = true
        end

        if needsTp and returnBack then
            task.wait(0.08)
            hrp.CFrame = originalCF
        end
    end)
    return put
end

local isRepairing = false

-- Тохиргоо (Хүссэн секундээ энд өөрчилж болно)
local CLOSE_DELAY = 0.5         -- Цэстэй байх хугацаа
local COOLDOWN_DURATION = 3     -- Засаж дууссаны дараа дахин шалгахгүй байх хүлээх хугацаа (сек)

local isRepairing = false
local lastRepairTime = 0

local function repairPowerBox(returnBack)
    if isRepairing then return end
    isRepairing = true

    pcall(function()
        local pbs = workspace:FindFirstChild("PowerBoxes")
        local pb = pbs and pbs:FindFirstChild("PowerBox1")
        if not pb then
            if typeof(Notify) == "function" then
                Notify("Power Box", "Power Box 1 not found in workspace!", 2.5)
            end
            isRepairing = false
            return
        end

        local char = LocalPlayer and LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local isFar = hrp and (hrp.Position - POWER_BOX_POS).Magnitude > 12
        local originalCF = nil

        -- 1. Хол байгаа бол байршил руу нь телепорт хийх
        if isFar and hrp then
            originalCF = hrp.CFrame
            hrp.CFrame = CFrame.new(POWER_BOX_POS)
            task.wait(0.15)
        end

        -- 2. ProximityPrompt-ийг албаар дарж мини-тоглоом/менюг идэвхжүүлэх
        local prompt = pb:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(0.1)
        end

        -- 3. ReplicatedStorage-оос Remotes-ийг найдвартай олж авах
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local remotes = replicatedStorage:FindFirstChild("Remotes")
        local powerCableRemote = remotes and remotes:FindFirstChild("PowerCable")

        if powerCableRemote then
            -- 1-ээс 6 хүртэл кабелийг залгах
            for i = 1, 6 do
                powerCableRemote:FireServer(pb, "Plug", i)
                task.wait(0.04)
            end

            -- Хайрцгийг хаах хүсэлт явуулах
            powerCableRemote:FireServer(pb, "Close")

            -- UI / Мини-тоглоомын цонхыг хаах хэсэг
            task.wait(CLOSE_DELAY)
            pcall(function()
                local pScripts = LocalPlayer:FindFirstChild("PlayerScripts")
                local ctrl = pScripts and pScripts:FindFirstChild("Controllers")
                local pwr = ctrl and ctrl:FindFirstChild("Power")
                local cableGameMod = pwr and pwr:FindFirstChild("CableGame")
                if cableGameMod then
                    local CableGame = require(cableGameMod)
                    if CableGame and CableGame.close then
                        CableGame.close()
                    end
                end
            end)
        end

        if typeof(Notify) == "function" then
            Notify("Power Box", "Power Box 1 successfully repaired!", 2.5)
        end
    end)

    lastRepairTime = tick()
    isRepairing = false
end

local function checkAnomalyDetected()
    local driveThru = workspace:FindFirstChild("DriveThru")
    if driveThru then
        if driveThru:GetAttribute("PatienceKind") == "Possessed" then
            return true, "DriveThru Possessed"
        end
        local car = driveThru:FindFirstChild("Car")
        if car and car:IsA("Model") then
            local anom = car:GetAttribute("Anomaly")
            if anom and anom ~= "None" and anom ~= "" then
                return true, tostring(anom)
            end
            local traits = car:GetAttribute("AnomalyTraits")
            if traits and traits ~= "None" and traits ~= "" then
                return true, tostring(traits)
            end
            if car:GetAttribute("AnomalyForced") == true then
                return true, "Anomaly Forced"
            end
        end
    end

    local traffic = workspace:FindFirstChild("Traffic")
    if traffic then
        for _, car in ipairs(traffic:GetChildren()) do
            if car:IsA("Model") then
                local anom = car:GetAttribute("Anomaly")
                if anom and anom ~= "None" and anom ~= "" then
                    return true, tostring(anom)
                end
                local traits = car:GetAttribute("AnomalyTraits")
                if traits and traits ~= "None" and traits ~= "" then
                    return true, tostring(traits)
                end
            end
        end
    end

    local anomalies = workspace:FindFirstChild("Anomalies")
    if anomalies and #anomalies:GetChildren() > 0 then
        return true, "Anomaly Entity"
    end

    return false, nil
end

-- -------------------------------------------------------------
-- TAB 1: 🍟 GAME (Potato Tycoon & Anomaly Defense)
-- -------------------------------------------------------------
local GameTab = CreateTab("Game", "🍟")
local FarmCol    = CreateSection(GameTab.Left,  "Auto Farm")
local AnomalyCol = CreateSection(GameTab.Right, "Anomaly Car Radar & Survival")
local TycoonCol  = CreateSection(GameTab.Right, "Tycoon Automation")

AddToggle(FarmCol, "Instant Peel (0s)", true, function(v)
    if SharedStats then
        if v then
            SharedStats.instantPeel = function() return true end
            Notify("Instant Peel", "Enabled: Potatoes peel in 0 seconds!", 2)
        else
            SharedStats.instantPeel = originalStats.instantPeel
            Notify("Instant Peel", "Disabled: Normal peeling restored", 2)
        end
    end
end)

local shutterCooldown = false
local autoFarmActive = false
AddToggle(FarmCol, "Auto Farm (Full Loop)", false, function(v)
    autoFarmActive = v
    Notify("Auto Farm", v and "Running: Continuous Pile -> Crate auto-farming (Big Scoop Enabled)!" or "Stopped", 2.5)
end)

task.spawn(function()
    while not isDestroyed do
        if autoFarmActive and not isRepairing and not shutterCooldown then
            pcall(function()
                local carry = LocalPlayer:GetAttribute("CarryCount") or 0
                local raw   = LocalPlayer:GetAttribute("CarryRaw")   or 0
                local busy  = LocalPlayer:GetAttribute("PotatoBusy")
                local char  = LocalPlayer.Character
                local hrp   = char and char:FindFirstChild("HumanoidRootPart")
                local cap   = (SharedStats and SharedStats.carryCapacity and SharedStats.carryCapacity(LocalPlayer)) or (LocalPlayer:GetAttribute("CarryCapacity")) or 3

                if not hrp or busy then task.wait(0.2) return end

                -- Сагс дүүрсэн эсвэл raw хэтэрсэн бол Карт руу зөөх
                if carry >= cap or (carry > 0 and raw > 99) then
                    hrp.CFrame = CFrame.new(CRATE_POS)
                    task.wait(0.1)
                    if Remotes and Remotes:FindFirstChild("CratePut") then
                        Remotes.CratePut:FireServer()
                    end
                    task.wait(0.25)
                else
                    -- Big Scoop ашиглан сагс дүүртэл цувралаар түүх хэсэг
                    while carry < cap and autoFarmActive and not isDestroyed do
                        local topPart, topCell, topTex = getTopPotato()
                        if topPart and topCell then
                            hrp.CFrame = topPart.CFrame + Vector3.new(0, 2.5, 0)
                            task.wait(0.02)
                            if Remotes and Remotes:FindFirstChild("RemovePotato") then
                                Remotes.RemovePotato:FireServer(topCell[1], topCell[2], topCell[3], topTex)
                            end
                            carry = carry + 1
                            task.wait(0.05)
                        else
                            hrp.CFrame = CFrame.new(POTATO_PILE_POS + Vector3.new(0, 2.5, 0))
                            task.wait(0.2)
                            break
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

local autoRepairPowerActive = false
AddToggle(FarmCol, "Auto Repair Power Box 1", false, function(v)
    autoRepairPowerActive = v
    Notify("Auto Power Repair", v and "Active: Will auto-fix Power Box 1 when broken" or "Disabled", 2)
end)

-- ----------------------------------------------------
-- ҮНДСЭН ШАЛГАХ ДАВТАЛТ (MAIN LOOP)
-- ----------------------------------------------------
task.spawn(function()
    while not isDestroyed do
        if autoRepairPowerActive and not isRepairing and (tick() - lastRepairTime >= COOLDOWN_DURATION) then
            pcall(function()
                local pbs = workspace:FindFirstChild("PowerBoxes")
                local pb = pbs and pbs:FindFirstChild("PowerBox1")
                local isBroken = false

                if pb then
                    -- ЗӨВХӨН PowerBroken == true үед л эвдэрсэн гэж үзнэ
                    if pb:GetAttribute("PowerBroken") == true then
                        isBroken = true
                    end
                end

                -- Зөвхөн үнэхээр эвдэрсэн үед засна
                if isBroken then
                    repairPowerBox(true)
                end
            end)
        end
        task.wait(2)
    end
end)

AddButton(FarmCol, "Repair Power Box 1 (Now)", function()
    repairPowerBox(true)
end)

-- -------------------------------------------------------------
-- ANOMALY CAR RADAR & SURVIVAL
-- -------------------------------------------------------------
local anomalyCarEspActive   = false
local autoShutterOnAnomaly  = false
local autoShutterClosedIt   = false
local shutterDebounce       = false
local anomalyCarHighlights  = {}
local anomalyCarBillboards  = {}

local function removeCarEsp(car)
    if anomalyCarHighlights[car] then
        anomalyCarHighlights[car]:Destroy()
        anomalyCarHighlights[car] = nil
    end
    if anomalyCarBillboards[car] then
        anomalyCarBillboards[car]:Destroy()
        anomalyCarBillboards[car] = nil
    end
end

local function updateCarEsp(car)
    if not anomalyCarEspActive or not car or not car:IsA("Model") then
        removeCarEsp(car)
        return
    end

    local anomaly = car:GetAttribute("Anomaly")
    local traits  = car:GetAttribute("AnomalyTraits") or "None"
    local driver  = car:GetAttribute("DriverName") or "Unknown"
    local isAnomaly = anomaly and anomaly ~= "None" and anomaly ~= ""

    if isAnomaly then
        if not anomalyCarHighlights[car] then
            local hl = Instance.new("Highlight")
            hl.Name = "MoonHub_AnomalyCarHL"
            hl.Adornee = car
            hl.FillColor = Color3.fromRGB(255, 30, 30)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.35
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = ScreenGui
            anomalyCarHighlights[car] = hl

            local root = car:FindFirstChildWhichIsA("BasePart") or car.PrimaryPart
            if root then
                local bb = Instance.new("BillboardGui")
                bb.Name = "MoonHub_AnomalyCarBB"
                bb.Adornee = root
                bb.Size = UDim2.new(0, 180, 0, 42)
                bb.StudsOffset = Vector3.new(0, 4.5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = ScreenGui

                anomalyCarBillboards[car] = bb
            end
        end
    else
        removeCarEsp(car)
        if not anomalyCarHighlights[car] then
            local hl = Instance.new("Highlight")
            hl.Name = "MoonHub_HumanCarHL"
            hl.Adornee = car
            hl.FillColor = Color3.fromRGB(0, 230, 120)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.5
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = ScreenGui
            anomalyCarHighlights[car] = hl

            local root = car:FindFirstChildWhichIsA("BasePart") or car.PrimaryPart
            if root then
                local bb = Instance.new("BillboardGui")
                bb.Name = "MoonHub_HumanCarBB"
                bb.Adornee = root
                bb.Size = UDim2.new(0, 140, 0, 24)
                bb.StudsOffset = Vector3.new(0, 4, 0)
                bb.AlwaysOnTop = true
                bb.Parent = ScreenGui

                anomalyCarBillboards[car] = bb
            end
        end
    end
end

local function scanTraffic()
    local traffic = workspace:FindFirstChild("Traffic")
    if traffic then
        for _, car in ipairs(traffic:GetChildren()) do
            updateCarEsp(car)
        end
    end
    local driveThru = workspace:FindFirstChild("DriveThru")
    local dtCar = driveThru and driveThru:FindFirstChild("Car")
    if dtCar then
        updateCarEsp(dtCar)
    end
end

AddToggle(AnomalyCol, "Anomaly Car ESP", false, function(v)
    anomalyCarEspActive = v
    if v then
        scanTraffic()
        Notify("Anomaly Radar", "Active: Anomaly cars in RED, Humans in GREEN", 2.5)
    else
        local traffic = workspace:FindFirstChild("Traffic")
        if traffic then
            for _, car in ipairs(traffic:GetChildren()) do
                removeCarEsp(car)
            end
        end
        local driveThru = workspace:FindFirstChild("DriveThru")
        local dtCar = driveThru and driveThru:FindFirstChild("Car")
        if dtCar then
            removeCarEsp(dtCar)
        end
    end
end)

local trafficFolder = workspace:FindFirstChild("Traffic")
if trafficFolder then
    table.insert(activeConnections, trafficFolder.ChildAdded:Connect(function(car)
        task.wait(0.2)
        if anomalyCarEspActive then
            updateCarEsp(car)
            car:GetAttributeChangedSignal("Anomaly"):Connect(function()
                updateCarEsp(car)
            end)
        end
    end))
    table.insert(activeConnections, trafficFolder.ChildRemoved:Connect(function(car)
        removeCarEsp(car)
    end))
end

local driveThruFolder = workspace:FindFirstChild("DriveThru")
if driveThruFolder then
    table.insert(activeConnections, driveThruFolder.ChildAdded:Connect(function(child)
        if child.Name == "Car" then
            task.wait(0.2)
            if anomalyCarEspActive then
                updateCarEsp(child)
                child:GetAttributeChangedSignal("Anomaly"):Connect(function()
                    updateCarEsp(child)
                end)
            end
        end
    end))
    table.insert(activeConnections, driveThruFolder.ChildRemoved:Connect(function(child)
        if child.Name == "Car" then
            removeCarEsp(child)
        end
    end))
end

local antiJumpscareActive = false
AddToggle(AnomalyCol, "Anti-Jumpscare", false, function(v)
    antiJumpscareActive = v
    Notify("Anti-Jumpscare", v and "Enabled: Screen jumpscares blocked" or "Disabled", 2)
end)

pcall(function()
    local pScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local ctrl = pScripts and pScripts:FindFirstChild("Controllers")
    local anomFolder = ctrl and ctrl:FindFirstChild("Anomaly")
    local anomScreenMod = anomFolder and anomFolder:FindFirstChild("AnomalyScreen")
    if anomScreenMod then
        local AnomalyScreen = require(anomScreenMod)
        local oldScare = AnomalyScreen.scare
        AnomalyScreen.scare = function(...)
            if antiJumpscareActive then return end
            return oldScare(...)
        end
        table.insert(cleanupCallbacks, function()
            AnomalyScreen.scare = oldScare
        end)
    end
end)

-- Close shutter
local function closeShutter()
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ShutterPress"):FireServer()
    end)
end

-- ── SHUTTER ───────────────────────────────────────────────────────
-- Only triggers when CarWaiting==true AND the car at the drive-thru window has Anomaly set
local autoShutterOnAnomaly = false
local shutterCooldown      = false
local autoShutterClosedIt  = false

-- Телепорт хийх координат
local SHUTTER_POS = Vector3.new(18.1, 4.0, 28.7)

AddToggle(AnomalyCol, "Auto Close on Anomaly at Window", false, function(v)
    autoShutterOnAnomaly = v
    Notify("Auto Shutter", v and "Active: closes when anomaly pulls up to window" or "OFF", 2)
end)

task.spawn(function()
    while not isDestroyed do
        if autoShutterOnAnomaly and not shutterCooldown then
            pcall(function()
                local dt = workspace:FindFirstChild("DriveThru")
                if not dt then return end
                local carWaiting = dt:GetAttribute("CarWaiting") == true
                local car        = dt:FindFirstChild("Car")
                local isAnomalyCar = car and carWaiting and (car:GetAttribute("Anomaly") ~= nil)

                local shutter = dt:FindFirstChild("Shutter")
                local isClosed = shutter and (shutter:GetAttribute("ShutterClosed") == true
                                           or shutter:GetAttribute("ShutterTo") == 1)

                if isAnomalyCar then
                    if not isClosed then
                        shutterCooldown = true

                        -- 1. Тухайн цэг рүү очиж телепорт хийх (Буцаж ирэх хэсгийг хассан)
                        local char = LocalPlayer and LocalPlayer.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        local isFar = hrp and (hrp.Position - SHUTTER_POS).Magnitude > 6

                        if isFar and hrp then
                            hrp.CFrame = CFrame.new(SHUTTER_POS)
                            task.wait(0.15) -- Байрлалдаа очтол бага зэрэг хүлээх
                        end

                        -- 2. Shutter-ийг хаах үйлдэл
                        closeShutter()
                        autoShutterClosedIt = true
                        Notify("🚨 AUTO SHUTTER", "Anomaly at window! Teleported & Shutter closed!", 3)

                        task.delay(5, function() shutterCooldown = false end)
                    end
                else
                    -- Reopen if we closed it and no anomaly now
                    if autoShutterClosedIt and isClosed and not shutterCooldown then
                        shutterCooldown = true

                        closeShutter()
                        autoShutterClosedIt = false
                        Notify("✅ AUTO SHUTTER", "Anomaly gone! Shutter reopened!", 2.5)

                        task.delay(5, function() shutterCooldown = false end)
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

AddButton(AnomalyCol, "Toggle Shutter (Manual)", function()
    closeShutter()
    Notify("Shutter", "Toggled drive-thru shutter", 2)
end)

local autoTycoonActive = false
AddToggle(TycoonCol, "Auto Step On Tycoon Pads", false, function(v)
    autoTycoonActive = v
    Notify("Auto Tycoon", v and "Active: Auto-buying available pads" or "Disabled", 2)
end)

task.spawn(function()
    while not isDestroyed do
        if autoTycoonActive then
            pcall(function()
                local tycoon = workspace:FindFirstChild("Tycoon")
                local pads   = tycoon and tycoon:FindFirstChild("Pads")
                local char   = LocalPlayer.Character
                local hrp    = char and char:FindFirstChild("HumanoidRootPart")
                if pads and hrp then
                    for _, pad in ipairs(pads:GetChildren()) do
                        if not autoTycoonActive then break end
                        local trig = pad:FindFirstChild("Trigger")
                        if trig and trig:IsA("BasePart") then
                            if firetouchinterest then
                                firetouchinterest(hrp, trig, 0)
                                task.wait()
                                firetouchinterest(hrp, trig, 1)
                            else
                                local oldPos = hrp.CFrame
                                hrp.CFrame = trig.CFrame
                                task.wait(0.08)
                                hrp.CFrame = oldPos
                            end
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- -------------------------------------------------------------
-- TAB 2: 📍 TELEPORTS (Place 139542527731344 Key Locations)
-- -------------------------------------------------------------
local TeleportTab = CreateTab("Teleports", "📍")
local WorkSpots = CreateSection(TeleportTab.Left,  "Station & Kitchen")
local MapSpots  = CreateSection(TeleportTab.Right, "Shops & Secrets")

local function TeleportTo(pos, name)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0))
        Notify("Teleport", "Arrived at: " .. name, 2)
    end
end

AddButton(WorkSpots, "Kitchen Station / Peeler", function()
    TeleportTo(Vector3.new(46.4, 4.0, 24.3), "Kitchen Peeler")
end)

AddButton(WorkSpots, "Potato Pile", function()
    TeleportTo(Vector3.new(104.7, 4.0, 17.0), "Potato Pile")
end)

AddButton(WorkSpots, "Drive-Thru Window", function()
    TeleportTo(Vector3.new(13.5, 4.8, 23.3), "Drive-Thru Window")
end)

AddButton(WorkSpots, "Power Box 1", function()
    TeleportTo(Vector3.new(14.1, 4.6, 36.3), "Power Box 1")
end)

AddButton(MapSpots, "Item Shop", function()
    TeleportTo(Vector3.new(28.3, 4.0, 29.3), "Item Shop")
end)

AddButton(MapSpots, "Merchant Shop", function()
    TeleportTo(Vector3.new(30.0, 4.0, 157.9), "Merchant Shop")
end)

AddButton(MapSpots, "Basement Padlock", function()
    TeleportTo(Vector3.new(103.8, 3.0, 40.9), "Basement Padlock")
end)

AddButton(MapSpots, "Safe Rooftop (High Spot)", function()
    TeleportTo(Vector3.new(24.4, 32.0, 20.4), "Safe Rooftop")
end)

-- -------------------------------------------------------------
-- TAB 3: 🏃 PLAYER (Movement & Mobility)
-- -------------------------------------------------------------
local PlayerTab = CreateTab("Player", "🏃")
local MoveCol = CreateSection(PlayerTab.Left,  "Movement Stats")
local FlyCol  = CreateSection(PlayerTab.Right, "Flight & Tools")

local speedEnabled = false
local customSpeed  = 16
local jumpEnabled  = false
local customJump   = 50

AddSlider(MoveCol, "WalkSpeed", 16, 200, 16, function(val)
    customSpeed = val
    if speedEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end)

AddToggle(MoveCol, "Enable Speed Loop", false, function(v)
    speedEnabled = v
    if not v and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)

AddSlider(MoveCol, "JumpPower", 50, 300, 50, function(val)
    customJump = val
    if jumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then
            if hum.UseJumpPower then hum.JumpPower = val else hum.JumpHeight = val * 0.144 end
        end
    end
end)

AddToggle(MoveCol, "Enable Jump Loop", false, function(v)
    jumpEnabled = v
    if not v and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then
            if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
        end
    end
end)

table.insert(activeConnections, RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then
            if speedEnabled then hum.WalkSpeed = customSpeed end
            if jumpEnabled then
                if hum.UseJumpPower then hum.JumpPower = customJump else hum.JumpHeight = customJump * 0.144 end
            end
        end
    end
end))

local infJumpActive = false
AddToggle(MoveCol, "Infinite Jump", false, function(v)
    infJumpActive = v
end)

table.insert(activeConnections, UserInputService.JumpRequest:Connect(function()
    if infJumpActive and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

local noclipActive = false
AddToggle(MoveCol, "Noclip (Through Walls)", false, function(v)
    noclipActive = v
end)

table.insert(activeConnections, RunService.Stepped:Connect(function()
    if noclipActive and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

local flyActive = false
local flySpeed  = 50
local flyBV     = nil
local flyBG     = nil
local flyConn   = nil

local function setFly(state)
    flyActive = state
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildWhichIsA("Humanoid")

    if state and hrp and hum then
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "MoonHub_FlyBV"
        flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "MoonHub_FlyBG"
        flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        flyBG.CFrame = hrp.CFrame
        flyBG.Parent = hrp

        hum.PlatformStand = true

        flyConn = RunService.RenderStepped:Connect(function()
            if not flyActive or not hrp or not hum or not flyBV or not flyBG then return end
            local cam = workspace.CurrentCamera
            flyBG.CFrame = cam.CFrame

            local dir = Vector3.zero
            if not IS_MOBILE then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            else
                local md = hum.MoveDirection
                if md.Magnitude > 0 then
                    dir = (cam.CFrame:VectorToWorldSpace(Vector3.new(md.X, 0, md.Z))).Unit
                end
            end

            if dir.Magnitude > 0 then
                flyBV.Velocity = dir.Unit * flySpeed
            else
                flyBV.Velocity = Vector3.zero
            end
        end)
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        if hum then hum.PlatformStand = false end
    end
end

table.insert(cleanupCallbacks, function() setFly(false) end)

AddToggle(FlyCol, "Fly (PC & Mobile)", false, function(v)
    setFly(v)
end)

AddSlider(FlyCol, "Fly Speed", 10, 200, 50, function(val)
    flySpeed = val
end)

AddButton(FlyCol, "Reset Character", function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.Health = 0 end
    end
end)

-- -------------------------------------------------------------
-- TAB 4: ⚙️ SETTINGS (Info & Utils)
-- -------------------------------------------------------------
local SettingsTab = CreateTab("Settings", "⚙️")
local InfoCol = CreateSection(SettingsTab.Left,  "Status & Info")
local UtilCol = CreateSection(SettingsTab.Right, "Game Utilities")

AddLabel(InfoCol, "Place: Map1 (139542527731344)", Theme.Accent)
AddLabel(InfoCol, "Player: " .. LocalPlayer.Name, Theme.TextWhite)
AddLabel(InfoCol, "Platform: " .. (IS_MOBILE and "Mobile Touch" or "PC Keyboard"), Theme.TextMuted)

AddButton(InfoCol, "Copy Current Coordinates", function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local text = string.format("Vector3.new(%.1f, %.1f, %.1f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
        if setclipboard then
            setclipboard(text)
            Notify("Copied", text, 2.5)
        else
            print("MoonHub Pos:", text)
            Notify("Position", text, 2.5)
        end
    end
end)

local antiAfkActive = true
AddToggle(UtilCol, "Anti-AFK (No 20m Kick)", true, function(v)
    antiAfkActive = v
end)

table.insert(activeConnections, LocalPlayer.Idled:Connect(function()
    if antiAfkActive then
        local VirtualUser = game:GetService("VirtualUser")
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end))

AddButton(UtilCol, "Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

AddButton(UtilCol, "Server Hop", function()
    pcall(function()
        local sf = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
        for _, s in ipairs(sf.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                break
            end
        end
    end)
end)

AddButton(UtilCol, "Unload Script (Close & Clean)", DestroyUI)
end

return Game


