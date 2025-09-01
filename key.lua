-- Enhanced Key Verification System with Webhook Logging
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Configuration
local KEY_SERVER_URL = "http://lavenderboa.onpella.app/static/keys.txt"
local WEBHOOK_URL = "https://discord.com/api/webhooks/1395916551940735088/uI1KthKsINh5aefwXcnsLh0VWJF9VDWiqJadnkVWDnO2WaZPHbgkdHN57zgj1o5JJjdl"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/hillsTools/t-b-4-sc-r-i-p-t/refs/heads/main/tb3.lua"

-- Use a proxy if Discord is blocking Roblox requests :cite[2]:cite[7]
local USE_PROXY = true
local PROXY_URL = "https://webhook.lewisakura.moe"  -- Example proxy

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
    local executorInfo = "Unknown"
    
    -- Method 1: Check for known executor identifiers
    if getexecutorname and type(getexecutorname) == "function" then
        executorInfo = getexecutorname() or "CustomExecutor"
    elseif identifyexecutor and type(identifyexecutor) == "function" then
        executorInfo = identifyexecutor() or "CustomExecutor"
    end
    
    -- Method 2: Check environment variables
    if executorInfo == "Unknown" then
        if syn and syn.request then
            executorInfo = "Synapse X"
        elseif PROTOSMASHER_LOADED then
            executorInfo = "ProtoSmasher"
        elseif KRNL_LOADED then
            executorInfo = "Krnl"
        elseif isvm then
            executorInfo = "ScriptWare"
        end
    end
    
    return executorInfo
end

local function getHWID()
    -- Generate a simulated HWID
    local player = Players.LocalPlayer
    if player then
        return HttpService:GenerateGUID(false):sub(1, 12)
    end
    return "Unknown"
end

local function prepareWebhookURL(url)
    if USE_PROXY and string.find(url, "discord.com") then
        -- Replace discord.com with proxy URL :cite[7]
        return string.gsub(url, "https://discord.com", PROXY_URL)
    end
    return url
end

local function sendWebhookLog(key, isValid, userIdToPing)
    local player = Players.LocalPlayer
    if not player then return false, "No player found" end
    
    local executorInfo = getExecutorInfo()
    local hwid = getHWID()
    local gameName = "Unknown Game"
    
    -- Safely get game name
    local success, gameInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if success and gameInfo then
        gameName = gameInfo.Name
    end
    
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
        }
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
    
    -- Prepare webhook URL (with proxy if needed)
    local webhookUrl = prepareWebhookURL(WEBHOOK_URL)
    
    -- Send the webhook request
    local requestSuccess, requestResult = pcall(function()
        -- Use RequestAsync for better error handling :cite[2]
        local response = HttpService:RequestAsync({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        
        if not response.Success then
            return false, "HTTP " .. response.StatusCode .. ": " .. response.StatusMessage
        end
        
        return true, "Success"
    end)
    
    if not requestSuccess then
        warn("Webhook request failed: " .. requestResult)
        return false, requestResult
    end
    
    return requestResult
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
