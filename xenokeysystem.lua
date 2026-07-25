local HttpService = game:GetService("HttpService")

local WORKER_URL = "https://access-keys.xenopersonalbusiness.workers.dev"

local SCRIPTS = {
    [14890802310] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
    [74747090658891] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
    [130169555191153] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/universalpiece/refs/heads/main/main",
    [15694107053] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Jujutsu-Legacy/refs/heads/main/main",
    [17889317592] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Jujutsu-Legacy/refs/heads/main/main",
    [18795268508] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Jujutsu-Legacy/refs/heads/main/main",
}

local AUTH_DIR = "XenoKeySystem"
local AUTH_FILE = "XenoKeySystem/auth_cache.json"
local SESSION_DURATION = 86400

local function urlEncode(str)
    return tostring(str):gsub("([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function doRequest(url, method)
    method = method or "GET"
    if syn and syn.request then
        local res = syn.request({ Url = url, Method = method })
        return res.StatusCode, res.Body
    end
    if request then
        local res = request({ Url = url, Method = method })
        if res and res.StatusCode then return res.StatusCode, res.Body end
    end
    local ok, http = pcall(require, "socket.http")
    if ok then
        local body, code = http.request(url)
        return code, body
    end
    return nil, nil
end

local function saveAuth(key)
    pcall(function()
        if not isfolder(AUTH_DIR) then makefolder(AUTH_DIR) end
        writefile(AUTH_FILE, HttpService:JSONEncode({ key = key, timestamp = os.time() }))
    end)
end

local function getCachedKey()
    local ok, result = pcall(function()
        if isfile(AUTH_FILE) then
            local data = HttpService:JSONDecode(readfile(AUTH_FILE))
            if data and data.key and data.timestamp and (os.time() - data.timestamp) < SESSION_DURATION then
                return data.key
            end
        end
        return nil
    end)
    return ok and result
end

local function clearAuth()
    pcall(function()
        if isfile(AUTH_FILE) then delfile(AUTH_FILE) end
    end)
end

local function detectExecutor()
    if identifyexecutor then
        local ok, name, version = pcall(identifyexecutor)
        if ok and name then
            if version and version ~= "" then
                return tostring(name) .. " " .. tostring(version)
            end
            return tostring(name)
        end
    end
    if syn then return "Synapse X" end
    if KRNL_LOADED then return "KRNL" end
    if FluxusAndroid or Fluxus then return "Fluxus" end
    if is_sirhurt then return "SirHurt" end
    if pebc_load then return "ProtoSmasher" end
    if OXYGEN_LOADED then return "Oxygen U" end
    if Electron then return "Electron" end
    return "Unknown"
end

local function bindAccount(key)
    pcall(function()
        local player = game.Players.LocalPlayer
        if player then
            local executor = detectExecutor()
            local bindUrl = WORKER_URL .. "/bind?key=" .. urlEncode(key) .. "&username=" .. urlEncode(player.Name) .. "&executor=" .. urlEncode(executor)
            doRequest(bindUrl, "POST")
        end
    end)
end

local function checkServerBinding(key)
    local status, body = doRequest(WORKER_URL .. "/validate?key=" .. urlEncode(key))
    if status ~= 200 or not body then
        return false, "could not reach key server"
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or not data then
        return false, "invalid server response"
    end
    if not data.valid then
        return false, "key expired or invalid"
    end
    if not data.username then
        return false, "account not bound"
    end
    return true, data.username
end

local function validateKey(key)
    if not key or key == "" then
        return false, "no key provided"
    end
    local status, body = doRequest(WORKER_URL .. "/validate?key=" .. urlEncode(key))
    if status ~= 200 or not body then
        return false, "could not reach key server"
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or not data then
        return false, "invalid server response"
    end
    if not data.valid then
        return false, "key expired or invalid"
    end
    bindAccount(key)
    return true, "ok"
end

local function loadGameScript()
    local src = SCRIPTS[game.PlaceId]
    if src then
        loadstring(game:HttpGet(src))()
    else
        pcall(function()
            local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
            local W = Rayfield:CreateWindow({ Name = "Xeno's", KeySystem = false })
            local T = W:CreateTab("Info", 4483362458)
            T:CreateSection("Notice")
            T:CreateParagraph({ Title = "Unsupported Game", Content = "This game is not supported yet." })
        end)
    end
end

if not SCRIPTS[game.PlaceId] then
    pcall(function()
        local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
        local W = Rayfield:CreateWindow({ Name = "Xeno's", KeySystem = false })
        local T = W:CreateTab("Info", 4483362458)
        T:CreateSection("Notice")
        T:CreateParagraph({ Title = "Unsupported Game", Content = "This game is not supported. Join the Discord for updates." })
    end)
    return
end

local cachedKey = getCachedKey()
if cachedKey then
    local bound, username = checkServerBinding(cachedKey)
    if bound then
        loadGameScript()
        return
    else
        clearAuth()
    end
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Xeno's - Key System",
    LoadingTitle = "Loading",
    LoadingSubtitle = "Almost there...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local AuthTab = Window:CreateTab("Verification", 4483362458)
local sessionKey = ""

AuthTab:CreateSection("License Key")

AuthTab:CreateInput({
    Name = "Enter Key",
    PlaceholderText = "Paste your key here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        sessionKey = value:gsub("%s+", "")
    end,
})

AuthTab:CreateButton({
    Name = "Verify Key",
    Callback = function()
        if sessionKey == "" then
            return Rayfield:Notify({ Title = "Error", Content = "Please enter a key!", Duration = 3, Image = 4483362458 })
        end

        Rayfield:Notify({ Title = "Verifying", Content = "Checking key...", Duration = 2, Image = 4483362458 })

        task.delay(1.6, function()
            local ok, msg = validateKey(sessionKey)

            if ok then
                local bound, username = checkServerBinding(sessionKey)
                if not bound then
                    Rayfield:Notify({ Title = "Error", Content = "Key valid but account not bound. Please wait and try again.", Duration = 4, Image = 4483362458 })
                    return
                end
                Rayfield:Notify({ Title = "Success", Content = "Key valid! Loading...", Duration = 3, Image = 4483362458 })
                task.wait(1)
                saveAuth(sessionKey)
                Rayfield:Destroy()
                loadGameScript()
            else
                Rayfield:Notify({ Title = "Failed", Content = msg, Duration = 4, Image = 4483362458 })
            end
        end)
    end,
})
