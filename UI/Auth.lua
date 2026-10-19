local Auth = {}

local BASE_URL = "https://moonhub.freesrv.com"

function Auth.Configure(menu, onAuthorized)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local GuiService = game:GetService("GuiService")
    local player = Players.LocalPlayer
    local alive = true

    menu.Main.Visible = false
    menu.SetFloatingEnabled(false)

    local panel = Instance.new("Frame")
    panel.Name = "AuthorizationPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Size = UDim2.fromOffset(360, 220)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.BackgroundColor3 = menu.Context.Theme.CardBg
    panel.BorderSizePixel = 0
    panel.ZIndex = 20
    panel.Parent = menu.Gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local outline = Instance.new("UIStroke", panel)
    outline.Color = menu.Context.Theme.Accent
    outline.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(18, 14)
    title.Size = UDim2.new(1, -36, 0, 28)
    title.Font = Enum.Font.GothamBold
    title.Text = "MooN | HUB · Discord authorization"
    title.TextColor3 = menu.Context.Theme.TextWhite
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 21
    title.Parent = panel

    local description = Instance.new("TextLabel")
    description.BackgroundTransparency = 1
    description.Position = UDim2.fromOffset(18, 48)
    description.Size = UDim2.new(1, -36, 0, 48)
    description.Font = Enum.Font.Gotham
    description.Text = "Open your personal authorization link, finish the Discord step, then wait here for confirmation."
    description.TextColor3 = menu.Context.Theme.TextMuted
    description.TextSize = 11
    description.TextWrapped = true
    description.TextXAlignment = Enum.TextXAlignment.Left
    description.ZIndex = 21
    description.Parent = panel

    local openButton = Instance.new("TextButton")
    openButton.Position = UDim2.fromOffset(18, 108)
    openButton.Size = UDim2.new(1, -36, 0, 36)
    openButton.BackgroundColor3 = menu.Context.Theme.AccentSoft
    openButton.BorderSizePixel = 0
    openButton.Font = Enum.Font.GothamBold
    openButton.Text = "Open Discord authorization"
    openButton.TextColor3 = menu.Context.Theme.TextWhite
    openButton.TextSize = 11
    openButton.ZIndex = 21
    openButton.Parent = panel
    Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(18, 154)
    status.Size = UDim2.new(1, -36, 0, 40)
    status.Font = Enum.Font.GothamMedium
    status.Text = "Status: waiting for authorization"
    status.TextColor3 = menu.Context.Theme.TextMuted
    status.TextSize = 10
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.ZIndex = 21
    status.Parent = panel

    local env = _G
    pcall(function()
        if getgenv then env = getgenv() end
    end)
    local synTable = env.syn or _G.syn
    local request = env.request or env.http_request or _G.request or _G.http_request
    if not request and synTable then request = synTable.request end

    local loginUrl = BASE_URL .. "/login/" .. tostring(player.UserId)
    openButton.Activated:Connect(function()
        local opened = false
        pcall(function()
            local openUrl = env.openurl or _G.openurl
            if openUrl then
                openUrl(loginUrl)
                opened = true
            elseif synTable and synTable.open_url then
                synTable.open_url(loginUrl)
                opened = true
            else
                GuiService:OpenBrowserWindow(loginUrl)
                opened = true
            end
        end)
        if not opened then
            local clipboard = env.setclipboard or _G.setclipboard
            if clipboard then
                pcall(clipboard, loginUrl)
                status.Text = "Status: link copied; open it in your browser"
            else
                status.Text = "Status: browser could not be opened by this client"
            end
        end
    end)

    menu.AddCleanup(function()
        alive = false
        if panel.Parent then panel:Destroy() end
    end)

    task.spawn(function()
        if not request then
            status.Text = "Status: this client does not provide the HTTP request function"
            return
        end
        while alive and panel.Parent do
            local ok, response = pcall(request, {
                Url = BASE_URL .. "/check?userid=" .. tostring(player.UserId),
                Method = "GET",
            })
            if ok and response and response.StatusCode == 200 then
                local decoded, data = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)
                if decoded and data and data.authorized == true then
                    alive = false
                    status.Text = "Status: authorized"
                    task.wait(0.25)
                    if panel.Parent then panel:Destroy() end
                    menu.Main.Visible = true
                    menu.SetFloatingEnabled(true)
                    if onAuthorized then onAuthorized() end
                    return
                end
            end
            task.wait(3)
        end
    end)
end

return Auth
