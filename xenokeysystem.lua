local HttpService = game:GetService("HttpService")

local CONFIG = {
    LICENSE_KEY = "Xeno",
    SCRIPTS = {
        [14890802310] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
        [74747090658891] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
        [130169555191153] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/universalpiece/refs/heads/main/main"
    },
    AUTH_DIR = "XenoKeySystem",
    AUTH_FILE = "XenoKeySystem/auth_cache.json",
    SESSION_DURATION = 86400
}

local function saveAuth()
    pcall(function()
        if not isfolder(CONFIG.AUTH_DIR) then
            makefolder(CONFIG.AUTH_DIR)
        end
        writefile(CONFIG.AUTH_FILE, HttpService:JSONEncode({ timestamp = os.time() }))
    end)
end

local function isAuthed()
    local success, result = pcall(function()
        if isfile(CONFIG.AUTH_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG.AUTH_FILE))
            return data and data.timestamp and (os.time() - data.timestamp) < CONFIG.SESSION_DURATION
        end
        return false
    end)
    return success and result
end

local source = CONFIG.SCRIPTS[game.PlaceId]

if isAuthed() then
    if source then
        return loadstring(game:HttpGet(source))()
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
            return Rayfield:Notify({Title = "Error", Content = "Please enter a key!", Duration = 3, Image = 4483362458})
        end

        Rayfield:Notify({Title = "Verifying", Content = "Checking key...", Duration = 2, Image = 4483362458})

        task.delay(1.6, function()
            if sessionKey == CONFIG.LICENSE_KEY then
                local src = CONFIG.SCRIPTS[game.PlaceId]

                if src then
                    Rayfield:Notify({Title = "Success", Content = "Key valid! Loading...", Duration = 3, Image = 4483362458})
                    task.wait(1)
                    saveAuth()
                    Rayfield:Destroy()
                    loadstring(game:HttpGet(src))()
                else
                    Rayfield:Notify({Title = "Unsupported", Content = "This game is not supported.", Duration = 4, Image = 4483362458})
                end
            else
                Rayfield:Notify({Title = "Failed", Content = "Invalid key.", Duration = 4, Image = 4483362458})
            end
        end)
    end,
})

if isAuthed() and not source then
    Rayfield:Notify({Title = "Notice", Content = "You are verified, but this game is not supported.", Duration = 6, Image = 4483362458})
end
