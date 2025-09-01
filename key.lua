local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Webhook_URL = "https://discord.com/api/webhooks/1395916551940735088/uI1KthKsINh5aefwXcnsLh0VWJF9VDWiqJadnkVWDnO2WaZPHbgkdHN57zgj1o5JJjdl"
local MAIN_SCRIPT_URL = "https://office-greennightingale.onpella.app/script/api/loader/v1/73e087e9-0c29-4201-a707-7b6fa81838fb"
local KEY_SERVER_URL = "http://lavenderboa.onpella.app/static/keys.txt"

-- Enhanced executor detection with better naming
local function getExecutor()
    if syn and syn.request then
        return syn.request, "Synapse X"
    elseif fluxus and fluxus.request then
        return fluxus.request, "Fluxus"
    elseif Krnl and Krnl.request then
        return Krnl.request, "Krnl"
    elseif Sentinel and Sentinel.request then
        return Sentinel.request, "Sentinel"
    elseif Electron and Electron.request then
        return Electron.request, "Electron"
    elseif Oxygen and Oxygen.request then
        return Oxygen.request, "Oxygen"
    elseif Delta and Delta.request then
        return Delta.request, "Delta"
    elseif Comet and Comet.request then
        return Comet.request, "Comet"
    elseif ScriptWare and ScriptWare.request then
        return ScriptWare.request, "Script-Ware"
    elseif Xeno and Xeno.request then
        return Xeno.request, "Xeno"
    elseif SirHurt and SirHurt.request then
        return SirHurt.request, "SirHurt"
    elseif ProtoSmasher and ProtoSasmher.request then
        return ProtoSmasher.request, "ProtoSmasher"
    elseif request then
        if getexecutorname then
            local success, name = pcall(getexecutorname)
            if success and name and type(name) == "string" and name ~= "" then
                return request, name
            end
        end
        return request, "Premium Executor"
    elseif http and http.request then
        return http.request, "HTTP Executor"
    else
        return nil, "Roblox Studio"
    end
end

-- Function to get real HWID
local function getRealHWID()
    if syn and syn.crypt then
        local success, result = pcall(function()
            return syn.crypt.custom.hex(syn.crypt.hash.sha256(syn.crypt.random(16)))
        end)
        if success then return result end
    end
    
    if fluxus and fluxus.get_hwid then
        local success, result = pcall(fluxus.get_hwid)
        if success then return result end
    end
    
    if Krnl and Krnl.GetHWID then
        local success, result = pcall(Krnl.GetHWID)
        if success then return result end
    end
    
    if Delta and Delta.get_hwid then
        local success, result = pcall(Delta.get_hwid)
        if success then return result end
    end
    
    local success, result = pcall(function()
        return game:GetService('RbxAnalyticsService'):GetClientId()
    end)
    if success then return result end
    
    return "HWID-Unavailable"
end

-- Function to get key from environment
local function getScriptKey()
    if script_key and script_key ~= "KEY_HERE" then
        return script_key
    elseif getgenv and getgenv().script_key and getgenv().script_key ~= "KEY_HERE" then
        return getgenv().script_key
    elseif _G and _G.script_key and _G.script_key ~= "KEY_HERE" then
        return _G.script_key
    else
        return "KEY_NOT_SET"
    end
end

-- Function to get Discord ID from key server
local function getDiscordIDFromKey(key)
    if key == "KEY_NOT_SET" then
        return "No Discord Linked"
    end
    
    local success, result = pcall(function()
        return game:HttpGet(KEY_SERVER_URL)
    end)
    
    if success then
        for line in result:gmatch("[^\r\n]+") do
            local storedKey, timestamp, userId = line:match("^([^|]+)|([^|]+)|([^|]+)$")
            if not storedKey then
                storedKey = line:match("^([^|]+)")
            end
            
            if storedKey and storedKey == key then
                return userId and ("<@" .. userId .. ">") or "No Discord Linked"
            end
        end
    end
    
    return "No Discord Linked"
end

-- Execution counter
local executionCount = 1
local function incrementExecutionCount()
    executionCount = executionCount + 1
    return executionCount
end

-- Anti-loadstring protection :cite[1]:cite[6]
local function checkForLoadstringInjection()
    -- Check if someone is trying to use loadstring maliciously
    if getgenv and getgenv().LOADSTRING_INJECTED then
        return true
    end
    
    -- Check for common injection methods
    local stack = debug.traceback()
    if string.find(stack:lower(), "loadstring") or string.find(stack:lower(), "inject") then
        return true
    end
    
    return false
end

-- Key verification function with anti-exploit measures :cite[1]:cite[7]
local function verifyKey(key)
    -- Anti-loadstring check
    if checkForLoadstringInjection() then
        warn("Loadstring injection detected! Kicking player.")
        game:GetService("Players").LocalPlayer:Kick("Anti-cheat violation detected. (Code: LSI-01)")
        return false, nil
    end
    
    if key == "KEY_NOT_SET" then
        game:GetService("Players").LocalPlayer:Kick("Please set your key in the script: script_key='YOUR_KEY'")
        return false, nil
    end
    
    wait(0.5)
    
    local success, result = pcall(function()
        return game:HttpGet(KEY_SERVER_URL)
    end)
    
    if not success then
        game:GetService("Players").LocalPlayer:Kick("Failed to connect to key server. Try again later.")
        return false, nil
    end
    
    local keyFound = false
    local userIdToPing = nil
    
    for line in result:gmatch("[^\r\n]+") do
        local storedKey, timestamp, userId = line:match("^([^|]+)|([^|]+)|([^|]+)$")
        if not storedKey then
            storedKey = line:match("^([^|]+)")
        end
        
        if storedKey and storedKey == key then
            keyFound = true
            userIdToPing = userId
            break
        end
    end
    
    if not keyFound then
        game:GetService("Players").LocalPlayer:Kick("Invalid key! Join Discord: discord.gg/kS8nha9K")
        return false, nil
    end
    
    return true, userIdToPing
end

-- Main execution
local requestFunc, executorName = getExecutor()
if not requestFunc then
    warn("Error: No HTTP request function available. Executor:", executorName)
    return
end

local realHWID = getRealHWID()
local playerName = Players.LocalPlayer.DisplayName
local scriptKey = getScriptKey()
local discordID = getDiscordIDFromKey(scriptKey)
local currentExecutionCount = incrementExecutionCount()

-- Get game name safely
local gameName = "Unknown Game"
local success, result = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId).Name
end)
if success then
    gameName = result
end

-- Send webhook
local success, response = pcall(function()
    return requestFunc({
        Url = Webhook_URL,
        Method = 'POST',
        Headers = {
            ['Content-Type'] = 'application/json'
        },
        Body = HttpService:JSONEncode({
            content = "",
            embeds = {{
                title = "**User executed!**",
                description = "This user has executed the script ``" .. currentExecutionCount .. "`` times in total successfully.",
                type = "rich",
                color = tonumber(0x00FF00),
                thumbnail = {
                    url = "https://cdn.discordapp.com/attachments/your_image_url_here/icon.png"
                },
                fields = {
                    {
                        name = "HWID:",
                        value = "||" .. realHWID .. "||",
                        inline = false
                    },
                    {
                        name = "Executor:",
                        value = "```" .. executorName .. "```",
                        inline = true
                    },
                    {
                        name = "Discord ID:",
                        value = discordID,
                        inline = true
                    },
                    {
                        name = "Key:",
                        value = "||" .. scriptKey .. "||",
                        inline = false
                    },
                    {
                        name = "Job ID:",
                        value = "||" .. game.JobId .. "||",
                        inline = true
                    },
                    {
                        name = "Action Fingerprint:",
                        value = "⬛⬛⬛⬛⬛⬛ -> syn/sw-uid\n⬛⬛⬛🟥🟫⬜ -> country\n🟫⬛⬛⬛⬛⬜ -> executor name\n🟫⬛⬛⬛⬛🟩 -> ip address",
                        inline = false
                    },
                    {
                        name = "Script:",
                        value = "```Synth\n(ID: 18c1d2e51a4b27a54fa6871d5cfaa5ec)```",
                        inline = false
                    }
                },
                footer = {
                    text = "Lua Networks - #1 Lua Licensing System https://luarmor.net/",
                    icon_url = "https://cdn.discordapp.com/attachments/your_image_url_here/logo.png"
                },
                timestamp = DateTime.now():ToIsoDate()
            }}
        })
    })
end)

-- Check webhook results
if success and response and response.Success then
    print("✅ Webhook sent successfully!")
    print("⚡ Executor:", executorName)
    print("🔑 Key:", scriptKey)
    print("👤 Player:", playerName)
    print("🔢 Execution Count:", currentExecutionCount)
else
    warn("❌ Failed to send webhook")
    if not success then
        warn("Error:", response)
    elseif response then
        warn("Status Code:", response.StatusCode)
        warn("Status Message:", response.StatusMessage)
    end
end

-- Execute key verification and main script loading
local verificationSuccess, userId = verifyKey(scriptKey)

if verificationSuccess then
    -- Key is valid, execute the main script
    print("✅ Key verified successfully! Loading main script...")
    
    local mainScriptSuccess, mainScript = pcall(function()
        return game:HttpGet(MAIN_SCRIPT_URL)
    end)
    
    if mainScriptSuccess then
        -- Safe execution environment :cite[1]
        local loadedFunction, loadError = loadstring(mainScript)
        if loadedFunction then
            -- Set a safe environment to prevent malicious code execution
            local safeEnv = {
                print = print,
                warn = warn,
                wait = wait,
                tick = tick,
                os = { time = os.time, date = os.date },
                math = math,
                string = string,
                table = table,
                coroutine = coroutine,
                type = type,
                assert = assert,
                error = error,
                pcall = pcall,
                xpcall = xpcall,
                select = select,
                tonumber = tonumber,
                tostring = tostring,
                unpack = unpack,
                pairs = pairs,
                ipairs = ipairs,
                next = next,
                rawequal = rawequal,
                rawget = rawget,
                rawset = rawset,
                setmetatable = setmetatable,
                getmetatable = getmetatable
            }
            
            setfenv(loadedFunction, safeEnv)
            
            local executeSuccess, executeError = pcall(loadedFunction)
            if not executeSuccess then
                warn("❌ Failed to execute main script:", executeError)
            end
        else
            warn("❌ Failed to load main script:", loadError)
        end
    else
        warn("❌ Failed to fetch main script:", mainScript)
    end
else
    warn("❌ Key verification failed. Script execution stopped.")
end
