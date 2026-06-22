if not getgenv or not hookmetamethod or not getgc then return end

-- === PONTEIROS C-SIDE DE ALTA VELOCIDADE (BYPASS DE INDEXAÇÃO) ===
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local Entities = Workspace:WaitForChild("Entities")

local GetPlayers = Players.GetPlayers
local PlayerFromCharacter = Players.GetPlayerFromCharacter
local WorldToScreen = Camera.WorldToScreenPoint
local GetMouseLocation = UserInputService.GetMouseLocation
local GetTagged = CollectionService.GetTagged

local math_huge = math.huge
local rawget = rawget
local pcall = pcall
local task_spawn = task.spawn
local newcclosure = newcclosure or function(f) return f end

-- === REGISTRADORES ESTÁTICOS DE MEMÓRIA (ZERO LATENCY CACHE) ===
local IsSpamActive = false
local CURRENT_RAW_TARGET = nil
local TARGET_BEST_PART = nil
local HAS_VALID_TARGET = false

local SCAN_RANGE = 120.0
local SCAN_RANGE_SQ = SCAN_RANGE * SCAN_RANGE
local RANGE_LIMIT = 65.0

-- === SISTEMA DE CACHE DE RELACIONAMENTO (AUTO-UPDATE COMPATÍVEL) ===
local FriendCache = {}

local function checkAndCachePlayer(player)
    if not player or player == LocalPlayer then return end
    local success, isFriend = pcall(function()
        return LocalPlayer:IsFriendsWith(player.UserId)
    end)
    if success and isFriend then
        FriendCache[player] = true
    end
end

local allPlayers = GetPlayers(Players)
for i = 1, #allPlayers do checkAndCachePlayer(allPlayers[i]) end

Players.PlayerAdded:Connect(function(player) checkAndCachePlayer(player) end)
Players.PlayerRemoving:Connect(function(player) if player then FriendCache[player] = nil end end)

-- === RESOLUÇÃO DIRETA DE ENDEREÇO DE REDE ===
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local ToServer = Remotes and Remotes:FindFirstChild("GameServices") and Remotes.GameServices:FindFirstChild("ToServer")
local AbilityActivated = ToServer and ToServer:FindFirstChild("AbilityActivated____") or ReplicatedStorage:FindFirstChild("AbilityActivated____", true)

local fireAbility = AbilityActivated and AbilityActivated.FireServer or Instance.new("RemoteEvent").FireServer

-- === MENTE 1: COGNITIVA (RASTREAMENTO DE DUPLA FONTE, ZERO ALOCAÇÃO) ===
task_spawn(function()
    local Heartbeat = RunService.Heartbeat
    while true do
        Heartbeat:Wait()

        local character = LocalPlayer.Character
        local localHrp = character and character:FindFirstChild("HumanoidRootPart")

        if not localHrp or not Camera then
            HAS_VALID_TARGET = false
            CURRENT_RAW_TARGET = nil
            TARGET_BEST_PART = nil
        else
            local mousePos = GetMouseLocation(UserInputService)
            local mpx, mpy = mousePos.X, mousePos.Y
            local localHrpPos = localHrp.Position
            local lx, ly, lz = localHrpPos.X, localHrpPos.Y, localHrpPos.Z
            local closestDistSq = math_huge
            local bestPart = nil
            local rawModel = nil

            -- Coleta hibrida e estática de alvos para cobrir entidades normais e carregadas
            local targets = Entities:GetChildren()
            local tagged = GetTagged(CollectionService, "CanBeCarried")
            
            -- Loop Principal Unificado
            for i = 1, #targets + #tagged do
                local entity = targets[i] or (tagged[i - #targets] and tagged[i - #targets].Parent)
                
                if entity and entity:IsA("Model") and entity ~= character then
                    local targetPlayer = PlayerFromCharacter(Players, entity) or Players:FindFirstChild(entity.Name)
                    if not (targetPlayer and FriendCache[targetPlayer]) then
                        
                        local root = entity:FindFirstChild("HumanoidRootPart") or entity.PrimaryPart
                        local realTargetModel = entity
                        
                        -- Bypass de anexação/carregamento
                        if entity.Parent ~= Workspace and entity.Parent ~= Entities then
                            local carrierChar = entity:FindFirstAncestorOfClass("Model")
                            if carrierChar and carrierChar ~= entity and carrierChar:FindFirstChild("HumanoidRootPart") then
                                root = carrierChar.HumanoidRootPart
                                realTargetModel = carrierChar
                            end
                        end
                        
                        if root then
                            local rootPos = root.Position
                            local dx = lx - rootPos.X
                            local dy = ly - rootPos.Y
                            local dz = lz - rootPos.Z
                            if (dx*dx + dy*dy + dz*dz) <= SCAN_RANGE_SQ then
                                local screen, onScreen = WorldToScreen(Camera, rootPos)
                                if onScreen and screen.Z > 0 then
                                    local mx = screen.X - mpx
                                    local my = screen.Y - mpy
                                    local mouseDistSq = mx*mx + my*my
                                    if mouseDistSq < closestDistSq then
                                        closestDistSq = mouseDistSq
                                        bestPart = root
                                        rawModel = realTargetModel
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if bestPart and rawModel then
                TARGET_BEST_PART = bestPart
                CURRENT_RAW_TARGET = rawModel
                HAS_VALID_TARGET = true
            else
                HAS_VALID_TARGET = false
                CURRENT_RAW_TARGET = nil
                TARGET_BEST_PART = nil
            end
        end
    end
end)

-- === MENTE 2: MOTOR DE SPAM MATRIX-CHRONO ULTRA-CADENCIADO ===
local networkAccumulator = 0
local CADENCE_LIMIT = 0.0105 -- Janela matemática perfeita do Matrix (~95 Hz estáveis)

local function executeCoreDischarge()
    if IsSpamActive and CURRENT_RAW_TARGET and AbilityActivated then
        -- Execução C-side direta, rápida e limpa
        fireAbility(AbilityActivated, CURRENT_RAW_TARGET)
    end
end

-- Pipeline 1: PostSimulation com Acumulador Matemático contra flutuação de FPS
RunService.PostSimulation:Connect(function(deltaTime)
    if not IsSpamActive or not CURRENT_RAW_TARGET then networkAccumulator = 0 return end
    networkAccumulator = networkAccumulator + deltaTime
    while networkAccumulator >= CADENCE_LIMIT do
        executeCoreDischarge()
        networkAccumulator = networkAccumulator - CADENCE_LIMIT
    end
end)

-- Pipeline 2: Prioridade Máxima Visual (Injeção imediata pós-Input de câmera e mouse)
RunService:BindToRenderStep("ChronoMatrixPrioritySpam", Enum.RenderPriority.Input.Value + 1, function()
    executeCoreDischarge()
end)

-- Pipeline 3: Saturação de Sub-Frame síncrona controlada
RunService.Heartbeat:Connect(function()
    if IsSpamActive and CURRENT_RAW_TARGET then
        executeCoreDischarge()
        executeCoreDischarge()
    end
end)

-- === HOOK SILENT AIM NATIVO COM NEWCCLOSURE ===
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and HAS_VALID_TARGET and TARGET_BEST_PART then
        if method == "ScreenPointToRay" or method == "ViewportPointToRay" then
            if Camera and self == Camera then
                local origin = Camera.CFrame.Position
                return Ray.new(origin, (TARGET_BEST_PART.Position - origin).Unit)
            end
        end
    end
    return oldNamecall(self, ...)
end))

-- === HOOK HITSCAN NATIVO ===
for _, v in pairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "Hitscan") and rawget(v, "AreaCheck") and not rawget(v, "CreateTargetProximityPrompt") then
        local oldHitscan = v.Hitscan
        v.Hitscan = function(p6, p7)
            if HAS_VALID_TARGET and TARGET_BEST_PART and not p7 then
                if CURRENT_RAW_TARGET then
                    local localHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if localHrp and ((TARGET_BEST_PART.Position - localHrp.Position).Magnitude <= RANGE_LIMIT) then
                        return CURRENT_RAW_TARGET, nil
                    end
                end
            end
            return oldHitscan(p6, p7)
        end
        break
    end
end

-- === ENTRADA E INTERFACE ===
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.R then
        IsSpamActive = not IsSpamActive
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "CHRONO - MATRIX",
            Text = IsSpamActive and "SISTEMA UNIFICADO: LIGADO" or "SISTEMA: DESLIGADO",
            Duration = 1
        })
    end
end)
