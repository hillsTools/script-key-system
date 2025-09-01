-- Key Verification System (No UI Version)
local script_key = "KEY HERE" -- Replace with your actual key

-- Function to kick player with message
local function kickPlayer(reason)
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick(reason)
    end
    wait(2)
    while true do end -- Freeze execution
end

-- Check if script_key is still the default value
if script_key == "KEY HERE" then
    kickPlayer("Please set your key in the script: script_key='YOUR_KEY'")
    return
end

-- Fetch valid keys from server
local success, result = pcall(function()
    return game:HttpGet("http://lavenderboa.onpella.app/static/keys.txt")
end)

if not success then
    kickPlayer("Failed to connect to key server. Try again later.")
    return
end

-- Parse keys and verify
local keyFound = false
for line in result:gmatch("[^\r\n]+") do
    local key = line:match("^([^|]+)|") or line
    if key and key == script_key then
        keyFound = true
        break
    end
end

if not keyFound then
    kickPlayer("Invalid key! Join Discord: discord.gg/kS8nha9K")
    return
end

-- Key is valid, execute the main script
loadstring(game:HttpGet("https://raw.githubusercontent.com/hillsTools/t-b-4-sc-r-i-p-t/refs/heads/main/tb3.lua"))()
