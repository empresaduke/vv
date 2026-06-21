-- Força os valores na tela

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Procura e altera os textos dos coins e moonstone
for _, obj in pairs(playerGui:GetDescendants()) do
    if obj:IsA("TextLabel") then
        if obj.Name == "MysticCoinAmount" then
            obj.Text = "2475"
            print("Coins alterado para 2475")
        elseif obj.Name == "MoonstoneAmount" then
            obj.Text = "100"
            print("Moonstone alterado para 100")
        end
    end
end

-- Tenta achar dentro de ScreenGuis também
for _, screenGui in pairs(playerGui:GetChildren()) do
    if screenGui:IsA("ScreenGui") then
        for _, obj in pairs(screenGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                if obj.Name == "MysticCoinAmount" then
                    obj.Text = "2475"
                elseif obj.Name == "MoonstoneAmount" then
                    obj.Text = "100"
                end
            end
        end
    end
end
