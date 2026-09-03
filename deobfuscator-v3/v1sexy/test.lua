--[=[do
    local valid = 'Xa2LYlqyvpa0W';
    --for i = 0, 6 do
        --[[if i == 0 then
            if valid ~= 'Xa2LYlqyvpa0W' then
                while true do end; 
            end;
            valid = true;
        elseif i == 1 then
            if valid == true then                  
            end;
        elseif i == 2 then
            valid = true;
        elseif i == 3 then
            if valid == true then                 
            else
                while true do end; 
            end;
        elseif i == 4 then
            valid = false;
        elseif i == 5 then
            if valid == false then                 
            else
                while true do end; 
            end;
        elseif i == 6 then
            valid = true; 
        end; ]]
        if i == 0 then
            print("nice")
        end
    --end;
    do
        valid = true; 
    end; 
end;]=]
--[[local random = math.random;
local valid = true

local acc1 = 0;
local acc2 = 0;

for i = 1, random(3, 65) do
    local len = math.random(1, 100);
	local n2 = random(0, 255);
	local pos = random(1, len);
	local shouldErr = random(1, 2) == 1;
    local arr = { pcall(function() error("MEOW") end) }
    local msg = "hi"

    if shouldErr then
		valid = valid and arr[1] == false and arr[2] == msg;
	else
		valid = valid and arr[1];
		acc1 = (acc1 + arr[pos + 1]) % 256;
		acc2 = (acc2 + n2) % 256;
	end
end]]
--[[local shouldErr = math.random(1, 2) == 2
if shouldErr then
    print("in true")
    valid = valid and arr[1] == false
else
    valid = valid and arr[1]
    print("in else")
end]]
--[[local valid = { 1, 2, 3 }
--valid = valid and arr[1] == false and arr[2] == msg
print(valid)
print(valid)
print(valid + 3)
print(valid - 16)

valid = new

print(valid)
print(valid)]]
--print("Hello, world! (From encrypted strings)")
--[[for i = 1, math.random(1, 5) do
	if shouldErr then
		valid = valid and arr[1] == false and arr[2] == msg;
	else
		valid = valid and arr[1];
		acc1 = (acc1 + arr[pos + 1]) % 256;
		acc2 = (acc2 + n2) % 256;
	end
end

print("Done")]]
--[[if true then
    print('true')
elseif a then
    print('a')
else
    print("false")
end

print("Afterwards")]]

VA[68] = 16257660198290;
VA[67] = "\xaf\x11p\x99\xed\xbf\x86\nV";
VA[66] = VA[65](VA[67], VA[68]);