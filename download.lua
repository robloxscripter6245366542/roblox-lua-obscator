-- Download module for GraniteLock obfuscation tool
-- Handles creating zip files and downloading obfuscated scripts

local download = {}

-- CRC-32 lookup table
local crc32_table = {}
for i = 0, 255 do
    local crc = i
    for j = 1, 8 do
        if bit.band(crc, 1) == 1 then
            crc = bit.bxor(bit.rshift(crc, 1), 0xEDB88320)
        else
            crc = bit.rshift(crc, 1)
        end
    end
    crc32_table[i] = crc
end

-- Calculate CRC-32 for data
local function calculateCRC32(data)
    local crc = 0xFFFFFFFF
    for i = 1, #data do
        local byte = string.byte(data, i)
        crc = bit.bxor(crc32_table[bit.band(bit.bxor(crc, byte), 0xFF)], bit.rshift(crc, 8))
    end
    return bit.bxor(crc, 0xFFFFFFFF)
end

-- Convert number to little-endian bytes
local function toLE32(num)
    return string.char(
        bit.band(num, 0xFF),
        bit.band(bit.rshift(num, 8), 0xFF),
        bit.band(bit.rshift(num, 16), 0xFF),
        bit.band(bit.rshift(num, 24), 0xFF)
    )
end

local function toLE16(num)
    return string.char(
        bit.band(num, 0xFF),
        bit.band(bit.rshift(num, 8), 0xFF)
    )
end

-- Create a simple base64 encoder for file compression
local base64Charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Encode(data)
    local result = {}
    for i = 1, #data, 3 do
        local a, b, c = string.byte(data, i), string.byte(data, i + 1), string.byte(data, i + 2)
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

-- Create a properly formatted zip file
function download.createZip(files)
    --[[
    files: table of {filename = "name.lua", content = "script content"}
    Returns: zip file content as string (binary)
    ]]
    
    local localFileHeaders = {}
    local centralDirectoryHeaders = {}
    local fileOffset = 0
    
    -- Build local file headers and central directory entries
    for _, file in ipairs(files) do
        local filename = file.filename
        local content = file.content
        local fileSize = #content
        local crc32 = calculateCRC32(content)
        
        -- Local file header
        local localHeader = string.char(0x50, 0x4B, 0x03, 0x04) -- Local file header signature
        localHeader = localHeader .. toLE16(20) -- Version needed to extract
        localHeader = localHeader .. toLE16(0) -- General purpose bit flag
        localHeader = localHeader .. toLE16(0) -- Compression method (0 = stored)
        localHeader = localHeader .. toLE16(0) -- File last modification time
        localHeader = localHeader .. toLE16(0) -- File last modification date
        localHeader = localHeader .. toLE32(crc32) -- CRC-32
        localHeader = localHeader .. toLE32(fileSize) -- Compressed size
        localHeader = localHeader .. toLE32(fileSize) -- Uncompressed size
        localHeader = localHeader .. toLE16(#filename) -- Filename length
        localHeader = localHeader .. toLE16(0) -- Extra field length
        localHeader = localHeader .. filename
        
        -- Track offset for central directory
        table.insert(localFileHeaders, localHeader .. content)
        
        -- Central directory header
        local centralHeader = string.char(0x50, 0x4B, 0x01, 0x02) -- Central file header signature
        centralHeader = centralHeader .. toLE16(20) -- Version made by
        centralHeader = centralHeader .. toLE16(20) -- Version needed to extract
        centralHeader = centralHeader .. toLE16(0) -- General purpose bit flag
        centralHeader = centralHeader .. toLE16(0) -- Compression method
        centralHeader = centralHeader .. toLE16(0) -- File last modification time
        centralHeader = centralHeader .. toLE16(0) -- File last modification date
        centralHeader = centralHeader .. toLE32(crc32) -- CRC-32
        centralHeader = centralHeader .. toLE32(fileSize) -- Compressed size
        centralHeader = centralHeader .. toLE32(fileSize) -- Uncompressed size
        centralHeader = centralHeader .. toLE16(#filename) -- Filename length
        centralHeader = centralHeader .. toLE16(0) -- Extra field length
        centralHeader = centralHeader .. toLE16(0) -- File comment length
        centralHeader = centralHeader .. toLE16(0) -- Disk number start
        centralHeader = centralHeader .. toLE16(0) -- Internal file attributes
        centralHeader = centralHeader .. toLE32(0) -- External file attributes
        centralHeader = centralHeader .. toLE32(fileOffset) -- Relative offset of local header
        centralHeader = centralHeader .. filename
        
        table.insert(centralDirectoryHeaders, centralHeader)
        fileOffset = fileOffset + #localFileHeaders[#localFileHeaders]
    end
    
    local localData = table.concat(localFileHeaders)
    local centralData = table.concat(centralDirectoryHeaders)
    local centralDirOffset = #localData
    local centralDirSize = #centralData
    
    -- End of central directory record
    local endOfCentralDir = string.char(0x50, 0x4B, 0x05, 0x06) -- End of central dir signature
    endOfCentralDir = endOfCentralDir .. toLE16(0) -- Disk number
    endOfCentralDir = endOfCentralDir .. toLE16(0) -- Disk with central directory
    endOfCentralDir = endOfCentralDir .. toLE16(#files) -- Number of entries on this disk
    endOfCentralDir = endOfCentralDir .. toLE16(#files) -- Total number of entries
    endOfCentralDir = endOfCentralDir .. toLE32(centralDirSize) -- Size of central directory
    endOfCentralDir = endOfCentralDir .. toLE32(centralDirOffset) -- Offset of central directory
    endOfCentralDir = endOfCentralDir .. toLE16(0) -- ZIP file comment length
    
    return localData .. centralData .. endOfCentralDir
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
    Returns: zip file data (binary string)
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
