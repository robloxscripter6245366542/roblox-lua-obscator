--[[ Generated @ dsc.gg/6vms ]]

local Players, Vector2_New, GuiService, Character, CurrentCamera, AbsoluteSize_2, Character_2, CurrentCamera_2;
local fenv = getfenv();
if pcall(function(p1, a, b, c)

end) then 
    pcall(function(p1_3, p2_3, p3_3, p4_3, a_3, b_3, c_3)
        if fenv.tlczRITSCTShVL then
        else 

        end;
    end);
end;
if fenv.njeAWlatBPgJj then
else 

end;
if fenv["1iFPu4eCPQeSwR"] then
else 
    Players = game:GetService("Players");
end;
local LocalPlayer = Players.LocalPlayer;
LocalPlayer:GetMouse();
game:GetService("Players");
getgenv().Key = "c";
fenv.FindNearestEnemy = function(p1_4, p2_4, p3_4, p4_4, p5_4, a_4, b_4, c_4)
    Vector2_New = Vector2.new;
    GuiService = game:GetService("GuiService");
    game:GetService("GuiService");
    Vector2_New(
        GuiService:GetScreenResolution().X / 2,
        GuiService:GetScreenResolution().Y / 2
    );
    game:GetService("Players");
    for for_key_0, for_val_0 in ipairs(Players:GetPlayers()) do
        local _ = (not for_key_0);
        if (for_val_0 ~= LocalPlayer) then 
            Character = for_val_0.Character;
        end;
        if Character then 
            Character:FindFirstChild("HumanoidRootPart");
        end;
        if Character.Humanoid.Health > 0 then 
            game:GetService("Workspace");
        end;
        workspace.CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position);
    end;
    if fenv.FPBJxvuv9i14zn then
    else 
    end;
end;
game:GetService("RunService").Heartbeat:Connect(function(deltaTime, p2_5, p3_5, p4_5, a_5, b_5, c_5)
    if fenv.wBqzwxPuBRZvjQ then
    else 
    end;
end);
LocalPlayer:GetMouse().KeyDown:Connect(function(p1_6, p2_6, p3_6, p4_6, a_6, b_6, c_6)
    if p1_6 ~= getgenv().Key then
    else 

    end;
    if fenv.lieRooM9aF0RHx then
    else 

    end;
end);
local BladLock = Instance.new"ScreenGui";
local Frame = Instance.new"Frame";
Instance.new"ImageLabel";
local CamLock = Instance.new"TextButton";
Instance.new"UICorner";
BladLock.Name = "BladLock";
BladLock.Parent = game.CoreGui;
BladLock.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
Frame.Parent = BladLock;
local FromRGB = Color3.fromRGB;
Frame.BackgroundColor3 = FromRGB(0, 0, 0);
Frame.BorderColor3 = FromRGB(0, 0, 0);
Frame.BorderSizePixel = 0;
local UDim2_New = UDim2.new;
Frame.Position = UDim2_New(0.133798108, 0, 0.20107238, 0);
Frame.Size = UDim2_New(0, 202, 0, 70);
Frame.Active = true;
Frame.Draggable = true;
local AbsoluteSize = Frame.AbsoluteSize;
Frame.Position = UDim2_New(
    0.5,
    -(AbsoluteSize.X) / 2,
    0,
    -(AbsoluteSize.Y) / 2
);
if fenv.UYRB6aWEgrio then
else 

end;
Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function(p1_7, p2_7, p3_7, p4_7, p5_7, a_7, b_7, c_7)
    Frame.Position = UDim2_New(
        0.5,
        -(AbsoluteSize.X) / 2,
        0,
        -(AbsoluteSize.Y) / 2
    );
end);
Instance.new"UICorner".Parent = Frame;
CamLock.Parent = Frame;
CamLock.BackgroundColor3 = FromRGB(255, 255, 255);
CamLock.BackgroundTransparency = 5;
CamLock.BorderColor3 = FromRGB(0, 0, 0);
CamLock.BorderSizePixel = 0;
CamLock.Position = UDim2_New(0.0792079195, 0, 0.18571429, 0);
CamLock.Size = UDim2_New(0, 170, 0, 44);
CamLock.Font = Enum.Font.SourceSansSemibold;
CamLock.Text = "CamLock";
CamLock.TextColor3 = FromRGB(255, 255, 255);
CamLock.TextScaled = true;
CamLock.TextSize = 14;
CamLock.TextWrapped = true;
CamLock.MouseButton1Click:Connect(function(p1_8, p2_8, p3_8, p4_8, a_8, b_8, c_8)
    CamLock.Text = "ON v1";
    FindNearestEnemy();
    game:GetService("GuiService");
    game:GetService("GuiService");
    Vector2_New(
        GuiService:GetScreenResolution().X / 2,
        GuiService:GetScreenResolution().Y / 2
    );
    game:GetService("Players");
    for for_key_1, for_val_1 in ipairs(Players:GetPlayers()) do
        local _ = (not for_key_1);
        if (for_val_1 ~= LocalPlayer) then 
            Character_2 = for_val_1.Character;
        end;
        if Character_2 then 
            Character_2:FindFirstChild("HumanoidRootPart");
        end;
        if Character_2.Humanoid.Health > 0 then 
            game:GetService("Workspace");
        end;
        workspace.CurrentCamera:WorldToViewportPoint(Character_2.HumanoidRootPart.Position);
    end;
    if fenv.MjXNQbB5ei8NhR then
    else 
    end;
end);
if fenv.kg4LJoCBjc4Kwq then
else 

end;