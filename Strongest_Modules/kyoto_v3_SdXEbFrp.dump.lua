--[[ Generated @ dsc.gg/6vms ]]

local Players, Humanoid, Connection, AnimationPlayed, Tostring_Result, Humanoid_2, AnimationPlayed_2, Tostring_Result_2, UserInputType_Is_Touch, TweenInfo_New, r200, r207, Completed, Size, r237, r242, Completed_2, Size_2, r273, r278, Completed_3, Size_3, r309, r314, Completed_4;
local fenv = getfenv();
if not pcall(function(p1, a, b, c)

end) then
else 
    Players = game:GetService("Players");
end;
game:GetService("Workspace");
game:GetService("VirtualInputManager");
game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local LocalPlayer = Players.LocalPlayer;
LocalPlayer.CharacterAdded:Connect(function(character, a_2, b_2, c_2)
    Humanoid = character:WaitForChild("Humanoid");
    if not r30 then
    else 
        r30:Disconnect();
    end;
    if not Humanoid then
    else 
        Humanoid.AnimationPlayed:Connect(function(p1_11, p2_11, p3_11, a_11, b_11, c_11)
            if pcall(function(p1_12, p2_12, p3_12, p4_12, p5_12, a_12, b_12, c_12)
                if not p1_11 then
                else 
                    if p1_11.Animation then 
                        Tostring_Result = tostring(p1_11.Animation.AnimationId);
                    end;
                end;
                if Tostring_Result then 
                end;
                return Tostring_Result;
            end) then 
            end;
        end);
    end;
end);
local Character = LocalPlayer.Character;
if not Character then
else 
    Humanoid_2 = Character:WaitForChild("Humanoid");
end;
if not Humanoid_2 then
else 
    r30 = Humanoid_2.AnimationPlayed:Connect(function(p1_3, p2_3, p3_3, a_3, b_3, c_3)
        local success_1, r158 = pcall(function(p1_4, p2_4, p3_4, p4_4, p5_4, a_4, b_4, c_4)
            if not p1_3 then
            else 
                if p1_3.Animation then 
                    Tostring_Result_2 = tostring(p1_3.Animation.AnimationId);
                end;
            end;
            if Tostring_Result_2 then 

            end;
            return Tostring_Result_2;
        end);
        if success_1 then 

        end;
        if (r158 == "rbxassetid://12273188754") then
        else 

        end;
    end);
end;
local ScreenGui = Instance.new"ScreenGui";
ScreenGui.Parent = game:GetService("CoreGui");
ScreenGui.ResetOnSpawn = false;
local On = Instance.new"TextButton";
local UDim2_New = UDim2.new;
On.Size = UDim2_New(0, 80, 0, 40);
On.Position = UDim2_New(0, 50, 0, 50);
local FromRGB = Color3.fromRGB;
On.BackgroundColor3 = FromRGB(255, 255, 255);
On.Text = "On";
On.TextColor3 = FromRGB(0, 0, 0);
On.Font = Enum.Font.SourceSansBold;
On.TextSize = 22;
On.Parent = ScreenGui;
local UICorner = Instance.new"UICorner";
local UDim_New = UDim.new;
UICorner.CornerRadius = UDim_New(0, 10);
UICorner.Parent = On;
local Sound = Instance.new"Sound";
Sound.SoundId = "rbxassetid://6042053626";
Sound.Volume = 1;
Sound.Parent = On;
On.InputBegan:Connect(function(input, a_5, b_5, c_5)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then 

    end;
    if input.UserInputType ~= Enum.UserInputType.Touch then 

    end;
end);
On.InputChanged:Connect(function(input_1, p2_6, p3_6, a_6, b_6, c_6)
    if (input_1.UserInputType == Enum.UserInputType.MouseMovement) then
    else 
        UserInputType_Is_Touch = (input_1.UserInputType == Enum.UserInputType.Touch);
    end;
    if UserInputType_Is_Touch then
    else 

    end;
    if not UserInputType_Is_Touch then 

    end;
end);
On.MouseButton1Click:Connect(function(p1_7, a_7, b_7, c_7)
    On.Text = "Off";
    Sound:Play();
    TweenInfo_New = TweenInfo.new;
    r200 = TweenService:Create(On, TweenInfo_New(0.1), {
        ["Size"] = UDim2_New(0, 72, 0, 36)
    });
    r200:Play();
    r200.Completed:Connect(function(p1_13, p2_13, p3_13, p4_13, p5_13, a_13, b_13, c_13)
        TweenService:Create(On, TweenInfo_New(0.1), {
            ["Size"] = UDim2_New(0, 80, 0, 40)
        }):Play();
    end);
end);
local Frame = Instance.new"Frame";
Frame.Size = UDim2_New(0, 150, 0, 60);
Frame.Position = UDim2_New(0, 150, 0, 50);
Frame.BackgroundColor3 = FromRGB(255, 255, 255);
Frame.BackgroundTransparency = 0.3;
Frame.Parent = ScreenGui;
Frame.Active = true;
Frame.Draggable = true;
local UICorner_2 = Instance.new"UICorner";
UICorner_2.CornerRadius = UDim_New(0, 10);
UICorner_2.Parent = Frame;
local Delay_1_5 = Instance.new"TextLabel";
Delay_1_5.Size = UDim2_New(1, -20, 0, 25);
Delay_1_5.Position = UDim2_New(0, 10, 0, 5);
Delay_1_5.BackgroundTransparency = 1;
Delay_1_5.Text = "Delay: 1.5";
Delay_1_5.TextColor3 = FromRGB(0, 0, 0);
Delay_1_5.Font = Enum.Font.SourceSansBold;
Delay_1_5.TextScaled = true;
Delay_1_5.Parent = Frame;
local TextButton = Instance.new"TextButton";
TextButton.Size = UDim2_New(0, 28, 0, 28);
TextButton.Position = UDim2_New(0, 10, 0, 26);
TextButton.BackgroundColor3 = FromRGB(255, 255, 255);
TextButton.BackgroundTransparency = 0.3;
TextButton.Text = "-";
TextButton.TextColor3 = FromRGB(0, 0, 0);
TextButton.Font = Enum.Font.SourceSansBold;
TextButton.TextSize = 22;
TextButton.Parent = Frame;
local UICorner_3 = Instance.new"UICorner";
UICorner_3.CornerRadius = UDim_New(0, 14);
UICorner_3.Parent = TextButton;
local TextButton_2 = Instance.new"TextButton";
TextButton_2.Size = UDim2_New(0, 28, 0, 28);
TextButton_2.Position = UDim2_New(0, 112, 0, 26);
TextButton_2.BackgroundColor3 = FromRGB(255, 255, 255);
TextButton_2.BackgroundTransparency = 0.3;
TextButton_2.Text = "+";
TextButton_2.TextColor3 = FromRGB(0, 0, 0);
TextButton_2.Font = Enum.Font.SourceSansBold;
TextButton_2.TextSize = 22;
TextButton_2.Parent = Frame;
local UICorner_4 = Instance.new"UICorner";
UICorner_4.CornerRadius = UDim_New(0, 14);
UICorner_4.Parent = TextButton_2;
local TextButton_3 = Instance.new"TextButton";
TextButton_3.Size = UDim2_New(0, 24, 0, 24);
TextButton_3.Position = UDim2_New(1, -30, 0, 6);
TextButton_3.BackgroundColor3 = FromRGB(255, 255, 255);
TextButton_3.BackgroundTransparency = 0.3;
TextButton_3.Text = "-";
TextButton_3.TextColor3 = FromRGB(0, 0, 0);
TextButton_3.Font = Enum.Font.SourceSansBold;
TextButton_3.TextSize = 18;
TextButton_3.Parent = Frame;
local UICorner_5 = Instance.new"UICorner";
UICorner_5.CornerRadius = UDim_New(0, 12);
UICorner_5.Parent = TextButton_3;
TextButton_3.MouseButton1Click:Connect(function(p1_8, p2_8, p3_8, a_8, b_8, c_8)
    Delay_1_5.Visible = false;
    TextButton.Visible = false;
    TextButton_2.Visible = false;
    TextButton_3.Text = "+";
    Size = TextButton_3.Size;
    Sound:Play();
    r237 = TweenService:Create(TextButton_3, TweenInfo_New(0.08), {
        ["Size"] = UDim2_New(
            Size.X.Scale,
            math.max(
                6,
                Size.X.Offset - 8
            ),
            Size.Y.Scale,
            math.max(
                6,
                Size.Y.Offset - 4
            )
        )
    });
    r237:Play();
    r237.Completed:Connect(function(p1_14, p2_14, a_14, b_14, c_14)
        TweenService:Create(TextButton_3, TweenInfo_New(0.08), {
            ["Size"] = Size
        }):Play();
    end);
end);
TextButton.MouseButton1Click:Connect(function(a_9, b_9, c_9)
    Delay_1_5.Text = "Delay: 1.4";
    Size_2 = TextButton.Size;
    Sound:Play();
    r273 = TweenService:Create(TextButton, TweenInfo_New(0.08), {
        ["Size"] = UDim2_New(
            Size_2.X.Scale,
            math.max(
                6,
                Size_2.X.Offset - 8
            ),
            Size_2.Y.Scale,
            math.max(
                6,
                Size_2.Y.Offset - 4
            )
        )
    });
    r273:Play();
    r273.Completed:Connect(function(p1_15, p2_15, a_15, b_15, c_15)
        TweenService:Create(TextButton, TweenInfo_New(0.08), {
            ["Size"] = Size_2
        }):Play();
    end);
end);
TextButton_2.MouseButton1Click:Connect(function(p1_10, p2_10, p3_10, p4_10, a_10, b_10, c_10)
    Delay_1_5.Text = "Delay: 1.5";
    Size_3 = TextButton_2.Size;
    Sound:Play();
    r309 = TweenService:Create(TextButton_2, TweenInfo_New(0.08), {
        ["Size"] = UDim2_New(
            Size_3.X.Scale,
            math.max(
                6,
                Size_3.X.Offset - 8
            ),
            Size_3.Y.Scale,
            math.max(
                6,
                Size_3.Y.Offset - 4
            )
        )
    });
    r309:Play();
    r309.Completed:Connect(function(p1_16, p2_16, a_16, b_16, c_16)
        TweenService:Create(TextButton_2, TweenInfo_New(0.08), {
            ["Size"] = Size_3
        }):Play();
    end);
end);
Delay_1_5.Text = "Delay: 1.5";
local Khengie_Slayer_In_Discord = Instance.new"TextLabel";
Khengie_Slayer_In_Discord.Size = UDim2_New(0, 250, 0, 25);
Khengie_Slayer_In_Discord.Position = UDim2_New(0, 10, 0, 10);
Khengie_Slayer_In_Discord.BackgroundTransparency = 1;
Khengie_Slayer_In_Discord.Text = "khengie_slayer in discord";
Khengie_Slayer_In_Discord.TextColor3 = FromRGB(255, 255, 255);
Khengie_Slayer_In_Discord.TextTransparency = 0.3;
Khengie_Slayer_In_Discord.TextScaled = true;
Khengie_Slayer_In_Discord.Font = Enum.Font.Arcade;
Khengie_Slayer_In_Discord.Parent = ScreenGui;