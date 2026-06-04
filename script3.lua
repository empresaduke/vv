- ============================================================================
-- 📡 KERNEL V200-STRICT_ALIGN [FINAL VERSION WITH NOTIFICATIONS]
-- ============================================================================
if not getgenv or not hookmetamethod then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
getgenv().KernelAutoAttack = true -- Ativa o motor automaticamente ao injetar

-- Alocação Dinâmica Zero Monolítica
local TableClone = table.clone
local Vector3Zero = Vector3.new(0, 0, 0)
local MathHuge = math.huge
local OsClock = os.clock
local TableUnpack = unpack or table.unpack
local CfLookAt = CFrame.lookAt
local CfIdentity = CFrame.identity
local TaskSpawn = task.spawn

-- 📢 INTERFACE DE NOTIFICAÇÕES NATIVAS (RESTAURADA)
local function notifySystemState(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 1.5,
            Button1 = "OK"
        })
    end)
end

-- Cache de Segurança
local FriendCache = {}
local function checkAndCacheFriend(player)
    if player == LocalPlayer then return end
    task.defer(function()
        local success, isFriend = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
        FriendCache[player] = success and isFriend or false
    end)
end

for _, player in ipairs(Players:GetPlayers()) do checkAndCacheFriend(player) end
Players.PlayerAdded:Connect(checkAndCacheFriend)
Players.PlayerRemoving:Connect(function(player) FriendCache[player] = nil end)

-- 🔐 CAPTURA DOS COMPONENTES NATIVOS
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local ClientServices = PlayerScripts:WaitForChild("ClientServices")
local AbilityClient = require(ClientServices:WaitForChild("AbilityClient"))
local AbilityManager = nil

pcall(function()
    for _, module in ipairs(ReplicatedStorage.ModuleScripts:GetChildren()) do
        if module:IsA("ModuleScript") and module.Name ~= "StateReplicator" and module.Name ~= "Data" then
            local data = require(module)
            if type(data) == "table" and data.canBeAffected then 
                AbilityManager = data 
                break 
            end
        end
    end
end)

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local ToServer = Remotes and Remotes:FindFirstChild("ToServer")
local AbilityActivated = ToServer and ToServer:FindFirstChild("AbilityActivated____") or ReplicatedStorage:FindFirstChild("AbilityActivated____", true)

-- 🔬 MATRIZ DE ASSINATURA DINÂMICA COMPACTA
local SIGNATURE = {
    Learned = false,
    StringIndex = nil,
    TargetIndex = nil,
    CFrameIndex = nil,
    PosIndex = nil,
    TemplateArgs = nil
}

local function learnSignature(args)
    SIGNATURE.TemplateArgs = TableClone(args)
    for i, arg in ipairs(args) do
        local t = typeof(arg)
        if t == "string" then
            SIGNATURE.StringIndex = i
        elseif t == "Instance" and arg:IsA("Model") then
            SIGNATURE.TargetIndex = i
        elseif t == "CFrame" then
            SIGNATURE.CFrameIndex = i
        elseif t == "Vector3" then
            SIGNATURE.PosIndex = i
        end
    end
    SIGNATURE.Learned = true
end

-- ============================================================================
-- 📊 CALIBRAGEM ESTÁVEL V200
-- ============================================================================
local SETTINGS = {
    MaxValidRange = 67.0,          
    MaxAbsoluteVelocity = 35.0,    
    DefaultRunSpeed = 16.0,        
    AutoFireInterval = 0.040       
}

local CURRENT_STATE = {
    Target = nil,
    PosPrimary = Vector3Zero,
    CfPrimary = CfIdentity,
    Valid = false
}

local LastPositions = {}
local LastAutoFireTime = 0

-- ============================================================================
-- ⚡ RASTREIO CINEMÁTICO SUAVE
-- ============================================================================
RunService.Heartbeat:Connect(function(dt)
    if not getgenv().KernelAutoAttack or not AbilityClient.getState() then 
        CURRENT_STATE.Valid = false
        CURRENT_STATE.Target = nil
        return 
    end
    
    local localChar = LocalPlayer.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localHrp then 
        CURRENT_STATE.Valid = false
        return 
    end
    
    local localPos = localHrp.Position
    local lookAheadTime = LocalPlayer:GetNetworkPing() or 0.03
    
    local bestChar = nil
    local bestScore = -MathHuge
    local currentEquippedAbility = AbilityClient.getEquippedAbility()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not FriendCache[player] and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if hrp and char.Parent then
                if AbilityManager and currentEquippedAbility and not AbilityManager.canBeAffected(char, currentEquippedAbility) then 
                    continue 
                end
                
                local currentPos = hrp.Position
                local lastPos = LastPositions[char] or currentPos
                LastPositions[char] = currentPos
                
                local velocity = hrp.AssemblyLinearVelocity
                if velocity.Magnitude > SETTINGS.MaxAbsoluteVelocity then
                    velocity = (currentPos - lastPos) / (dt > 0 and dt or 0.016)
                    if velocity.Magnitude > SETTINGS.MaxAbsoluteVelocity then
                        velocity = velocity.Unit * SETTINGS.DefaultRunSpeed
                    end
                end
                
                local currentDistance = (currentPos - localPos).Magnitude
                
                if currentDistance <= SETTINGS.MaxValidRange then
                    local score = 160 - currentDistance
                    
                    if score > bestScore then
                        bestScore = score
                        bestChar = char
                        
                        CURRENT_STATE.PosPrimary = currentPos + (velocity * lookAheadTime)
                        CURRENT_STATE.CfPrimary = CfLookAt(localPos, CURRENT_STATE.PosPrimary)
                    end
                end
            end
        end
    end
    
    if bestChar then
        CURRENT_STATE.Target = bestChar
        CURRENT_STATE.Valid = true
    else
        CURRENT_STATE.Valid = false
    end
end)

-- ============================================================================
-- ⚡ ENGINE LOOP ULTRA-ESTRITO (COMPATIBILIDADE CORRIGIDA)
-- ============================================================================
RunService.Heartbeat:Connect(function()
    if not getgenv().KernelAutoAttack or not CURRENT_STATE.Valid or not CURRENT_STATE.Target then return end
    
    local now = OsClock()
    if (now - LastAutoFireTime) < SETTINGS.AutoFireInterval then return end
    LastAutoFireTime = now
    
    local finalArgs = {}
    if SIGNATURE.Learned and SIGNATURE.TemplateArgs then
        finalArgs = TableClone(SIGNATURE.TemplateArgs)
        
        if SIGNATURE.TargetIndex then finalArgs[SIGNATURE.TargetIndex] = CURRENT_STATE.Target end
        if SIGNATURE.CFrameIndex then finalArgs[SIGNATURE.CFrameIndex] = CURRENT_STATE.CfPrimary end
        if SIGNATURE.PosIndex then finalArgs[SIGNATURE.PosIndex] = CURRENT_STATE.PosPrimary end
        
        if SIGNATURE.StringIndex and typeof(finalArgs[SIGNATURE.StringIndex]) ~= "string" then
            finalArgs[SIGNATURE.StringIndex] = tostring(finalArgs[SIGNATURE.StringIndex])
        end
    else
        finalArgs = {CURRENT_STATE.Target, CURRENT_STATE.CfPrimary, CURRENT_STATE.PosPrimary}
    end
    
    TaskSpawn(function()
        pcall(function() AbilityActivated:FireServer(TableUnpack(finalArgs)) end)
    end)
end)

-- ============================================================================
-- 🔐 INTERCEPÇÃO E APRENDIZADO DE TIPAGEM DO METAMETHOD
-- ============================================================================
if AbilityActivated then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        if getgenv().KernelAutoAttack and self == AbilityActivated then
            local success, method = pcall(getnamecallmethod)
            if success and method == "FireServer" then
                if not SIGNATURE.Learned then learnSignature(args) end
                
                if CURRENT_STATE.Valid and CURRENT_STATE.Target then
                    if SIGNATURE.TargetIndex then args[SIGNATURE.TargetIndex] = CURRENT_STATE.Target end
                    if SIGNATURE.CFrameIndex then args[SIGNATURE.CFrameIndex] = CURRENT_STATE.CfPrimary end
                    if SIGNATURE.PosIndex then args[SIGNATURE.PosIndex] = CURRENT_STATE.PosPrimary end
                    return oldNamecall(self, TableUnpack(args))
                end
            end
        end
        return oldNamecall(self, TableUnpack(args))
    end)
end

-- Limpeza periódica
local lastClean = OsClock()
RunService.Heartbeat:Connect(function()
    local now = OsClock()
    if (now - lastClean) > 5 then
        lastClean = now
        for char, _ in pairs(LastPositions) do
            if not char or not char.Parent then LastPositions[char] = nil end
        end
    end
end)

-- ============================================================================
-- 🔄 ALTERNADOR DE TECLADO (BOTÃO [R] DE VOLTA)
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then 
        getgenv().KernelAutoAttack = not getgenv().KernelAutoAttack
        
        if not getgenv().KernelAutoAttack then
            CURRENT_STATE.Valid = false
            CURRENT_STATE.Target = nil
        end
        
        -- Dispara a notificação visual do Roblox no canto inferior direito
        notifySystemState(
            "KERNEL V200", 
            getgenv().KernelAutoAttack and "MECÂNICA AUTOMÁTICA [LIGADA]" or "MECÂNICA AUTOMÁTICA [DESLIGADA]"
        )
    end
end)

-- Notificação de inicialização bem-sucedida ao carregar o script
notifySystemState("KERNEL V200 PRO", "MOTOR ALINHADO E PRONTO. APERTE [R] PARA ALTERNAR!")
