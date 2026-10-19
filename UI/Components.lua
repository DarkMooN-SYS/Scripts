local Components = {}

function Components.CreateSection(context, parent, title)
    local theme = context.Theme
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 32)
    section.BackgroundColor3 = theme.CardBg
    section.BorderSizePixel = 0
    section.Parent = parent
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", section)
    stroke.Color = theme.Border
    stroke.Transparency = 0.15

    local heading = Instance.new("TextLabel")
    heading.Size = UDim2.new(1, -18, 0, 26)
    heading.Position = UDim2.new(0, 10, 0, 2)
    heading.BackgroundTransparency = 1
    heading.Font = Enum.Font.GothamBold
    heading.Text = string.upper(title)
    heading.TextColor3 = theme.Accent
    heading.TextSize = context.IsCompact and 9 or 10
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = section

    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Position = UDim2.new(0, 0, 0, 30)
    controls.Size = UDim2.new(1, 0, 1, -30)
    controls.BackgroundTransparency = 1
    controls.Parent = section

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.Parent = controls

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = controls

    context.Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        section.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 38)
    end)
    return controls
end

function Components.AddInfo(context, parent, labelText, valueText)
    local row = Instance.new("Frame")
    row.Name = "InfoRow"
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.48, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = labelText
    label.TextColor3 = context.Theme.TextMuted
    label.TextSize = context.IsCompact and 9 or 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = row

    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(0.52, 0, 1, 0)
    value.Position = UDim2.new(0.48, 0, 0, 0)
    value.BackgroundTransparency = 1
    value.Font = Enum.Font.GothamMedium
    value.Text = tostring(valueText)
    value.TextColor3 = context.Theme.TextWhite
    value.TextSize = context.IsCompact and 9 or 10
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.TextTruncate = Enum.TextTruncate.AtEnd
    value.Parent = row
    return row
end

function Components.AddBanner(context, parent, headingText, bodyText)
    local banner = Instance.new("Frame")
    banner.Name = "WelcomeBanner"
    banner.Size = UDim2.new(1, 0, 0, context.IsCompact and 72 or 82)
    banner.BackgroundColor3 = context.Theme.AccentSoft
    banner.BorderSizePixel = 0
    banner.Parent = parent
    Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", banner)
    stroke.Color = context.Theme.Accent
    stroke.Transparency = 0.65

    local heading = Instance.new("TextLabel")
    heading.Size = UDim2.new(1, -24, 0, 22)
    heading.Position = UDim2.new(0, 12, 0, 11)
    heading.BackgroundTransparency = 1
    heading.Font = Enum.Font.GothamBold
    heading.Text = headingText
    heading.TextColor3 = context.Theme.TextWhite
    heading.TextSize = context.IsCompact and 12 or 14
    heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.Parent = banner

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -24, 0, 30)
    body.Position = UDim2.new(0, 12, 0, 34)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Gotham
    body.Text = bodyText
    body.TextColor3 = context.Theme.TextMuted
    body.TextSize = context.IsCompact and 9 or 10
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = banner
    return banner
end

function Components.AddToggle(context, parent, text, default, callback)
    local theme = context.Theme
    local button = Instance.new("TextButton")
    button.Name = "Toggle"
    button.Size = UDim2.new(1, 0, 0, 26)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = theme.TextWhite
    label.TextSize = context.IsCompact and 10 or 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 28, 0, 15)
    track.Position = UDim2.new(1, -28, 0.5, -7.5)
    track.BackgroundColor3 = default and theme.Accent or theme.ToggleOff
    track.Parent = button
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 9, 0, 9)
    knob.Position = default and UDim2.new(1, -12, 0.5, -4.5) or UDim2.new(0, 3, 0.5, -4.5)
    knob.BackgroundColor3 = theme.TextWhite
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default == true
    context.Connect(button.MouseButton1Click, function()
        state = not state
        context.Tween(track, 0.12, {BackgroundColor3 = state and theme.Accent or theme.ToggleOff})
        context.Tween(knob, 0.12, {
            Position = state and UDim2.new(1, -12, 0.5, -4.5) or UDim2.new(0, 3, 0.5, -4.5),
        })
        if callback then callback(state) end
    end)
    return { Get = function() return state end }
end

function Components.AddSlider(context, parent, text, minimum, maximum, default, callback)
    assert(maximum > minimum, "Slider maximum must exceed minimum")
    local theme = context.Theme
    local frame = Instance.new("Frame")
    frame.Name = "Slider"
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -36, 0, 13)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = theme.TextWhite
    label.TextSize = context.IsCompact and 10 or 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 34, 0, 13)
    valueLabel.Position = UDim2.new(1, -34, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextColor3 = theme.Accent
    valueLabel.TextSize = context.IsCompact and 9 or 10
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local hitbox = Instance.new("TextButton")
    hitbox.Name = "Hitbox"
    hitbox.Size = UDim2.new(1, 0, 0, 14)
    hitbox.Position = UDim2.new(0, 0, 0, 20)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 4)
    bar.Position = UDim2.new(0, 0, 0.5, -2)
    bar.BackgroundColor3 = theme.ToggleOff
    bar.BorderSizePixel = 0
    bar.Parent = hitbox
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local value = math.clamp(default, minimum, maximum)
    local dragging = false
    local function update(x)
        local width = bar.AbsoluteSize.X
        if width <= 0 then return end
        local percent = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
        local nextValue = math.floor(minimum + (maximum - minimum) * percent)
        if nextValue == value then return end
        value = nextValue
        fill.Size = UDim2.new(percent, 0, 1, 0)
        valueLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    local initialPercent = (value - minimum) / (maximum - minimum)
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    valueLabel.Text = tostring(value)
    context.Connect(hitbox.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    context.Connect(context.UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    context.Connect(context.UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {Get = function() return value end}
end

function Components.AddButton(context, parent, text, callback)
    local button = Instance.new("TextButton")
    button.Name = "ActionButton"
    button.Size = UDim2.new(1, 0, 0, 32)
    button.BackgroundColor3 = context.Theme.AccentSoft
    button.Font = Enum.Font.GothamMedium
    button.Text = text
    button.TextColor3 = context.Theme.TextWhite
    button.TextSize = context.IsCompact and 10 or 11
    button.Parent = parent
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", button)
    stroke.Color = context.Theme.Border
    stroke.Transparency = 0.15
    context.Connect(button.MouseButton1Click, function()
        context.Tween(button, 0.1, {BackgroundColor3 = context.Theme.Accent})
        if callback then callback() end
    end)
    return button
end

return Components

