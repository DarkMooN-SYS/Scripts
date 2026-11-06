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

    pcall(function()
        local controllers = LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Controllers")
        ThrowMeter = require(controllers:WaitForChild("ThrowMeter"))
        ThrowController = require(controllers:WaitForChild("ThrowController"))
        RevealSequence = require(controllers:WaitForChild("RevealSequence"))
        ClientState = require(controllers:WaitForChild("ClientState"))
    end)

    -- ================================================================
    -- SETTINGS STATE
    -- ================================================================
    local autoPerfectThrow = true
    local autoLoopThrow = false
    local autoPlaceAnimals = true
    local autoEquipBest = true
    local fastReveal = true
    local autoTrain = false
    local rethrowDelay = 1.2
    local lastThrowTime = 0
    local isThrowing = false

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
                task.wait(0.2)
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
    -- HELPER FUNCTIONS
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

    -- ================================================================
    -- AUTO PLACE ANIMALS & EGGS
    -- ================================================================
    local function ProcessPlacement()
        if not autoPlaceAnimals or not Remotes then return end

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

    -- ================================================================
    -- AUTO EQUIP BEST
    -- ================================================================
    local function ProcessEquipBest()
        if not autoEquipBest or not Remotes then return end
        pcall(function()
            Remotes.Invoke("Plot_EquipBest")
        end)
    end

    -- ================================================================
    -- THROW MONITOR / RE-THROW LOOP
    -- ================================================================
    if ThrowController and ThrowController.Finished then
        local conn = ThrowController.Finished:Connect(function(result)
            lastThrowTime = os.clock()
            isThrowing = false

            -- Immediately run auto-place and equip best upon landing
            task.delay(0.3, function()
                ProcessPlacement()
                if autoEquipBest then
                    ProcessEquipBest()
                end
            end)
        end)
        table.insert(activeConnections, conn)
    end

    -- Main loop
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

            -- Auto Loop Throw
            if autoLoopThrow and not isThrowing and os.clock() - lastThrowTime >= rethrowDelay then
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                local isBusy = (ClientState and ClientState.Busy) ~= nil
                local isTraining = LocalPlayer:GetAttribute("Training") == true

                if hrp and humanoid and humanoid.Health > 0 and not isBusy and not isTraining then
                    isThrowing = true

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

            -- Auto Train (when not throwing and enabled)
            if autoTrain and not autoLoopThrow and not isThrowing and Remotes then
                local isTraining = LocalPlayer:GetAttribute("Training") == true
                if not isTraining then
                    local plot = GetPlot()
                    if plot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(plot.Position + Vector3.new(-16, 2, -30.5))
                        task.wait(0.3)
                        pcall(function()
                            Remotes.Invoke("Training_Start")
                        end)
                    end
                else
                    pcall(function()
                        Remotes.Invoke("Training_TapBonus")
                    end)
                end
            end
        end
    end)

    -- ================================================================
    -- UI SETUP
    -- ================================================================
    local farmTab = CreateTab("Food Farm", "rbxassetid://6031075938")

    -- SECTION: THROW CONTROLS (Left Column)
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

    -- SECTION: ANIMAL & PLOT AUTOMATION (Right Column)
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

    AddButton(placeSection, "Equip Best Animals Now", function()
        ProcessEquipBest()
        Notify("Equip Best", "Equipped best available animals", 2)
    end)

    AddButton(placeSection, "Place Carried Animals Now", function()
        ProcessPlacement()
        Notify("Place Animals", "Placed carried animals/eggs", 2)
    end)

    -- SECTION: STATS & INFO (Right Column)
    local statsSection = CreateSection(farmTab.Right, "Plot Status")
    local plotRow = AddLabel(statsSection, "Your Plot:", Theme.TextWhite)
    local animalsRow = AddLabel(statsSection, "Animals on Plot:", Theme.Accent)
    local incomeRow = AddLabel(statsSection, "Income Rate:", Theme.TextWhite)

    -- Live stat updates
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
            end)
        end
    end)

    return true
end

return Game
