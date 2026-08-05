--[[ Generated @ dsc.gg/6vms ]]

local LocalPlayer, Character, AnimationPlayed, Connection;
local fenv = getfenv();
if pcall(function(p1, p2, a, b, c)

end) then 

end;
if pcall(function(p1_3, p2_3, p3_3, p4_3, p5_3, p6_3, a_3, b_3, c_3)
    if not fenv.efxSzb1AiAVU then 

    end;
end) then 

end;
if not fenv["6OVNUMoc0zDpjL"] then 

end;
if not fenv["2moj0IdHRXEkk"] then 
    LocalPlayer = game.Players.LocalPlayer;
    game:GetService("RunService");
end;
local ScreenGui = Instance.new"ScreenGui";
local Auto_Kyoto = Instance.new"TextButton";
ScreenGui.Parent = game.CoreGui;
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
Auto_Kyoto.Parent = ScreenGui;
local FromRGB = Color3.fromRGB;
Auto_Kyoto.BackgroundColor3 = FromRGB(0, 102, 204);
Auto_Kyoto.BorderSizePixel = 0;
local UDim2_New = UDim2.new;
Auto_Kyoto.Position = UDim2_New(0.6826, 0, 0.1626, 0);
Auto_Kyoto.Size = UDim2_New(0.0666, 0, 0.1169, 0);
Auto_Kyoto.Font = Enum.Font.SourceSans;
Auto_Kyoto.Text = "Auto Kyoto";
Auto_Kyoto.TextColor3 = FromRGB(245, 245, 245);
Auto_Kyoto.TextScaled = true;
Auto_Kyoto.TextWrapped = true;
Auto_Kyoto.Draggable = true;
Instance.new"UICorner".Parent = Auto_Kyoto;
Auto_Kyoto.MouseButton1Click:Connect(function(p1_5, p2_5, p3_5, p4_5, p5_5, p6_5, a_5, b_5, c_5)
    Auto_Kyoto.Text = "ON";
    Character = LocalPlayer.Character;
    if Character then 

    end;
    if not fenv.JtxidAG6DMu1 then 

    end;
end);
LocalPlayer.CharacterAdded:Connect(function(character, p2_6, p3_6, p4_6, p5_6, p6_6, a_6, b_6, c_6)
    Auto_Kyoto.Text = "OFF";
    Character:WaitForChild("Humanoid").AnimationPlayed:Connect(function(p1_7, p2_7, p3_7, p4_7, p5_7, p6_7, p7_7, p8_7, a_7, b_7, c_7)
        local _ = (p1_7.Animation.AnimationId == "rbxassetid://12273188754");
        if not fenv.NjtTPpWsGwy3 then 

        end;
    end):Disconnect();
    if not fenv.lulZk7XbMSB7 then 
    end;
end);
if not fenv.kQt2t0T5ycKySC then 

end;