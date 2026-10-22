local Game = {}

function Game.Configure(menu)
    if game.PlaceId ~= GameConfigWW2.PlaceId then
        return false
    end

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    local activeConnections = {}
    local cleanupCallbacks = {}
    local isDestroyed = false

    local function Notify(title, message, duration)
        if menu.Notify then menu.Notify(title, message, duration) end
    end

    local function CreateTab(name, icon, desc)
        return menu.CreateTab(name, icon, desc or "WW2 Strategy Automation")
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
    -- GAME REMOTES & MODULES (Conquer The World WW2)
    -- ================================================================
    local CitiesFolder      = ReplicatedStorage:WaitForChild("Cities", 5)
    local PurchaseFactory   = CitiesFolder and CitiesFolder:WaitForChild("PurchaseFactory", 5)
    local PurchaseDefense   = CitiesFolder and CitiesFolder:WaitForChild("PurchaseDefense", 5)

    local ResearchFolder    = ReplicatedStorage:WaitForChild("Research", 5)
    local StartResearch     = ResearchFolder and ResearchFolder:WaitForChild("StartResearch", 5)
    local TryPurchaseTech   = ResearchFolder and ResearchFolder:WaitForChild("TryPurchaseTech", 5)

    local ArmyFolder        = ReplicatedStorage:WaitForChild("Army", 5)
    local TryIncreaseTarget = ArmyFolder and ArmyFolder:WaitForChild("TryIncreaseTarget", 5)
    local TryBuyManpower    = ArmyFolder and ArmyFolder:WaitForChild("TryBuyManpower", 5)
    local SetPriorityCity   = ArmyFolder and ArmyFolder:WaitForChild("SetPriorityCity", 5)

    local DiplomacyFolder   = ReplicatedStorage:WaitForChild("Diplomacy", 5)
    local AllianceCallToWar = DiplomacyFolder and DiplomacyFolder:WaitForChild("AllianceCallToWar", 5)

    local GovFolder         = ReplicatedStorage:WaitForChild("Government", 5)
    local TryStartFocus     = GovFolder and GovFolder:WaitForChild("TryStartFocus", 5)
    local TryFormCountry    = GovFolder and GovFolder:WaitForChild("TryFormCountry", 5)

    local PlayerRemotes     = ReplicatedStorage:WaitForChild("Player", 5)
    local CountrySelected   = PlayerRemotes and PlayerRemotes:WaitForChild("CountrySelected", 5)

    local ResearchCommon = nil
    pcall(function()
        local common = ReplicatedStorage:WaitForChild("Common", 5)
        local resMod = common and common:WaitForChild("ResearchCommon", 5)
        if resMod and resMod:IsA("ModuleScript") then
            ResearchCommon = require(resMod)
        end
    end)

    -- ================================================================
    -- STATE & SETTINGS (SMART V2 + WAR & GOVERNMENT AI)
    -- ================================================================
    local smartMasterActive       = false
    local autoFactoryActive       = false
    local autoDefenseActive       = false
    local autoResearchActive      = false
    local autoGovFocusActive      = true   -- Auto research Government Focuses
    local autoWarDefenseActive    = true   -- Auto respond to War / Enemies
    local autoCallAlliesActive    = true   -- Auto call allies when attacked
    local autoInfantryActive      = false
    local autoTanksActive         = false
    local autoAntiTankActive      = false
    local autoManpowerActive      = false
    local autoSelectCountry       = false
    local autoFormEmpireActive    = false
    local smartPriorityCity       = true

    local techFocusProfile        = "Industrial" -- "Industrial", "Military", "Balanced"
    local reserveCash             = 3000         -- Lowered from $25k so upgrades run smoothly!
    local targetCountryName       = "Spain"
    local minManpowerThreshold    = 5000
    local isCurrentlyAtWar        = false
    local currentActiveFocusName  = "None"

    -- ================================================================
    -- HELPER FUNCTIONS
    -- ================================================================
    local function GetMyCountry()
        local countryVal = LocalPlayer:FindFirstChild("Country")
        if countryVal and countryVal:IsA("ObjectValue") and countryVal.Value then
            return countryVal.Value
        end
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local countryStat = leaderstats and leaderstats:FindFirstChild("Country")
        if countryStat and countryStat.Value ~= "" and countryStat.Value ~= "None" then
            local repCountries = ReplicatedStorage:FindFirstChild("Countries")
            if repCountries then
                return repCountries:FindFirstChild(countryStat.Value)
            end
        end
        return nil
    end

    local function GetEffectiveReserveCash()
        if isCurrentlyAtWar then
            return 500 -- In war, spend almost everything to defend!
        end
        return reserveCash
    end

    local function GetCountryMoney(country)
        return country and country:GetAttribute("money") or 0
    end

    local function GetCountryManpower(country)
        return country and country:GetAttribute("manpower") or 0
    end

    local function GetCountryPP(country)
        return country and country:GetAttribute("politicalPower") or 0
    end

    local function GetConstructionQueueCount(city, queueAttr, startAttr)
        local count = city:GetAttribute(queueAttr)
        if type(count) == "number" then
            return math.max(0, math.floor(count))
        end
        if city:GetAttribute(startAttr) then
            return 1
        end
        return 0
    end

    local function IsTechPrerequisitesMet(country, tech)
        if not ResearchCommon or not ResearchCommon.techs then
            return true
        end
        local techData = ResearchCommon.techs[tech.Name]
        if not techData or not techData.required then
            return true
        end
        local countryTechs = country:FindFirstChild("Techs")
        if not countryTechs then return false end
        for _, reqName in ipairs(techData.required) do
            local reqTech = countryTechs:FindFirstChild(reqName)
            if not reqTech or (reqTech:GetAttribute("progress") or 0) < 1 then
                return false
            end
        end
        return true
    end

    -- ================================================================
    -- 1. ⚔️ WAR & ENEMY DEFENSE ENGINE
    -- ================================================================
    local lastAllyCallTime = 0

    local function RunSmartWarResponse()
        local country = GetMyCountry()
        if not country then return end

        local diplo = country:FindFirstChild("Diplomacy")
        local enemiesFolder = diplo and diplo:FindFirstChild("Enemies")
        local enemies = enemiesFolder and enemiesFolder:GetChildren() or {}

        if #enemies > 0 then
            if not isCurrentlyAtWar then
                isCurrentlyAtWar = true
                Notify("🚨 WAR DETECTED!", "At war with " .. enemies[1].Name .. "! War Mobilization Activated!", 4)
            end

            -- 1. Auto Call Allies to War
            if autoCallAlliesActive and AllianceCallToWar and (tick() - lastAllyCallTime > 15) then
                lastAllyCallTime = tick()
                for _, enemy in ipairs(enemies) do
                    local enemyCountry = ReplicatedStorage.Countries:FindFirstChild(enemy.Name)
                    if enemyCountry then
                        pcall(function()
                            AllianceCallToWar:FireServer(enemyCountry)
                        end)
                    end
                end
            end

            -- 2. Emergency Wartime Mobilization: Recruit Troops Immediately
            local money = GetCountryMoney(country)
            local manpower = GetCountryManpower(country)
            local armyFolder = country:FindFirstChild("Army")
            local classes = armyFolder and armyFolder:FindFirstChild("Classes")

            if classes and TryIncreaseTarget and money > 500 and manpower > 1000 then
                local inf = classes:FindFirstChild("Infantry")
                if inf then pcall(function() TryIncreaseTarget:InvokeServer(inf) end) end

                if money > 3000 then
                    local tanks = classes:FindFirstChild("Tanks")
                    if tanks then pcall(function() TryIncreaseTarget:InvokeServer(tanks) end) end
                    local at = classes:FindFirstChild("AntiTank")
                    if at then pcall(function() TryIncreaseTarget:InvokeServer(at) end) end
                end
            end

            -- 3. Emergency Manpower Buy if under 10k
            if TryBuyManpower and manpower < 10000 and money > 15000 then
                pcall(function() TryBuyManpower:InvokeServer() end)
            end
        else
            isCurrentlyAtWar = false
        end
    end

    -- ================================================================
    -- 2. 🏛️ SMART GOVERNMENT FOCUS UPGRADES
    -- ================================================================
    local function RunSmartGovernmentFocuses()
        local country = GetMyCountry()
        if not country or not TryStartFocus then return end

        local gov = country:FindFirstChild("Government")
        local focFolder = gov and gov:FindFirstChild("Focuses")
        if not focFolder then return end

        local curFocusesStr = focFolder:GetAttribute("currentFocuses") or "[]"
        local activeFocuses = {}
        pcall(function() activeFocuses = HttpService:JSONDecode(curFocusesStr) end)

        if #activeFocuses > 0 then
            currentActiveFocusName = tostring(activeFocuses[1])
            return
        end

        currentActiveFocusName = "Idle / Searching..."

        local pp = GetCountryPP(country)
        local candidates = {}

        for _, focus in ipairs(focFolder:GetChildren()) do
            local prog = focus:GetAttribute("progress") or 0
            local cost = focus:GetAttribute("ppCost") or 0
            if prog < 1 and pp >= cost then
                local reqStr = focus:GetAttribute("required") or "[]"
                local reqs = {}
                pcall(function() reqs = HttpService:JSONDecode(reqStr) end)
                local allMet = true
                for _, reqName in ipairs(reqs) do
                    local reqFoc = focFolder:FindFirstChild(reqName)
                    if not reqFoc or (reqFoc:GetAttribute("progress") or 0) < 1 then
                        allMet = false
                        break
                    end
                end
                if allMet then
                    table.insert(candidates, focus)
                end
            end
        end

        if #candidates > 0 then
            -- Preferred priority order for focuses
            local preferredNames = {
                "Detain the Disruptive", "Industry Driven", "Military Complex",
                "Five-Year Plan", "Autarkic Steel Combine", "Army Discipline",
                "Military Tradition", "Ironwill Doctrine", "Blitzkrieg",
                "Call to Arms", "Forced Labor Logistics", "Build The Siegfried Line"
            }

            local chosen = nil
            for _, pref in ipairs(preferredNames) do
                for _, cand in ipairs(candidates) do
                    if cand.Name == pref then
                        chosen = cand
                        break
                    end
                end
                if chosen then break end
            end

            if not chosen then
                chosen = candidates[1]
            end

            if chosen then
                local ok = pcall(function()
                    TryStartFocus:InvokeServer(chosen)
                end)
                if ok then
                    currentActiveFocusName = chosen.Name
                    Notify("🏛️ Government Upgrade", "Started Focus: " .. chosen.Name .. "!", 3)
                end
            end
        end
    end

    -- ================================================================
    -- 3. 🏭 SMART CITY & FACTORY UPGRADES
    -- ================================================================
    local function AnalyzeAndUpgradeCities()
        local country = GetMyCountry()
        if not country then return end
        local money = GetCountryMoney(country)
        local safeReserve = GetEffectiveReserveCash()
        if money <= safeReserve then return end

        local citiesFolder = country:FindFirstChild("Cities")
        if not citiesFolder then return end

        local cities = citiesFolder:GetChildren()
        if #cities == 0 then return end

        -- Sort cities: High capacity & Capital first for Factories
        table.sort(cities, function(a, b)
            local aCap = (a:GetAttribute("maxFactories") or 0) + (a:GetAttribute("isCapital") and 100 or 0)
            local bCap = (b:GetAttribute("maxFactories") or 0) + (b:GetAttribute("isCapital") and 100 or 0)
            return aCap > bCap
        end)

        -- Auto Set Priority City to the highest-population city or Capital
        if smartPriorityCity and SetPriorityCity and cities[1] then
            pcall(function()
                SetPriorityCity:FireServer(cities[1].Name)
            end)
        end

        for _, city in ipairs(cities) do
            if not autoFactoryActive and not smartMasterActive and not autoDefenseActive then break end
            money = GetCountryMoney(country)
            if money <= safeReserve then break end

            local currentFactories = city:GetAttribute("factories") or 0
            local queuedFactories  = GetConstructionQueueCount(city, "factoryBuildQueue", "factoryBuildStart")
            local maxFactories     = city:GetAttribute("maxFactories") or 0

            local currentDefenses  = city:GetAttribute("defenses") or 0
            local queuedDefenses   = GetConstructionQueueCount(city, "defenseBuildQueue", "defenseBuildStart")
            local maxDefenses      = city:GetAttribute("maxDefenses") or 0

            -- Priority 1: High max factories (Economic hubs) -> Build Factory
            if (autoFactoryActive or smartMasterActive) and PurchaseFactory then
                if (currentFactories + queuedFactories) < maxFactories then
                    PurchaseFactory:FireServer(city)
                    task.wait(0.2)
                end
            end

            -- Priority 2: Fortify Defenses (Frontline & city protection)
            if (autoDefenseActive or smartMasterActive or isCurrentlyAtWar) and PurchaseDefense then
                if (currentDefenses + queuedDefenses) < maxDefenses and (currentDefenses + queuedDefenses) < 5 then
                    PurchaseDefense:FireServer(city)
                    task.wait(0.2)
                end
            end
        end
    end

    -- ================================================================
    -- 4. 🔬 SMART TECH RESEARCH LOOP
    -- ================================================================
    local function RunSmartTechResearch()
        local country = GetMyCountry()
        if not country or not StartResearch then return end

        local slotsFolder = country:FindFirstChild("ResearchSlots")
        local techsFolder = country:FindFirstChild("Techs")
        if not slotsFolder or not techsFolder then return end

        local hasFreeSlot = false
        local activeResearches = {}

        for _, slot in ipairs(slotsFolder:GetChildren()) do
            local currentTech = slot:GetAttribute("tech") or (slot:IsA("ObjectValue") and slot.Value and slot.Value.Name)
            if currentTech and currentTech ~= "" then
                activeResearches[currentTech] = true
            else
                hasFreeSlot = true
            end
        end

        if not hasFreeSlot and #slotsFolder:GetChildren() > 0 then return end

        local candidateTech = nil
        local priorityList = {}

        if techFocusProfile == "Industrial" then
            priorityList = {
                "Industry I", "Industry II", "Industry III", "Industry IV",
                "Transport Ship I", "Transport Ship II",
                "Fortifications I", "Fortifications II", "Fortifications III"
            }
        elseif techFocusProfile == "Military" then
            priorityList = {
                "Infantry Equipment I", "Infantry Equipment II", "Infantry Equipment III",
                "Tank Turret I", "Tank Turret II", "Tank Turret III", "Tank Turret IV",
                "Fortifications I", "Fortifications II", "Fortifications III"
            }
        else -- Balanced
            priorityList = {
                "Industry I", "Infantry Equipment I", "Industry II", "Tank Turret I",
                "Fortifications I", "Industry III", "Tank Turret II", "Infantry Equipment II"
            }
        end

        for _, name in ipairs(priorityList) do
            local tech = techsFolder:FindFirstChild(name)
            if tech and not activeResearches[tech.Name] then
                local prog = tech:GetAttribute("progress") or 0
                if prog < 1 and IsTechPrerequisitesMet(country, tech) then
                    candidateTech = tech
                    break
                end
            end
        end

        if not candidateTech then
            for _, tech in ipairs(techsFolder:GetChildren()) do
                if not activeResearches[tech.Name] then
                    local prog = tech:GetAttribute("progress") or 0
                    if prog < 1 and IsTechPrerequisitesMet(country, tech) then
                        candidateTech = tech
                        break
                    end
                end
            end
        end

        if candidateTech then
            local money = GetCountryMoney(country)
            local price = candidateTech:GetAttribute("price") or 0
            local safeReserve = GetEffectiveReserveCash()
            if money > (safeReserve + price) then
                if not candidateTech:GetAttribute("purchased") and TryPurchaseTech then
                    pcall(function() TryPurchaseTech:InvokeServer(candidateTech) end)
                    task.wait(0.2)
                end
                StartResearch:FireServer(candidateTech)
                Notify("Tech Research", "Started: " .. candidateTech.Name, 2)
            end
        end
    end

    -- ================================================================
    -- 5. 💂 SMART TROOP RECRUITMENT & REPLENISHMENT
    -- ================================================================
    local function RunSmartArmyRecruitment()
        local country = GetMyCountry()
        if not country or not TryIncreaseTarget then return end

        local money = GetCountryMoney(country)
        local manpower = GetCountryManpower(country)
        local safeReserve = GetEffectiveReserveCash()
        if money <= (safeReserve + 1000) or manpower < 1000 then return end

        local armyFolder = country:FindFirstChild("Army")
        local classes = armyFolder and armyFolder:FindFirstChild("Classes")
        if not classes then return end

        if smartMasterActive or autoInfantryActive or isCurrentlyAtWar then
            local inf = classes:FindFirstChild("Infantry")
            if inf then pcall(function() TryIncreaseTarget:InvokeServer(inf) end) end
        end

        if (smartMasterActive or autoTanksActive or isCurrentlyAtWar) and money > (safeReserve + 4000) then
            local tanks = classes:FindFirstChild("Tanks")
            if tanks then pcall(function() TryIncreaseTarget:InvokeServer(tanks) end) end
        end

        if (smartMasterActive or autoAntiTankActive) and money > (safeReserve + 2000) then
            local at = classes:FindFirstChild("AntiTank")
            if at then pcall(function() TryIncreaseTarget:InvokeServer(at) end) end
        end
    end

    -- ================================================================
    -- 6. 👑 AUTO-FORM EMPIRE
    -- ================================================================
    local function CheckAutoFormNation()
        local country = GetMyCountry()
        if not country or not TryFormCountry then return end
        local formables = country:FindFirstChild("Formables")
        if formables and #formables:GetChildren() > 0 then
            for _, f in ipairs(formables:GetChildren()) do
                pcall(function()
                    local ok = TryFormCountry:InvokeServer(f.Name)
                    if ok then
                        Notify("👑 EMPIRE FORMED!", "Ascended to: " .. f.Name .. "!", 4)
                    end
                end)
            end
        end
    end

    -- ================================================================
    -- 7. 🌍 AUTO-JOIN MATCH LOBBY SELECTOR
    -- ================================================================
    local function CheckAutoSelectCountry()
        if not autoSelectCountry or not CountrySelected then return end
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local countryStat = leaderstats and leaderstats:FindFirstChild("Country")
        local current = countryStat and countryStat.Value

        if not current or current == "" or current == "None" then
            CountrySelected:FireServer(targetCountryName)
            Notify("Auto Select", "Joined match as " .. targetCountryName .. "!", 3)
        end
    end

    -- ================================================================
    -- MAIN ENGINE LOOP
    -- ================================================================
    task.spawn(function()
        while not isDestroyed do
            if autoSelectCountry then
                pcall(CheckAutoSelectCountry)
            end

            local country = GetMyCountry()
            if country then
                -- 1. War Defense & Ally Response
                if autoWarDefenseActive or smartMasterActive then
                    pcall(RunSmartWarResponse)
                end

                -- 2. Government Focus Upgrades
                if autoGovFocusActive or smartMasterActive then
                    pcall(RunSmartGovernmentFocuses)
                end

                -- 3. City & Factory Upgrades
                if smartMasterActive or autoFactoryActive or autoDefenseActive then
                    pcall(AnalyzeAndUpgradeCities)
                end

                -- 4. Tech Research Upgrades
                if smartMasterActive or autoResearchActive then
                    pcall(RunSmartTechResearch)
                end

                -- 5. Army Recruitment
                if smartMasterActive or autoInfantryActive or autoTanksActive or autoAntiTankActive or isCurrentlyAtWar then
                    pcall(RunSmartArmyRecruitment)
                end

                -- 6. Manpower Purchase
                if smartMasterActive or autoManpowerActive then
                    local money = GetCountryMoney(country)
                    local manpower = GetCountryManpower(country)
                    if manpower < minManpowerThreshold and money > 8000 and TryBuyManpower then
                        pcall(function() TryBuyManpower:InvokeServer() end)
                    end
                end

                -- 7. Empire Formables
                if autoFormEmpireActive or smartMasterActive then
                    pcall(CheckAutoFormNation)
                end
            end
            task.wait(1.5)
        end
    end)

    -- ================================================================
    -- TAB 1: ⚡ SMART AUTO FARM V2 + WAR & GOVERNMENT
    -- ================================================================
    local FarmTab = CreateTab("Auto Farm", "⚡", "Smart AI War, Government & Economy V2")
    local EconCol = CreateSection(FarmTab.Left,  "🧠 Smart Economy & Government")
    local ArmyCol = CreateSection(FarmTab.Right, "⚔️ Smart War Defense & Logistics")

    -- 🚀 MASTER AI TOGGLE
    AddToggle(EconCol, "🚀 MASTER SMART AI (All-in-One)", false, function(state)
        smartMasterActive = state
        autoGovFocusActive = state
        autoWarDefenseActive = state
        autoCallAlliesActive = state
        Notify("Master Smart AI", state and "Enabled: War Defense, Government & Economy Active!" or "Disabled", 3)
    end)

    AddToggle(EconCol, "Auto Upgrade Government (Focuses)", true, function(state)
        autoGovFocusActive = state
    end)

    AddToggle(EconCol, "Smart Prioritize High-Value Cities", true, function(state)
        smartPriorityCity = state
    end)

    AddToggle(EconCol, "Auto Build Factories (Capacity AI)", false, function(state)
        autoFactoryActive = state
    end)

    AddToggle(EconCol, "Auto Fortify Defenses (Border Defense)", false, function(state)
        autoDefenseActive = state
    end)

    AddToggle(EconCol, "Auto Tech Research (Continuous Loop)", false, function(state)
        autoResearchActive = state
    end)

    AddButton(EconCol, "Tech Focus: 🏭 Industrial", function()
        techFocusProfile = "Industrial"
        Notify("Tech Focus", "Set to: Industrial (Factory Limits & Econ)", 2)
    end)

    AddButton(EconCol, "Tech Focus: ⚔️ Military Might", function()
        techFocusProfile = "Military"
        Notify("Tech Focus", "Set to: Military (Infantry & Tank upgrades)", 2)
    end)

    AddButton(EconCol, "Tech Focus: ⚖️ Balanced Path", function()
        techFocusProfile = "Balanced"
        Notify("Tech Focus", "Set to: Balanced (Econ + Army hybrid)", 2)
    end)

    AddSlider(EconCol, "Reserve Cash Buffer ($)", 500, 100000, 3000, function(val)
        reserveCash = val
    end)

    -- RIGHT COLUMN: WAR DEFENSE & MILITARY
    AddToggle(ArmyCol, "🚨 Auto War Defense (Call Allies & Mobilize)", true, function(state)
        autoWarDefenseActive = state
    end)

    AddToggle(ArmyCol, "Auto Call Allies to War", true, function(state)
        autoCallAlliesActive = state
    end)

    AddToggle(ArmyCol, "Auto Train Infantry Divisions", false, function(state)
        autoInfantryActive = state
    end)

    AddToggle(ArmyCol, "Auto Train Armor (Tanks)", false, function(state)
        autoTanksActive = state
    end)

    AddToggle(ArmyCol, "Auto Train Anti-Tank Battalions", false, function(state)
        autoAntiTankActive = state
    end)

    AddToggle(ArmyCol, "Auto Buy Manpower (When < 5k)", false, function(state)
        autoManpowerActive = state
    end)

    AddToggle(ArmyCol, "Auto-Form Empire (When Ready)", false, function(state)
        autoFormEmpireActive = state
    end)

    AddButton(ArmyCol, "⚡ Instant Buy Manpower", function()
        if TryBuyManpower then
            local ok = pcall(function() TryBuyManpower:InvokeServer() end)
            Notify("Manpower", ok and "Manpower purchase dispatched!" or "Failed to purchase", 2)
        end
    end)

    -- ================================================================
    -- TAB 2: 🌍 NATION, WAR & LOBBY
    -- ================================================================
    local NationTab = CreateTab("Nation", "🌍", "Live Country Overview & War Status")
    local LobbyCol  = CreateSection(NationTab.Left,  "Country Selector")
    local StatusCol = CreateSection(NationTab.Right, "Live Nation Status")

    AddToggle(LobbyCol, "Auto Select Country on Match Start", false, function(state)
        autoSelectCountry = state
        if state then CheckAutoSelectCountry() end
    end)

    local countries = {
        "Spain", "German Reich", "USSR", "United States", "United Kingdom",
        "Empire of Japan", "France", "Italy", "Poland"
    }

    for _, cName in ipairs(countries) do
        AddButton(LobbyCol, "Select " .. cName, function()
            targetCountryName = cName
            if CountrySelected then
                CountrySelected:FireServer(cName)
                Notify("Country Selected", "Joined as " .. cName .. "!", 2.5)
            end
        end)
    end

    -- Status Labels
    local countryLbl = AddLabel(StatusCol, "Country: None", Theme.Accent)
    local warStatusLbl = AddLabel(StatusCol, "War Status: Peace 🕊️", Theme.TextWhite)
    local focusLbl   = AddLabel(StatusCol, "Gov Focus: None", Theme.Accent)
    local moneyLbl   = AddLabel(StatusCol, "Treasury: $0", Theme.TextWhite)
    local manLbl     = AddLabel(StatusCol, "Manpower: 0", Theme.TextWhite)
    local divLbl     = AddLabel(StatusCol, "Divisions: 0", Theme.TextWhite)
    local factLbl    = AddLabel(StatusCol, "Factories: 0", Theme.TextWhite)
    local tileLbl    = AddLabel(StatusCol, "Tiles: 0", Theme.TextWhite)

    AddButton(StatusCol, "Check & Form Empire Now", function()
        CheckAutoFormNation()
    end)

    -- Dynamic Status Refresher
    task.spawn(function()
        local function SetVal(row, txt)
            local v = row and row:FindFirstChild("Value")
            if v then v.Text = tostring(txt) end
        end

        while not isDestroyed do
            local country = GetMyCountry()
            if country then
                SetVal(countryLbl, country.Name)

                if isCurrentlyAtWar then
                    SetVal(warStatusLbl, "🚨 AT WAR! (Defending)")
                    local v = warStatusLbl and warStatusLbl:FindFirstChild("Value")
                    if v then v.TextColor3 = Color3.fromRGB(255, 60, 60) end
                else
                    SetVal(warStatusLbl, "Peace 🕊️")
                    local v = warStatusLbl and warStatusLbl:FindFirstChild("Value")
                    if v then v.TextColor3 = Color3.fromRGB(0, 230, 120) end
                end

                SetVal(focusLbl, currentActiveFocusName)

                local m = country:GetAttribute("money") or 0
                SetVal(moneyLbl, string.format("$%s", tostring(math.floor(m))))
                local mp = country:GetAttribute("manpower") or 0
                SetVal(manLbl, tostring(math.floor(mp)))
                SetVal(divLbl, tostring(country:GetAttribute("divisions") or 0))
                SetVal(factLbl, tostring(country:GetAttribute("factories") or 0))
                SetVal(tileLbl, tostring(country:GetAttribute("tiles") or 0))
            else
                SetVal(countryLbl, "Lobby / None")
                SetVal(warStatusLbl, "None")
                SetVal(focusLbl, "None")
                SetVal(moneyLbl, "$0")
                SetVal(manLbl, "0")
                SetVal(divLbl, "0")
                SetVal(factLbl, "0")
                SetVal(tileLbl, "0")
            end
            task.wait(1)
        end
    end)

    return true
end

return Game
