--[[ Generated @ dsc.gg/6vms ]]

local PlaceId_Is_Number, CamlockUI, CamlockUI_2, TweenInfo_New, r447, r460, r486, r499, r525, r538, r564, r577, r599, r612, R48_Result, r629, r643, Text, String_Upper_Result, R48_Result_2, r678, r692, UserInputType_Is_Touch, r334, r347, r360, r377, r390, r741, r756, r775, r790, r801, Not_GameProcessedEvent_1, Typeof_Result_Is_EnumItem, Not_PlaceId_2_Is_Number_2, ViewportSize, Character, Workspace_Live, Weakest_Dummy, CamlockKeyConn, CamlockUI_3;
local fenv = getfenv();
if not pcall(function(p1, p2, p3, p4, p5, a, b, c)

end) then
else 
    if not getgenv().CamlockDisconnect then
    else 
        pcall(function(p1_3, p2_3, p3_3, p4_3, a_3, b_3, c_3)
            getgenv().CamlockDisconnect();
        end);
    end;
end;
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
game:GetService("Workspace");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local LocalPlayer = Players.LocalPlayer;
local CurrentCamera = workspace.CurrentCamera;
if LocalPlayer.Character then 
    PlaceId_Is_Number = (game.PlaceId == 10449761463);
end;
LocalPlayer.CharacterAdded:Connect(function(character, p2_4, p3_4, p4_4, a_4, b_4, c_4)
    wait(1);
    if getgenv().CamlockUI then 
        getgenv().CamlockUI.Parent = LocalPlayer:WaitForChild("PlayerGui");
    end;
    local _ = Enum.ZIndexBehavior.Global;
    r42.ZIndexBehavior = Enum.ZIndexBehavior.Global;
end);
local _ = Enum.KeyCode.C;
local _ = LocalPlayer:FindFirstChild("PlayerGui") and 6473;
local PlayerGui = LocalPlayer.PlayerGui;
if not PlayerGui:FindFirstChild("CamlockUI") then
else 
    PlayerGui.CamlockUI:Destroy();
end;
r42 = Instance.new"ScreenGui";
r42.Name = "CamlockUI";
r42.ResetOnSpawn = false;
r42.ZIndexBehavior = Enum.ZIndexBehavior.Global;
r42.Parent = LocalPlayer:WaitForChild("PlayerGui");
getgenv().CamlockUI = r42;
local Camlock_Off = Instance.new"TextButton";
local UDim2_New = UDim2.new;
Camlock_Off.Size = UDim2_New(0, 160, 0, 50);
Camlock_Off.Position = UDim2_New(0.5, -80, 0, -100);
local FromRGB = Color3.fromRGB;
Camlock_Off.BackgroundColor3 = FromRGB(143, 0, 255);
local Color3_New = Color3.new;
Camlock_Off.TextColor3 = Color3_New(1, 1, 1);
Camlock_Off.Text = "Camlock: Off";
Camlock_Off.Font = Enum.Font.GothamBold;
Camlock_Off.TextSize = 18;
Camlock_Off.BorderSizePixel = 0;
Camlock_Off.AutoButtonColor = true;
Camlock_Off.ZIndex = 10;
Camlock_Off.Parent = r42;
local UIGradient = Instance.new("UIGradient", Camlock_Off);
local ColorSequenceKeypoint_New = ColorSequenceKeypoint.new;
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint_New(
        0,
        FromRGB(200, 150, 255)
    ),
    ColorSequenceKeypoint_New(
        1,
        FromRGB(143, 0, 255)
    )
};
UIGradient.Rotation = 45;
local UDim_New = UDim.new;
Instance.new("UICorner", Camlock_Off).CornerRadius = UDim_New(0, 12);
local By_Khengie_Slayer = Instance.new"TextLabel";
By_Khengie_Slayer.Size = UDim2_New(0, 300, 0, 40);
By_Khengie_Slayer.Position = UDim2_New(0.5, -150, 0, 20);
By_Khengie_Slayer.BackgroundTransparency = 1;
By_Khengie_Slayer.TextColor3 = FromRGB(143, 0, 255);
By_Khengie_Slayer.Text = "By khengie_slayer";
By_Khengie_Slayer.Font = Enum.Font.GothamBold;
By_Khengie_Slayer.TextSize = 28;
By_Khengie_Slayer.TextTransparency = 1;
By_Khengie_Slayer.TextStrokeTransparency = 1;
By_Khengie_Slayer.TextStrokeColor3 = FromRGB(200, 150, 255);
By_Khengie_Slayer.ZIndex = 10;
By_Khengie_Slayer.Parent = r42;
UIGradient:Clone().Parent = By_Khengie_Slayer;
local V3 = Instance.new"TextLabel";
V3.Size = UDim2_New(0, 300, 0, 35);
V3.Position = UDim2_New(0.5, -150, 0, 65);
V3.BackgroundTransparency = 1;
V3.TextColor3 = FromRGB(143, 0, 255);
V3.Text = "V3";
V3.Font = Enum.Font.GothamBold;
V3.TextSize = 24;
V3.TextTransparency = 1;
V3.TextStrokeTransparency = 1;
V3.TextStrokeColor3 = FromRGB(200, 150, 255);
V3.ZIndex = 10;
V3.Parent = r42;
UIGradient:Clone().Parent = V3;
local Regex = Instance.new"TextButton";
Regex.Size = UDim2_New(0, 20, 0, 20);
Regex.Position = UDim2_New(0.5, -10, 0, -60);
Regex.BackgroundColor3 = FromRGB(143, 0, 255);
Regex.TextColor3 = Color3_New(1, 1, 1);
Regex.Text = "^";
Regex.Font = Enum.Font.GothamBold;
Regex.TextSize = 16;
Regex.BorderSizePixel = 0;
Regex.AutoButtonColor = false;
Regex.ZIndex = 10;
Regex.Parent = Camlock_Off;
Instance.new("UICorner", Regex).CornerRadius = UDim_New(1, 0);
UIGradient:Clone().Parent = Regex;
local TextButton = Instance.new"TextButton";
TextButton.Size = UDim2_New(0, 24, 0, 24);
TextButton.Position = UDim2_New(0, -29, 0, 0);
TextButton.BackgroundColor3 = FromRGB(143, 0, 255);
TextButton.TextColor3 = Color3_New(1, 1, 1);
TextButton.Text = "��";
TextButton.Font = Enum.Font.GothamBold;
TextButton.TextSize = 14;
TextButton.BorderSizePixel = 0;
TextButton.AutoButtonColor = false;
TextButton.ZIndex = 10;
TextButton.Parent = Camlock_Off;
Instance.new("UICorner", TextButton).CornerRadius = UDim_New(1, 0);
UIGradient:Clone().Parent = TextButton;
local Frame = Instance.new"Frame";
Frame.Size = UDim2_New(0, 160, 0, 0);
Frame.Position = UDim2_New(0, -29, 0, -5);
Frame.BackgroundColor3 = FromRGB(143, 0, 255);
Frame.BorderSizePixel = 0;
Frame.Visible = false;
Frame.ClipsDescendants = true;
Frame.ZIndex = 11;
Frame.Parent = Camlock_Off;
Instance.new("UICorner", Frame).CornerRadius = UDim_New(0, 12);
UIGradient:Clone().Parent = Frame;
local TextBox = Instance.new"TextBox";
TextBox.Size = UDim2_New(0, 20, 0, 20);
TextBox.Position = UDim2_New(0, -27, 0, 27);
TextBox.BackgroundColor3 = FromRGB(143, 0, 255);
TextBox.TextColor3 = Color3_New(1, 1, 1);
TextBox.PlaceholderText = "0.45";
TextBox.Text = "0.45";
TextBox.Font = Enum.Font.GothamBold;
TextBox.TextSize = 11;
TextBox.BorderSizePixel = 0;
TextBox.ClearTextOnFocus = true;
TextBox.Visible = false;
TextBox.ZIndex = 10;
TextBox.Parent = Camlock_Off;
UIGradient:Clone().Parent = TextBox;
Instance.new("UICorner", TextBox).CornerRadius = UDim_New(0, 8);
local Custom = Instance.new"TextButton";
Custom.Size = UDim2_New(1, -10, 0, 35);
Custom.Position = UDim2_New(0, 5, 0, 5);
Custom.BackgroundColor3 = FromRGB(143, 0, 255);
Custom.TextColor3 = Color3_New(1, 1, 1);
Custom.Text = "Custom";
Custom.Font = Enum.Font.GothamBold;
Custom.TextSize = 14;
Custom.BorderSizePixel = 0;
Custom.AutoButtonColor = false;
Custom.ZIndex = 12;
Custom.Parent = Frame;
Instance.new("UICorner", Custom).CornerRadius = UDim_New(0, 8);
UIGradient:Clone().Parent = Custom;
local Smooth = Instance.new"TextButton";
Smooth.Size = UDim2_New(1, -10, 0, 35);
Smooth.Position = UDim2_New(0, 5, 0, 45);
Smooth.BackgroundColor3 = FromRGB(143, 0, 255);
Smooth.TextColor3 = Color3_New(1, 1, 1);
Smooth.Text = "Smooth";
Smooth.Font = Enum.Font.GothamBold;
Smooth.TextSize = 14;
Smooth.BorderSizePixel = 0;
Smooth.AutoButtonColor = false;
Smooth.ZIndex = 12;
Smooth.Parent = Frame;
Instance.new("UICorner", Smooth).CornerRadius = UDim_New(0, 8);
UIGradient:Clone().Parent = Smooth;
local Fast = Instance.new"TextButton";
Fast.Size = UDim2_New(1, -10, 0, 35);
Fast.Position = UDim2_New(0, 5, 0, 85);
Fast.BackgroundColor3 = FromRGB(143, 0, 255);
Fast.TextColor3 = Color3_New(1, 1, 1);
Fast.Text = "Fast";
Fast.Font = Enum.Font.GothamBold;
Fast.TextSize = 14;
Fast.BorderSizePixel = 0;
Fast.AutoButtonColor = false;
Fast.ZIndex = 12;
Fast.Parent = Frame;
Instance.new("UICorner", Fast).CornerRadius = UDim_New(0, 8);
UIGradient:Clone().Parent = Fast;
Fast.BackgroundColor3 = FromRGB(200, 150, 255);
local Instant = Instance.new"TextButton";
Instant.Size = UDim2_New(1, -10, 0, 35);
Instant.Position = UDim2_New(0, 5, 0, 125);
Instant.BackgroundColor3 = FromRGB(143, 0, 255);
Instant.TextColor3 = Color3_New(1, 1, 1);
Instant.Text = "Instant";
Instant.Font = Enum.Font.GothamBold;
Instant.TextSize = 14;
Instant.BorderSizePixel = 0;
Instant.AutoButtonColor = false;
Instant.ZIndex = 12;
Instant.Parent = Frame;
Instance.new("UICorner", Instant).CornerRadius = UDim_New(0, 8);
UIGradient:Clone().Parent = Instant;
local TextBox_2 = Instance.new"TextBox";
TextBox_2.Size = UDim2_New(0, 85, 0, 30);
TextBox_2.Position = UDim2_New(0.5, -42, 1, 5);
TextBox_2.BackgroundColor3 = FromRGB(143, 0, 255);
TextBox_2.TextColor3 = Color3_New(1, 1, 1);
TextBox_2.PlaceholderText = "0.65";
TextBox_2.Text = "0.65";
TextBox_2.Font = Enum.Font.GothamBold;
TextBox_2.TextSize = 14;
TextBox_2.BorderSizePixel = 0;
TextBox_2.ClearTextOnFocus = true;
TextBox_2.Visible = false;
TextBox_2.ZIndex = 10;
TextBox_2.Parent = Camlock_Off;
UIGradient:Clone().Parent = TextBox_2;
Instance.new("UICorner", TextBox_2).CornerRadius = UDim_New(0, 18);
Custom.MouseButton1Click:Connect(function(p1_5, p2_5, p3_5, p4_5, a_5, b_5, c_5)
    Custom.BackgroundColor3 = FromRGB(200, 150, 255);
    Smooth.BackgroundColor3 = FromRGB(143, 0, 255);
    Fast.BackgroundColor3 = FromRGB(143, 0, 255);
    Instant.BackgroundColor3 = FromRGB(143, 0, 255);
    TextBox.Visible = true;
    TextBox.Text = "0.45";
    TextBox_2.Text = "0.45";
    TweenService:Create(Frame, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, -5),
        ["Size"] = UDim2_New(0, 160, 0, 0)
    }):Play();
    TweenService:Create(TextButton, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, 0)
    }):Play();
    wait(0.3);
    Frame.Visible = false;
    TextButton.Text = "��";
end);
Smooth.MouseButton1Click:Connect(function(p1_6, p2_6, a_6, b_6, c_6)
    Custom.BackgroundColor3 = FromRGB(143, 0, 255);
    Smooth.BackgroundColor3 = FromRGB(200, 150, 255);
    Fast.BackgroundColor3 = FromRGB(143, 0, 255);
    Instant.BackgroundColor3 = FromRGB(143, 0, 255);
    TextBox.Visible = false;
    TextBox.Text = "0.25";
    TextBox_2.Text = "0.25";
    TweenService:Create(Frame, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, -5),
        ["Size"] = UDim2_New(0, 160, 0, 0)
    }):Play();
    TweenService:Create(TextButton, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, 0)
    }):Play();
    wait(0.3);
    Frame.Visible = false;
    TextButton.Text = "��";
end);
Fast.MouseButton1Click:Connect(function(a_7, b_7, c_7)
    Custom.BackgroundColor3 = FromRGB(143, 0, 255);
    Smooth.BackgroundColor3 = FromRGB(143, 0, 255);
    Fast.BackgroundColor3 = FromRGB(200, 150, 255);
    Instant.BackgroundColor3 = FromRGB(143, 0, 255);
    TextBox.Visible = false;
    TextBox.Text = "0.67";
    TextBox_2.Text = "0.67";
    TweenService:Create(Frame, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, -5),
        ["Size"] = UDim2_New(0, 160, 0, 0)
    }):Play();
    TweenService:Create(TextButton, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, 0)
    }):Play();
    wait(0.3);
    Frame.Visible = false;
    TextButton.Text = "��";
end);
Instant.MouseButton1Click:Connect(function(p1_8, p2_8, p3_8, p4_8, a_8, b_8, c_8)
    Custom.BackgroundColor3 = FromRGB(143, 0, 255);
    Smooth.BackgroundColor3 = FromRGB(143, 0, 255);
    Fast.BackgroundColor3 = FromRGB(143, 0, 255);
    Instant.BackgroundColor3 = FromRGB(200, 150, 255);
    TextBox.Visible = false;
    TextBox.Text = "6.7";
    TextBox_2.Text = "6.7";
    TweenService:Create(Frame, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, -5),
        ["Size"] = UDim2_New(0, 160, 0, 0)
    }):Play();
    TweenService:Create(TextButton, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, 0)
    }):Play();
    wait(0.3);
    Frame.Visible = false;
    TextButton.Text = "��";
end);
TextBox.FocusLost:Connect(function(enterPressed, inputThatCausedFocusLoss, p3_9, p4_9, a_9, b_9, c_9)
    if tonumber(TextBox.Text) then 

    end;
end);
TextButton.MouseButton1Click:Connect(function(p1_10, p2_10, p3_10, p4_10, a_10, b_10, c_10)
    TextButton.Text = "��";
    Frame.Visible = true;
    TweenService:Create(Frame, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, -165),
        ["Size"] = UDim2_New(0, 160, 0, 160)
    }):Play();
    TweenService:Create(TextButton, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, -190)
    }):Play();
end);
local TextButton_2 = Instance.new"TextButton";
TextButton_2.Size = UDim2_New(0, 24, 0, 24);
TextButton_2.Position = UDim2_New(1, 5, 0.5, -12);
TextButton_2.BackgroundColor3 = FromRGB(143, 0, 255);
TextButton_2.TextColor3 = Color3_New(1, 1, 1);
TextButton_2.Text = "��";
TextButton_2.Font = Enum.Font.GothamBold;
TextButton_2.TextSize = 16;
TextButton_2.BorderSizePixel = 0;
TextButton_2.AutoButtonColor = false;
TextButton_2.ZIndex = 10;
TextButton_2.Parent = Camlock_Off;
Instance.new("UICorner", TextButton_2).CornerRadius = UDim_New(1, 0);
local C = Instance.new"TextBox";
C.Size = UDim2_New(0, 85, 0, 30);
C.Position = UDim2_New(0.5, -42, 0, -35);
C.BackgroundColor3 = FromRGB(143, 0, 255);
C.TextColor3 = Color3_New(1, 1, 1);
C.PlaceholderText = "Keybind";
C.Text = "C";
C.Font = Enum.Font.GothamBold;
C.TextSize = 14;
C.BorderSizePixel = 0;
C.ClearTextOnFocus = false;
C.ZIndex = 10;
C.Parent = Camlock_Off;
UIGradient:Clone().Parent = C;
Instance.new("UICorner", C).CornerRadius = UDim_New(0, 18);
Regex.MouseButton1Click:Connect(function(p1_11, a_11, b_11, c_11)
    Regex.Text = "v";
    R48_Result = UDim2_New(0.5, -10, 0, -25);
    if R48_Result then 

    end;
    TweenService:Create(C, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0.5, -42, 0, 10)
    }):Play();
    wait(0.15);
    C.Visible = false;
    TweenService:Create(Regex, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = R48_Result
    }):Play();
end);
C.FocusLost:Connect(function(enterPressed_1, inputThatCausedFocusLoss_1, a_12, b_12, c_12)
    Text = C.Text;
    String_Upper_Result = string.upper(Text);
    if #String_Upper_Result == 1 then 

    end;
    local _ = not string.match(String_Upper_Result, "%a");
    if not Enum.KeyCode.C then
    else 

    end;
end);
local Regex_2 = Instance.new"TextButton";
Regex_2.Size = UDim2_New(0, 20, 0, 20);
Regex_2.Position = UDim2_New(0.5, -10, 1, 40);
Regex_2.BackgroundColor3 = FromRGB(143, 0, 255);
Regex_2.TextColor3 = Color3_New(1, 1, 1);
Regex_2.Text = "^";
Regex_2.Font = Enum.Font.GothamBold;
Regex_2.TextSize = 16;
Regex_2.BorderSizePixel = 0;
Regex_2.Visible = false;
Regex_2.ZIndex = 10;
Regex_2.Parent = Camlock_Off;
UIGradient:Clone().Parent = Regex_2;
Instance.new("UICorner", Regex_2).CornerRadius = UDim_New(1, 0);
Regex_2.MouseButton1Click:Connect(function(a_13, b_13, c_13)
    Regex_2.Text = "v";
    R48_Result_2 = UDim2_New(0.5, -10, 1, 5);
    if R48_Result_2 then 

    end;
    TweenService:Create(TextBox_2, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0.5, -42, 1, -30)
    }):Play();
    wait(0.15);
    TextBox_2.Visible = false;
    TweenService:Create(Regex_2, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = R48_Result_2
    }):Play();
end);
TextBox_2.FocusLost:Connect(function(a_14, b_14, c_14)
    if tonumber(TextBox_2.Text) then 

    end;
end);
Camlock_Off.InputBegan:Connect(function(input, a_15, b_15, c_15)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then 

    end;
    if input.UserInputType ~= Enum.UserInputType.Touch then 

    end;
end);
UserInputService.InputEnded:Connect(function(input_1, gameProcessedEvent, p3_16, p4_16, p5_16, a_16, b_16, c_16)
    if (input_1.UserInputType == Enum.UserInputType.MouseButton1) then
    else 
        UserInputType_Is_Touch = (input_1.UserInputType == Enum.UserInputType.Touch);
    end;
    if UserInputType_Is_Touch then
    else 

    end;
    if UserInputType_Is_Touch then
    else 

    end;
end);
spawn(function()
    r324 = TweenInfo.new;
    TweenService:Create(Camlock_Off, r324(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0.5, -80, 0.5, -25)
    }):Play();
    wait(0.6);
    TweenService:Create(By_Khengie_Slayer, r324(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["TextTransparency"] = 0,
        ["TextStrokeTransparency"] = 0.5
    }):Play();
    wait(1);
    TweenService:Create(V3, r324(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["TextTransparency"] = 0,
        ["TextStrokeTransparency"] = 0.5
    }):Play();
    wait(8);
    TweenService:Create(V3, r324(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Size"] = UDim2_New(0, 60, 0, 20),
        ["TextSize"] = 14,
        ["Position"] = UDim2_New(1, -80, 0, 10)
    }):Play();
    wait(1);
    TweenService:Create(By_Khengie_Slayer, r324(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["TextTransparency"] = 1,
        ["TextStrokeTransparency"] = 1
    }):Play();
    wait(0.5);
end);
Camlock_Off.MouseButton1Click:Connect(function(p1_17, p2_17, p3_17, p4_17, p5_17, a_17, b_17, c_17)
    Camlock_Off.Text = "Camlock: On";
end);
TextButton_2.MouseButton1Click:Connect(function(p1_18, p2_18, p3_18, p4_18, a_18, b_18, c_18)
    TweenService:Create(TextButton, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Size"] = UDim2_New(0, 0, 0, 0)
    }):Play();
    TweenService:Create(Frame, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0, -5),
        ["Size"] = UDim2_New(0, 160, 0, 0)
    }):Play();
    wait(0.3);
    Frame.Visible = false;
    wait(0.15);
    TextButton.Visible = false;
    TextBox_2.Visible = true;
    TextBox_2.Position = UDim2_New(0.5, -42, 1, 40);
    TweenService:Create(TextBox_2, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0.5, -42, 1, 5)
    }):Play();
    Regex_2.Visible = true;
    Regex_2.Position = UDim2_New(0.5, -10, 1, 70);
    TweenService:Create(Regex_2, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0.5, -10, 1, 40)
    }):Play();
    TweenService:Create(TextButton_2, r324(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Position"] = UDim2_New(0, -29, 0.5, -12)
    }):Play();
    Camlock_Off.Text = "Aim: On";
end);
getgenv().CamlockKeyConn = UserInputService.InputBegan:Connect(function(input_2, gameProcessedEvent_1, p3_19, p4_19, p5_19, p6_19, a_19, b_19, c_19)
    Not_GameProcessedEvent_1 = not gameProcessedEvent_1;
    if not Not_GameProcessedEvent_1 then 

    end;
    if Not_GameProcessedEvent_1 then
    else 

    end;
end);
getgenv().CamlockSetKeybind = function(p1_20, p2_20, p3_20, a_20, b_20, c_20)
    if typeof(p1_20) == "string" then
    else 

    end;
    Typeof_Result_Is_EnumItem = (typeof(p1_20) == "EnumItem");
    if Typeof_Result_Is_EnumItem then
    else 

    end;
    if Typeof_Result_Is_EnumItem then
    else 

    end;
end;
tick();
local _ = PlaceId_Is_Number and 0;
RunService:BindToRenderStep("CamlockStep", Enum.RenderPriority.Camera.Value + 1, function(p1_21, p2_21, p3_21, p4_21, a_21, b_21, c_21)
    tick();
    Not_PlaceId_2_Is_Number_2 = not PlaceId_Is_Number;
    if Not_PlaceId_2_Is_Number_2 then
    else 

    end;
    if Not_PlaceId_2_Is_Number_2 then
    else 
        ViewportSize = CurrentCamera.ViewportSize;
    end;
    Vector2.new(
        ViewportSize.X / 2,
        ViewportSize.Y / 2
    );
    for for_key_0, for_val_0 in ipairs(Players:GetPlayers()) do
        if for_key_0 then 

        end;
        if (for_val_0 ~= LocalPlayer) then 
            if not for_val_0.Character then
            else 

            end;
        end;
        if for_val_0.Character:FindFirstChild("HumanoidRootPart") then 
            CurrentCamera:WorldToViewportPoint(for_val_0.Character.HumanoidRootPart.Position);
        end;
    end;
    if not PlaceId_Is_Number then
    else 
        Weakest_Dummy = workspace.Live:FindFirstChild("Weakest Dummy");
    end;
    if Weakest_Dummy then 

    end;
    if not Weakest_Dummy:FindFirstChild("HumanoidRootPart") then
    else 

    end;
    if Weakest_Dummy:FindFirstChildOfClass("Humanoid") then 
        CurrentCamera:WorldToViewportPoint(Weakest_Dummy.HumanoidRootPart.Position);
    end;
end);
getgenv().CamlockDisconnect = function(a_22, b_22, c_22)
    pcall(function(a_23, b_23, c_23)
        RunService:UnbindFromRenderStep("CamlockStep");
    end);
    pcall(function(p1_24, p2_24, p3_24, p4_24, p5_24, a_24, b_24, c_24)
        if getgenv().CamlockKeyConn then 
            getgenv().CamlockKeyConn:Disconnect();
        end;
        getgenv().CamlockKeyConn = nil;
    end);
    pcall(function(p1_25, p2_25, p3_25, a_25, b_25, c_25)

    end);
    pcall(function(p1_26, p2_26, p3_26, p4_26, a_26, b_26, c_26)
        if getgenv().CamlockUI then 
            CamlockUI_3 = getgenv().CamlockUI;
            CamlockUI_3:Destroy();
            r42:Destroy();
        end;
        getgenv().CamlockUI = nil;
    end);
end;