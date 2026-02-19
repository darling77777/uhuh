local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local PlayerGui = lp:WaitForChild("PlayerGui")
local Humanoid, Animator
local StarterGui  = game:GetService("StarterGui")
local TestService = game:GetService("TestService")
local ChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
local SayMessageRequest = ChatEvents and ChatEvents:FindFirstChild("SayMessageRequest")
local testRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")

-- Camera and character locking features
local characterLockOn = false
local cameraLockOn = false
local lockedTarget = nil
local cameraLockThread = nil
local lockTimeout = 2.0 -- Keep lock active for 2 seconds after losing target
local lockCooldown = 0.05 -- Reduced cooldown for more responsive tracking
local aggressiveSmoothing = 0.7 -- More aggressive rotation smoothing
local cameraAggressiveSmoothing = 0.6 -- More aggressive camera smoothing
local lockLastActiveTime = 0
local lockDuration = 2.0 -- Default lock duration in seconds

local autoBlockTriggerSounds = {
       ["111225773242486"] = true, ["110592910502331"] = true, ["127793641088496"] = true, ["88582935528044"] = true,
    ["115968400767084"] = true, ["127648610882555"] = true, ["84353899757208"] = true, ["102228729296384"] = true,
    ["101633163910404"] = true, ["90819435118493"] = true, ["111647315359080"] = true, ["78487121898558"] = true,
    ["81597761297703"] = true, ["101387972373714"] = true, ["118250546180773"] = true, ["140659146085461"] = true,
    ["106727013904874"] = true, ["105484443350662"] = true, ["76875360649149"] = true, ["90905210726859"] = true,
    ["110115912768379"] = true, ["124538915839300"] = true, ["105014798922226"] = true, ["89315669689903"] = true,
    ["75640648249157"] = true, ["124580948668075"] = true, ["96949588668580"] = true, ["118831439312095"] = true,
    ["127672659178959"] = true, ["113037804008732"] = true, ["129533890149435"] = true, ["90878551190839"] = true,
    ["103260933771149"] = true, ["120179334324041"] = true, ["80507156446203"] = true, ["127930499074723"] = true,
    ["108516384531797"] = true, ["77907043310586"] = true, ["114710327235372"] = true, ["71090513459907"] = true,
    ["99282022492246"] = true, ["85810983952228"] = true, ["101034356725510"] = true, ["116945782470932"] = true,
    ["111654237193989"] = true, ["118193755053618"] = true, ["136098764956500"] = true, ["86833981571073"] = true,
    ["128386033701120"] = true, ["106466457231141"] = true, ["124601599539441"] = true, ["78293483681897"] = true,
    ["98211836782253"] = true, ["127249424960903"] = true, ["136728245733659"] = true, ["71310583817000"] = true,
    ["76959687420003"] = true, ["72425554233832"] = true, ["144352131"] = true, ["83419374143723"] = true,
    ["81859713902429"] = true, ["86510482379594"] = true, ["133990700986998"] = true, ["84895799077246"] = true,
    ["84413781229733"] = true, ["108901210586307"] = true, ["106647770195831"] = true, ["100452671741436"] = true,
    ["71834552297085"] = true, ["110877859670130"] = true, ["12222208"] = true, ["10548112"] = true,
    ["127324570265084"] = true, ["105937652127383"] = true, ["102923788301986"] = true, ["11998777"] = true,
    ["105458270463374"] = true, ["88970503168421"] = true, ["81299297965542"] = true, ["93069721274110"] = true,
    ["97167027849946"] = true, ["118919403162061"] = true, ["131219306779772"] = true, ["106776364623742"] = true,
    ["127846074966393"] = true, ["123345437821399"] = true, ["18885909645"] = true, ["18885909645"] = true,
    ["18885909645"] = true,
    ["121080480916189"] = true,
    ["131543461321709"] = true,
    ["84069821282466"] = true,
    ["114126519127454"] = true,
    ["70371667919898"] = true,
    ["137679730950847"] = true
}

-- Prevent repeated aim triggers for the same animation track
local lastAimTrigger = {}   -- keys = AnimationTrack, value = timestamp when we triggered
local AIM_WINDOW = 0.5      -- how long to aim (seconds)
local AIM_COOLDOWN = 0.6    -- don't retrigger within this many seconds

-- add once, outside the RenderStepped loop
local _lastPunchMessageTime = _lastPunchMessageTime or 0
local MESSAGE_PUNCH_COOLDOWN = 0.6 -- overall throttle (seconds)
local _punchPrevPlaying = _punchPrevPlaying or {} -- persist between frames

local _lastBlockMessageTime = _lastBlockMessageTime or 0
local MESSAGE_BLOCK_COOLDOWN = 0.6 -- overall throttle (seconds)
local _blockPrevPlaying = _blockPrevPlaying or {} -- persist between frames


local autoBlockTriggerAnims = {
    "105458270463374",
    "126830014841198",
    "129260077168659",
    "114375669802778",
    "80208162053146",
    "135853087227453",
    "88451353906104",
    "116618003477002",
    "83829782357897",
    "118298475669935",
    "74707328554358",
    "109667959938617",
    "120112897026015",
    "125403313786645",
    "118298475669935",
    "94958041603347",
    "130958529065375",
    "106860049270347",
    "124705663396411",
    "70948173568515",
    "126355327951215",
    "82113744478546",
    "133336594357903",
    "126681776859538",
    "81639435858902",
    "82113744478546",
    "126727756047566",
    "110702884830060",
    "101736016625776",
    "109845134167647",
    "121086746534252",
    "113440898787986",
    "118901677478609",
    "86204001129974",
    "81255669374177",
    "83446441317389",
    "129976080405072",
    "140125695162370",
    "77154853064447",
    "93316899246221",
    "137314737492715",
    "138390711856189",
    "121043188582126",
    "106847695270773",
    "91758760621955",
    "114356208094580",
    "126896426760253",
    "135884061951801",
    "139321362207112",
    "137642639873297",
    "132221505301108",
    "94634594529334",
    "100358581940485",
    "86185540502966",
    "106538427162796",
    "77375846492436",
    "93366464803829",
    "91509234639766",
    "86510482379594",
    "133990700986998",
    "84895799077246",
    "84413781229733",
    "128414736976503",
    "133363345661032",
    "139309647473555",
    "122709416391891",  
    "88451353906104",    -- Assets/Killers/Nosferatu/Config/Slash (M1 mặc định)
    "91628732643385",
    "124269076578545",
    "124269076578545",
    "90620531468240",
    "71834552297085",
    "110877859670130",
    "12222208",
    "10548112",
    "127324570265084",
    "105937652127383",
    "102923788301986",
    "11998777",
    "105458270463374",
    "88970503168421",
    "81299297965542",
    "93069721274110",
    "97167027849946",
    "118919403162061",
    "131219306779772",
    "106776364623742",
    "127846074966393",
    "123345437821399",
    "18885909645",
    "121080480916189",
    "131543461321709",
    "84069821282466",
    "114126519127454",
    "70371667919898",
    "137679730950847"-- Assets/Skins/Killers/Nosferatu/SpiderNosferatu/Config/Slash    -- Assets/Killers/Nosferatu/Config/SlashAir
}

-- State Variables
local autoBlockOn = false
local autoBlockAudioOn = false

local doubleblocktech = false
local blockdelay = 0
local looseFacing = true
local detectionRange = 18
local messageWhenAutoBlockOn = false
local messageWhenAutoBlock = ""
-- local fasterAudioAB = false (this is scrapped. im too lazy to remove it)
local Debris = game:GetService("Debris")
-- Anti-flick toggle state
local antiFlickOn = false
-- how many anti-flick parts to spawn (default 4)
local antiFlickParts = 4

-- optional: base distance in front of killer for the first part
local antiFlickBaseOffset = 2.7

-- optional: distance step between successive parts
local antiFlickOffsetStep = 0

local antiFlickDelay = 0 -- seconds to wait before parts spawn (default 0 = instant)
local PRED_SECONDS_FORWARD = 0.25   -- seconds ahead for linear prediction
local PRED_SECONDS_LATERAL  = 0.18  -- seconds ahead for lateral prediction
local PRED_MAX_FORWARD      = 6     -- clamp (studs)
local PRED_MAX_LATERAL      = 4     -- clamp (studs)
local ANG_TURN_MULTIPLIER   = 0.6   -- how much angular velocity contributes to lateral offset
local SMOOTHING_LERP        = 0.22  -- smoothing for sampled velocity/angular vel
local stagger  = 0.02

local killerState = {} -- [model] = { prevPos, prevLook, vel(Vector3), angVel(number) }

-- prediction multiplier: 1.0 is normal, up to 10.0
-- prediction multipliers
local predictionStrength = 1        -- forward/lateral (1x .. 10x)
local predictionTurnStrength = 1    -- turning strength (1x .. 10x)
-- multiplier for blue block parts size (1.0 = default)
local blockPartsSizeMultiplier = 1

local autoAdjustDBTFBPS = false
local _savedManualAntiFlickDelay = antiFlickDelay or 0 -- keep user's manual value when toggle is turned off

-- map of killer name (lowercase) -> antiFlickDelay value you requested
local killerDelayMap = {
    ["c00lkidd"] = 0,
    ["jason"]    = 0,
    ["slasher"]  = 0,
    ["1x1x1x1"]  = 0.1,
    ["johndoe"]  = 0.2,
    ["noli"]     = 0.10,
}

local predictiveBlockOn = false
local edgeKillerDelay = 3
local killerInRangeSince = nil
local predictiveCooldown = 0
-- auto punch
local predictionValue = 4

local hitboxDraggingTech = false
local _hitboxDraggingDebounce = false
local HITBOX_DRAG_DURATION = 1.4
local HITBOX_DETECT_RADIUS = 6
local Dspeed = 5.6 -- you can tweak these numbers
local Ddelay = 0

local killerNames = {"c00lkidd", "Jason", "JohnDoe", "1x1x1x1", "Noli", "Slasher", "Sixer"}
local autoPunchOn = false
local messageWhenAutoPunchOn = false
local messageWhenAutoPunch = ""
local flingPunchOn = false
local flingPower = 10000
local hiddenfling = false
local aimPunch = false

local espEnabled = false
local KillersFolder = workspace:WaitForChild("Players"):WaitForChild("Killers")

local lastBlockTime = 0
local lastPunchTime = 0


local blockAnimIds = {
"100926346851492",
"140671644163156",
"72182155407310",
"72722244508749",
"95802026624883",
"88557287105521",
"82605295530067",
"96959123077498",
"120748030255574",
"88287038085804",
"115706752305794",
"82036084568393",
"72722244508749"
}
local punchAnimIds = {
"87259391926321",   -- Sorcerer / #SoyGOAT / Base
"138040001965654",  -- GreenbeltGuest
"136007065400978",  -- LittleBrotherGuest
"108911997126897",  -- #ChudGuest
"129843313690921", 
"81905101227053",   -- Christmas / BurntChristmas
"113936304594883",  -- GeneGuest
"140703210927645",  -- DragonGuest
"86709774283672",   -- SorcererGuest
"119850211147676",  -- #SoyGOAT
"108807732150251",  -- GreenbeltGuest
"111270184603402",  -- BogardGuest
"86096387000557",   -- Milestone75 / Milestone100 / #ProbablyDemo
"99422325754526",   -- ToughGuySantaGuest
"136007065400978",  -- LittleBrotherGuest
"82137285150006",   -- #ChudGuest
"129843313690921",  -- #NerfedDemomanGuest
"78440860685556",   -- RabbidsPaintballGuest
"87259391926321"    -- Base
}

local chargeAnimIds = {
    "106014898538300"
}

local cachedAnimator = nil
local function refreshAnimator()
    local char = lp.Character
    if not char then
        cachedAnimator = nil
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local anim = hum:FindFirstChildOfClass("Animator")
        cachedAnimator = anim or nil
    else
        cachedAnimator = nil
    end
end

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5) -- allow Humanoid/Animator to be created
    refreshAnimator()
end)

-- ===== performance improvements for Sound Auto Block =====
-- cached UI / refs
local cachedPlayerGui = PlayerGui
local cachedPunchBtn, cachedBlockBtn, cachedCharges, cachedCooldown, cachedChargeBtn, cachedCloneBtn = nil, nil, nil, nil, nil, nil
local detectionRangeSq = detectionRange * detectionRange

local function refreshUIRefs()
    -- ensure we have the most up-to-date references for MainUI and ability buttons
    cachedPlayerGui = lp:FindFirstChild("PlayerGui") or PlayerGui
    local main = cachedPlayerGui and cachedPlayerGui:FindFirstChild("MainUI")
    if main then
        local ability = main:FindFirstChild("AbilityContainer")
        cachedPunchBtn = ability and ability:FindFirstChild("Punch")
        cachedBlockBtn = ability and ability:FindFirstChild("Block")
        cachedChargeBtn = ability and ability:FindFirstChild("Charge")
        cachedCloneBtn = ability and ability:FindFirstChild("Clone")
        cachedCharges = cachedPunchBtn and cachedPunchBtn:FindFirstChild("Charges")
        cachedCooldown = cachedBlockBtn and cachedBlockBtn:FindFirstChild("CooldownTime")
    else
        cachedPunchBtn, cachedBlockBtn, cachedCharges, cachedCooldown, cachedChargeBtn, cachedCloneBtn = nil, nil, nil, nil, nil, nil
    end
end

-- call once at startup
refreshUIRefs()

-- refresh on GUI or character changes (keeps caches fresh)
if cachedPlayerGui then
    cachedPlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "MainUI" then
            task.delay(0.02, refreshUIRefs)
        end
    end)
end

local facingCheckEnabled = true
local customFacingDot = -0.3

-- Optimized facing check
local function isFacing(localRoot, targetRoot)
    -- fast global reads
    local enabled = facingCheckEnabled
    if not enabled then return true end

    local loose = looseFacing

    -- difference vector (one allocation, unavoidable)
    local dx = localRoot.Position.X - targetRoot.Position.X
    local dy = localRoot.Position.Y - targetRoot.Position.Y
    local dz = localRoot.Position.Z - targetRoot.Position.Z

    -- magnitude (sqrt) once; handle zero-distance safely
    local mag = math.sqrt(dx*dx + dy*dy + dz*dz)
    if mag == 0 then
        -- if positions coincide treat as "facing" (matches permissive behavior)
        return true
    end
    local invMag = 1 / mag

    -- unit direction components (no new Vector3 allocation)
    local ux, uy, uz = dx * invMag, dy * invMag, dz * invMag

    -- cache look vector components
    local lv = targetRoot.CFrame.LookVector
    local lx, ly, lz = lv.X, lv.Y, lv.Z

    -- dot product (fast scalar math)
    local dot = lx * ux + ly * uy + lz * uz

    -- same logic as original, but explicit for clarity/branch prediction
    return dot > (customFacingDot or -0.3)
end

-- ===== Facing Check Visual (fixed) =====
local facingVisualOn = false
local facingVisuals = {} -- [killer] = visual

local function updateFacingVisual(killer, visual)
    if not (killer and visual and visual.Parent) then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- calculate angle from DOT threshold (safe-clamp)
    local dot = math.clamp(customFacingDot or -0.3, -1, 1)
    local angle = math.acos(dot)              -- radians, 0..pi
    local frac = angle / math.pi              -- 0..1 (0 = very narrow cone, 1 = very wide)

    -- scale radius between a small fraction and full detectionRange
    local minFrac = 0.20                      -- tune: smallest disc is 20% of detectionRange
    local radius = math.max(1, detectionRange * (minFrac + (1 - minFrac) * frac))
    visual.Radius = radius
    visual.Height = 0.12

    -- place the disc in front of the killer; move slightly less forward for narrow cones
    local forwardDist = detectionRange * (0.35 + 0.15 * frac) -- tune if you like
    local yOffset = -(hrp.Size.Y / 2 + 0.05)
    visual.CFrame = CFrame.new(0, yOffset, -forwardDist) * CFrame.Angles(math.rad(90), 0, 0)

    -- determine local player's HRP and whether they are inside range & facing
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local inRange = false
    local facingOkay = false

    if myRoot and hrp then
        local dist = (hrp.Position - myRoot.Position).Magnitude
        inRange = dist <= detectionRange
        facingOkay = (not facingCheckEnabled) or (type(isFacing) == "function" and isFacing(myRoot, hrp))
    end

    -- color / transparency
    if inRange and facingOkay then
        visual.Color3 = Color3.fromRGB(0, 255, 0)
        visual.Transparency = 0.40
    else
        visual.Color3 = Color3.fromRGB(255, 255, 0) -- show yellow when not both conditions
        visual.Transparency = 0.85
    end
end

local function addFacingVisual(killer)
    if not killer or not killer:IsA("Model") then return end
    if facingVisuals[killer] then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local visual = Instance.new("CylinderHandleAdornment")
    visual.Name = "FacingCheckVisual"
    visual.Adornee = hrp
    visual.AlwaysOnTop = true
    visual.ZIndex = 2
    visual.Transparency = 0.55
    visual.Color3 = Color3.fromRGB(0, 255, 0) -- green

    visual.Parent = hrp
    facingVisuals[killer] = visual

    -- initialize placement immediately
    updateFacingVisual(killer, visual)
end

local function removeFacingVisual(killer)
    local v = facingVisuals[killer]
    if v then
        v:Destroy()
        facingVisuals[killer] = nil
    end
end

local function refreshFacingVisuals()
    for _, k in ipairs(KillersFolder:GetChildren()) do
        if facingVisualOn then
            -- make sure HRP exists before creating
            local hrp = k:FindFirstChild("HumanoidRootPart") or k:WaitForChild("HumanoidRootPart", 5)
            if hrp then addFacingVisual(k) end
        else
            removeFacingVisual(k)
        end
    end
end

-- keep visuals in sync every frame (ensures size/mode changes apply immediately)
RunService.RenderStepped:Connect(function()
    for killer, visual in pairs(facingVisuals) do
        -- if the killer was removed/died, clean up
        if not killer.Parent or not killer:FindFirstChild("HumanoidRootPart") then
            removeFacingVisual(killer)
        else
            updateFacingVisual(killer, visual)
        end
    end
end)

-- Keep visuals for newly added/removed killers
KillersFolder.ChildAdded:Connect(function(killer)
    if facingVisualOn then
        task.spawn(function()
            local hrp = killer:WaitForChild("HumanoidRootPart", 5)
            if hrp then addFacingVisual(killer) end
        end)
    end
end)
KillersFolder.ChildRemoved:Connect(function(killer) removeFacingVisual(killer) end)

-- ===== Facing Check Visual (paste after detectionCircles / addKillerCircle) =====
local detectionCircles = {} -- store all killer circles
local killerCirclesVisible = false

-- Function to add circle to a killer
-- replace your addKillerCircle with this
local function addKillerCircle(killer)
    if not killer:FindFirstChild("HumanoidRootPart") then return end
    if detectionCircles[killer] then return end

    local hrp = killer.HumanoidRootPart
    local circle = Instance.new("CylinderHandleAdornment")
    circle.Name = "KillerDetectionCircle"
    circle.Adornee = hrp
    circle.Color3 = Color3.fromRGB(255, 0, 0)
    circle.AlwaysOnTop = true
    circle.ZIndex = 1
    circle.Transparency = 0.6
    circle.Radius = detectionRange            -- <- use detectionRange exactly
    circle.Height = 0.12                      -- thin disc
    -- place the disc at the feet of the HumanoidRootPart (CFrame is relative to Adornee)
    local yOffset = -(hrp.Size.Y / 2 + 0.05)  -- a little below HRP origin
    circle.CFrame = CFrame.new(0, yOffset, 0) * CFrame.Angles(math.rad(90), 0, 0)
    circle.Parent = hrp

    detectionCircles[killer] = circle
end

-- Update radius when detectionRange changes (and on render)


-- Function to remove circle from a killer
local function removeKillerCircle(killer)
    if detectionCircles[killer] then
        detectionCircles[killer]:Destroy()
        detectionCircles[killer] = nil
    end
end

-- Refresh all circles
local function refreshKillerCircles()
    for _, killer in ipairs(KillersFolder:GetChildren()) do
        if killerCirclesVisible then
            addKillerCircle(killer)
        else
            removeKillerCircle(killer)
        end
    end
end

-- Keep radius updated
RunService.RenderStepped:Connect(function()
    for killer, circle in pairs(detectionCircles) do
        if circle and circle.Parent then
            circle.Radius = detectionRange
        end
    end
end)

-- Hook into killers being added/removed
KillersFolder.ChildAdded:Connect(function(killer)
    if killerCirclesVisible then
        task.spawn(function()
            -- Wait until HRP exists (max 5s timeout)
            local hrp = killer:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                addKillerCircle(killer)
            end
        end)
    end
end)

KillersFolder.ChildRemoved:Connect(function(killer)
    removeKillerCircle(killer)
end)


local autoblocktype = "Block"

local StarterGui = game:GetService("StarterGui")

-- simple notification
local function SendNotif(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title or "Hello",
        Text = text or "hi",
        Duration = duration or 4 -- seconds
    })
end

lp.CharacterAdded:Connect(function()
    task.delay(0.5, refreshUIRefs)
end)

local function getNearestKillerModel()
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest, closestDist = nil, math.huge
    for _, k in ipairs(KillersFolder:GetChildren()) do
        if k and k:IsA("Model") then
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < closestDist then
                    closest, closestDist = k, d
                end
            end
        end
    end
    return closest
end

local function applyDelayForKillerModel(killerModel)
    if not killerModel then
        -- no killer found -> restore manual value
        if antiFlickDelay ~= _savedManualAntiFlickDelay then
            antiFlickDelay = _savedManualAntiFlickDelay
            print(("Auto-DBTFBPS: no killer -> restore antiFlickDelay = %s"):format(tostring(antiFlickDelay)))
        end
    end

    local key = (tostring(killerModel.Name) or ""):lower()
    local mapped = killerDelayMap[key]

    if mapped ~= nil then
        if antiFlickDelay ~= mapped then
            antiFlickDelay = mapped
            print(("Auto-DBTFBPS: matched killer '%s' -> antiFlickDelay = %s"):format(killerModel.Name, tostring(mapped)))
        end
    else
        -- killer not in mapping: restore manual value (avoid surprising changes)
        if antiFlickDelay ~= _savedManualAntiFlickDelay then
            antiFlickDelay = _savedManualAntiFlickDelay
            print(("Auto-DBTFBPS: killer '%s' not mapped -> restore antiFlickDelay = %s"):format(killerModel.Name, tostring(_savedManualAntiFlickDelay)))
        end
    end
end

-- small throttled heartbeat loop (runs only when toggle enabled)
local adjustTicker = 0
RunService.Heartbeat:Connect(function(dt)
    if not autoAdjustDBTFBPS then return end
    adjustTicker = adjustTicker + dt
    if adjustTicker < 0.15 then return end -- check ~every 0.15s
    adjustTicker = 0

    local nearest = getNearestKillerModel()
    applyDelayForKillerModel(nearest)
end)

-- immediate update helper when killers spawn/leave or user toggles
local function doImmediateUpdate()
    if not autoAdjustDBTFBPS then return end
    local nearest = getNearestKillerModel()
    applyDelayForKillerModel(nearest)
end

-- respond quickly when killers are added/removed (so toggle reacts immediately)
KillersFolder.ChildAdded:Connect(function() task.delay(0.05, doImmediateUpdate) end)
KillersFolder.ChildRemoved:Connect(function() task.delay(0.05, doImmediateUpdate) end)

local detectorChargeIds = (type(chargeAnimIds) == "table" and chargeAnimIds) or {}

-- Optional: detect a custom charge anim id (if you already use these vars elsewhere)
-- set customChargeEnabled = true and customChargeAnimId = "123456" elsewhere in your script to detect custom anim too
-- local customChargeEnabled = false
-- local customChargeAnimId = ""

-- Override speed (same as your noli script)
local ORIGINAL_DASH_SPEED = 60

-- Toggle / runtime state
local controlChargeEnabled = false
local controlChargeActive = false
local overrideConnection = nil

-- Save/restore for humanoid original values
local savedHumanoidState = {}

local function getHumanoid()
    if not lp or not lp.Character then return nil end
    return lp.Character:FindFirstChildOfClass("Humanoid")
end

local function saveHumState(hum)
    if not hum then return end
    if savedHumanoidState[hum] then return end
    local s = {}
    pcall(function()
        s.WalkSpeed = hum.WalkSpeed
        -- support either JumpPower or JumpHeight
        local ok, _ = pcall(function() s.JumpPower = hum.JumpPower end)
        if not ok then
            pcall(function() s.JumpPower = hum.JumpHeight end)
        end
        -- AutoRotate might not exist on all Humanoids; try to capture if possible
        local ok2, ar = pcall(function() return hum.AutoRotate end)
        if ok2 then s.AutoRotate = ar end
        s.PlatformStand = hum.PlatformStand
    end)
    savedHumanoidState[hum] = s
end

local function restoreHumState(hum)
    if not hum then return end
    local s = savedHumanoidState[hum]
    if not s then return end
    pcall(function()
        if s.WalkSpeed ~= nil then hum.WalkSpeed = s.WalkSpeed end
        if s.JumpPower ~= nil then
            local ok, _ = pcall(function() hum.JumpPower = s.JumpPower end)
            if not ok then pcall(function() hum.JumpHeight = s.JumpPower end) end
        end
        if s.AutoRotate ~= nil then pcall(function() hum.AutoRotate = s.AutoRotate end) end
        if s.PlatformStand ~= nil then hum.PlatformStand = s.PlatformStand end
    end)
    savedHumanoidState[hum] = nil
end

-- Start the override (forces dash movement similar to noli void rush)
local function startOverride()
    if controlChargeActive then return end
    local hum = getHumanoid()
    if not hum then return end

    controlChargeActive = true
    saveHumState(hum)

    -- Make sure humanoid is set to dash state
    pcall(function()
        hum.WalkSpeed = ORIGINAL_DASH_SPEED
        hum.AutoRotate = false
    end)

    -- RenderStepped connection to force forward movement every frame (like your noli function)
    overrideConnection = RunService.RenderStepped:Connect(function()
        local humanoid = getHumanoid()
        local rootPart = humanoid and humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end

        -- ensure speed + autorotate each frame (helps if some other code fights it)
        pcall(function()
            humanoid.WalkSpeed = ORIGINAL_DASH_SPEED
            humanoid.AutoRotate = false
        end)

        local direction = rootPart.CFrame.LookVector
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        if horizontal.Magnitude > 0 then
            humanoid:Move(horizontal.Unit)
        else
            humanoid:Move(Vector3.new(0,0,0))
        end
    end)
end

-- Stop the override and restore humanoid state
local function stopOverride()
    if not controlChargeActive then return end
    controlChargeActive = false

    -- disconnect override loop
    if overrideConnection then
        pcall(function() overrideConnection:Disconnect() end)
        overrideConnection = nil
    end

    -- restore humanoid fields
    local hum = getHumanoid()
    if hum then
        pcall(function()
            -- restore saved values if present
            restoreHumState(hum)
            -- ensure we stop movement
            humanoid:Move(Vector3.new(0,0,0))
        end)
    end
end

-- Internal detection: look for playing anim tracks that match charge IDs or custom ID
local function detectChargeAnimation()
    local hum = getHumanoid()
    if not hum then return false end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local ok, animId = pcall(function()
            return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
        end)
        if ok and animId and animId ~= "" then
            if detectorChargeIds and table.find(detectorChargeIds, animId) then
                return true
            end
        end
    end
    return false
end

-- Public toggle control
local function ControlCharge_SetEnabled(val)
    controlChargeEnabled = val and true or false
    if not controlChargeEnabled and controlChargeActive then
        stopOverride()
    end
end

-- Main loop: check detection each RenderStepped (uses same cadence as noli script)
RunService.RenderStepped:Connect(function()
    if not controlChargeEnabled then
        if controlChargeActive then stopOverride() end
        return
    end

    -- If humanoid dies or character resets, ensure override cleared
    local hum = getHumanoid()
    if not hum then
        if controlChargeActive then stopOverride() end
        return
    end

    local isCharging = detectChargeAnimation()

    if isCharging then
        if not controlChargeActive then
            startOverride()
        end
    else
        if controlChargeActive then
            stopOverride()
        end
    end
end)

-- Keep humanoid state fresh on CharacterAdded
lp.CharacterAdded:Connect(function(char)
    -- small wait to let Humanoid exist
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 2)
        if hum then
            -- optionally prime saved state (not necessary)
        end
    end)
end)

-- Expose toggle function globally for other script parts or for hotkeys
_G.ControlCharge_SetEnabled = ControlCharge_SetEnabled

-- ==================== ORIGINAL ESP FUNCTIONS ====================
local function addESP(obj)
    if not obj:IsA("Model") then return end
    if not obj:FindFirstChild("HumanoidRootPart") then return end

    local plr = Players:GetPlayerFromCharacter(obj)
    if not plr then return end -- ✅ only add ESP if it's a player character

    -- Prevent duplicates
    if obj:FindFirstChild("ESP_Highlight") then return end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = obj
    highlight.Parent = obj

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Adornee = obj:FindFirstChild("HumanoidRootPart")
    billboard.Parent = obj

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = obj.Name
    textLabel.Parent = billboard
end

-- Function to clear ESP
local function clearESP(obj)
    if obj:FindFirstChild("ESP_Highlight") then
        obj.ESP_Highlight:Destroy()
    end
    if obj:FindFirstChild("ESP_Billboard") then
        obj.ESP_Billboard:Destroy()
    end
end

-- Function to refresh all ESP
local function refreshESP()
    if not espEnabled then
        for _, killer in pairs(KillersFolder:GetChildren()) do
            clearESP(killer)
        end
        return
    end

    for _, killer in pairs(KillersFolder:GetChildren()) do
        addESP(killer)
    end
end


-- Modify ChildAdded connection:
KillersFolder.ChildAdded:Connect(function(child)
    if espEnabled then
        task.wait(0.1) -- wait for HRP
        addESP(child)
    end
end)


KillersFolder.ChildRemoved:Connect(function(child)
    clearESP(child)
end)

-- Distance updater
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, killer in pairs(KillersFolder:GetChildren()) do
        local billboard = killer:FindFirstChild("ESP_Billboard")
        if billboard and billboard:FindFirstChild("ESP_Text") and killer:FindFirstChild("HumanoidRootPart") then
            local dist = (killer.HumanoidRootPart.Position - hrp.Position).Magnitude
            billboard.ESP_Text.Text = string.format("%s\n[%d]", killer.Name, dist)
        end
    end
end)

local _LP = Players.LocalPlayer
local _isFacing = isFacing
local LOCAL_BLOCK_COOLDOWN = 0.7   -- optimistic local cooldown (tune as needed)
local lastLocalBlockTime = 0

-- =========== FIXED REMOTE FUNCTIONS ===========
local function fireRemoteBlock()
    testRemote:FireServer(
        "UseActorAbility",
        {
            [1] = buffer.fromstring("\3\5\0\0\0Block")  -- FIXED FORMAT
        }
    )
end

local function fireRemotePunch()
    testRemote:FireServer(
        "UseActorAbility",
        {
            [1] = buffer.fromstring("\3\5\0\0\0Punch")  -- FIXED FORMAT
        }
    )
end

local function fireRemoteCharge()
    testRemote:FireServer(
        "UseActorAbility",
        {
            [1] = buffer.fromstring("\3\5\0\0\0Charge")  -- FIXED FORMAT
        }
    )
end

local function fireRemoteClone()
    testRemote:FireServer(
        "UseActorAbility",
        {
            [1] = buffer.fromstring("\3\5\0\0\0Clone")  -- FIXED FORMAT
        }
    )
end

-- Fling coroutine
coroutine.wrap(function()
    local hrp, c, vel, movel = nil, nil, nil, 0.1
    while true do
        RunService.Heartbeat:Wait()
        if hiddenfling then
            while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
                RunService.Heartbeat:Wait()
                c = lp.Character
                hrp = c and c:FindFirstChild("HumanoidRootPart")
            end
            if hiddenfling then
                vel = hrp.Velocity
                hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end
    end
end)()

local function sendChatMessage(text)
    if not text or text:match("^%s*$") then return end
    local TextChatService = game:GetService("TextChatService")
    local channel = TextChatService.TextChannels.RBXGeneral

    channel:SendAsync(text)
end

-- ===== AGGRESSIVE Character and Camera Lock Functions with Duration =====
local function lockCharacterToTarget(targetHRP, myRoot, duration)
    if not targetHRP or not myRoot then return end
    
    -- Disable auto rotate for smooth tracking
    local humanoid = myRoot.Parent and myRoot.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = false
    end
    
    local lockStartTime = tick()
    local lastValidPos = targetHRP.Position
    
    while characterLockOn and (tick() - lockStartTime < duration) do
        -- Even if target disappears, keep facing the last known position for a bit
        if targetHRP and targetHRP.Parent and myRoot and myRoot.Parent then
            -- Get target position with aggressive prediction
            local targetPos = targetHRP.Position
            lastValidPos = targetPos
            
            -- Aggressive prediction for moving targets
            local targetVelocity = targetHRP.Velocity or Vector3.new()
            local prediction = targetVelocity * 0.3 -- Increased prediction to 0.3 seconds ahead
            
            -- Apply prediction
            targetPos = targetPos + prediction
            
            -- Create smooth rotation with aggressive smoothing
            local lookCFrame = CFrame.lookAt(myRoot.Position, targetPos)
            
            -- Apply rotation with aggressive smoothing
            local currentCF = myRoot.CFrame
            local newCF = currentCF:Lerp(lookCFrame, aggressiveSmoothing) -- Increased smoothing
            myRoot.CFrame = CFrame.new(newCF.Position, targetPos)
            
            -- Update last active time
            lockLastActiveTime = tick()
        elseif myRoot and myRoot.Parent then
            -- If target is lost but we're still within timeout, continue facing last known direction
            local lookCFrame = CFrame.lookAt(myRoot.Position, lastValidPos)
            local currentCF = myRoot.CFrame
            local newCF = currentCF:Lerp(lookCFrame, aggressiveSmoothing * 0.5) -- Slower smoothing when target lost
            myRoot.CFrame = CFrame.new(newCF.Position, lastValidPos)
        end
        
        task.wait(lockCooldown) -- Reduced wait for more responsive tracking
    end
    
    -- Restore auto rotate when done
    if humanoid and humanoid.Parent then
        humanoid.AutoRotate = true
    end
end

local function lockCameraToTarget(targetHRP, duration)
    if not targetHRP then return end
    local camera = workspace.CurrentCamera
    
    local lockStartTime = tick()
    local lastValidPos = targetHRP.Position + Vector3.new(0, 1.5, 0)
    
    while cameraLockOn and (tick() - lockStartTime < duration) do
        if camera then
            -- Even if target disappears, keep camera on last known position
            local targetPos
            if targetHRP and targetHRP.Parent then
                targetPos = targetHRP.Position + Vector3.new(0, 1.5, 0)
                lastValidPos = targetPos
                
                -- Aggressive prediction for camera
                local targetVelocity = targetHRP.Velocity or Vector3.new()
                local prediction = targetVelocity * 0.35 -- Increased prediction
                
                targetPos = targetPos + prediction
                lockLastActiveTime = tick()
            else
                -- Use last known position if target is lost
                targetPos = lastValidPos
            end
            
            -- Get current camera position
            local camPos = camera.CFrame.Position
            
            -- Create aggressive camera rotation
            local lookCFrame = CFrame.lookAt(camPos, targetPos)
            
            -- Apply camera rotation with aggressive smoothing
            local currentCF = camera.CFrame
            local newCF = currentCF:Lerp(lookCFrame, cameraAggressiveSmoothing)
            camera.CFrame = newCF
        end
        task.wait(lockCooldown)
    end
end

local function startAggressiveLockOnPunch()
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    -- Find all nearby killers, not just the first one
    local foundTargets = {}
    for _, name in ipairs(killerNames) do
        local killer = workspace:FindFirstChild("Players")
            and workspace.Players:FindFirstChild("Killers")
            and workspace.Players.Killers:FindFirstChild(name)
        if killer and killer:FindFirstChild("HumanoidRootPart") then
            local targetHRP = killer.HumanoidRootPart
            if targetHRP and myRoot and (targetHRP.Position - myRoot.Position).Magnitude <= 30 then
                table.insert(foundTargets, targetHRP)
            end
        end
    end
    
    if #foundTargets > 0 then
        -- Prioritize closest target
        table.sort(foundTargets, function(a, b)
            return (a.Position - myRoot.Position).Magnitude < (b.Position - myRoot.Position).Magnitude
        end)
        
        local targetHRP = foundTargets[1]
        
        -- Store locked target
        lockedTarget = targetHRP
        
        -- Start character lock if enabled
        if characterLockOn then
            task.spawn(function()
                lockCharacterToTarget(targetHRP, myRoot, lockDuration)
            end)
        end
        
        -- Start camera lock if enabled
        if cameraLockOn then
            if cameraLockThread then
                task.cancel(cameraLockThread)
            end
            cameraLockThread = task.spawn(function()
                lockCameraToTarget(targetHRP, lockDuration)
            end)
        end
        
        -- Extend lock timeout
        lockLastActiveTime = tick()
    end
end

-- Function to stop all locks
local function stopAllLocks()
    lockedTarget = nil
    if cameraLockThread then
        task.cancel(cameraLockThread)
        cameraLockThread = nil
    end
    
    -- Restore auto rotate
    local myChar = lp.Character
    if myChar then
        local humanoid = myChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = true
        end
    end
end

-- Also update the auto punch section to use aggressive locking:
-- In the auto punch section of RenderStepped, change:
if characterLockOn or cameraLockOn then
    startAggressiveLockOnPunch() -- Changed from startLockOnPunch()
end

-- And in the punch animation detection:
if characterLockOn or cameraLockOn then
    startAggressiveLockOnPunch() -- Changed from startLockOnPunch()
end

local soundHooks = {}     -- [Sound] = {playedConn, propConn, destroyConn}
local soundBlockedUntil = {} -- [Sound] = timestamp when we can block again (throttle)

local function getNearestKillerRoot(maxDist)
    local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if not killersFolder then return nil end

    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest, closestDist = nil, maxDist or math.huge
    for _, killer in ipairs(killersFolder:GetChildren()) do
        local hrp = killer:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - myRoot.Position).Magnitude
            if dist < closestDist then
                closest, closestDist = hrp, dist
            end
        end
    end
    return closest
end

-- place once in outer scope if this runs in a hot loop
local string_match = string.match
local tostring_local = tostring

local function extractNumericSoundId(sound)
    if not sound then return nil end

    local sid = sound.SoundId
    if not sid then return nil end
    sid = (type(sid) == "string") and sid or tostring_local(sid)

    -- Prefer explicit "rbxassetid://" pattern (most common), then generic "://digits", then plain digits
    local num =
        string_match(sid, "rbxassetid://(%d+)") or
        string_match(sid, "://(%d+)") or
        string_match(sid, "^(%d+)$")

    if num and #num > 0 then
        return num
    end

    -- Fallbacks (kept for completeness)
    local hash = string_match(sid, "[&%?]hash=([^&]+)")
    if hash then
        return "&hash=" .. hash
    end

    local path = string_match(sid, "rbxasset://sounds/.+")
    if path then
        return path
    end

    return nil
end

-- cache KillersFolder outside the function when possible:
local KF = KillersFolder

local function getSoundWorldPosition(sound)
    if not sound then return nil end

    local parent = sound.Parent
    if parent then
        if parent:IsA("BasePart") then
            return parent.Position, parent
        end

        if parent:IsA("Attachment") then
            local gp = parent.Parent
            if gp and gp:IsA("BasePart") then
                return gp.Position, gp
            end
        end
    end

    -- Only perform deep descendant search if the sound is inside KillersFolder
    if KF and sound:IsDescendantOf(KF) then
        -- search descendants of the nearest meaningful root (prefer parent if present)
        local root = parent or sound
        local found = root:FindFirstChildWhichIsA("BasePart", true)
        if found then
            return found.Position, found
        end
    end

    return nil, nil
end

local function getCharacterFromDescendant(inst)
    if not inst then return nil end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then
        return model
    end
    return nil
end

local function isPointInsidePart(part, point)
    if not (part and point) then return false end
    -- convert world point to part-local coordinates and test against half-extents
    local rel = part.CFrame:PointToObjectSpace(point)
    local half = part.Size * 0.5
    return math.abs(rel.X) <= half.X + 0.001 and
           math.abs(rel.Y) <= half.Y + 0.001 and
           math.abs(rel.Z) <= half.Z + 0.001
end

-- ===== predictive helpers =====

-- keep killerState updated each frame (lightweight)
RunService.RenderStepped:Connect(function(dt)
    if dt <= 0 then return end
    local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if not killersFolder then return end

    for _, killer in ipairs(killersFolder:GetChildren()) do
        if killer and killer.Parent then
            local hrp = killer:FindFirstChild("HumanoidRootPart")
            if hrp then
                local st = killerState[killer] or { prevPos = hrp.Position, prevLook = hrp.CFrame.LookVector, vel = Vector3.new(), angVel = 0 }
                -- linear velocity sample & smoothing
                local newVel = (hrp.Position - st.prevPos) / math.max(dt, 1e-6)
                st.vel = st.vel and st.vel:Lerp(newVel, SMOOTHING_LERP) or newVel

                -- angular velocity (radians/sec, signed by left/right)
                local prevLook = st.prevLook or hrp.CFrame.LookVector
                local look = hrp.CFrame.LookVector
                local dot = math.clamp(prevLook:Dot(look), -1, 1)
                local angle = math.acos(dot) -- 0..pi
                local crossY = prevLook:Cross(look).Y
                local angSign = (crossY >= 0) and 1 or -1
                local newAngVel = (angle / math.max(dt, 1e-6)) * angSign
                st.angVel = (st.angVel * (1 - SMOOTHING_LERP)) + (newAngVel * SMOOTHING_LERP)

                st.prevPos = hrp.Position
                st.prevLook = look
                killerState[killer] = st
            end
        end
    end
end)

-- Use the FIXED remote functions
local function fireGuiBlock()
    fireRemoteBlock()
end

local function fireGuiPunch()
    fireRemotePunch()
end

local function fireGuiCharge()
    fireRemoteCharge()
end

local function fireGuiClone()
    fireRemoteClone()
end

local chargeAimActive = false
local chargeAimThread = nil

local function stopChargeAim()
    chargeAimActive = false
    -- thread will exit when it notices the flag; we don't force-kill it
end

-- Start aiming at nearest killer until the charge animation stops (or fallback timeout)
-- fallbackSec is optional (seconds) to stop attempting if no animation is detected.
local function startChargeAimUntilChargeEnds(fallbackSec)
    -- ensure only one thread at a time
    stopChargeAim()
    chargeAimActive = true

    chargeAimThread = task.spawn(function()
        local startWatch = tick()
        local fallback = tonumber(fallbackSec) or 1.2

        -- try to get humanoid/root/animator
        local function getCharObjects()
            local char = lp.Character
            if not char then return nil, nil, nil end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local animator = char:FindFirstChildOfClass("Animator")
            return hum, hrp, animator
        end

        local humanoid, myRoot, animator = getCharObjects()
        if humanoid then
            pcall(function() humanoid.AutoRotate = false end)
        end

        local seenChargeAnim = false
        local watchStart = tick()

        while chargeAimActive do
            -- refresh references each loop in case character reloaded
            humanoid, myRoot, animator = getCharObjects()
            if not myRoot then break end

            -- find nearest killer model and its hrp
            local killerModel = getNearestKillerModel()
            local targetHRP = (killerModel and killerModel:FindFirstChild("HumanoidRootPart")) or nil

            if targetHRP then
                -- predictionValue exists in your script (used by aimPunch). use it for nicer aiming.
                local pred = (type(predictionValue) == "number") and predictionValue or 0
                local predictedPos = targetHRP.Position + (targetHRP.CFrame.LookVector * pred)

                -- set lookAt while keeping our position
                pcall(function()
                    myRoot.CFrame = CFrame.lookAt(myRoot.Position, predictedPos)
                end)
            end

            -- check if charge animation is playing (if we can access animator)
            local stillPlaying = false
            if animator then
                local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
                if ok and tracks then
                    for _, track in ipairs(tracks) do
                        local animId = nil
                        pcall(function() animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                        if animId and table.find(chargeAnimIds, animId) then
                            stillPlaying = true
                            seenChargeAnim = true
                            break
                        end
                    end
                end
            end

            -- stop conditions:
            -- 1) we saw a charge anim and now it's gone -> stop
            if seenChargeAnim and not stillPlaying then
                break
            end

            -- 2) we never saw a charge anim and we've exceeded fallback -> stop
            if not seenChargeAnim and (tick() - watchStart) > fallback then
                break
            end

            task.wait()
        end

        -- restore AutoRotate
        if humanoid then
            pcall(function() humanoid.AutoRotate = true end)
        end

        chargeAimActive = false
    end)
end

-- optimized attemptBlockForSound (accepts optional precomputed id)
-- TUNABLES (put near top of file so you can tweak for high ping)
local AUDIO_PREDICT_DT = 0.08        -- seconds to predict forward (increase for high ping)
local AUDIO_LOCAL_COOLDOWN = 0.35    -- local throttle between blocks (seconds)
local AUDIO_SOUND_THROTTLE = 1.0     -- how long to throttle the same sound (seconds)

-- helper: fast squared distance (no sqrt)
local function distSq(a, b)
    local dx = a.X - b.X
    local dy = a.Y - b.Y
    local dz = a.Z - b.Z
    return dx*dx + dy*dy + dz*dz
end

local _getSoundWorldPosition = getSoundWorldPosition

-- shared heavy work helper (local to file/scope)
local function _attemptForSound(sound, idParam, mode)
    -- quick guards (keep same order)
    if not autoBlockAudioOn then return end
    if not sound or not sound:IsA("Sound") then return end
    if not sound.IsPlaying then return end

    -- hot locals
    local now = tick()
    local hooks = soundHooks
    local hook = hooks and hooks[sound]

    -- id resolution (prefer cached)
    local id = idParam or (hook and hook.id) or extractNumericSoundId(sound)
    if not id or not autoBlockTriggerSounds[id] then return end

    -- per-sound throttle
    if soundBlockedUntil[sound] and now < soundBlockedUntil[sound] then return end

    -- global local cooldown
    if now - lastLocalBlockTime < AUDIO_LOCAL_COOLDOWN then return end

    -- ensure UI refs depending on mode (preserve original checks)
    if mode == "Block" or mode == "Charge" then
        if not cachedBlockBtn or not cachedCooldown or not cachedCharges then
            refreshUIRefs()
        end
    elseif mode == "Clone" then
        if not cachedCloneBtn then
            refreshUIRefs()
        end
    end

    -- local player root
    local lpLocal = _LP or Players.LocalPlayer
    local myChar = lpLocal and lpLocal.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- cached hook mapping (may be nil)
    local char = hook and hook.char
    local hrp = hook and hook.hrp

    if not hrp then
        -- expensive path: only when cache missing
        local soundPos, soundPart = getSoundWorldPosition(sound)
        if not soundPart then return end
        char = getCharacterFromDescendant(soundPart)
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        -- cache mapping for next time
        if hook then
            hook.char = char
            hook.hrp = hrp
        else
            soundHooks[sound] = { id = id, char = char, hrp = hrp }
            hook = soundHooks[sound]
        end
    end

    if not hrp then return end

    -- predicted position using velocity (unrolled for speed)
    local v = hrp.Velocity or Vector3.new()
    local predictedX = hrp.Position.X + v.X * AUDIO_PREDICT_DT
    local predictedY = hrp.Position.Y + v.Y * AUDIO_PREDICT_DT
    local predictedZ = hrp.Position.Z + v.Z * AUDIO_PREDICT_DT

    local dx = predictedX - myRoot.Position.X
    local dy = predictedY - myRoot.Position.Y
    local dz = predictedZ - myRoot.Position.Z
    local distSqPred = dx*dx + dy*dy + dz*dz

    -- detection range check (preserve grace fallback logic)
    if detectionRangeSq and distSqPred > detectionRangeSq then
        local dx2 = hrp.Position.X - myRoot.Position.X
        local dy2 = hrp.Position.Y - myRoot.Position.Y
        local dz2 = hrp.Position.Z - myRoot.Position.Z
        local distSqNow = dx2*dx2 + dy2*dy2 + dz2*dz2
        local grace = (detectionRange + 3) * (detectionRange + 3)
        if distSqNow > grace then
            return
        end
    end

    -- verify sound world position (kept as in original)
    local soundPos, soundPart = _getSoundWorldPosition(sound)
    if not soundPart then return end

    -- climb to Model & validate humanoid
    local model = soundPart and soundPart:FindFirstAncestorOfClass("Model") or nil
    if not model then return end

    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end

    local plr = Players:GetPlayerFromCharacter(model)
    if not plr or plr == lp then return end

    -- facing check (cached _isFacing)
    if facingCheckEnabled and not _isFacing(myRoot, hrp) then
        return
    end

    task.wait(blockdelay)

    -- mode-specific extra checks & actions (preserve prints and exact calls)
    if mode == "Block" then
        if cachedCooldown and cachedCooldown.Text == "" then
            print("yay")
        else
            return
        end
        fireRemoteBlock()  -- Use FIXED function
        if doubleblocktech == true then
            fireRemotePunch()  -- Use FIXED function
        end
    elseif mode == "Charge" then
        if cachedChargeBtn and cachedChargeBtn:FindFirstChild("CooldownTime") and cachedChargeBtn.CooldownTime.Text == "" then
            print("yay")
        else
            return
        end
        fireRemoteCharge()  -- Use FIXED function
        startChargeAimUntilChargeEnds(0.4)
    elseif mode == "Clone" then
        if cachedCloneBtn and cachedCloneBtn:FindFirstChild("CooldownTime") and cachedCloneBtn.CooldownTime.Text == "" then
            print("yay")
        else
            return
        end
        fireRemoteClone()  -- Use FIXED function
        startChargeAimUntilChargeEnds(0.4)
    end

    -- optimistic local timestamp & throttle this sound (identical)
    lastLocalBlockTime = now
    soundBlockedUntil[sound] = now + AUDIO_SOUND_THROTTLE
end

-- public wrappers to preserve original names/behavior
local function attemptBlockForSound(sound, idParam)
    return _attemptForSound(sound, idParam, "Block")
end

local function attemptChargeForSound(sound, idParam)
    return _attemptForSound(sound, idParam, "Charge")
end

local function attemptCloneForSound(sound, idParam)
    return _attemptForSound(sound, idParam, "Clone")
end

-- Improved hookSound: cache id and keep placeholder for hrp/char (so attemptBlock hot-path reads cached data)

local function attemptBDParts(sound)
    if not autoBlockAudioOn then return end
    if not sound or not sound:IsA("Sound") then return end
    if not sound.IsPlaying then return end

    local id = extractNumericSoundId(sound)
    if not id or not autoBlockTriggerSounds[id] then return end

    local t = tick()
    if soundBlockedUntil[sound] and t < soundBlockedUntil[sound] then return end

    local lp = Players.LocalPlayer
    local myChar = lp and lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local soundPos, soundPart = getSoundWorldPosition(sound)
    if not soundPos or not soundPart then return end

    local char = getCharacterFromDescendant(soundPart)
    local plr = char and Players:GetPlayerFromCharacter(char)
    if not plr or plr == lp then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local Debris = game:GetService("Debris")

    if antiFlickOn then
        local basePartSize = Vector3.new(5.5, 7.5, 8.5)  -- original / default size
        local partSize = basePartSize * (blockPartsSizeMultiplier or 1)
        local count = math.max(1, antiFlickParts or 4)
        local base  = antiFlickBaseOffset or 2.5
        local step  = antiFlickOffsetStep or 0.2
        local lifeTime = 0.2

        task.spawn(function()
            local blocked = false
            task.wait(antiFlickDelay or 0)
            for i = 1, count do
                if not hrp or not myRoot then break end

                local dist = base + (i - 1) * step

                local st = killerState[char] or { vel = hrp.Velocity or Vector3.new(), angVel = 0 }
                local vel = st.vel or hrp.Velocity or Vector3.new()

                local forwardSpeed = vel:Dot(hrp.CFrame.LookVector)
                local lateralSpeed = vel:Dot(hrp.CFrame.RightVector)

                -- separate multipliers
                local pStrength = (type(predictionStrength) == "number" and predictionStrength) or 1
                local pTurn = (type(predictionTurnStrength) == "number" and predictionTurnStrength) or 1

                -- raw predicted displacements
                local forwardPredictRaw = forwardSpeed * PRED_SECONDS_FORWARD * pStrength
                local lateralPredictRaw = lateralSpeed * PRED_SECONDS_LATERAL * pStrength
                local turnLateralRaw    = st.angVel * ANG_TURN_MULTIPLIER * pTurn

                -- clamps (scaled separately)
                local forwardClamp = PRED_MAX_FORWARD * pStrength
                local lateralClamp = PRED_MAX_LATERAL * pStrength
                local turnClamp    = PRED_MAX_LATERAL * pTurn

                local forwardPredict = math.clamp(forwardPredictRaw, -forwardClamp, forwardClamp)
                local lateralPredict = math.clamp(lateralPredictRaw, -lateralClamp, lateralClamp)
                local turnLateral = math.clamp(turnLateralRaw, -turnClamp, turnClamp)

                local forwardDist = dist + forwardPredict

                local spawnPos = hrp.Position
                                + hrp.CFrame.LookVector * forwardDist
                                + hrp.CFrame.RightVector * (lateralPredict + turnLateral)

                local part = Instance.new("Part")
                part.Name = "AntiFlickZone"
                part.Size = partSize
                part.Transparency = 0.45
                part.Anchored = true
                part.CanCollide = false
                part.CFrame = CFrame.new(spawnPos, hrp.Position)
                part.BrickColor = BrickColor.new("Bright blue")
                part.Parent = workspace

                Debris:AddItem(part, lifeTime)

                if isPointInsidePart(part, myRoot.Position) then
                    blocked = true
                else
                    local touching = {}
                    pcall(function() touching = myRoot:GetTouchingParts() end)
                    for _, p in ipairs(touching) do
                        if p == part then
                            blocked = true
                            break
                        end
                    end
                end

                if blocked then
                    if not (facingCheckEnabled and not isFacing(myRoot, hrp)) then
                        if autoblocktype == "Block" then
                            fireRemoteBlock()  -- Use FIXED function
                        elseif autoblocktype == "Charge" then
                            fireRemoteCharge()  -- Use FIXED function
                        elseif autoblocktype == "7n7 Clone" then
                            fireRemoteClone()  -- Use FIXED function
                        end
                        soundBlockedUntil[sound] = t + 1.2
                    end
                    break
                end

                if stagger and stagger > 0 then
                    task.wait(stagger)
                else
                    task.wait(0)
                end
            end
        end)
        return
    end
end

local function hookSound(sound)
    if not sound or not sound:IsA("Sound") then return end
    if soundHooks[sound] then return end

    local preId = extractNumericSoundId(sound)

    -- create entry with id; hrp/char may be nil initially and will be cached later
    soundHooks[sound] = { id = preId, hrp = nil, char = nil }

    -- helper: centralize the logic so behaviour remains identical but without duplication
    local function handleAttempt(snd, id)
        if not autoBlockAudioOn then return end

        if not antiFlickOn then
            local at = autoblocktype
            if at == "Block" then
                attemptBlockForSound(snd, id)
            elseif at == "Charge" then
                attemptChargeForSound(snd, id)
            elseif at == "7n7 Clone" then
                attemptCloneForSound(snd, id)
            end
        else
            attemptBDParts(snd, id)
        end
    end

    -- connections
    local playedConn = sound.Played:Connect(function()
        handleAttempt(sound, preId)
    end)

    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then
            handleAttempt(sound, preId)
        end
    end)

    local destroyConn
    destroyConn = sound.Destroying:Connect(function()
        if playedConn and playedConn.Connected then playedConn:Disconnect() end
        if propConn and propConn.Connected then propConn:Disconnect() end
        if destroyConn and destroyConn.Connected then destroyConn:Disconnect() end
        soundHooks[sound] = nil
        soundBlockedUntil[sound] = nil
    end)

    -- store connections & metadata in hook table for later cleanup if you want (optional)
    soundHooks[sound].playedConn = playedConn
    soundHooks[sound].propConn = propConn
    soundHooks[sound].destroyConn = destroyConn

    -- If currently playing, handle immediately (cheap)
    if sound.IsPlaying then
        handleAttempt(sound, preId)
    end
end

-- Hook existing Sounds across the game (covers workspace, SoundService, Lighting, etc.)
for _, desc in ipairs(KillersFolder:GetDescendants()) do
    if desc:IsA("Sound") then
        hookSound(desc)
    end
end

-- Hook any future Sounds
KillersFolder.DescendantAdded:Connect(function(desc)
    if desc:IsA("Sound") then
        hookSound(desc)
    end
end)

-- Utility to safely get a killer HRP
local function getKillerHRP(killerModel)
    if not killerModel then return nil end
    if killerModel:FindFirstChild("HumanoidRootPart") then
        return killerModel:FindFirstChild("HumanoidRootPart")
    end
    if killerModel.PrimaryPart then
        return killerModel.PrimaryPart
    end
    -- try finding any basepart descendant
    return killerModel:FindFirstChildWhichIsA("BasePart", true)
end

local function beginDragIntoKiller(killerModel)
    -- Basic guards
    if _hitboxDraggingDebounce then return end
    if not killerModel or not killerModel.Parent then return end
    local char = lp and lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    local targetHRP = getKillerHRP(killerModel)
    if not targetHRP then
        warn("beginDragIntoKiller: killer has no HRP/PrimaryPart")
        return
    end

    _hitboxDraggingDebounce = true

    -- save old locomotion state so we can restore it
    local oldWalk = humanoid.WalkSpeed
    local oldJump = humanoid.JumpPower
    local oldPlatformStand = humanoid.PlatformStand

    -- block normal movement by zeroing walk/jump (works for mobile joystick too)
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.PlatformStand = false  -- keep physics normal so BodyVelocity works

    -- create BodyVelocity to push the HRP toward the killer smoothly
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)     -- allow horizontal movement, keep y free
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp

    -- optional: lightly damp vertical to avoid sudden pops (leave Y alone to respect gravity)
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not _hitboxDraggingDebounce then
            conn:Disconnect()
            if bv and bv.Parent then pcall(function() bv:Destroy() end) end
            humanoid.WalkSpeed = oldWalk
            humanoid.JumpPower = oldJump
            humanoid.PlatformStand = oldPlatformStand
            return
        end

        -- abort if character/killer removed
        if not (char and char.Parent) or not (killerModel and killerModel.Parent) then
            _hitboxDraggingDebounce = false
            return
        end

        -- refresh target HRP (killer may respawn)
        targetHRP = getKillerHRP(killerModel)
        if not targetHRP then
            _hitboxDraggingDebounce = false
            return
        end

        -- compute desired horizontal velocity toward the target
        local toTarget = (targetHRP.Position - hrp.Position)
        local dist = toTarget.Magnitude
        -- desired speed: based on distance but clamped so it feels natural
        
        local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
        if horiz.Magnitude > 0.01 then
            local dir = horiz.Unit
            bv.Velocity = Vector3.new(dir.X * Dspeed, bv.Velocity.Y, dir.Z * Dspeed)
        else
            bv.Velocity = Vector3.new(0, bv.Velocity.Y, 0)
        end

        -- stop condition: when very close to killer (adjust threshold as needed)
        local stopDist = 2.0
        if dist <= stopDist then
            _hitboxDraggingDebounce = false
            -- cleanup will happen in next loop tick
        end
    end)

    -- final cleanup safety (timeout)
    task.delay(0.4, function()
        if _hitboxDraggingDebounce then
            _hitboxDraggingDebounce = false
        end
    end)
end

-- Example call:
-- beginDragIntoKiller(someKillerModel)

-- Watch for local block animations starting and trigger drag
RunService.RenderStepped:Connect(function()
    if not hitboxDraggingTech then return end
    if not cachedAnimator then refreshAnimator() end
    local animator = cachedAnimator
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local ok, animId = pcall(function()
            local a = track.Animation
            return a and tostring(a.AnimationId):match("%d+")
        end)
        if ok and animId and table.find(blockAnimIds, animId) then
            -- only trigger once when it starts (timepos ~ 0)
            local timePos = 0
            pcall(function() timePos = track.TimePosition or 0 end)
            if timePos <= 0.12 then
                local nearest = getNearestKillerModel()
                if nearest then
                    -- spawn so we don't block the RenderStepped loop
                    task.wait(Ddelay)
                    task.spawn(function() beginDragIntoKiller(nearest) end)
                    startChargeAimUntilChargeEnds(0.4)
                end
            end
        end
    end
end)

-- If Better Detection (antiFlickOn) is enabled, watch for blue AntiFlickZone parts near the player
-- and trigger dragging when they appear in range.
task.spawn(function()
    if not cachedBlockBtn or not cachedCooldown or not cachedCharges then
        refreshUIRefs()
    end

    if cachedBlockBtn and cachedBlockBtn:FindFirstChild("CooldownTime") and cachedBlockBtn.CooldownTime.Text == "" then
        print("yay")
    else
        return
    end

    while true do
        RunService.Heartbeat:Wait()
        if not (hitboxDraggingTech and antiFlickOn) then
            task.wait(0.15)
            continue
        end

        local char = lp.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then task.wait(0.15) continue end

        -- look for parts named "AntiFlickZone" inside radius (fast and simple)
        local found = nil
        for _, part in ipairs(workspace:GetDescendants()) do
            if not part:IsA("BasePart") then continue end
            if part.Name ~= "AntiFlickZone" then continue end
            if (part.Position - myRoot.Position).Magnitude <= HITBOX_DETECT_RADIUS then
                found = part
                break
            end
        end        
        if found and not _hitboxDraggingDebounce then
            local nearest = getNearestKillerModel()
            if nearest then
                task.wait(Ddelay)
                task.spawn(function() beginDragIntoKiller(nearest) end)
                startChargeAimUntilChargeEnds(0.4)
            end
        end
        task.wait(0.12) -- throttle checks
    end
end)

-- double-punch tech detection
-- Replacement double-punch detection (safer + debounced)
local _REFRESH_UI_IF_NIL = true
local TRACK_DEBOUNCE = 0.45   -- seconds to avoid retriggering same track
local START_WINDOW = 0     -- consider a track "starting" if TimePosition <= START_WINDOW

local trackLastTriggered = setmetatable({}, { __mode = "k" }) -- weak keys (AnimationTrack -> last tick)

-- Auto block + punch detection loop
RunService.RenderStepped:Connect(function()
    local gui = PlayerGui:FindFirstChild("MainUI")
    local punchBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Punch")
    local charges = punchBtn and punchBtn:FindFirstChild("Charges")
    local blockBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Block")
    local cooldown = blockBtn and blockBtn:FindFirstChild("CooldownTime")

    local myChar = lp.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    Humanoid = myChar:FindFirstChildOfClass("Humanoid")
        -- Auto Block: Trigger block if a valid animation is played by a killer
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local animTracks = hum and hum:FindFirstChildOfClass("Animator") and hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()

            if hrp and myRoot and (hrp.Position - myRoot.Position).Magnitude <= detectionRange then
                for _, track in ipairs(animTracks or {}) do
                    local id = tostring(track.Animation.AnimationId):match("%d+")
                    if table.find(autoBlockTriggerAnims, id) then
                        if autoBlockOn and (hrp.Position - myRoot.Position).Magnitude <= detectionRange then
                            if isFacing(myRoot, hrp) then
                                if cooldown and cooldown.Text == "" then
                                    fireRemoteBlock()  -- Use FIXED function
                                end
                                if doubleblocktech == true and charges and charges.Text == "1" then
                                    fireRemotePunch()  -- Use FIXED function
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Detect if player is playing a block animation, and blockTP is enabled

    -- Predictive Auto Block: Check killer range and time
    if predictiveBlockOn and tick() > predictiveCooldown then
        local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        local myChar = lp.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChild("Humanoid")

        if killersFolder and myHRP and myHum then
            local killerInRange = false

            for _, killer in ipairs(killersFolder:GetChildren()) do
                local hrp = killer:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (myHRP.Position - hrp.Position).Magnitude
                    if dist <= detectionRange then
                        killerInRange = true
                        break
                    end
                end
            end

            -- Handle killer entering range
            if killerInRange then
                if not killerInRangeSince then
                    killerInRangeSince = tick()  -- Start the timer when the killer enters the range
                elseif tick() - killerInRangeSince >= edgeKillerDelay then
                    -- Block if the killer has stayed in range long enough
                    fireRemoteBlock()  -- Use FIXED function
                    predictiveCooldown = tick() + 2  -- Set cooldown to avoid blocking too quickly again
                    killerInRangeSince = nil  -- Reset the timer
                end
            else
                killerInRangeSince = nil  -- Reset timer if the killer leaves range
            end
        end
    end


    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    -- Auto Punch
    if autoPunchOn then
        if charges and charges.Text == "1" then
            
            for _, name in ipairs(killerNames) do
                local killer = workspace:FindFirstChild("Players")
                    and workspace.Players:FindFirstChild("Killers")
                    and workspace.Players.Killers:FindFirstChild(name)
                if killer and killer:FindFirstChild("HumanoidRootPart") then
                    local root = killer.HumanoidRootPart
                    if root and myRoot and (root.Position - myRoot.Position).Magnitude <= 10 then

                        -- Trigger punch GUI button
                        fireRemotePunch()  -- Use FIXED function

                        -- Start character and camera lock when punching with duration
                        if characterLockOn or cameraLockOn then
                            startAggressiveLockOnPunch()
                        end

                        -- Fling Punch: Constant TP 2 studs in front of killer for 1 second
                        if flingPunchOn then
                            hiddenfling = true
                            local targetHRP = root
                            task.spawn(function()
                                local start = tick()
                                while tick() - start < 1 do
                                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and targetHRP and targetHRP.Parent then
                                        local frontPos = targetHRP.Position + (targetHRP.CFrame.LookVector * 2)
                                        lp.Character.HumanoidRootPart.CFrame = CFrame.new(frontPos, targetHRP.Position)
                                    end
                                    task.wait()
                                end
                                hiddenfling = false
                            end)
                        end

                        break -- Only punch one killer per frame
                    end
                end
            end
        end
    end
    -- === Message-When-Punching: send once per animation start ===
    do
        local myChar = lp.Character
        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local animator = cachedAnimator
        local currentPlaying = {} -- map animId -> true for tracks playing this frame
        if not animator then
            refreshAnimator()
            animator = cachedAnimator
        end
        if animator then
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    local animId
                    pcall(function() animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                    if animId and table.find(punchAnimIds, animId) then
                        currentPlaying[animId] = true
    
                        -- if it wasn't playing last frame, it's a newly-started punch animation
                        if not _punchPrevPlaying[animId] then
                            if messageWhenAutoPunchOn and messageWhenAutoPunch and tostring(messageWhenAutoPunch):match("%S") and (tick() - _lastPunchMessageTime) > MESSAGE_PUNCH_COOLDOWN then
                                pcall(function() sendChatMessage(messageWhenAutoPunch) end)
                                _lastPunchMessageTime = tick()
                            end
                            
                            -- Start lock when punch animation begins with duration
                            if characterLockOn or cameraLockOn then
                                startAggressiveLockOnPunch()
                            end
                        end
                    end
                end
            end
        end

        -- replace prev state with current state (garbage-collected)
        _punchPrevPlaying = currentPlaying
    end

    do
        local myChar = lp.Character
        local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local animator = cachedAnimator
        local currentPlaying = {} -- map animId -> true for tracks playing this frame
        if not animator then
            refreshAnimator()
            animator = cachedAnimator
        end
        if animator then
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    local animId
                    pcall(function() animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                    if animId and table.find(blockAnimIds, animId) then
                        currentPlaying[animId] = true
    
                        -- if it wasn't playing last frame, it's a newly-started punch animation
                        if not _blockPrevPlaying[animId] then
                            if messageWhenAutoBlockOn and messageWhenAutoBlock and tostring(messageWhenAutoBlock):match("%S") and (tick() - _lastBlockMessageTime) > MESSAGE_BLOCK_COOLDOWN then
                                pcall(function() sendChatMessage(messageWhenAutoBlock) end)
                                _lastBlockMessageTime = tick()
                            end
                        end
                    end
                end
            end
        end

        -- replace prev state with current state (garbage-collected)
        _blockPrevPlaying = currentPlaying
    end

    -- === end message-when-punching ===
    if aimPunch then
        if not cachedAnimator then
            refreshAnimator()
        end
        local animator = cachedAnimator
        if animator and myRoot and myChar then
            for _, name in ipairs(killerNames) do
                local killer = workspace:FindFirstChild("Players")
                    and workspace.Players:FindFirstChild("Killers")
                    and workspace.Players.Killers:FindFirstChild(name)
                if killer and killer:FindFirstChild("HumanoidRootPart") then
                    local root = killer.HumanoidRootPart

                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        -- guard: want only punch tracks (vanilla or custom)
                        local animId = tostring(track.Animation.AnimationId):match("%d+")
                        if table.find(punchAnimIds, animId) then

                            -- Avoid retriggering for the same AnimationTrack within cooldown
                            local last = lastAimTrigger[track]
                            if last and tick() - last < AIM_COOLDOWN then
                                -- already triggered recently for this track -> skip
                            else
                                -- Only trigger when the track is just starting (helps avoid mid/late triggers)
                                local timePos = 0
                                pcall(function() timePos = track.TimePosition or 0 end) -- safe read
                                if timePos <= 0.1 then
                                    -- Lock it so we don't retrigger
                                    lastAimTrigger[track] = tick()

                                    -- Disable autoroate once and aim for AIM_WINDOW seconds
                                    local humanoid = myChar:FindFirstChild("Humanoid")
                                    if humanoid then
                                        humanoid.AutoRotate = false
                                    end

                                    task.spawn(function()
                                        local start = tick()
                                        while tick() - start < AIM_WINDOW do
                                            if myRoot and root and root.Parent then
                                                local predictedPos = root.Position + (root.CFrame.LookVector * predictionValue)
                                                myRoot.CFrame = CFrame.lookAt(myRoot.Position, predictedPos)
                                            end
                                            task.wait()
                                        end
                                        -- restore
                                        if humanoid then
                                            humanoid.AutoRotate = true
                                        end

                                        -- cleanup: allow retrigger later
                                        task.delay(AIM_COOLDOWN - AIM_WINDOW, function()
                                            lastAimTrigger[track] = nil
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Stop locks if no punch animation is playing
    if characterLockOn or cameraLockOn then
        local animator = cachedAnimator
        if animator then
            local hasPunchAnim = false
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
                if animId and table.find(punchAnimIds, animId) then
                    hasPunchAnim = true
                    break
                end
            end
            if not hasPunchAnim then
                stopAllLocks()
            end
        end
    end
end)

local success, Library = pcall(function()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    return loadstring(game:HttpGet(repo .. "Library.lua"))()
end)


local Tabs

local ThemeManager, SaveManager
if success and Library then
    pcall(function()
        local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
        ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
        SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
    end)
else
    warn("Obsidian library failed to load. If HttpGet is blocked, require a local copy of Library.lua and addons instead.")
end

-- If Library loaded, build UI using Example.lua patterns
local Options, Toggles, Window
local ui_refs = {}


-- GUI SHIT --

if Library then
    -- optional recommended settings from Example.lua
    Library.ForceCheckbox = false
    Library.ShowToggleFrameInKeybinds = true

    Window = Library:CreateWindow({
        Title = "Auto Block",
        Footer = "idk wtf ts",
        Icon = 0,
        NotifySide = "Right",
        ShowCustomCursor = true,
    })

    Tabs = {
        Notice = Window:AddTab("Notice", "user"),
        AutoBlock = Window:AddTab("Auto Block", "sword"),
        BD = Window:AddTab("BD", "sword"),
        Tech = Window:AddTab("Techs", "sword"),
        AutoBlockPrediction = Window:AddTab("Auto Block Prediction", "wrench"),
        AutoPunch = Window:AddTab("Auto Punch", "wrench"),
        FB = Window:AddTab("Fake Block", "user"),
        ["UI Settings"] = Window:AddTab("Settings", "settings"),
    }

    local NoticeLeftGroup = Tabs.Notice:AddLeftGroupbox("welcome")
    local NoticeRightGroup = Tabs.Notice:AddRightGroupbox("Update Log")

    local AutoBlockLeftGroup = Tabs.AutoBlock:AddLeftGroupbox("autoblock")
    local AutoBlockRightGroup = Tabs.AutoBlock:AddRightGroupbox("more things")

    local BDLeftGroup = Tabs.BD:AddLeftGroupbox("autoblock")
    local BDRightGroup = Tabs.BD:AddRightGroupbox("more things")

    local TechLeftGroup = Tabs.Tech:AddLeftGroupbox("techs")
    local TechRightGroup = Tabs.Tech:AddRightGroupbox("what they do")

    local AutoBlockPredictionLeftGroup = Tabs.AutoBlockPrediction:AddLeftGroupbox("autoblock prediction")
    local AutoBlockPredictionRightGroup = Tabs.AutoBlockPrediction:AddRightGroupbox("more things")

    local AutoPunchLeftGroup = Tabs.AutoPunch:AddLeftGroupbox("Techs")
    local AutoPunchRightGroup = Tabs.AutoPunch:AddRightGroupbox("a")

    local FBLeftGroup = Tabs.FB:AddLeftGroupbox("Fake Block")

    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Setting", "wrench")

    NoticeLeftGroup:AddLabel("thanks for using my wonderful auto block script")
    NoticeLeftGroup:AddLabel("some features may only work with guest skins thats using the default anims")
    NoticeLeftGroup:AddLabel(".gg/Tmby2GkKJR")

    -- UPDATED NOTICE LOG
    NoticeRightGroup:AddLabel("1. Added Survivor ESP")
    NoticeRightGroup:AddLabel("2. Added Infinite Stamina")
    NoticeRightGroup:AddLabel("3. Updated Audio Sounds List")
    NoticeRightGroup:AddLabel("4. Fixed Remote Functions")
    NoticeRightGroup:AddLabel("5. Audio AB now works with CK")
    NoticeRightGroup:AddLabel("6. Added Character & Camera Lock (Smooth Tracking)")

    NoticeRightGroup:AddLabel("UPDATE PLANS")
    NoticeRightGroup:AddLabel("1. Optimize Lag")
    NoticeRightGroup:AddLabel("2. More ESP Options")
    NoticeRightGroup:AddLabel("3. Suggest in discord")


    AutoBlockLeftGroup:AddToggle("AutoBlockAnimation", {
        Text = "Auto Block (Animation)",
        Tooltip = "auto block animation detection",
        Default = false,
        Callback = function(Value)
            autoBlockOn = Value
        end,
    })

    AutoBlockLeftGroup:AddToggle("AutoBlockAudio", {
        Text = "Auto Block (Audio)",
        Tooltip = "auto block audio detection",
        Default = false,
        Callback = function(Value)
            autoBlockAudioOn = Value
        end,
    })

    AutoBlockLeftGroup:AddDropdown("BlockType", {
        Values = {"Block", "Charge", "7n7 Clone"},
        Default = 1,
        Multi = false,
        Text = "Auto Block Type",
        Tooltip = "Choose ab type",
        Callback = function(Value)
            autoblocktype = Value
        end,
    })

    AutoBlockLeftGroup:AddLabel("use audio auto block and use 20 range for it")


    AutoBlockLeftGroup:AddToggle("messageWhenBlockToggle", {
        Text = "Message When Blocking",
        Tooltip = "auto chat when blocking",
        Default = false,
        Callback = function(Value)
            messageWhenAutoBlockOn = Value
        end,
    })

    -- Input: Range (N)
    AutoBlockLeftGroup:AddInput("MessageWhenBlock", {
        Text = "The message",
        Default = "",
        Numeric = false,
        ClearTextOnFocus = false,
        Placeholder = "im gonna block ya",
        Callback = function(Value)
            messageWhenAutoBlock = Value
        end,
    })

    AutoBlockLeftGroup:AddInput("BlockDelay", {
        Text = "block delay",
        Default = "0",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0",
        Callback = function(Value)
            blockdelay = tonumber(Value) or blockdelay
        end,
    })

    AutoBlockLeftGroup:AddLabel("face check might delay on coolkid, dont use face check agaisnt coolkid.")

    AutoBlockLeftGroup:AddToggle("FacingCheckToggle", {
        Text = "Facing Check",
        Tooltip = "facing chekc",
        Default = false,
        Callback = function(Value)
            facingCheckEnabled = Value
        end,
    })

    AutoBlockLeftGroup:AddToggle("FacingCheckVisualToggle", {
        Text = "Facing Check Visual",
        Tooltip = "facing chekc visual",
        Default = false,
        Callback = function(Value)
            facingVisualOn = Value
            refreshFacingVisuals()
        end,
    })

    AutoBlockLeftGroup:AddLabel("facing check visual not being accurate is because its just there to give u an idea of the facing check")

    AutoBlockLeftGroup:AddInput("FacingChekDot", {
        Text = "Facing Check angle (DOT)",
        Default = "-0.3",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "-0.3",
        Callback = function(Value)
            customFacingDot = tonumber(Value) or customFacingDot
        end,
    })

    AutoBlockLeftGroup:AddLabel("DOT Explanation: if for example you put it 0 you will need to be EXACTLY infront of the killer. but you can make the facing check cone larger by making it -0.3 or -0.5 if you put -1 is going to be a half circle cone infront the killer, so yeah.")

    AutoBlockLeftGroup:AddInput("DetectionRange", {
        Text = "Detection Range",
        Default = "18",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "18",
        Callback = function(Value)
            detectionRange = tonumber(Value) or detectionRange
            detectionRangeSq = detectionRange * detectionRange
        end,
    })

    AutoBlockLeftGroup:AddToggle("DetectionRangeVisualToggle", {
        Text = "Detection Range Visual",
        Tooltip = "detection range visual",
        Default = false,
        Callback = function(Value)
            killerCirclesVisible = Value
            refreshKillerCircles()
        end,
    })

    -- BDtab
    
    BDLeftGroup:AddLabel("BD or Better Detection delays on coolkid, use normal detection agaisnt coolkid.")

    BDLeftGroup:AddToggle("AntiFlickToggle", {
        Text = "Better Detection (doesn't use detectrange)",
        Tooltip = "activate nd",
        Default = false,
        Callback = function(Value)
            antiFlickOn = Value
        end,
    })

    BDLeftGroup:AddInput("AntiFlickParts", {
        Text = "How many block parts that spawn",
        Default = "4",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "4",
        Callback = function(Value)
            antiFlickParts = math.max(1, math.floor(Value))
        end,
    })

    BDLeftGroup:AddInput("BlockPartsSizeMultiplier", {
        Text = "Block Parts Size Multiplier",
        Default = "1",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "1",
        Callback = function(Value)
            blockPartsSizeMultiplier = tonumber(Value) or 1
        end,
    })

    BDLeftGroup:AddInput("PredictionStrength", {
        Text = "Forward Prediction Strength",
        Default = "1",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "1",
        Callback = function(Value)
            predictionStrength = tonumber(Value)
        end,
    })

    BDLeftGroup:AddInput("PredictionTurnStrength", {
        Text = "Turn Prediction Strength",
        Default = "1",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "1",
        Callback = function(Value)
            predictionTurnStrength = tonumber(Value)
        end,
    })

    BDLeftGroup:AddInput("AntiFlickDelay", {
        Text = "delay before the first block part spawn (seconds) (DBTFBPS)",
        Default = "0",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                antiFlickDelay = math.max(0, num) -- don't allow negative
            end
        end,
    })

    BDLeftGroup:AddToggle("AutoAdjustDBTFBPS", {
        Text = "Auto-adjust DBTFBPS based on killer",
        Tooltip = "activate auto dbtfbps",
        Default = false,
        Callback = function(Value)
            autoAdjustDBTFBPS = Value
            if state then
                -- save the current manual value so we can restore it when the toggle is off
                _savedManualAntiFlickDelay = antiFlickDelay or 0
                doImmediateUpdate()
                print("Auto-DBTFBPS: enabled (saved manual antiFlickDelay = " .. tostring(_savedManualAntiFlickDelay) .. ")")
            else
                -- restore manual value when user disables
                antiFlickDelay = _savedManualAntiFlickDelay
                print("Auto-DBTFBPS: disabled -> restored antiFlickDelay = " .. tostring(antiFlickDelay))
            end
        end,
    })

    BDLeftGroup:AddInput("AntiFlickDelayEachParts", {
        Text = "delay before each block parts spawns (seconds)",
        Default = "0.02",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.02",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                stagger = math.max(0, num) -- don't allow negative
            end
        end,
    })

    BDLeftGroup:AddInput("AntiFlickDistanceInfront", {
        Text = "how much studs infront killer the block parts are gonna spawn (studs)",
        Default = "2.7",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "2.7",
        Callback = function(Value)
            local num = tonumber(text)
            if num then
                antiFlickBaseOffset = math.max(0, num) -- don't allow negative
            end
        end,
    })

    TechLeftGroup:AddToggle("doubleblockTechtoggle", {
        Text = "Double Punch Tech",
        Tooltip = "look at the right group for info",
        Default = false,
        Callback = function(Value)
            doubleblocktech = Value
        end,
    })

    TechLeftGroup:AddToggle("HitboxDraggingToggle", {
        Text = "Hitbox Dragging tech (HDT)",
        Tooltip = "look at the right group for info",
        Default = false,
        Callback = function(Value)
            hitboxDraggingTech = Value
        end,
    })

    TechLeftGroup:AddInput("HDTspeed", {
        Text = "HDT speed",
        Default = "5.6",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "5.6",
        Callback = function(Value)
            Dspeed = tonumber(Value)
        end,
    })

    TechLeftGroup:AddInput("HDTdelay", {
        Text = "HDT delay",
        Default = "0",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0",
        Callback = function(Value)
            Ddelay = tonumber(Value)
        end,
    })

    TechLeftGroup:AddButton("Fake Lag Tech", function()
        pcall(function()
            local char = lp.Character or lp.CharacterAdded:Wait()
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end

            local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

            -- (optional) stop any identical track already playing
            for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                local id = tostring(t.Animation and t.Animation.AnimationId or ""):match("%d+")
                if id == "136252471123500" then
                    pcall(function() t:Stop() end)
                end
            end

            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://136252471123500"
            local track = animator:LoadAnimation(anim)
            track:Play()
        end)
    end)



    AutoBlockPredictionLeftGroup:AddToggle("predictiveABtoggle", {
        Text = "Predictive Auto Block",
        Tooltip = "blocks if the killer is in a range",
        Default = false,
        Callback = function(Value)
            predictiveBlockOn = Value
        end,
    })

    AutoBlockPredictionLeftGroup:AddInput("predictiveABrange", {
        Text = "Detection Range",
        Default = "10",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "10",
        Callback = function(Value)
            local vlue = tonumber(Value)
            if vlue then
                detectionRange = vlue
            end
        end,
    })

    AutoBlockPredictionLeftGroup:AddInput("edgekillerlmao", {
        Text = "Edge Killer",
        Default = "3",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "3",
        Callback = function(Value)
            local vlue = tonumber(Value)
            if vlue then
                edgeKillerDelay = vlue
            end
        end,
    })


    AutoPunchLeftGroup:AddToggle("AutoPunchToggle", {
        Text = "Auto Punch",
        Tooltip = "auto parries after block",
        Default = false,
        Callback = function(Value)
            autoPunchOn = Value
        end,
    })

    -- NEW: Added character and camera lock toggles with smooth tracking
    AutoPunchLeftGroup:AddToggle("CharacterLockToggle", {
        Text = "Character Lock (Smooth Tracking)",
        Tooltip = "Locks your character to face and track the killer when punching",
        Default = false,
        Callback = function(Value)
            characterLockOn = Value
            if not Value then
                stopAllLocks()
            end
        end,
    })

    AutoPunchLeftGroup:AddToggle("CameraLockToggle", {
        Text = "Camera Lock (Smooth Tracking)",
        Tooltip = "Locks your camera on the killer and tracks movement when punching",
        Default = false,
        Callback = function(Value)
            cameraLockOn = Value
            if not Value then
                stopAllLocks()
            end
        end,
    })

    -- Add lock duration control
    AutoPunchLeftGroup:AddInput("LockDuration", {
        Text = "Lock Duration (seconds)",
        Default = "2.0",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "2.0",
        Callback = function(Value)
            local num = tonumber(Value)
            if num and num > 0 then
                lockDuration = num
            end
        end,
    })

    -- Add lock smoothing controls
    AutoPunchLeftGroup:AddInput("CharLockSmoothing", {
        Text = "Character Lock Smoothing (0.1-1.0)",
        Default = "0.7",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.7",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                aggressiveSmoothing = math.clamp(num, 0.1, 1.0)
            end
        end,
    })

    AutoPunchLeftGroup:AddInput("CamLockSmoothing", {
        Text = "Camera Lock Smoothing (0.1-1.0)",
        Default = "0.6",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.6",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                cameraAggressiveSmoothing = math.clamp(num, 0.1, 1.0)
            end
        end,
    })

    AutoPunchLeftGroup:AddToggle("MessageWhenPunchToggle", {
        Text = "Message When Punching",
        Tooltip = "message when you are punching",
        Default = false,
        Callback = function(Value)
            messageWhenAutoPunchOn = Value
        end,
    })

    AutoPunchLeftGroup:AddInput("MessageWhenPunchText", {
        Text = "Message when punching",
        Default = "",
        Numeric = false,
        ClearTextOnFocus = false,
        Placeholder = "Im not gonna sugarcoat it.",
        Callback = function(Value)
            messageWhenAutoPunch = Value
        end,
    })

    AutoPunchLeftGroup:AddToggle("flingpunchtoggle", {
        Text = "Fling Punch",
        Tooltip = "fling punch (broken)",
        Default = false,
        Callback = function(Value)
            flingPunchOn = Value
        end,
    })

    AutoPunchLeftGroup:AddToggle("PunchAimToggle", {
        Text = "Punch Aimbot",
        Tooltip = "aimbots to the killer when punching",
        Default = false,
        Callback = function(Value)
            aimPunch = Value
        end,
    })


    AutoPunchLeftGroup:AddInput("PredictionSlider", {
        Text = "Aim Prediction",
        Default = tostring(predictionValue),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "4",
        Callback = function(Value)
            local vlue = tonumber(Value)
            if vlue then
                predictionValue = vlue
            end
        end,
    })

    AutoPunchLeftGroup:AddInput("FlingPower", {
        Text = "Fling Power",
        Default = "10000",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "10000",
        Callback = function(Value)
            local vlue = tonumber(Value)
            if vlue then
                flingPower = vlue
            end
        end,
    })

    FBLeftGroup:AddButton("Load Fake Block", function()
        pcall(function()
            local fakeGui = PlayerGui:FindFirstChild("FakeBlockGui")
            if not fakeGui then
                local success, result = pcall(function()
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/skibidi399/Auto-block-script/refs/heads/main/fakeblock"))()
                end)
                if not success then
                    warn("❌ Failed to load Fake Block GUI:", result)
                end
            else
                fakeGui.Enabled = true
                print("✅ Fake Block GUI enabled")
            end
        end)
    end)

    MenuGroup:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible,
        Text = "Open Keybind Menu",
        Callback = function(value)
            Library.KeybindFrame.Visible = value
        end,
    })
    MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = true,
        Callback = function(Value)
            Library.ShowCustomCursor = Value
        end,
    })
    MenuGroup:AddDropdown("NotificationSide", {
        Values = { "Left", "Right" },
        Default = "Right",
        Text = "Notification Side",
        Callback = function(Value)
            Library:SetNotifySide(Value)
        end,
    })
    MenuGroup:AddDropdown("DPIDropdown", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",

        Text = "DPI Scale",

        Callback = function(Value)
            Value = Value:gsub("%%", "")
            local DPI = tonumber(Value)

            Library:SetDPIScale(DPI)
        end,
    })
    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

    MenuGroup:AddButton("unload script", function()
        Library:Unload()
    end)

    Library.ToggleKeybind = Options.MenuKeybind
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    ThemeManager:SetFolder("autoblock")
    SaveManager:SetFolder("autoblock/games")
    SaveManager:SetSubFolder("Forsaken")
    SaveManager:BuildConfigSection(Tabs["UI Settings"])
    ThemeManager:ApplyToTab(Tabs["UI Settings"])
    SaveManager:LoadAutoloadConfig()
end