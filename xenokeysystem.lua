local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main"
local UNIVERSAL_SCRIPT_URL = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/universalpiece/refs/heads/main/main"
local VALID_KEY = "KEY--65FFD-4E435-7956A-3FBA7-55EE2-77E92-2B80E-9E5C4"

local GAME_SCRIPTS = {
    [14890802310] = MAIN_SCRIPT_URL,
    [130169555191153] = UNIVERSAL_SCRIPT_URL,
}

local Window = Rayfield:CreateWindow({
    Name = "Xeno's - Key System",
    LoadingTitle = "Loading",
    LoadingSubtitle = "Almost there...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local Tab = Window:CreateTab("Verification", 4483362458)
local KeyInput = ""

Tab:CreateSection("License Key")

Tab:CreateInput({
    Name = "Enter Key",
    PlaceholderText = "Paste your key here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        KeyInput = Text:gsub("%s+", "")
    end,
})

Tab:CreateButton({
    Name = "Verify Key",
    Callback = function()
        if KeyInput == "" then
            Rayfield:Notify({Title = "Error", Content = "Please enter a key!", Duration = 3, Image = 4483362458})
            return
        end

        Rayfield:Notify({Title = "Verifying", Content = "Checking key...", Duration = 2, Image = 4483362458})

        task.spawn(function()
            task.wait(0.5)

            if KeyInput == VALID_KEY then
                local scriptUrl = GAME_SCRIPTS[game.PlaceId]

                if scriptUrl then
                    Rayfield:Notify({Title = "Success", Content = "Key valid! Loading...", Duration = 3, Image = 4483362458})
                    task.wait(1.5)
                    loadstring(game:HttpGet(scriptUrl))()
                else
                    Rayfield:Notify({Title = "Unsupported", Content = "This game is not supported.", Duration = 4, Image = 4483362458})
                end
            else
                Rayfield:Notify({Title = "Failed", Content = "Invalid key.", Duration = 4, Image = 4483362458})
            end
        end)
    end,
})