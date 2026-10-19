local Debug = {}

local CACHE_LIMIT = 40
local DEDUPE_SECONDS = 60
local lastSent = {}

function Debug.Configure(menu)
    local cache = {}
    local remotePath = {"MooNHubDebug", "Report"}

    local function report(feature, message, traceback)
        feature = tostring(feature or "Unknown feature"):sub(1, 80)
        message = tostring(message or "Unknown error"):sub(1, 1200)
        traceback = tostring(traceback or ""):sub(1, 2500)
        local key = feature .. "\n" .. message .. "\n" .. traceback
        local now = os.clock()
        for cachedKey, cachedAt in pairs(lastSent) do
            if now - cachedAt >= DEDUPE_SECONDS then lastSent[cachedKey] = nil end
        end
        local previous = lastSent[key]
        if previous and now - previous < DEDUPE_SECONDS then
            return false
        end
        lastSent[key] = now

        table.insert(cache, {
            Time = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            PlaceId = game.PlaceId,
            GameId = game.GameId,
            Feature = feature,
            Message = message,
            Traceback = traceback,
        })
        while #cache > CACHE_LIMIT do table.remove(cache, 1) end

        task.spawn(function()
            local folder = game:GetService("ReplicatedStorage"):FindFirstChild(remotePath[1])
            if not folder then
                local ok, result = pcall(function()
                    return game:GetService("ReplicatedStorage"):WaitForChild(remotePath[1], 5)
                end)
                if ok then folder = result end
            end
            local remote = folder and folder:FindFirstChild(remotePath[2])
            if remote and remote:IsA("RemoteEvent") then
                pcall(function()
                    remote:FireServer({
                        Feature = feature,
                        Message = message,
                        Traceback = traceback,
                    })
                end)
            end
        end)
        return true
    end

    menu.Debug = {
        Report = report,
        GetCache = function()
            local copy = {}
            for index, entry in ipairs(cache) do
                copy[index] = table.clone(entry)
            end
            return copy
        end,
        Wrap = function(feature, callback)
            return function(...)
                local args = table.pack(...)
                local result = table.pack(xpcall(function()
                    return callback(table.unpack(args, 1, args.n))
                end, debug.traceback))
                if not result[1] then
                    report(feature, result[2], result[2])
                    warn("[MooN | HUB] " .. tostring(feature) .. " failed: " .. tostring(result[2]))
                    return nil
                end
                return table.unpack(result, 2, result.n)
            end
        end,
    }
end

return Debug
