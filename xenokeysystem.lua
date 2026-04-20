local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local CONFIG = {
    LICENSE_KEY = "Test",
    SCRIPTS = {
        [14890802310] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
        [74747090658891] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
        [130169555191153] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/universalpiece/refs/heads/main/main"
    }
}

local Window = Rayfield:CreateWindow({
    Name = "Xeno's - Key System",
    LoadingTitle = "Loading",
    LoadingSubtitle = "Almost there...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local AuthTab = Window:CreateTab("Verification", 4483362458)
local SessionKey = ""

AuthTab:CreateSection("License Key")

AuthTab:CreateInput({
    Name = "Enter Key",
    PlaceholderText = "Paste your key here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        SessionKey = Value:gsub("%s+", "")
    end,
})

AuthTab:CreateButton({
    Name = "Verify Key",
    Callback = function()
        if SessionKey == "" then
            return Rayfield:Notify({Title = "Error", Content = "Please enter a key!", Duration = 3, Image = 4483362458})
        end

        Rayfield:Notify({Title = "Verifying", Content = "Checking key...", Duration = 2, Image = 4483362458})

        task.delay(1.6, function()
            if SessionKey == CONFIG.LICENSE_KEY then
                local Source = CONFIG.SCRIPTS[game.PlaceId]

                if Source then
                    Rayfield:Notify({Title = "Success", Content = "Key valid! Loading...", Duration = 3, Image = 4483362458})
                    task.wait(1)
                    Rayfield:Destroy()
                    loadstring(game:HttpGet(Source))()
                else
                    Rayfield:Notify({Title = "Unsupported", Content = "This game is not supported.", Duration = 4, Image = 4483362458})
                end
            else
                Rayfield:Notify({Title = "Failed", Content = "Invalid key.", Duration = 4, Image = 4483362458})
            end
        end)
    end,
})
