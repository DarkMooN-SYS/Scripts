local Dashboard = {}

function Dashboard.Configure(menu)
    local home = menu.CreateTab("About", "i", "MooN | HUB and current experience details.")

    menu.AddBanner(home.Left, "Welcome to MooN | HUB", "A clean, responsive menu for your experience.")

    local session = menu.CreateSection(home.Left, "Current experience")
    menu.AddInfo(session, "Place ID", menu.Context.PlaceId)
    menu.AddInfo(session, "Universe ID", menu.Context.UniverseId)
    menu.AddInfo(session, "Interface", menu.Context.IsMobile and "Touch" or "Desktop")

    local details = menu.CreateSection(home.Left, "About MooN | HUB")
    menu.AddInfo(details, "Version", "1.0.0")
    menu.AddInfo(details, "Layout", menu.Context.IsCompact and "Compact" or "Desktop")
    menu.AddInfo(details, "Input", menu.Context.IsMobile and "Touch controls" or "Keyboard and mouse")

    local preview = menu.CreateSection(home.Right, "Control preview")
    local previewStatus = menu.AddInfo(preview, "Demo setting", "Off")
    menu.AddToggle(preview, "Preview toggle", false, function(enabled)
        previewStatus.Value.Text = enabled and "On" or "Off"
        previewStatus.Value.TextColor3 = enabled and menu.Context.Theme.Accent or menu.Context.Theme.TextWhite
    end)
    menu.AddSlider(preview, "Preview slider", 0, 100, 65, function(value)
        previewStatus.Value.Text = tostring(value) .. "%"
    end)

    local keys = menu.CreateSection(home.Right, "Controls")
    menu.AddInfo(keys, "Toggle menu", menu.Context.IsCompact and "Tap minimize" or "Right Shift")
    menu.AddInfo(keys, "Move window", menu.Context.IsCompact and "Touch" or "Drag the header")
end

return Dashboard
