-- Enhanced Key Verification System with Webhook Logging
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Configuration
local KEY_SERVER_URL = "http://lavenderboa.onpella.app/static/keys.txt"
local WEBHOOK_URL = "https://discord.com/api/webhooks/1395916551940735088/uI1KthKsINh5aefwXcnsLh0VWJF9VDWiqJadnkVWDnO2WaZPHbgkdHN57zgj1o5JJjdl"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/hillsTools/t-b-4-sc-r-i-p-t/refs/heads/main/tb3.lua"

-- Utility functions
local function kickPlayer(reason)
    local player = Players.LocalPlayer
    if player then
        player:Kick(reason)
    end
    wait(2)
    while true do end -- Freeze execution
end

local function getExecutorInfo()
    -- Enhanced executor detection based on multiple methods
    local executorInfo = "Unknown"
    
    -- Method 1: Check for known executor files :cite[7]
    local contentProvider = game:GetService("ContentProvider")
    local knownExecutors = {
        "rbxasset://custom_gloop/",
        "rbxasset://RonixExploit/",
        "rbxasset://Synapse/",
        "rbxasset://ScriptWare/"
    }
    
    for _, executorPath in pairs(knownExecutors) do
        local success = pcall(function()
            contentProvider:PreloadAsync({executorPath})
        end)
        if not success then
            executorInfo = executorPath:match("rbxasset://(.*)/")
            break
        end
    end
    
    -- Method 2: Check for environment variables
    if executorInfo == "Unknown" then
        if getexecutorname and type(getexecutorname) == "function" then
            executorInfo = getexecutorname() or "CustomExecutor"
        elseif identifyexecutor and type(identifyexecutor) == "function" then
            executorInfo = identifyexecutor() or "CustomExecutor"
        end
    end
    
    return executorInfo
end

local function getHWID()
    -- Simulate HWID generation (note: real HWID requires proper implementation)
    local player = Players.LocalPlayer
    if player then
        return HttpService:GenerateGUID(false):sub(1, 12)
    end
    return "Unknown"
end

local function sendWebhookLog(key, isValid, userIdToPing)
    local player = Players.LocalPlayer
    if not player then return end
    
    local executorInfo = getExecutorInfo()
    local hwid = getHWID()
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    
    local messageContent = isValid and ("<@" .. userIdToPing .. "> Key used successfully!") or "Invalid key attempt!"
    
    local embed = {
        title = "Key Verification Log",
        color = isValid and 65280 or 16711680, -- Green or Red
        fields = {
            {
                name = "Player Info",
                value = "Username: " .. player.Name .. "\nDisplay Name: " .. player.DisplayName,
                inline = true
            },
            {
                name = "Key Status",
                value = isValid and "✅ Valid Key" or "❌ Invalid Key",
                inline = true
            },
            {
                name = "Key Used",
                value = "```" .. key .. "```",
                inline = false
            },
            {
                name = "Executor Info",
                value = "```" .. executorInfo .. "```",
                inline = true
            },
            {
                name = "HWID",
                value = "```" .. hwid .. "```",
                inline = true
            },
            {
                name = "Game",
                value = "```" .. gameName .. "```",
                inline = false
            },
            {
                name = "Timestamp",
                value = "```" .. os.date("%Y-%m-%d %H:%M:%S") .. "```",
                inline = true
            }
        }
    }
    
    local data = {
        content = messageContent,
        embeds = {embed},
        username = "Key Verification System",
        avatar_url = "https://i.imgur.com/AfFp7pu.png"
    }
    
    local success, result = pcall(function()
        return game:HttpPost(
            WEBHOOK_URL,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson,
            false
        )
    end)
    
    if not success then
        warn("Failed to send webhook: " .. result)
    end
end

-- Main verification logic
local function verifyKey(key)
    -- Check if script_key is defined
    if not script_key or script_key == "KEY_HERE" then
        kickPlayer("Please set your key in the script: script_key='YOUR_KEY'")
        return false, nil
    end
    
    -- Add a small delay before verification :cite[2]:cite[6]
    wait(0.5)
    
    -- Fetch valid keys from server
    local success, result = pcall(function()
        return game:HttpGet(KEY_SERVER_URL)
    end)
    
    if not success then
        kickPlayer("Failed to connect to key server. Try again later.")
        return false, nil
    end
    
    -- Parse keys and verify
    local keyFound = false
    local userIdToPing = nil
    
    for line in result:gmatch("[^\r\n]+") do
        -- Parse the key format: KEY_XXXX|TIMESTAMP|USERID
        local storedKey, timestamp, userId = line:match("^([^|]+)|([^|]+)|([^|]+)$")
        
        if storedKey and storedKey == script_key then
            keyFound = true
            userIdToPing = userId
            break
        end
    end
    
    -- Send webhook log
    sendWebhookLog(script_key, keyFound, userIdToPing)
    
    if not keyFound then
        kickPlayer("Invalid key! Join Discord: discord.gg/kS8nha9K")
        return false, nil
    end
    
    return true, userIdToPing
end

-- Main execution
local success, userId = verifyKey(script_key)

if success then
    -- Key is valid, execute the main script
    loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
end
