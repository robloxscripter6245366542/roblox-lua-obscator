-- Download module for GraniteLock obfuscation tool
-- Handles creating zip files and downloading obfuscated scripts

local download = {}

-- Check if we have access to required libraries
local function getZipLibrary()
    -- Try common zip libraries available in Lua
    local success, zip = pcall(require, "zip")
    if success then
        return zip
    end
    return nil
end

-- Create a simple base64 encoder for file compression
local base64Charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Encode(data)
    local result = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i), data:byte(i + 1), data:byte(i + 2)
        local bitmap = bit.bor(
            bit.lshift(a or 0, 16),
            bit.lshift(b or 0, 8),
            c or 0
        )
        
        result[#result + 1] = base64Charset:sub(bit.rshift(bitmap, 18) + 1, bit.rshift(bitmap, 18) + 1)
        result[#result + 1] = base64Charset:sub(bit.band(bit.rshift(bitmap, 12), 63) + 1, bit.band(bit.rshift(bitmap, 12), 63) + 1)
        
        if b then
            result[#result + 1] = base64Charset:sub(bit.band(bit.rshift(bitmap, 6), 63) + 1, bit.band(bit.rshift(bitmap, 6), 63) + 1)
        else
            result[#result + 1] = "="
        end
        
        if c then
            result[#result + 1] = base64Charset:sub(bit.band(bitmap, 63) + 1, bit.band(bitmap, 63) + 1)
        else
            result[#result + 1] = "="
        end
    end
    return table.concat(result)
end

-- Create a zip file structure
function download.createZip(files)
    --[[
    files: table of {filename = "name.lua", content = "script content"}
    Returns: zip file content as string
    ]]
    
    local zipContent = {}
    local fileHeaders = {}
    local centralDirectory = {}
    local offset = 0
    
    -- Local file headers for each file
    for _, file in ipairs(files) do
        local filename = file.filename
        local content = file.content
        
        -- Local file header signature
        table.insert(fileHeaders, string.char(0x50, 0x4B, 0x03, 0x04)) -- PK\003\004
        table.insert(fileHeaders, string.char(0x14, 0x00)) -- version needed
        table.insert(fileHeaders, string.char(0x00, 0x00)) -- general purpose bit flag
        table.insert(fileHeaders, string.char(0x00, 0x00)) -- compression method (0 = stored)
        
        -- File modification time and date (stub values)
        table.insert(fileHeaders, string.char(0x00, 0x00, 0x00, 0x00))
        
        -- CRC-32 (simplified - set to 0)
        table.insert(fileHeaders, string.char(0x00, 0x00, 0x00, 0x00))
        
        -- File sizes
        local fileSize = #content
        table.insert(fileHeaders, string.pack("<I4", fileSize)) -- compressed size
        table.insert(fileHeaders, string.pack("<I4", fileSize)) -- uncompressed size
        
        -- Filename length and extra field length
        table.insert(fileHeaders, string.pack("<H", #filename))
        table.insert(fileHeaders, string.char(0x00, 0x00))
        
        -- Filename
        table.insert(fileHeaders, filename)
        
        -- File content
        table.insert(fileHeaders, content)
        
        offset = offset + #table.concat(fileHeaders)
    end
    
    return table.concat(fileHeaders)
end

-- Generate download link for browser
function download.generateDownloadLink(obfuscatedScript, filename)
    --[[
    obfuscatedScript: the obfuscated Lua code
    filename: desired filename (e.g., "script.lua")
    Returns: data URL or download info
    ]]
    
    local encodedContent = base64Encode(obfuscatedScript)
    local dataUrl = "data:application/octet-stream;base64," .. encodedContent
    
    return {
        url = dataUrl,
        filename = filename,
        method = "base64"
    }
end

-- Package multiple files into a downloadable zip
function download.packageZip(scripts)
    --[[
    scripts: table of {name = "script_name", content = "obfuscated code"}
    Returns: zip file data
    ]]
    
    local files = {}
    for _, script in ipairs(scripts) do
        table.insert(files, {
            filename = script.name .. ".lua",
            content = script.content
        })
    end
    
    return download.createZip(files)
end

-- Create a download manifest
function download.createManifest(scripts, timestamp)
    timestamp = timestamp or os.date("%Y-%m-%d %H:%M:%S")
    
    local manifest = {
        version = "1.0",
        createdAt = timestamp,
        tool = "GraniteLock Obfuscator",
        files = {}
    }
    
    for _, script in ipairs(scripts) do
        table.insert(manifest.files, {
            name = script.name,
            obfuscated = true,
            size = #script.content
        })
    end
    
    return manifest
end

return download
