-- Enhanced Key Verification System with Working Webhook
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration
local KEY_SERVER_URL = "http://lavenderboa.onpella.app/static/keys.txt"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/hillsTools/t-b-4-sc-r-i-p-t/refs/heads/main/tb3.lua"

-- Webhook URL (Replace with your actual webhook)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1395916551940735088/uI1KthKsINh5aefwXcnsLh0VWJF9VDWiqJadnkVWDnO2WaZPHbgkdHN57zgj1o5JJjdl"

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
    -- Enhanced executor detection
    if identifyexecutor and type(identifyexecutor) == "function" then
        return identifyexecutor() or "Unknown"
    elseif getexecutorname and type(getexecutorname) == "function" then
        return getexecutorname() or "Unknown"
    else
        return "Unknown"
    end
end

local function getHWID()
    -- Generate a simulated HWID
    local success, hwid = pcall(function()
        return HttpService:GenerateGUID(false):sub(1, 12)
    end)
    return success and hwid or "Unknown"
end

local function sendWebhookLog(key, isValid, userIdToPing)
    local player = Players.LocalPlayer
    if not player then return false, "No player found" end
    
    local executorInfo = getExecutorInfo()
    local hwid = getHWID()
    local gameName = "Unknown Game"
    
    -- Safely get game name
    local success, gameInfo = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and gameInfo then
        gameName = gameInfo.Name
    end
    
    -- Prepare message content with user ping if valid
    local messageContent = isValid and ("<@" .. userIdToPing .. "> Key used successfully!") or "Invalid key attempt!"
    
    -- Prepare embed data
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
        },
        footer = {
            text = "Lua Networks Script Logger"
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    -- Prepare the complete payload
    local data = {
        content = messageContent,
        embeds = {embed},
        username = "Key Verification System",
        avatar_url = "https://i.imgur.com/AfFp7pu.png"
    }
    
    -- Encode to JSON
    local jsonData
    local encodeSuccess, encodeResult = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if not encodeSuccess then
        warn("Failed to encode webhook data: " .. encodeResult)
        return false, "JSON encoding failed"
    end
    
    jsonData = encodeResult
    
    -- Send the webhook request using your working method
    local requestSuccess, requestResult = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, jsonData)
        return true, "Success"
    end)
    
    if not requestSuccess then
        warn("Webhook request failed: " .. requestResult)
        return false, requestResult
    end
    
    return true, "Success"
end

-- Main verification logic
local function verifyKey(key)
    -- Check if script_key is defined
    if not script_key or script_key == "KEY_HERE" then
        kickPlayer("Please set your key in the script: script_key='YOUR_KEY'")
        return false, nil
    end
    
    -- Add a small delay before verification 
    wait(0.5)
    
    -- Fetch valid keys from server
    local success, result = pcall(function()
        return game:HttpGet(KEY_SERVER_URL)
    end)
    
    if not success then
        kickPlayer("Failed to connect to key server. Try again later.")
        return false, nil
    end
    
    -- Parse keys and verify (looking only for the key portion)
    local keyFound = false
    local userIdToPing = nil
    
    for line in result:gmatch("[^\r\n]+") do
        -- Parse the key format: KEY_XXXX|TIMESTAMP|USERID
        local storedKey, timestamp, userId = line:match("^([^|]+)|([^|]+)|([^|]+)$")
        
        -- Also try matching if the format is slightly different
        if not storedKey then
            storedKey = line:match("^([^|]+)") -- Just get the key part
        end
        
        if storedKey and storedKey == script_key then
            keyFound = true
            userIdToPing = userId -- This will be nil if format didn't include user ID
            break
        end
    end
    
    -- Send webhook log
    local webhookSuccess, webhookResult = sendWebhookLog(script_key, keyFound, userIdToPing)
    if not webhookSuccess then
        warn("Webhook logging failed: " .. webhookResult)
        -- Don't kick for webhook failures, just continue
    end
    
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
