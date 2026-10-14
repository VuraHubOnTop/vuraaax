-- loader.lua
local BASE = "https://TNJ.wispbyte.app"  -- ganti URL Railway kamu

-- pastikan key sudah di-set user
if not getgenv().script_key then
    warn("[Key] Key belum diisi. Set dulu: getgenv().script_key = \"KEY-KAMU\"")
    return
end

-- fungsi HTTP request yang kompatibel banyak executor
local function req(url, body)
    local payload = game:GetService("HttpService"):JSONEncode(body)
    if request then
        return request({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=payload}).Body
    elseif syn and syn.request then
        return syn.request({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=payload}).Body
    elseif http_request then
        return http_request({Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=payload}).Body
    else
        error("[Key] Executor tidak mendukung HTTP request")
    end
end

-- kumpulkan identitas
local ok, hwid = pcall(function()
    if gethwid then return gethwid() end
    if syn and syn.get_hwid then return syn.get_hwid() end
    return game:GetService("RbxAnalyticsService"):GetClientId()
end)
if not ok then hwid = "unknown" end

local player = game:GetService("Players").LocalPlayer

-- kirim ke server key
local body = {
    key     = getgenv().script_key,
    hwid    = hwid,
    userid  = player.UserId,
    username= player.Name,
    placeid = game.PlaceId,
}

local ok2, response = pcall(req, BASE .. "/verify", body)
if not ok2 or not response then
    warn("[Key] Gagal menghubungi server key: " .. tostring(response))
    return
end

local data = game:GetService("HttpService"):JSONDecode(response)
if not data.ok then
    warn("[Key] " .. (data.message or "Key nya busuk woy!"))
    return
end

-- jalankan payload dari server
local fn = loadstring(data.payload)
if not fn then
    warn("[Key] Payload dari server tidak valid")
    return
end
fn()
