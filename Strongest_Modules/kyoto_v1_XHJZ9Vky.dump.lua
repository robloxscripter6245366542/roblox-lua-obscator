--[[ Generated @ dsc.gg/6vms ]]

local LocalPlayer, TweenService, r82, Completed, Kyoto, InputBegan, InputChanged, InputEnded;
local fenv = getfenv();
if not pcall(function(p1, p2, a, b, c)

end) then
else 
    pcall(function(p1_3, p2_3, p3_3, p4_3, a_3, b_3, c_3)
        if not fenv.MjQaCBvcI7EmNn then 

        end;
    end);
end;
if not fenv.hDwXdmqalLdEeI then 

end;
if not fenv.v6zUjMY8to9Nxn then 

end;
local ScreenGui = Instance.new(
    "ScreenGui",
    game.Players.LocalPlayer:WaitForChild("PlayerGui")
);
ScreenGui.ResetOnSpawn = false;
local Auto_Kyoto_By_Khengie_Slayer = Instance.new"TextLabel";
Auto_Kyoto_By_Khengie_Slayer.Parent = ScreenGui;
local UDim2_New = UDim2.new;
Auto_Kyoto_By_Khengie_Slayer.Size = UDim2_New(1, 0, 1, 0);
Auto_Kyoto_By_Khengie_Slayer.BackgroundTransparency = 1;
Auto_Kyoto_By_Khengie_Slayer.Text = "Auto Kyoto by Khengie_slayer";
local Color3_New = Color3.new;
Auto_Kyoto_By_Khengie_Slayer.TextColor3 = Color3_New(2, 2, 1);
Auto_Kyoto_By_Khengie_Slayer.TextScaled = true;
Auto_Kyoto_By_Khengie_Slayer.Font = Enum.Font.SourceSansBold;
task.delay(5, function(p1_5, p2_5, p3_5, a_5, b_5, c_5)
    r82 = game:GetService("TweenService"):Create(Auto_Kyoto_By_Khengie_Slayer, TweenInfo.new(1), {
        ["TextTransparency"] = 1
    });
    r82:Play();
    r82.Completed:Wait();
    Auto_Kyoto_By_Khengie_Slayer:Destroy();
    if not fenv.IKpPgJvLoXelZ4 then 
    end;
end);
task.delay(6, function(p1_4, p2_4, p3_4, p4_4, a_4, b_4, c_4)
    Kyoto = Instance.new"TextButton";
    Kyoto.Parent = ScreenGui;
    Kyoto.Size = UDim2_New(0, 50, 0, 50);
    Kyoto.Position = UDim2_New(0.5, -100, 0.8, 0);
    Kyoto.Text = "Kyoto";
    Kyoto.BackgroundColor3 = Color3.fromRGB(80, 80, 255);
    Kyoto.TextColor3 = Color3_New(1, 1, 1);
    Kyoto.TextScaled = true;
    Kyoto.Active = true;
    Kyoto.Draggable = true;
    Kyoto.InputBegan:Connect(function(input, p2_6, p3_6, p4_6, p5_6, p6_6, p7_6, p8_6, a_6, b_6, c_6)
        local _ = (input.UserInputType == Enum.UserInputType.Touch);
        local _ = (input.UserInputType == Enum.UserInputType.MouseButton1);
        if not fenv.iN27phCF7lcy3P then 

        end;
    end);
    Kyoto.InputChanged:Connect(function(input_1, p2_7, p3_7, a_7, b_7, c_7)
        local _ = (input_1.UserInputType == Enum.UserInputType.Touch);
        local _ = (input_1.UserInputType == Enum.UserInputType.MouseMovement);
        if not fenv.WrlTZsSOeIKlz then 
        end;
    end);
    Kyoto.InputEnded:Connect(function(input_2, p2_8, p3_8, p4_8, p5_8, p6_8, p7_8, a_8, b_8, c_8)
        local _ = (input_2.UserInputType == Enum.UserInputType.Touch);
        local _ = (input_2.UserInputType == Enum.UserInputType.MouseButton1);
        if not fenv.HTR5upfSmzc8 then 
        end;
    end);
    if not fenv.NOO5GmEBPTH5 then 
    end;
end);
if not fenv.lzg9NK362uUj then 

end;