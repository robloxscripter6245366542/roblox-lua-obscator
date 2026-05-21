-- Download module for GraniteLock obfuscation tool
-- Handles creating zip files and downloading obfuscated scripts

local download = {}

-- Generate download link for browser as base64 encoded ZIP
function download.generateDownloadLink(zipData, filename)
    --[[
    zipData: binary zip file data
    filename: desired filename (e.g., "scripts.zip")
    Returns: data URL for direct download
    ]]
    
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
    
    local encodedContent = base64Encode(zipData)
    local dataUrl = "data:application/zip;base64," .. encodedContent
    
    return {
        url = dataUrl,
        filename = filename,
        method = "base64"
    }
end

-- Download button handler
function download.createDownloadButton(zipData, filename)
    --[[
    Creates and triggers download of ZIP file
    zipData: binary zip file content
    filename: name for downloaded file (e.g., "GraniteZip.zip")
    ]]
    
    local downloadLink = download.generateDownloadLink(zipData, filename)
    
    return {
        href = downloadLink.url,
        download = downloadLink.filename,
        type = "application/zip"
    }
end

-- Package multiple scripts into downloadable data
function download.packageScripts(scripts)
    --[[
    scripts: table of {name = "script_name", content = "obfuscated code"}
    Returns: formatted data ready for download
    ]]
    
    local packageData = {
        scripts = scripts,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        tool = "GraniteLock Obfuscator"
    }
    
    return packageData
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
