local Window = {}

function Window.new(options)
    options = options or {}
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer
    assert(player, "UI must run on the client")
    local playerGui = player:WaitForChild("PlayerGui")
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1024, 768)
    local mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local compact = mobile or viewport.X < 700
    local name = options.Name or "MooN_HUB_Menu"

    local old = playerGui:FindFirstChild(name)
    if old then old:Destroy() end

    local connections = {}
    local cleanupCallbacks = {}
    local reducedMotion = false
    local floatingEnabled = true
    local windowWidth = compact and 520 or 780
    local windowHeight = compact and 360 or 530
    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end
    local function tween(object, duration, properties)
        if reducedMotion then duration = 0 end
        TweenService:Create(object, TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quad), properties):Play()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = options.DisplayOrder or 20
    gui.Parent = playerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Size = UDim2.fromOffset(windowWidth, windowHeight)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.BackgroundColor3 = Theme.MainBg
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local outline = Instance.new("UIStroke", main)
    outline.Color = Theme.Border
    outline.Thickness = 1

    local function fitWindow()
        local currentCamera = workspace.CurrentCamera
        if not currentCamera then return end
        local size = currentCamera.ViewportSize
        local isCompact = mobile or size.X < 700
        local maxWidth = math.max(260, size.X - 24)
        local maxHeight = math.max(220, size.Y - 24)
        windowWidth = math.min(windowWidth, isCompact and math.min(520, maxWidth) or maxWidth)
        windowHeight = math.min(windowHeight, isCompact and math.min(360, maxHeight) or maxHeight)
        main.Size = UDim2.fromOffset(windowWidth, windowHeight)
    end
    fitWindow()
    local currentCamera = workspace.CurrentCamera
    if currentCamera then
        connect(currentCamera:GetPropertyChangedSignal("ViewportSize"), fitWindow)
    end
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        local nextCamera = workspace.CurrentCamera
        if nextCamera then
            connect(nextCamera:GetPropertyChangedSignal("ViewportSize"), fitWindow)
            fitWindow()
        end
    end)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, compact and 42 or 48)
    header.BackgroundColor3 = Theme.HeaderBg
    header.BorderSizePixel = 0
    header.Parent = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

    local brandMark = Instance.new("TextLabel")
    brandMark.Name = "BrandMark"
    brandMark.Size = UDim2.fromOffset(28, 28)
    brandMark.Position = UDim2.new(0, 14, 0.5, -14)
    brandMark.BackgroundColor3 = Theme.AccentSoft
    brandMark.Font = Enum.Font.GothamBlack
    brandMark.Text = "M"
    brandMark.TextColor3 = Theme.Accent
    brandMark.TextSize = 16
    brandMark.Parent = header
    Instance.new("UICorner", brandMark).CornerRadius = UDim.new(0, 9)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -150, 0, 20)
    title.Position = UDim2.new(0, 52, 0, compact and 5 or 7)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = options.Title or "MooN | HUB"
    title.TextColor3 = Theme.TextWhite
    title.TextSize = compact and 12 or 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -150, 0, 14)
    subtitle.Position = UDim2.new(0, 52, 0, compact and 23 or 27)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "UNIVERSAL INTERFACE"
    subtitle.TextColor3 = Theme.TextMuted
    subtitle.TextSize = 8
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    local controls = Instance.new("Frame")
    controls.Size = UDim2.new(0, 68, 1, 0)
    controls.Position = UDim2.new(1, -68, 0, 0)
    controls.BackgroundTransparency = 1
    controls.Parent = header
    local controlLayout = Instance.new("UIListLayout")
    controlLayout.FillDirection = Enum.FillDirection.Horizontal
    controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlLayout.Padding = UDim.new(0, 5)
    controlLayout.Parent = controls
    local controlPadding = Instance.new("UIPadding")
    controlPadding.PaddingRight = UDim.new(0, 8)
    controlPadding.Parent = controls

    local hidden = Instance.new("TextButton")
    hidden.Name = "Minimize"
    hidden.Size = UDim2.fromOffset(25, 25)
    hidden.BackgroundColor3 = Theme.CardBg
    hidden.Font = Enum.Font.GothamBold
    hidden.Text = "-"
    hidden.TextColor3 = Theme.TextMuted
    hidden.Parent = controls
    Instance.new("UICorner", hidden).CornerRadius = UDim.new(0, 7)

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.Size = UDim2.fromOffset(25, 25)
    close.BackgroundColor3 = Theme.CardBg
    close.Font = Enum.Font.GothamBold
    close.Text = "×"
    close.TextColor3 = Theme.CloseRed
    close.Parent = controls
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 7)

    local floating = Instance.new("TextButton")
    floating.Name = "FloatingToggle"
    floating.Size = UDim2.fromOffset(compact and 38 or 44, compact and 38 or 44)
    floating.Position = UDim2.new(0, 15, 0.5, -20)
    floating.BackgroundColor3 = Theme.HeaderBg
    floating.Font = Enum.Font.GothamBold
    floating.Text = "🌙"
    floating.TextColor3 = Theme.Accent
    floating.Visible = false
    floating.ZIndex = 999
    floating.Parent = gui
    Instance.new("UICorner", floating).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", floating).Color = Theme.Accent

    local function toggle()
        main.Visible = not main.Visible
        floating.Visible = floatingEnabled and not main.Visible
    end
    connect(hidden.MouseButton1Click, toggle)
    local floatingDragging, floatStart, floatPosition, floatMoved = false, nil, nil, false
    connect(floating.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            floatingDragging = true
            floatMoved = false
            floatStart = Vector2.new(input.Position.X, input.Position.Y)
            floatPosition = floating.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if floatingDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - floatStart
            if delta.Magnitude > 4 then floatMoved = true end
            floating.Position = UDim2.new(floatPosition.X.Scale, floatPosition.X.Offset + delta.X,
                floatPosition.Y.Scale, floatPosition.Y.Offset + delta.Y)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if floatingDragging then
                floatingDragging = false
                if not floatMoved then toggle() end
            end
        end
    end)

    local destroyed = false
    local function destroy()
        if destroyed then return end
        destroyed = true
        for _, callback in ipairs(cleanupCallbacks) do
            pcall(callback)
        end
        table.clear(cleanupCallbacks)
        for _, connection in ipairs(connections) do connection:Disconnect() end
        table.clear(connections)
        gui:Destroy()
    end
    connect(close.MouseButton1Click, destroy)

    if not compact then
        local dragging, dragStart, startPosition
        connect(header.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging, dragStart, startPosition = true, input.Position, main.Position
                local stateConnection
                stateConnection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        stateConnection:Disconnect()
                    end
                end)
                table.insert(connections, stateConnection)
            end
        end)
        connect(UserInputService.InputChanged, function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
            end
        end)
        connect(UserInputService.InputBegan, function(input, processed)
            if not processed and input.KeyCode == Enum.KeyCode.RightShift then toggle() end
        end)
    end

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    local sidebarWidth = compact and 116 or 174
    sidebar.Size = UDim2.new(0, sidebarWidth, 1, -50)
    sidebar.Position = UDim2.new(0, 0, 0, compact and 46 or 52)
    sidebar.BackgroundColor3 = Theme.SidebarBg
    sidebar.Parent = main
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

    local navLabel = Instance.new("TextLabel")
    navLabel.Size = UDim2.new(1, -24, 0, 18)
    navLabel.Position = UDim2.new(0, 12, 0, 12)
    navLabel.BackgroundTransparency = 1
    navLabel.Font = Enum.Font.GothamBold
    navLabel.Text = "WORKSPACE"
    navLabel.TextColor3 = Theme.TextMuted
    navLabel.TextSize = 8
    navLabel.TextXAlignment = Enum.TextXAlignment.Left
    navLabel.Parent = sidebar

    local tabHolder = Instance.new("ScrollingFrame")
    tabHolder.Name = "Tabs"
    tabHolder.Size = UDim2.new(1, -16, 1, -42)
    tabHolder.Position = UDim2.new(0, 8, 0, 34)
    tabHolder.BackgroundTransparency = 1
    tabHolder.BorderSizePixel = 0
    tabHolder.ScrollBarThickness = 0
    tabHolder.Parent = sidebar
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.Parent = tabHolder

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -sidebarWidth - 30, 1, compact and -60 or -68)
    content.Position = UDim2.new(0, sidebarWidth + 16, 0, compact and 52 or 60)
    content.BackgroundTransparency = 1
    content.Parent = main

    local resizeGrip = Instance.new("TextButton")
    resizeGrip.Name = "ResizeGrip"
    resizeGrip.AnchorPoint = Vector2.new(1, 1)
    resizeGrip.Position = UDim2.new(1, -5, 1, -5)
    resizeGrip.Size = UDim2.fromOffset(24, 24)
    resizeGrip.BackgroundColor3 = Theme.CardBg
    resizeGrip.BackgroundTransparency = 0.15
    resizeGrip.AutoButtonColor = false
    resizeGrip.Font = Enum.Font.GothamBold
    resizeGrip.Text = "◢"
    resizeGrip.TextColor3 = Theme.Accent
    resizeGrip.TextSize = 14
    resizeGrip.ZIndex = 20
    resizeGrip.Parent = main
    Instance.new("UICorner", resizeGrip).CornerRadius = UDim.new(0, 7)

    local resizing, resizeStart, resizeSize, resizePosition, resizeInputType
    connect(resizeGrip.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeInputType = input.UserInputType
            resizeStart = Vector2.new(input.Position.X, input.Position.Y)
            resizeSize = Vector2.new(windowWidth, windowHeight)
            resizePosition = main.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if not resizing then return end
        local mouseMove = resizeInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement
        local touchMove = resizeInputType == Enum.UserInputType.Touch
            and input.UserInputType == Enum.UserInputType.Touch
        if not mouseMove and not touchMove then return end

        local delta = Vector2.new(input.Position.X, input.Position.Y) - resizeStart
        local currentCamera = workspace.CurrentCamera
        local viewportSize = currentCamera and currentCamera.ViewportSize or Vector2.new(1024, 768)
        local topLeft = main.AbsolutePosition
        local maxWidth = math.max(220, viewportSize.X - 12 - topLeft.X)
        local maxHeight = math.max(180, viewportSize.Y - 12 - topLeft.Y)
        local minWidth = math.min(compact and 300 or 440, maxWidth)
        local minHeight = math.min(compact and 240 or 320, maxHeight)
        windowWidth = math.clamp(resizeSize.X + delta.X, minWidth, maxWidth)
        windowHeight = math.clamp(resizeSize.Y + delta.Y, minHeight, maxHeight)

        local widthDelta = windowWidth - resizeSize.X
        local heightDelta = windowHeight - resizeSize.Y
        main.Size = UDim2.fromOffset(windowWidth, windowHeight)
        main.Position = UDim2.new(resizePosition.X.Scale, resizePosition.X.Offset + widthDelta / 2,
            resizePosition.Y.Scale, resizePosition.Y.Offset + heightDelta / 2)
    end)
    connect(UserInputService.InputEnded, function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            resizing = false
            resizeInputType = nil
        end
    end)

    local tabs, activeTab = {}, nil
    local context = {
        Theme = Theme,
        IsMobile = mobile,
        IsCompact = compact,
        PlaceId = game.PlaceId,
        UniverseId = game.GameId,
        Tween = tween,
        Connect = connect,
        UserInputService = UserInputService,
    }

    local api = {}
    function api.CreateTab(tabName, icon, description)
        assert(not tabs[tabName], "Duplicate tab: " .. tabName)
        local button = Instance.new("TextButton")
        button.Name = tabName .. "Tab"
        button.Size = UDim2.new(1, 0, 0, compact and 34 or 38)
        button.BackgroundColor3 = Theme.SidebarBg
        button.Font = Enum.Font.GothamMedium
        button.Text = "   " .. (icon or "•") .. "   " .. tabName
        button.TextColor3 = Theme.TextMuted
        button.TextSize = compact and 10 or 11
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = tabHolder
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = Theme.Accent
        page.Visible = false
        page.Parent = content

        local pageTitle = Instance.new("TextLabel")
        pageTitle.Size = UDim2.new(1, -8, 0, 24)
        pageTitle.Position = UDim2.new(0, 2, 0, 0)
        pageTitle.BackgroundTransparency = 1
        pageTitle.Font = Enum.Font.GothamBold
        pageTitle.Text = tabName
        pageTitle.TextColor3 = Theme.TextWhite
        pageTitle.TextSize = compact and 16 or 19
        pageTitle.TextXAlignment = Enum.TextXAlignment.Left
        pageTitle.Parent = page

        local pageDescription = Instance.new("TextLabel")
        pageDescription.Size = UDim2.new(1, -8, 0, 18)
        pageDescription.Position = UDim2.new(0, 2, 0, 24)
        pageDescription.BackgroundTransparency = 1
        pageDescription.Font = Enum.Font.Gotham
        pageDescription.Text = description or "Your menu, ready when you are."
        pageDescription.TextColor3 = Theme.TextMuted
        pageDescription.TextSize = compact and 9 or 10
        pageDescription.TextXAlignment = Enum.TextXAlignment.Left
        pageDescription.Parent = page

        local left = Instance.new("Frame")
        left.Name = "Left"
        left.Position = UDim2.new(0, 0, 0, 52)
        left.Size = UDim2.new(compact and 1 or 0.49, 0, 1, -52)
        left.BackgroundTransparency = 1
        left.Parent = page
        local right = Instance.new("Frame")
        right.Name = "Right"
        right.Size = UDim2.new(compact and 1 or 0.49, 0, 1, -52)
        right.Position = UDim2.new(compact and 0 or 0.51, 0, 0, 52)
        right.BackgroundTransparency = 1
        right.Parent = page
        local leftLayout = Instance.new("UIListLayout")
        leftLayout.Padding = UDim.new(0, 10)
        leftLayout.Parent = left
        local rightLayout = Instance.new("UIListLayout")
        rightLayout.Padding = UDim.new(0, 10)
        rightLayout.Parent = right

        local function updatePageLayout()
            local leftHeight = leftLayout.AbsoluteContentSize.Y
            local rightHeight = rightLayout.AbsoluteContentSize.Y
            if compact then
                left.Size = UDim2.new(1, 0, 0, leftHeight)
                right.Position = UDim2.new(0, 0, 0, leftHeight + 10)
                right.Size = UDim2.new(1, 0, 0, rightHeight)
                page.CanvasSize = UDim2.new(0, 0, 0, 52 + leftHeight + rightHeight + 10)
            else
                page.CanvasSize = UDim2.new(0, 0, 0, 52 + math.max(leftHeight, rightHeight))
            end
        end
        connect(leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updatePageLayout)
        connect(rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updatePageLayout)

        local data = {Button = button, Page = page, Left = left, Right = right}
        tabs[tabName] = data
        connect(button.MouseButton1Click, function() api.SelectTab(tabName) end)
        if not activeTab then
            activeTab = tabName
            page.Visible = true
            button.BackgroundColor3 = Theme.AccentSoft
            button.TextColor3 = Theme.Accent
        end
        updatePageLayout()
        return data
    end

    function api.CreateSection(parent, sectionTitle)
        return Components.CreateSection(context, parent, sectionTitle)
    end
    function api.AddInfo(parent, label, value)
        return Components.AddInfo(context, parent, label, value)
    end
    function api.AddBanner(parent, heading, body)
        return Components.AddBanner(context, parent, heading, body)
    end
    function api.AddToggle(parent, label, default, callback)
        return Components.AddToggle(context, parent, label, default, callback)
    end
    function api.AddSlider(parent, label, minimum, maximum, default, callback)
        return Components.AddSlider(context, parent, label, minimum, maximum, default, callback)
    end
    function api.AddButton(parent, label, callback)
        return Components.AddButton(context, parent, label, callback)
    end
    function api.SelectTab(tabName)
        if not tabs[tabName] then return false end
        activeTab = tabName
        for tabNameKey, tab in pairs(tabs) do
            local selected = tabNameKey == tabName
            tab.Page.Visible = selected
            tween(tab.Button, 0.15, {
                TextColor3 = selected and Theme.Accent or Theme.TextMuted,
                BackgroundColor3 = selected and Theme.AccentSoft or Theme.SidebarBg,
            })
        end
        return true
    end
    function api.SetReducedMotion(value)
        reducedMotion = value == true
    end
    function api.SetFloatingEnabled(value)
        floatingEnabled = value == true
        floating.Visible = floatingEnabled and not main.Visible
    end
    function api.Destroy()
        destroy()
    end
    function api.AddCleanup(callback)
        assert(type(callback) == "function", "Cleanup callback must be a function")
        table.insert(cleanupCallbacks, callback)
    end
    function api.Notify(title, message, duration)
        local toast = Instance.new("Frame")
        toast.Name = "Notification"
        toast.AnchorPoint = Vector2.new(1, 0)
        toast.Position = UDim2.new(1, -16, 0, 16)
        toast.Size = UDim2.fromOffset(compact and 220 or 280, 54)
        toast.BackgroundColor3 = Theme.HeaderBg
        toast.BorderSizePixel = 0
        toast.ZIndex = 100
        toast.Parent = gui
        Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", toast)
        stroke.Color = Theme.Accent
        local heading = Instance.new("TextLabel")
        heading.BackgroundTransparency = 1
        heading.Position = UDim2.fromOffset(12, 7)
        heading.Size = UDim2.new(1, -24, 0, 16)
        heading.Font = Enum.Font.GothamBold
        heading.Text = tostring(title)
        heading.TextColor3 = Theme.Accent
        heading.TextSize = compact and 10 or 11
        heading.TextXAlignment = Enum.TextXAlignment.Left
        heading.ZIndex = 101
        heading.Parent = toast
        local body = Instance.new("TextLabel")
        body.BackgroundTransparency = 1
        body.Position = UDim2.fromOffset(12, 25)
        body.Size = UDim2.new(1, -24, 0, 20)
        body.Font = Enum.Font.Gotham
        body.Text = tostring(message)
        body.TextColor3 = Theme.TextWhite
        body.TextSize = compact and 9 or 10
        body.TextTruncate = Enum.TextTruncate.AtEnd
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.ZIndex = 101
        body.Parent = toast
        task.delay(duration or 2.5, function()
            if toast.Parent then toast:Destroy() end
        end)
    end
    api.Gui = gui
    api.Main = main
    api.Context = context
    return api
end

return Window


