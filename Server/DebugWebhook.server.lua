-- Install this Script in ServerScriptService in each experience you own.
-- Create a Creator Hub secret named MooNHubDiscordWebhook containing the FULL,
-- rotated Discord webhook URL. Never put the webhook URL in a LocalScript.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local folder = ReplicatedStorage:FindFirstChild("MooNHubDebug")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "MooNHubDebug"
	folder.Parent = ReplicatedStorage
end

local remote = folder:FindFirstChild("Report")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Report"
	remote.Parent = folder
end

local RATE_WINDOW = 60
local MAX_PER_WINDOW = 4
local DEDUPE_WINDOW = 300
local rate = {}
local dedupe = {}

local function clean(value, limit)
	if type(value) ~= "string" then return "" end
	value = value:gsub("@everyone", "@ everyone"):gsub("@here", "@ here")
	return value:sub(1, limit)
end

remote.OnServerEvent:Connect(function(player, report)
	if type(report) ~= "table" then return end
	local feature = clean(report.Feature, 80)
	local message = clean(report.Message, 1000)
	local traceback = clean(report.Traceback, 900)
	if feature == "" or message == "" then return end

	local now = os.clock()
	local bucket = rate[player]
	if not bucket or now - bucket.Start >= RATE_WINDOW then
		bucket = {Start = now, Count = 0}
		rate[player] = bucket
	end
	if bucket.Count >= MAX_PER_WINDOW then return end
	bucket.Count += 1

	local signature = tostring(game.PlaceId) .. "|" .. feature .. "|" .. message
	for oldSignature, sentAt in pairs(dedupe) do
		if now - sentAt >= DEDUPE_WINDOW then dedupe[oldSignature] = nil end
	end
	if dedupe[signature] and now - dedupe[signature] < DEDUPE_WINDOW then return end
	dedupe[signature] = now

	task.spawn(function()
		local ok, err = pcall(function()
			local webhook = HttpService:GetSecret("MooNHubDiscordWebhook")
			local payload = {
				allowed_mentions = {parse = {}},
				embeds = {{
					title = "MooN | HUB · Client bug report",
					color = 15158332,
					fields = {
						{name = "Experience", value = string.format("%s\nPlaceId: %d\nGameId: %d\nVersion: %d", game.Name, game.PlaceId, game.GameId, game.PlaceVersion), inline = false},
						{name = "Feature", value = feature, inline = true},
						{name = "Error", value = message, inline = false},
						{name = "Traceback", value = traceback ~= "" and ("```\n" .. traceback .. "\n```") or "(not provided)", inline = false},
					},
				}}
			}
			local body = HttpService:JSONEncode(payload)
			local response = HttpService:RequestAsync({
				Url = webhook,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = body,
			})
			if not response.Success then error("Webhook returned HTTP " .. tostring(response.StatusCode)) end
		end)
		if not ok then warn("[MooN | HUB Debug] Discord relay failed: " .. tostring(err)) end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	rate[player] = nil
end)
