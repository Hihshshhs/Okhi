--[[
    MOKZ ULTRA FAST JOINER - CLEAN VERSION

    IMPORTANT:
    1. Fully close Roblox before replacing the previous script.
    2. Do not run this together with another FPS booster/fast loader.
    3. This never deletes or modifies sounds.
    4. This never changes RenderFidelity.
    5. This does not preload the entire game.
]]

local CONFIG = {
    -- FPS while Roblox is initially loading.
    LoadingFPS = 60,

    -- FPS after loading.
    FinishedFPS = 9999,

    -- The loader will never remain longer than this.
    MaximumLoaderTime = 10,

    -- Maximum time spent waiting for the character.
    CharacterWaitTime = 5,

    -- Temporarily stop rendering the 3D world.
    Disable3DWhileLoading = true,

    -- Only preload important local assets.
    PreloadCriticalAssets = true,

    -- Never preload thousands of assets.
    MaximumCriticalAssets = 200,

    -- Loader only waits this long for critical assets.
    CriticalPreloadWait = 0.75,

    -- Low graphics
    DisableGlobalShadows = true,
    DisablePartShadows = true,
    DisableParticles = true,
    DisableTrails = true,
    DisableBeams = true,
    DisableFireSmokeSparkles = true,
    DisablePostEffects = true,
    DisableClouds = true,
    DisableLightShadows = true,

    -- Amount optimized each frame.
    InstancesPerFrame = 350
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

local environment = _G

if type(getgenv) == "function" then
    local success, result = pcall(getgenv)

    if success and type(result) == "table" then
        environment = result
    end
end

-- Remove a previous copy of this script.
if type(environment.__MokzUltraFastJoinCleanup) == "function" then
    pcall(environment.__MokzUltraFastJoinCleanup)
end

repeat
    task.wait()
until Players.LocalPlayer

local LocalPlayer = Players.LocalPlayer
local setFPSCap = environment.setfpscap

local active = true
local renderingDisabled = false
local loadingUI
local statusLabel
local connections = {}
local optimizationQueue = {}

local function addConnection(connection)
    connections[#connections + 1] = connection
    return connection
end

local function setFPS(fps)
    if type(setFPSCap) == "function" then
        pcall(function()
            setFPSCap(fps)
        end)
    end
end

local function setRendering(enabled)
    local success = pcall(function()
        RunService:Set3dRenderingEnabled(enabled)
    end)

    if success then
        renderingDisabled = not enabled
    end

    return success
end

local function updateStatus(text)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = text
    end
end

local function cleanupLoader()
    if renderingDisabled then
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)

        renderingDisabled = false
    end

    if loadingUI then
        pcall(function()
            loadingUI:Destroy()
        end)

        loadingUI = nil
    end
end

environment.__MokzUltraFastJoinCleanup = function()
    active = false

    cleanupLoader()

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)
    table.clear(optimizationQueue)
end

local function createLoadingUI()
    local parent

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

    if not playerGui then
        playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    end

    parent = playerGui or CoreGui

    if not parent then
        return
    end

    local oldUI = parent:FindFirstChild("MokzUltraFastJoin")

    if oldUI then
        oldUI:Destroy()
    end

    loadingUI = Instance.new("ScreenGui")
    loadingUI.Name = "MokzUltraFastJoin"
    loadingUI.IgnoreGuiInset = true
    loadingUI.ResetOnSpawn = false
    loadingUI.DisplayOrder = 2147483647
    loadingUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    background.BorderSizePixel = 0
    background.Parent = loadingUI

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.fromScale(0.5, 0.47)
    title.Size = UDim2.new(0.8, 0, 0, 45)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = "FAST JOINING BY MOKZ"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 27
    title.Parent = background

    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    statusLabel.Position = UDim2.fromScale(0.5, 0.53)
    statusLabel.Size = UDim2.new(0.8, 0, 0, 30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Starting client..."
    statusLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    statusLabel.TextSize = 16
    statusLabel.Parent = background

    local spinner = Instance.new("Frame")
    spinner.Name = "Spinner"
    spinner.AnchorPoint = Vector2.new(0.5, 0.5)
    spinner.Position = UDim2.fromScale(0.5, 0.575)
    spinner.Size = UDim2.fromOffset(24, 24)
    spinner.BackgroundTransparency = 1
    spinner.Parent = background

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Transparency = 0.25
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = spinner

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = spinner

    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.85),
        NumberSequenceKeypoint.new(1, 0)
    })
    gradient.Parent = stroke

    addConnection(
        RunService.RenderStepped:Connect(function(deltaTime)
            if spinner and spinner.Parent then
                spinner.Rotation += deltaTime * 230
            end
        end)
    )

    local success = pcall(function()
        loadingUI.Parent = parent
    end)

    if not success or not loadingUI.Parent then
        pcall(function()
            loadingUI.Parent = CoreGui
        end)
    end
end

createLoadingUI()
setFPS(CONFIG.LoadingFPS)

-- Use Roblox's lowest graphics quality.
pcall(function()
    local gameSettings =
        UserSettings():GetService("UserGameSettings")

    gameSettings.SavedQualityLevel =
        Enum.SavedQualitySetting.QualityLevel1
end)

pcall(function()
    settings().Rendering.QualityLevel =
        Enum.QualityLevel.Level01
end)

-- Do not set MeshPartDetailLevel.
-- Do not change RenderFidelity.

if CONFIG.DisableGlobalShadows then
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
    end)
end

pcall(function()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    if terrain then
        terrain.Decoration = false
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
    end
end)

local function optimizeInstance(instance)
    if not active or not instance or not instance.Parent then
        return
    end

    -- Never modify sounds.
    if instance:IsA("Sound")
        or instance:IsA("SoundGroup")
        or instance:IsA("AudioPlayer")
    then
        return
    end

    if instance:IsA("BasePart") then
        if CONFIG.DisablePartShadows then
            pcall(function()
                instance.CastShadow = false
            end)
        end

        -- Do not change Material, RenderFidelity,
        -- CollisionFidelity or physical properties.
        return
    end

    if instance:IsA("ParticleEmitter") then
        if CONFIG.DisableParticles then
            pcall(function()
                instance.Enabled = false
            end)
        end

        return
    end

    if instance:IsA("Trail") then
        if CONFIG.DisableTrails then
            pcall(function()
                instance.Enabled = false
            end)
        end

        return
    end

    if instance:IsA("Beam") then
        if CONFIG.DisableBeams then
            pcall(function()
                instance.Enabled = false
            end)
        end

        return
    end

    if instance:IsA("Fire")
        or instance:IsA("Smoke")
        or instance:IsA("Sparkles")
    then
        if CONFIG.DisableFireSmokeSparkles then
            pcall(function()
                instance.Enabled = false
            end)
        end

        return
    end

    if instance:IsA("PostEffect") then
        if CONFIG.DisablePostEffects then
            pcall(function()
                instance.Enabled = false
            end)
        end

        return
    end

    if instance:IsA("Clouds") then
        if CONFIG.DisableClouds then
            pcall(function()
                instance.Enabled = false
            end)
        end

        return
    end

    if instance:IsA("PointLight")
        or instance:IsA("SpotLight")
        or instance:IsA("SurfaceLight")
    then
        if CONFIG.DisableLightShadows then
            pcall(function()
                instance.Shadows = false
            end)
        end

        return
    end

    -- Intentionally untouched:
    --
    -- Sounds
    -- Animations
    -- Decals
    -- Textures
    -- SurfaceAppearance
    -- Clothing
    -- Atmosphere
    -- Sky
    -- Models
    -- GUIs
end

local function enqueue(instance)
    if active and instance then
        optimizationQueue[#optimizationQueue + 1] = instance
    end
end

addConnection(
    Workspace.DescendantAdded:Connect(function(instance)
        task.defer(function()
            optimizeInstance(instance)
        end)
    end)
)

addConnection(
    Lighting.DescendantAdded:Connect(function(instance)
        task.defer(function()
            optimizeInstance(instance)
        end)
    end)
)

-- Process optimization gradually to prevent a giant freeze.
addConnection(
    RunService.Heartbeat:Connect(function()
        local processed = 0

        while processed < CONFIG.InstancesPerFrame do
            local queueLength = #optimizationQueue

            if queueLength == 0 then
                break
            end

            local instance = optimizationQueue[queueLength]
            optimizationQueue[queueLength] = nil

            optimizeInstance(instance)
            processed += 1
        end
    end)
)

-- Scan existing visuals without blocking the main loading thread.
task.spawn(function()
    local roots = {
        Workspace,
        Lighting
    }

    for _, root in ipairs(roots) do
        if not active then
            return
        end

        local descendants = root:GetDescendants()

        for index, instance in ipairs(descendants) do
            if not active then
                return
            end

            enqueue(instance)

            if index % 1000 == 0 then
                task.wait()
            end
        end
    end
end)

-- Render the UI once before disabling 3D rendering.
task.wait()

if CONFIG.Disable3DWhileLoading then
    if setRendering(false) then
        updateStatus("Receiving game data...")
    end
end

local loaderStarted = os.clock()
local loaderDeadline =
    loaderStarted + CONFIG.MaximumLoaderTime

local dots = 0

-- Only wait for Roblox's actual initial load.
while not game:IsLoaded()
    and os.clock() < loaderDeadline
    and active
do
    dots = (dots % 3) + 1

    updateStatus(
        "Receiving game data" .. string.rep(".", dots)
    )

    task.wait(0.12)
end

-- Wait briefly for the local character.
local character = LocalPlayer.Character
local characterDeadline = math.min(
    loaderDeadline,
    os.clock() + CONFIG.CharacterWaitTime
)

while not character
    and os.clock() < characterDeadline
    and active
do
    character = LocalPlayer.Character

    dots = (dots % 3) + 1

    updateStatus(
        "Starting character" .. string.rep(".", dots)
    )

    task.wait(0.1)
end

if character then
    local rootPart =
        character:FindFirstChild("HumanoidRootPart")

    while not rootPart
        and os.clock() < characterDeadline
        and active
    do
        rootPart =
            character:FindFirstChild("HumanoidRootPart")

        task.wait(0.05)
    end
end

-- Preload only the local UI and character.
-- Never scan ReplicatedStorage or the entire Workspace.
if CONFIG.PreloadCriticalAssets
    and active
    and os.clock() < loaderDeadline
then
    local criticalAssets = {}
    local assetSeen = setmetatable({}, {
        __mode = "k"
    })

    local allowedClasses = {
        ImageLabel = true,
        ImageButton = true,
        Sound = true,
        Animation = true,
        MeshPart = true,
        SpecialMesh = true,
        Decal = true,
        Texture = true,
        SurfaceAppearance = true,
        Shirt = true,
        Pants = true,
        ShirtGraphic = true,
        VideoFrame = true
    }

    local function collectCritical(root)
        if not root then
            return
        end

        local descendants = root:GetDescendants()

        for _, instance in ipairs(descendants) do
            if #criticalAssets >= CONFIG.MaximumCriticalAssets then
                return
            end

            if allowedClasses[instance.ClassName]
                and not assetSeen[instance]
            then
                assetSeen[instance] = true
                criticalAssets[#criticalAssets + 1] = instance
            end
        end
    end

    collectCritical(character)

    local playerGui =
        LocalPlayer:FindFirstChildOfClass("PlayerGui")

    collectCritical(playerGui)

    -- Include sounds that are already trying to play.
    for _, sound in ipairs(SoundService:GetDescendants()) do
        if #criticalAssets >= CONFIG.MaximumCriticalAssets then
            break
        end

        if sound:IsA("Sound")
            and sound.Playing
            and not assetSeen[sound]
        then
            assetSeen[sound] = true
            criticalAssets[#criticalAssets + 1] = sound
        end
    end

    if #criticalAssets > 0 then
        updateStatus(
            string.format(
                "Warming important assets... %d",
                #criticalAssets
            )
        )

        local preloadFinished = false

        task.spawn(function()
            pcall(function()
                ContentProvider:PreloadAsync(criticalAssets)
            end)

            preloadFinished = true
        end)

        local preloadDeadline = math.min(
            loaderDeadline,
            os.clock() + CONFIG.CriticalPreloadWait
        )

        -- Never keep the screen waiting indefinitely.
        while not preloadFinished
            and os.clock() < preloadDeadline
            and active
        do
            task.wait(0.05)
        end
    end
end

updateStatus("Ready")

-- Always restore rendering.
pcall(function()
    RunService:Set3dRenderingEnabled(true)
end)

renderingDisabled = false
setFPS(CONFIG.FinishedFPS)

task.wait(0.1)

if loadingUI then
    pcall(function()
        loadingUI:Destroy()
    end)

    loadingUI = nil
end

print("[Mokz Fast Joiner] Ready. Sounds were preserved.")