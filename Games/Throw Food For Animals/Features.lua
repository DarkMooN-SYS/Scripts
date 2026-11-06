local Game = {}

function Game.Configure(menu)
    if game.PlaceId ~= GameConfigFood.PlaceId then
        return false
    end

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

    local function CreateTab(name, icon, desc)
        return menu.CreateTab(name, icon, desc or "Experience controls")
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
        local val = row and row:FindFirstChild("Value")
        if color and val then val.TextColor3 = color end
        return row
    end

    menu.AddCleanup(function()
        isDestroyed = true
        for _, callback in ipairs(cleanupCallbacks) do pcall(callback) end
        for _, connection in ipairs(activeConnections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(activeConnections)
    end)

    -- ================================================================
    -- GAME CONTROLLER REFERENCES & REMOTES
    -- ================================================================
    local Remotes = nil
    pcall(function()
        Remotes = require(ReplicatedStorage.Shared.Remotes)
    end)

    local ThrowMeter = nil
    local ThrowController = nil
    local RevealSequence = nil
    local ClientState = nil
    local TrainingController = nil
    local SuperThrow = nil
    local DataController = nil
    local FoodsConfig = nil

    pcall(function()
        local controllers = LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Controllers")
        ThrowMeter = require(controllers:WaitForChild("ThrowMeter"))
        ThrowController = require(controllers:WaitForChild("ThrowController"))
        RevealSequence = require(controllers:WaitForChild("RevealSequence"))
        ClientState = require(controllers:WaitForChild("ClientState"))
        TrainingController = require(controllers:WaitForChild("TrainingController"))
        SuperThrow = require(controllers:WaitForChild("SuperThrow"))
        DataController = require(controllers:WaitForChild("DataController"))
    end)

    pcall(function()
        FoodsConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("FoodsConfig"))
    end)

    -- ================================================================
    -- SETTINGS STATE
    -- ================================================================
    -- Throw & Plot
    local autoPerfectThrow = true
    local fastReveal = true
    local autoLoopThrow = false
    local autoSuperThrow = true
    local autoPlaceAnimals = true
    local autoEquipBest = true
    local autoSellAllBackpack = false
    local rethrowDelay = 1.2
    local lastThrowTime = 0
    local isThrowing = false

    -- Training & Upgrades
    local autoTrain = false
    local autoClaimBonus = true
    local autoUpgradeStand = false
    local autoUpgradeFence = false
    local autoBuyBestFood = false
    local autoClaimOffline = true

    -- Movement / Player
    local customWalkSpeed = 16
    local walkSpeedEnabled = false
    local customJumpPower = 50
    local jumpPowerEnabled = false
    local infiniteJumpEnabled = false
    local noclipEnabled = false

    -- ================================================================
    -- HOOK: AUTO PERFECT THROW
    -- ================================================================
    if ThrowMeter and not ThrowMeter._moonHooked then
        ThrowMeter._moonHooked = true
        local origNew = ThrowMeter.new
        ThrowMeter.new = function(...)
            local meter = origNew(...)
            if autoPerfectThrow then
                meter.Locked = true
                ThrowMeter.TestAutoTap = 0.38
            else
                ThrowMeter.TestAutoTap = nil
            end
            return meter
        end

        table.insert(cleanupCallbacks, function()
            ThrowMeter.new = origNew
            ThrowMeter.TestAutoTap = nil
            ThrowMeter._moonHooked = nil
        end)
    end

    -- ================================================================
    -- HOOK: FAST / SKIP REVEAL
    -- ================================================================
    if RevealSequence and not RevealSequence._moonHooked then
        RevealSequence._moonHooked = true
        local origRun = RevealSequence.Run
        RevealSequence.Run = function(args)
            if fastReveal then
                task.wait(0.15)
                return
            end
            return origRun(args)
        end

        table.insert(cleanupCallbacks, function()
            RevealSequence.Run = origRun
            RevealSequence._moonHooked = nil
        end)
    end

    -- ================================================================
    -- HOOK: HUDController.SetGameplayVisible
    -- Keep MooN Hub Menu visible even during throw or training sequences
    -- ================================================================
    pcall(function()
        local controllers = LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Controllers")
        local HUDController = require(controllers:WaitForChild("HUDController"))
        if HUDController and not HUDController._moonHooked then
            HUDController._moonHooked = true
            local origSetVisible = HUDController.SetGameplayVisible
            HUDController.SetGameplayVisible = function(visible, filter)
                if not visible and filter and typeof(filter) == "table" then
                    filter["MooN_HUB_Menu"] = true
                elseif not visible and not filter then
                    filter = { ["MooN_HUB_Menu"] = true }
                end
                return origSetVisible(visible, filter)
            end

            table.insert(cleanupCallbacks, function()
                HUDController.SetGameplayVisible = origSetVisible
                HUDController._moonHooked = nil
            end)
        end
    end)
    -- ================================================================
    pcall(function()
        if Remotes and Remotes.Event then
            local bonusEvent = Remotes.Event("Training_Bonus")
            if bonusEvent and bonusEvent.OnClientEvent then
                local conn = bonusEvent.OnClientEvent:Connect(function(bonusData)
                    if autoClaimBonus and bonusData and bonusData.Id then
                        task.spawn(function()
                            pcall(function()
                                Remotes.Invoke("Training_TapBonus", bonusData.Id)
                            end)
                        end)
                    end
                end)
                table.insert(activeConnections, conn)
            end
        end
    end)

    -- ================================================================
    -- HELPER FUNCTIONS & TELEPORT LOCATIONS
    -- ================================================================
    local function GetPlot()
        local plotIndex = LocalPlayer:GetAttribute("PlotIndex")
        if not plotIndex then return nil end
        return workspace.Plots:FindFirstChild(tostring(plotIndex))
    end

    local function GetRandomPlotPosition()
        local plot = GetPlot()
        if not plot then return nil end
        local rx = math.random(-14, 14)
        local rz = math.random(-14, 14)
        return plot.Position + Vector3.new(rx, 0.5, rz)
    end

    local function GetThrowLineCFrame()
        local starter = workspace:FindFirstChild("StarterArea")
        local crossLine = starter and starter:FindFirstChild("CrossLine")
        if crossLine then
            return CFrame.new(crossLine.Position.X, crossLine.Position.Y + 2.5, crossLine.Position.Z + 2)
        end
        return CFrame.new(0, 5, -38)
    end

    local function GetStandCFrame()
        local plot = GetPlot()
        if plot then
            local server = plot:FindFirstChild("Server")
            local stand = server and server:FindFirstChild("PullUpStand")
            if stand then
                if stand:IsA("Model") then
                    return stand:GetPivot() + Vector3.new(0, 2.5, 0)
                elseif stand:IsA("BasePart") then
                    return stand.CFrame + Vector3.new(0, 2.5, 0)
                end
            end
            return CFrame.new(plot.Position + Vector3.new(-16, 2, -30.5))
        end
        return nil
    end

    local function TeleportTo(cf)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and cf then
            hrp.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
        end
    end

    -- ================================================================
    -- AUTO ACTIONS
    -- ================================================================
    local function ProcessPlacement()
        if not Remotes then return end

        local character = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")

        local tools = {}
        if character then
            for _, item in ipairs(character:GetChildren()) do
                if item:IsA("Tool") and (item:GetAttribute("AnimalId") or item:GetAttribute("EggKey")) then
                    table.insert(tools, item)
                end
            end
        end
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and (item:GetAttribute("AnimalId") or item:GetAttribute("EggKey")) then
                    table.insert(tools, item)
                end
            end
        end

        for _, tool in ipairs(tools) do
            local animalId = tool:GetAttribute("AnimalId")
            local eggKey = tool:GetAttribute("EggKey")
            local pos = GetRandomPlotPosition()

            if pos then
                if eggKey then
                    pcall(function()
                        Remotes.Invoke("Egg_Place", eggKey, pos)
                    end)
                    task.wait(0.2)
                elseif animalId then
                    pcall(function()
                        Remotes.Invoke("Plot_PlaceAnimal", animalId, pos)
                    end)
                    task.wait(0.2)
                end
            end
        end
    end

    local function ProcessEquipBest()
        if not Remotes then return end
        pcall(function()
            Remotes.Invoke("Plot_EquipBest")
        end)
    end

    local function ProcessSellAll()
        if not Remotes then return end
        pcall(function()
            Remotes.Invoke("Plot_SellAll")
        end)
    end

    local function ProcessUpgradeStand()
        if not Remotes then return end
        pcall(function()
            Remotes.Invoke("Stand_Upgrade")
        end)
    end

    local function ProcessUpgradeFence()
        if not Remotes then return end
        pcall(function()
            Remotes.Invoke("Plot_UpgradeFence")
        end)
    end

    local function ProcessClaimOffline()
        if not Remotes then return end
        pcall(function()
            Remotes.Invoke("Offline_Claim")
        end)
    end

    local function ProcessClaimFreeShop()
        if not Remotes then return end
        pcall(function()
            Remotes.Invoke("Shop_ClaimFree")
        end)
    end

    local function ProcessBuyBestFood()
        if not Remotes or not FoodsConfig or not DataController then return end
        pcall(function()
            local data = DataController.GetData and DataController:GetData()
            if not data then return end
            local money = data.Money or 0
            local owned = data.OwnedFoods or {}
            local equipped = data.EquippedFood

            local bestOwnedIndex = 1
            local candidateBuy = nil

            for i, food in ipairs(FoodsConfig.List or {}) do
                local idx = food.Index or i
                local isOwned = owned[tostring(idx)] == true or owned[idx] == true
                if isOwned then
                    if idx > bestOwnedIndex then
                        bestOwnedIndex = idx
                    end
                else
                    if not candidateBuy and food.Price and money >= food.Price then
                        candidateBuy = food
                    end
                end
            end

            if candidateBuy then
                local res = Remotes.Invoke("Shop_Buy", candidateBuy.Index)
                if res and res.Ok then
                    Notify("Auto Food", "Purchased " .. tostring(candidateBuy.Name) .. "!", 2)
                    Remotes.Invoke("Shop_Equip", candidateBuy.Index)
                    return
                end
            end

            if equipped and tonumber(equipped) ~= bestOwnedIndex and bestOwnedIndex > 1 then
                Remotes.Invoke("Shop_Equip", bestOwnedIndex)
            end
        end)
    end

    -- ================================================================
    -- THROW MONITOR / RE-THROW LOOP
    -- ================================================================
    if ThrowController and ThrowController.Finished then
        local conn = ThrowController.Finished:Connect(function(result)
            lastThrowTime = os.clock()
            isThrowing = false

            task.delay(0.3, function()
                if autoPlaceAnimals then
                    pcall(ProcessPlacement)
                end
                if autoEquipBest then
                    pcall(ProcessEquipBest)
                end
                if autoSellAllBackpack then
                    pcall(ProcessSellAll)
                end
            end)
        end)
        table.insert(activeConnections, conn)
    end

    -- ================================================================
    -- MAIN AUTOMATION LOOP
    -- ================================================================
    task.spawn(function()
        local tickCounter = 0
        while not isDestroyed do
            task.wait(0.5)
            tickCounter = tickCounter + 1

            -- Auto Place check every ~1s
            if autoPlaceAnimals and tickCounter % 2 == 0 then
                pcall(ProcessPlacement)
            end

            -- Auto Equip Best every ~4s
            if autoEquipBest and tickCounter % 8 == 0 then
                pcall(ProcessEquipBest)
            end

            -- Auto Sell Backpack every ~5s
            if autoSellAllBackpack and tickCounter % 10 == 0 then
                pcall(ProcessSellAll)
            end

            -- Auto Upgrade Stand every ~3s
            if autoUpgradeStand and tickCounter % 6 == 0 then
                pcall(ProcessUpgradeStand)
            end

            -- Auto Upgrade Fence every ~4s
            if autoUpgradeFence and tickCounter % 8 == 0 then
                pcall(ProcessUpgradeFence)
            end

            -- Auto Buy Best Food every ~5s
            if autoBuyBestFood and tickCounter % 10 == 0 then
                pcall(ProcessBuyBestFood)
            end

            -- Auto Claim Offline Earnings every ~15s
            if autoClaimOffline and tickCounter % 30 == 0 then
                pcall(ProcessClaimOffline)
            end

            -- Auto Loop Throw
            if autoLoopThrow and not isThrowing and os.clock() - lastThrowTime >= rethrowDelay then
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                local isBusy = (ClientState and ClientState.Busy) ~= nil
                local isTraining = LocalPlayer:GetAttribute("Training") == true

                if hrp and humanoid and humanoid.Health > 0 and not isBusy and not isTraining then
                    isThrowing = true

                    -- Check Super Throw
                    if autoSuperThrow and Remotes and DataController then
                        pcall(function()
                            local supers = tonumber(DataController:GetPath("SuperThrows")) or 0
                            if supers > 0 then
                                Remotes.Invoke("Throw_UseSuper")
                            end
                        end)
                    end

                    -- Move to throw line
                    hrp.CFrame = GetThrowLineCFrame()
                    task.wait(0.3)

                    -- Trigger throw
                    if ThrowController and ThrowController.Start then
                        pcall(function()
                            ThrowController.Start()
                        end)
                    end

                    -- Safety reset if throw didn't start in 5 seconds
                    task.delay(5, function()
                        if isThrowing and (not ClientState or ClientState.Busy ~= "Throw") then
                            isThrowing = false
                        end
                    end)
                end
            end

            -- Auto Pull-Up Train
            if autoTrain and not autoLoopThrow and not isThrowing and Remotes then
                local isTraining = LocalPlayer:GetAttribute("Training") == true
                if not isTraining then
                    local standCF = GetStandCFrame()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if standCF and hrp then
                        hrp.CFrame = standCF
                        task.wait(0.3)
                        pcall(function()
                            if TrainingController and TrainingController.Start then
                                TrainingController.Start()
                            else
                                Remotes.Invoke("Training_Start")
                            end
                        end)
                    end
                end
            end
        end
    end)

    -- ================================================================
    -- PLAYER MOVEMENT & UTILITIES
    -- ================================================================
    local function applyMovement()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if walkSpeedEnabled then
                hum.WalkSpeed = customWalkSpeed
            end
            if jumpPowerEnabled then
                hum.UseJumpPower = true
                hum.JumpPower = customJumpPower
            end
        end
    end

    local moveConn = RunService.Heartbeat:Connect(applyMovement)
    table.insert(activeConnections, moveConn)

    -- Infinite Jump
    local jumpConn = UserInputService.JumpRequest:Connect(function()
        if infiniteJumpEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    table.insert(activeConnections, jumpConn)

    -- Noclip
    local noclipConn = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    table.insert(activeConnections, noclipConn)

    -- ================================================================
    -- UI: TAB 1 - FOOD FARM (🍖)
    -- ================================================================
    local farmTab = CreateTab("Food Farm", "🍖", "Throwing & Animal Automation")

    local throwSection = CreateSection(farmTab.Left, "Throw Controls")

    AddToggle(throwSection, "Auto Perfect Throw (100% Power)", autoPerfectThrow, function(enabled)
        autoPerfectThrow = enabled
        Notify("Perfect Throw", enabled and "Auto 100% PERFECT enabled" or "Disabled", 2)
    end)

    AddToggle(throwSection, "Fast Reveal / Skip Animation", fastReveal, function(enabled)
        fastReveal = enabled
        Notify("Fast Reveal", enabled and "Animal reveal animation bypassed" or "Disabled", 2)
    end)

    AddToggle(throwSection, "Auto Re-Throw (Infinite Loop)", autoLoopThrow, function(enabled)
        autoLoopThrow = enabled
        if enabled then
            autoTrain = false
        end
        Notify("Auto Throw", enabled and "Continuous auto-throw loop started" or "Stopped", 2)
    end)

    AddToggle(throwSection, "Auto Super Throw", autoSuperThrow, function(enabled)
        autoSuperThrow = enabled
        Notify("Super Throw", enabled and "Auto Super Throw enabled" or "Disabled", 2)
    end)

    AddSlider(throwSection, "Re-Throw Delay", 0.5, 5.0, rethrowDelay, function(val)
        rethrowDelay = val
    end)

    AddButton(throwSection, "Manual Perfect Throw (Start Once)", function()
        if ThrowController and ThrowController.Start then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = GetThrowLineCFrame()
                task.wait(0.2)
            end
            ThrowController.Start()
            Notify("Throw Started", "Executing perfect throw...", 2)
        end
    end)

    local placeSection = CreateSection(farmTab.Right, "Animals & Plot")

    AddToggle(placeSection, "Auto Place Animals & Eggs", autoPlaceAnimals, function(enabled)
        autoPlaceAnimals = enabled
        if enabled then pcall(ProcessPlacement) end
        Notify("Auto Place", enabled and "Placing unplaced animals/eggs on plot" or "Disabled", 2)
    end)

    AddToggle(placeSection, "Auto Equip Best Animals", autoEquipBest, function(enabled)
        autoEquipBest = enabled
        if enabled then pcall(ProcessEquipBest) end
        Notify("Auto Equip Best", enabled and "Always placing highest income animals" or "Disabled", 2)
    end)

    AddToggle(placeSection, "Auto Sell Backpack Animals", autoSellAllBackpack, function(enabled)
        autoSellAllBackpack = enabled
        if enabled then pcall(ProcessSellAll) end
        Notify("Auto Sell", enabled and "Auto selling carried backpack animals" or "Disabled", 2)
    end)

    AddButton(placeSection, "Equip Best Animals Now", function()
        ProcessEquipBest()
        Notify("Equip Best", "Equipped best available animals", 2)
    end)

    AddButton(placeSection, "Place Carried Animals Now", function()
        ProcessPlacement()
        Notify("Place Animals", "Placed carried animals/eggs", 2)
    end)

    AddButton(placeSection, "Sell All Backpack Animals", function()
        ProcessSellAll()
        Notify("Sell All", "Sold carried animals from backpack", 2)
    end)

    local statsSection = CreateSection(farmTab.Right, "Plot & Stats")
    local plotRow = AddLabel(statsSection, "Your Plot:", Theme.TextWhite)
    local animalsRow = AddLabel(statsSection, "Animals on Plot:", Theme.Accent)
    local incomeRow = AddLabel(statsSection, "Income Rate:", Theme.TextWhite)
    local powerRow = AddLabel(statsSection, "Throw Power:", Theme.Accent)
    local moneyRow = AddLabel(statsSection, "Current Money:", Theme.TextWhite)

    task.spawn(function()
        while not isDestroyed do
            task.wait(1.5)
            pcall(function()
                local plotIndex = LocalPlayer:GetAttribute("PlotIndex")
                if plotRow and plotRow:FindFirstChild("Value") then
                    plotRow.Value.Text = plotIndex and ("Plot #" .. tostring(plotIndex)) or "None"
                end

                local plot = GetPlot()
                local animalCount = 0
                if plot and plot:FindFirstChild("Animals") then
                    animalCount = #plot.Animals:GetChildren()
                end
                if animalsRow and animalsRow:FindFirstChild("Value") then
                    animalsRow.Value.Text = tostring(animalCount) .. " Animals"
                end

                local income = LocalPlayer:GetAttribute("IncomeRate") or 0
                if incomeRow and incomeRow:FindFirstChild("Value") then
                    incomeRow.Value.Text = "$" .. tostring(income) .. "/s"
                end

                if DataController and DataController.GetData then
                    local d = DataController:GetData()
                    if d then
                        if powerRow and powerRow:FindFirstChild("Value") then
                            powerRow.Value.Text = tostring(d.ThrowPower or 0)
                        end
                        if moneyRow and moneyRow:FindFirstChild("Value") then
                            local m = tonumber(d.Money) or 0
                            if m >= 1e12 then
                                moneyRow.Value.Text = string.format("%.2e", m)
                            else
                                moneyRow.Value.Text = tostring(math.floor(m))
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- ================================================================
    -- UI: TAB 2 - TRAINING & UPGRADES (💪)
    -- ================================================================
    local trainTab = CreateTab("Training", "💪", "Pull-Ups, Stand & Economy Upgrades")

    local trainCol = CreateSection(trainTab.Left, "Pull-Up Training")

    AddToggle(trainCol, "Auto Pull-Up Train", autoTrain, function(enabled)
        autoTrain = enabled
        if enabled then
            autoLoopThrow = false
            local standCF = GetStandCFrame()
            if standCF then TeleportTo(standCF) end
        else
            pcall(function()
                if TrainingController and TrainingController.Stop then
                    TrainingController.Stop()
                elseif Remotes then
                    Remotes.Invoke("Training_Stop")
                end
            end)
        end
        Notify("Auto Train", enabled and "Continuous pull-up training active" or "Stopped", 2)
    end)

    AddToggle(trainCol, "Auto 2X Tap Bonus", autoClaimBonus, function(enabled)
        autoClaimBonus = enabled
        Notify("Tap Bonus", enabled and "Auto 2X power bonus enabled" or "Disabled", 2)
    end)

    AddButton(trainCol, "Start Training Now", function()
        local standCF = GetStandCFrame()
        if standCF then TeleportTo(standCF) end
        task.wait(0.2)
        pcall(function()
            if TrainingController and TrainingController.Start then
                TrainingController.Start()
            elseif Remotes then
                Remotes.Invoke("Training_Start")
            end
        end)
        Notify("Training", "Started pull-up training", 2)
    end)

    AddButton(trainCol, "Stop Training Now", function()
        pcall(function()
            if TrainingController and TrainingController.Stop then
                TrainingController.Stop()
            elseif Remotes then
                Remotes.Invoke("Training_Stop")
            end
        end)
        Notify("Training", "Stopped pull-up training", 2)
    end)

    local upgradeCol = CreateSection(trainTab.Right, "Auto Upgrades & Claims")

    AddToggle(upgradeCol, "Auto Upgrade Pull-Up Stand", autoUpgradeStand, function(enabled)
        autoUpgradeStand = enabled
        if enabled then pcall(ProcessUpgradeStand) end
        Notify("Auto Stand", enabled and "Auto upgrading stand when affordable" or "Disabled", 2)
    end)

    AddToggle(upgradeCol, "Auto Upgrade Plot Fence", autoUpgradeFence, function(enabled)
        autoUpgradeFence = enabled
        if enabled then pcall(ProcessUpgradeFence) end
        Notify("Auto Fence", enabled and "Auto upgrading fence when affordable" or "Disabled", 2)
    end)

    AddToggle(upgradeCol, "Auto Buy & Equip Best Food", autoBuyBestFood, function(enabled)
        autoBuyBestFood = enabled
        if enabled then pcall(ProcessBuyBestFood) end
        Notify("Auto Food", enabled and "Auto purchasing highest affordable food" or "Disabled", 2)
    end)

    AddToggle(upgradeCol, "Auto Claim Offline Profits", autoClaimOffline, function(enabled)
        autoClaimOffline = enabled
        if enabled then pcall(ProcessClaimOffline) end
        Notify("Offline Profits", enabled and "Auto claiming offline earnings" or "Disabled", 2)
    end)

    AddButton(upgradeCol, "Upgrade Stand Now", function()
        ProcessUpgradeStand()
        Notify("Stand", "Attempted pull-up stand upgrade", 2)
    end)

    AddButton(upgradeCol, "Upgrade Fence Now", function()
        ProcessUpgradeFence()
        Notify("Fence", "Attempted fence upgrade", 2)
    end)

    AddButton(upgradeCol, "Claim Offline Profits Now", function()
        ProcessClaimOffline()
        Notify("Offline", "Claimed offline profits", 2)
    end)

    AddButton(upgradeCol, "Claim Free Shop Reward", function()
        ProcessClaimFreeShop()
        Notify("Shop", "Attempted claiming free shop reward", 2)
    end)

    -- ================================================================
    -- UI: TAB 3 - TELEPORTS (📍)
    -- ================================================================
    local tpTab = CreateTab("Teleports", "📍", "Instant Fast-Travel & Biomes")

    local keyTpCol = CreateSection(tpTab.Left, "Key Locations")

    AddButton(keyTpCol, "Throw Line (Starter Area)", function()
        TeleportTo(GetThrowLineCFrame())
        Notify("Teleport", "Teleported to Throw Line", 1.5)
    end)

    AddButton(keyTpCol, "My Plot Center", function()
        local plot = GetPlot()
        if plot then
            TeleportTo(plot.Position + Vector3.new(0, 3, 0))
            Notify("Teleport", "Teleported to Plot", 1.5)
        else
            Notify("Teleport", "Plot not found", 2)
        end
    end)

    AddButton(keyTpCol, "My Pull-Up Stand", function()
        local standCF = GetStandCFrame()
        if standCF then
            TeleportTo(standCF)
            Notify("Teleport", "Teleported to Stand", 1.5)
        else
            Notify("Teleport", "Stand not found", 2)
        end
    end)

    AddButton(keyTpCol, "Sell Shop (SellPlace)", function()
        local sell = workspace:FindFirstChild("SellPlace")
        if sell then
            local pos = sell:IsA("Model") and sell:GetPivot().Position or sell.Position
            TeleportTo(pos + Vector3.new(0, 3, 0))
            Notify("Teleport", "Teleported to Sell Place", 1.5)
        end
    end)

    local biomePositions = {
        {"Forest (Area 1)", Vector3.new(-1, -10, -190)},
        {"Savanna (Area 2)", Vector3.new(-1, -13, -330)},
        {"Desert (Area 3)", Vector3.new(0, -16, -498)},
        {"Jungle (Area 4)", Vector3.new(0, -19, -666)},
        {"Ocean (Area 5)", Vector3.new(0, -22, -750)},
        {"Mountains (Area 6)", Vector3.new(0, -25, -954)},
        {"Taiga (Area 7)", Vector3.new(0, -28, -1190)},
        {"Winter (Area 8)", Vector3.new(0, -31, -1458)},
        {"Prehistoric Forest (Area 9)", Vector3.new(0, -34, -1670)},
        {"Deep Waters (Area 10)", Vector3.new(0, -37, -2042)},
        {"Hell (Area 11)", Vector3.new(0, -40, -2258)},
        {"Ancient Ruins (Area 12)", Vector3.new(0, -43, -2618)},
        {"Mythical Paradise (Area 13)", Vector3.new(0, -46, -3130)},
        {"Shadow Realm (Area 14)", Vector3.new(0, -49, -3710)},
        {"Harvest Fields (Area 15)", Vector3.new(0, -52, -4670)},
        {"Phantom Harbor (Area 16)", Vector3.new(0, -55, -5390)},
        {"Nuclear Wasteland (Area 17)", Vector3.new(0, -58, -6866)},
    }

    local biomeCol1 = CreateSection(tpTab.Right, "Biomes (Areas 1 - 9)")
    for i = 1, 9 do
        local entry = biomePositions[i]
        AddButton(biomeCol1, entry[1], function()
            TeleportTo(entry[2])
            Notify("Teleport", "Teleported to " .. entry[1], 1.5)
        end)
    end

    local biomeCol2 = CreateSection(tpTab.Left, "Biomes (Areas 10 - 17)")
    for i = 10, #biomePositions do
        local entry = biomePositions[i]
        AddButton(biomeCol2, entry[1], function()
            TeleportTo(entry[2])
            Notify("Teleport", "Teleported to " .. entry[1], 1.5)
        end)
    end

    -- ================================================================
    -- UI: TAB 4 - PLAYER (🏃)
    -- ================================================================
    local playerTab = CreateTab("Player", "🏃", "Movement, Speed & Utilities")

    local moveCol = CreateSection(playerTab.Left, "Movement Modifiers")

    AddToggle(moveCol, "Enable Custom WalkSpeed", walkSpeedEnabled, function(enabled)
        walkSpeedEnabled = enabled
        if not enabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end)

    AddSlider(moveCol, "WalkSpeed", 16, 150, customWalkSpeed, function(val)
        customWalkSpeed = val
        if walkSpeedEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end)

    AddToggle(moveCol, "Enable Custom JumpPower", jumpPowerEnabled, function(enabled)
        jumpPowerEnabled = enabled
        if not enabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = 50 end
        end
    end)

    AddSlider(moveCol, "JumpPower", 50, 200, customJumpPower, function(val)
        customJumpPower = val
        if jumpPowerEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = val
            end
        end
    end)

    local utilCol = CreateSection(playerTab.Right, "Mobility & Cheats")

    AddToggle(utilCol, "Infinite Jump", infiniteJumpEnabled, function(enabled)
        infiniteJumpEnabled = enabled
        Notify("Infinite Jump", enabled and "Enabled" or "Disabled", 1.5)
    end)

    AddToggle(utilCol, "Noclip", noclipEnabled, function(enabled)
        noclipEnabled = enabled
        Notify("Noclip", enabled and "Enabled" or "Disabled", 1.5)
    end)

    return true
end

return Game
