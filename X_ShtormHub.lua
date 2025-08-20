local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "X shtorm",
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by coolselsi",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "X_ShtormHub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = true,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"PornoHub"}
   }
})

-- Сервисы
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Локальные переменные
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Настройки ESP
local ESP_SETTINGS = {
    Enabled = false,
    TeamCheck = false,
    Boxes = false,
    Tracers = false,
    Names = false,
    Health = false,
    Distance = false,
    MaxDistance = 1000,
    TextSize = 13,
    TeamColor = false,
    EnemyColor = Color3.fromRGB(255, 0, 0),
    FriendlyColor = Color3.fromRGB(0, 255, 0)
}

-- Настройки аимбота
local AIMBOT_SETTINGS = {
    Enabled = false,
    TeamCheck = true,
    Smoothness = 20,
    FOV = 180,
    TargetPart = "Head",
    ShowFOV = true,
    Prediction = 0.12, -- Предсказание движения
    MaxDistance = 1000, -- Максимальная дистанция аимбота
    BigHeadMode = false, -- Режим большой головы
    HeadSize = 2.0 -- Размер головы
}

-- Настройки спидхака
local SPEEDHACK_SETTINGS = {
    Enabled = false,
    Speed = 50,
    OriginalWalkSpeed = nil -- Будет установлено при первом включении
}

-- Таблицы для хранения объектов
local ESPObjects = {}
local ESPConnections = {}
local AimbotConnection = nil
local SpeedhackConnection = nil
local FOVCircle = nil
local LastTarget = nil
local SmoothingBuffer = Vector2.new(0, 0)
local OriginalHeadSizes = {} -- Таблица для хранения оригинальных размеров голов

-- Создание FOV круга
local function CreateFOVCircle()
    if FOVCircle then
        FOVCircle:Remove()
    end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = AIMBOT_SETTINGS.ShowFOV and AIMBOT_SETTINGS.Enabled
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Thickness = 1.5
    FOVCircle.Filled = false
    FOVCircle.Radius = AIMBOT_SETTINGS.FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Transparency = 0.7
    FOVCircle.ZIndex = 999
end

-- Функция для увеличения/уменьшения головы
local function ApplyBigHead(player, enable)
    if not player.Character then return end
    
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    
    if enable then
        -- Сохраняем оригинальный размер
        if not OriginalHeadSizes[player] then
            OriginalHeadSizes[player] = head.Size
        end
        -- Увеличиваем голову
        head.Size = Vector3.new(
            OriginalHeadSizes[player].X * AIMBOT_SETTINGS.HeadSize,
            OriginalHeadSizes[player].Y * AIMBOT_SETTINGS.HeadSize,
            OriginalHeadSizes[player].Z * AIMBOT_SETTINGS.HeadSize
        )
    else
        -- Восстанавливаем оригинальный размер
        if OriginalHeadSizes[player] then
            head.Size = OriginalHeadSizes[player]
            OriginalHeadSizes[player] = nil
        end
    end
end

-- Функция применения/сброса большой головы для всех игроков
local function ToggleBigHeadMode(enable)
    if enable then
        -- Применяем большую голову ко всем игрокам
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ApplyBigHead(player, true)
            end
        end
    else
        -- Сбрасываем большую голову у всех игроков
        for player, originalSize in pairs(OriginalHeadSizes) do
            if player and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    head.Size = originalSize
                end
            end
        end
        OriginalHeadSizes = {}
    end
end

-- Функция создания ESP для игрока
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    -- Настройка Box
    esp.Box.Visible = false
    esp.Box.Thickness = 1.5
    esp.Box.Filled = false
    esp.Box.ZIndex = 1
    
    -- Настройка Tracer
    esp.Tracer.Visible = false
    esp.Tracer.Thickness = 1.5
    esp.Tracer.ZIndex = 1
    
    -- Настройка текстовых элементов
    for _, text in pairs({esp.Name, esp.Health, esp.Distance}) do
        text.Visible = false
        text.Size = ESP_SETTINGS.TextSize
        text.Center = true
        text.Outline = true
        text.OutlineColor = Color3.new(0, 0, 0)
        text.ZIndex = 2
    end
    
    ESPObjects[player] = esp
end

-- Функция удаления ESP
local function RemoveESP(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            pcall(function()
                drawing:Remove()
            end)
        end
        ESPObjects[player] = nil
    end
end

-- Функция обновления ESP
local function UpdateESP()
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Character or not player.Character:FindFirstChild("Humanoid") or not player.Character:FindFirstChild("HumanoidRootPart") then
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
            continue
        end

        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
            continue
        end

        local character = player.Character
        local rootPart = character.HumanoidRootPart
        local humanoid = character.Humanoid
        
        -- Проверка команды
        local isEnemy = true
        if ESP_SETTINGS.TeamCheck and player.Team and LocalPlayer.Team then
            isEnemy = player.Team ~= LocalPlayer.Team
        end
        
        -- Расчет расстояния
        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
        local isInRange = distance <= ESP_SETTINGS.MaxDistance
        
        -- Определение цвета
        local color = ESP_SETTINGS.EnemyColor
        if not isEnemy then
            color = ESP_SETTINGS.FriendlyColor
        end
        if ESP_SETTINGS.TeamColor then
            color = player.TeamColor.Color
        end
        
        local shouldShow = isInRange and (not ESP_SETTINGS.TeamCheck or isEnemy) and ESP_SETTINGS.Enabled
        
        -- Обновление Box
        esp.Box.Visible = shouldShow and ESP_SETTINGS.Boxes
        if esp.Box.Visible then
            local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local head = character:FindFirstChild("Head")
                if head then
                    local headPos = Camera:WorldToViewportPoint(head.Position)
                    local height = math.abs(headPos.Y - rootPos.Y) * 1.8
                    local width = height * 0.6
                    
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Color = color
                end
            else
                esp.Box.Visible = false
            end
        end
        
        -- Обновление Tracer
        esp.Tracer.Visible = shouldShow and ESP_SETTINGS.Tracers
        if esp.Tracer.Visible then
            local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                esp.Tracer.Color = color
            else
                esp.Tracer.Visible = false
            end
        end
        
        -- Обновление текстовых элементов
        local head = character:FindFirstChild("Head")
        if head then
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                -- Имя
                esp.Name.Visible = shouldShow and ESP_SETTINGS.Names
                if esp.Name.Visible then
                    esp.Name.Text = player.Name
                    esp.Name.Position = Vector2.new(headPos.X, headPos.Y - 35)
                    esp.Name.Color = color
                end
                
                -- Здоровье
                esp.Health.Visible = shouldShow and ESP_SETTINGS.Health
                if esp.Health.Visible then
                    esp.Health.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                    esp.Health.Position = Vector2.new(headPos.X, headPos.Y - 20)
                    esp.Health.Color = color
                end
                
                -- Дистанция
                esp.Distance.Visible = shouldShow and ESP_SETTINGS.Distance
                if esp.Distance.Visible then
                    esp.Distance.Text = math.floor(distance) .. " studs"
                    esp.Distance.Position = Vector2.new(headPos.X, headPos.Y - 5)
                    esp.Distance.Color = color
                end
            else
                esp.Name.Visible = false
                esp.Health.Visible = false
                esp.Distance.Visible = false
            end
        end
    end
end

-- Инициализация ESP
local function InitializeESP()
    -- Очистка старых объектов
    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end
    
    -- Создание ESP для всех игроков
    for _, player in ipairs(Players:GetPlayers()) do
        CreateESP(player)
    end
    
    -- Обработчики игроков
    if ESPConnections.PlayerAdded then
        ESPConnections.PlayerAdded:Disconnect()
    end
    if ESPConnections.PlayerRemoving then
        ESPConnections.PlayerRemoving:Disconnect()
    end
    if ESPConnections.Update then
        ESPConnections.Update:Disconnect()
    end
    
    ESPConnections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        CreateESP(player)
        -- Применяем большую голову к новому игроку если режим включен
        if AIMBOT_SETTINGS.BigHeadMode then
            ApplyBigHead(player, true)
        end
    end)
    
    ESPConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
        -- Убираем большую голову при выходе игрока
        if OriginalHeadSizes[player] then
            OriginalHeadSizes[player] = nil
        end
    end)
    
    ESPConnections.Update = RunService.RenderStepped:Connect(UpdateESP)
end

-- Улучшенная система аимбота с плавностью и предсказанием
local function GetTargetPosition(character)
    local targetPart
    if AIMBOT_SETTINGS.TargetPart == "Head" then
        targetPart = character:FindFirstChild("Head")
    else
        targetPart = character:FindFirstChild("HumanoidRootPart")
    end
    
    if not targetPart then
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart").Position
    end
    
    -- Предсказание движения
    local velocity = targetPart.Velocity
    local predictedPosition = targetPart.Position + (velocity * AIMBOT_SETTINGS.Prediction)
    
    return predictedPosition
end

local function SmoothAim(targetScreenPos)
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local rawDelta = targetScreenPos - screenCenter
    
    -- Экспоненциальное сглаживание
    local smoothingFactor = 1 / AIMBOT_SETTINGS.Smoothness
    SmoothingBuffer = SmoothingBuffer:Lerp(rawDelta, smoothingFactor)
    
    -- Применяем сглаженное движение
    mousemoverel(SmoothingBuffer.X, SmoothingBuffer.Y)
end

local function AdvancedAimbot()
    if not AIMBOT_SETTINGS.Enabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then 
        SmoothingBuffer = Vector2.new(0, 0) -- Сброс буфера при отпускании кнопки
        LastTarget = nil
        return 
    end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local closestTarget = nil
    local closestDistance = AIMBOT_SETTINGS.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local localPlayerPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    -- Обновляем позицию FOV круга
    if FOVCircle and FOVCircle.Visible then
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = AIMBOT_SETTINGS.FOV
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Проверка команды
        if AIMBOT_SETTINGS.TeamCheck then
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                continue
            end
        end
        
        -- Проверка дистанции
        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end
        
        local distance = (localPlayerPos - targetRoot.Position).Magnitude
        if distance > AIMBOT_SETTINGS.MaxDistance then continue end
        
        local targetPos = GetTargetPosition(player.Character)
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        
        if onScreen then
            local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            
            if screenDistance < closestDistance then
                closestDistance = screenDistance
                closestTarget = player
            end
        end
    end
    
    if closestTarget then
        LastTarget = closestTarget
        local targetPos = GetTargetPosition(closestTarget.Character)
        local screenPos = Camera:WorldToViewportPoint(targetPos)
        
        SmoothAim(Vector2.new(screenPos.X, screenPos.Y))
    else
        LastTarget = nil
        SmoothingBuffer = Vector2.new(0, 0) -- Сброс буфера если нет цели
    end
end

local function InitializeAimbot()
    if AimbotConnection then
        AimbotConnection:Disconnect()
    end
    
    CreateFOVCircle()
    AimbotConnection = RunService.RenderStepped:Connect(AdvancedAimbot)
end

-- Система спидхака
local function GetDefaultWalkSpeed()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            return humanoid.WalkSpeed
        end
    end
    return 16 -- Значение по умолчанию
end

local function ApplySpeedhack()
    if not SPEEDHACK_SETTINGS.Enabled then return end
    if not LocalPlayer.Character then return end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Сохраняем оригинальные значения при первом включении
    if SPEEDHACK_SETTINGS.OriginalWalkSpeed == nil then
        SPEEDHACK_SETTINGS.OriginalWalkSpeed = GetDefaultWalkSpeed()
    end
    
    -- Применяем настройки спидхака
    humanoid.WalkSpeed = SPEEDHACK_SETTINGS.Speed
end

local function ResetSpeedhack()
    if not LocalPlayer.Character then return end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Восстанавливаем оригинальные значения
    if SPEEDHACK_SETTINGS.OriginalWalkSpeed then
        humanoid.WalkSpeed = SPEEDHACK_SETTINGS.OriginalWalkSpeed
    else
        humanoid.WalkSpeed = GetDefaultWalkSpeed()
    end
end

local function InitializeSpeedhack()
    if SpeedhackConnection then
        SpeedhackConnection:Disconnect()
    end
    
    if SPEEDHACK_SETTINGS.Enabled then
        -- Сохраняем оригинальную скорость перед включением
        if SPEEDHACK_SETTINGS.OriginalWalkSpeed == nil then
            SPEEDHACK_SETTINGS.OriginalWalkSpeed = GetDefaultWalkSpeed()
        end
        SpeedhackConnection = RunService.Heartbeat:Connect(ApplySpeedhack)
    else
        ResetSpeedhack()
    end
end

-- Функция сброса настроек
local function ResetSettings()
    ESP_SETTINGS.Enabled = false
    AIMBOT_SETTINGS.Enabled = false
    SPEEDHACK_SETTINGS.Enabled = false
    
    -- Выключаем режим большой головы
    if AIMBOT_SETTINGS.BigHeadMode then
        ToggleBigHeadMode(false)
        if BigHeadToggle then BigHeadToggle:Set(false) end
        AIMBOT_SETTINGS.BigHeadMode = false
    end
    
    if ESPToggle then ESPToggle:Set(false) end
    if AimbotToggle then AimbotToggle:Set(false) end
    if SpeedhackToggle then SpeedhackToggle:Set(false) end
    
    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end
    
    if AimbotConnection then
        AimbotConnection:Disconnect()
        AimbotConnection = nil
    end
    
    if SpeedhackConnection then
        SpeedhackConnection:Disconnect()
        SpeedhackConnection = nil
    end
    
    if FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end
    
    SmoothingBuffer = Vector2.new(0, 0)
    LastTarget = nil
    
    -- Сбрасываем спидхак
    ResetSpeedhack()
    SPEEDHACK_SETTINGS.OriginalWalkSpeed = nil -- Сбрасываем для следующего включения
    
    for _, connection in pairs(ESPConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    Rayfield:Notify({
        Title = "Сброс",
        Content = "Все настройки сброшены!",
        Duration = 2,
    })
end

-- Инициализация при запуске
InitializeESP()

-- Создание вкладок
local ESPTab = Window:CreateTab("ESP", 4483362458)
local AimbotTab = Window:CreateTab("Aimbot", 7733960981)
local SpeedhackTab = Window:CreateTab("Speedhack", 7733960981)

-- Элементы ESP
local ESPToggle = ESPTab:CreateToggle({
    Name = "Включить ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        ESP_SETTINGS.Enabled = Value
        Rayfield:Notify({
            Title = "ESP",
            Content = Value and "ВКЛ" or "ВЫКЛ",
            Duration = 1,
        })
    end,
})

ESPTab:CreateToggle({
    Name = "Проверка команды",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(Value)
        ESP_SETTINGS.TeamCheck = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Боксы",
    CurrentValue = false,
    Flag = "Boxes",
    Callback = function(Value)
        ESP_SETTINGS.Boxes = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Линии",
    CurrentValue = false,
    Flag = "Tracers",
    Callback = function(Value)
        ESP_SETTINGS.Tracers = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Имена",
    CurrentValue = false,
    Flag = "Names",
    Callback = function(Value)
        ESP_SETTINGS.Names = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Здоровье",
    CurrentValue = false,
    Flag = "Health",
    Callback = function(Value)
        ESP_SETTINGS.Health = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Дистанция",
    CurrentValue = false,
    Flag = "Distance",
    Callback = function(Value)
        ESP_SETTINGS.Distance = Value
    end,
})

ESPTab:CreateSlider({
    Name = "Макс. дистанция ESP",
    Range = {0, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "MaxDistance",
    Callback = function(Value)
        ESP_SETTINGS.MaxDistance = Value
    end,
})

-- Элементы аимбота
local AimbotToggle = AimbotTab:CreateToggle({
    Name = "Включить аимбот",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(Value)
        AIMBOT_SETTINGS.Enabled = Value
        if Value then
            InitializeAimbot()
            Rayfield:Notify({
                Title = "Aimbot",
                Content = "Аимбот ВКЛ (ПКМ для прицеливания)",
                Duration = 3,
            })
        else
            if AimbotConnection then
                AimbotConnection:Disconnect()
                AimbotConnection = nil
            end
            if FOVCircle then
                FOVCircle.Visible = false
            end
            SmoothingBuffer = Vector2.new(0, 0)
            LastTarget = nil
            Rayfield:Notify({
                Title = "Aimbot",
                Content = "Аимбот ВЫКЛ",
                Duration = 2,
            })
        end
    end,
})

local BigHeadToggle = AimbotTab:CreateToggle({
    Name = "Режим большой головы",
    CurrentValue = false,
    Flag = "BigHeadMode",
    Callback = function(Value)
        AIMBOT_SETTINGS.BigHeadMode = Value
        ToggleBigHeadMode(Value)
        Rayfield:Notify({
            Title = "Big Head",
            Content = Value and "ВКЛ" or "ВЫКЛ",
            Duration = 2,
        })
    end,
})

AimbotTab:CreateSlider({
    Name = "Размер головы",
    Range = {1.0, 5.0},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 2.0,
    Flag = "HeadSize",
    Callback = function(Value)
        AIMBOT_SETTINGS.HeadSize = Value
        -- Обновляем размер головы если режим включен
        if AIMBOT_SETTINGS.BigHeadMode then
            ToggleBigHeadMode(false) -- Сначала сбрасываем
            ToggleBigHeadMode(true)  -- Затем применяем новый размер
        end
    end,
})

AimbotTab:CreateToggle({
    Name = "Показать FOV",
    CurrentValue = true,
    Flag = "ShowFOV",
    Callback = function(Value)
        AIMBOT_SETTINGS.ShowFOV = Value
        if FOVCircle then
            FOVCircle.Visible = Value and AIMBOT_SETTINGS.Enabled
        end
    end,
})

AimbotTab:CreateToggle({
    Name = "Проверка команды",
    CurrentValue = true,
    Flag = "AimbotTeamCheck",
    Callback = function(Value)
        AIMBOT_SETTINGS.TeamCheck = Value
    end,
})

AimbotTab:CreateSlider({
    Name = "Плавность",
    Range = {5, 50},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 20,
    Flag = "Smoothness",
    Callback = function(Value)
        AIMBOT_SETTINGS.Smoothness = Value
    end,
})

AimbotTab:CreateSlider({
    Name = "FOV",
    Range = {50, 400},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 180,
    Flag = "FOV",
    Callback = function(Value)
        AIMBOT_SETTINGS.FOV = Value
        if FOVCircle then
            FOVCircle.Radius = Value
        end
    end,
})

AimbotTab:CreateSlider({
    Name = "Макс. дистанция аимбота",
    Range = {0, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "AimbotMaxDistance",
    Callback = function(Value)
        AIMBOT_SETTINGS.MaxDistance = Value
    end,
})

AimbotTab:CreateSlider({
    Name = "Предсказание",
    Range = {0, 0.3},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.12,
    Flag = "Prediction",
    Callback = function(Value)
        AIMBOT_SETTINGS.Prediction = Value
    end,
})

AimbotTab:CreateDropdown({
    Name = "Цель",
    Options = {"Head", "Body"},
    CurrentOption = "Head",
    Flag = "TargetPart",
    Callback = function(Option)
        AIMBOT_SETTINGS.TargetPart = Option
    end,
})

-- Элементы спидхака
local SpeedhackToggle = SpeedhackTab:CreateToggle({
    Name = "Включить спидхак",
    CurrentValue = false,
    Flag = "SpeedhackEnabled",
    Callback = function(Value)
        SPEEDHACK_SETTINGS.Enabled = Value
        if Value then
            InitializeSpeedhack()
            Rayfield:Notify({
                Title = "Speedhack",
                Content = "Спидхак ВКЛ",
                Duration = 2,
            })
        else
            if SpeedhackConnection then
                SpeedhackConnection:Disconnect()
                SpeedhackConnection = nil
            end
            ResetSpeedhack()
            Rayfield:Notify({
                Title = "Speedhack",
                Content = "Спидхак ВЫКЛ",
                Duration = 2,
            })
        end
    end,
})

SpeedhackTab:CreateSlider({
    Name = "Скорость передвижения",
    Range = {16, 1000},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = 50,
    Flag = "WalkSpeed",
    Callback = function(Value)
        SPEEDHACK_SETTINGS.Speed = Value
        if SPEEDHACK_SETTINGS.Enabled then
            ApplySpeedhack()
        end
    end,
})

SpeedhackTab:CreateLabel({
    Name = "Рекомендуемые настройки:",
    Text = "Обычная: 25-50 | Быстрая: 100-200 | Максимальная: 500-1000"
})

-- Кнопка сброса
local SettingsTab = Window:CreateTab("Настройки", 7733960981)
SettingsTab:CreateButton({
    Name = "Сбросить все настройки",
    Callback = ResetSettings
})

Rayfield:LoadConfiguration()

-- Автоматическое обновление FOV круга
RunService.RenderStepped:Connect(function()
    if FOVCircle and FOVCircle.Visible then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end)

-- Автоматическое применение спидхака при изменении персонажа
LocalPlayer.CharacterAdded:Connect(function()
    if SPEEDHACK_SETTINGS.Enabled then
        task.wait(0.5) -- Ждем пока персонаж полностью загрузится
        ApplySpeedhack()
    else
        -- При смене персонажа всегда сбрасываем к оригинальной скорости
        ResetSpeedhack()
    end
end)

-- Автоматическое сохранение оригинальной скорости при появлении персонажа
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if SPEEDHACK_SETTINGS.OriginalWalkSpeed == nil then
        SPEEDHACK_SETTINGS.OriginalWalkSpeed = GetDefaultWalkSpeed()
    end
end)

-- Автоматическое применение большой головы к новым игрокам
Players.PlayerAdded:Connect(function(player)
    if AIMBOT_SETTINGS.BigHeadMode then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            ApplyBigHead(player, true)
        end)
    end
end)

