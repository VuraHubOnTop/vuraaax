-- ============================================
-- LOADER UNIVERSAL - Template
-- Tinggal tambahin link raw script di tabel
-- ============================================

local scripts = {
    -- ===== GAME YANG UDAH DIISI PLACEID =====
    [121864768012064] = "https://raw.githubusercontent.com/ballsmarkettreal-cyber/vuraaax/refs/heads/main/gamelist/fishit.lua",           -- Fish It
    [136533956395153] = "https://raw.githubusercontent.com/VuraHubOnTop/vuraaax/refs/heads/main/gamelist/carflipper.lua",       -- Car Flipper
    [15494065142]     = "LINK_RAW_SCRIPT_CLICK_A_ROCK",      -- Click A Rock
    [13284033561]     = "LINK_RAW_SCRIPT_FISHING_FRENZY",    -- Fishing Frenzy Simulator
    [8962384769]      = "LINK_RAW_SCRIPT_FIREWORK_SIM",      -- Firework Simulator
    [126884695634066] = "LINK_RAW_SCRIPT_GROW_A_GARDEN",     -- Grow a Garden
    [8737899170]      = "LINK_RAW_SCRIPT_PET_SIM_99",        -- Pet Simulator 99
    [2753915549]      = "LINK_RAW_SCRIPT_BLOX_FRUITS",       -- Blox Fruits (Sea 1)
    [4442272183]      = "LINK_RAW_SCRIPT_BLOX_FRUITS_2",     -- Blox Fruits (Sea 2)
    [7449423635]      = "LINK_RAW_SCRIPT_BLOX_FRUITS_3",     -- Blox Fruits (Sea 3)
    [124216119978534] = "https://raw.githubusercontent.com/VuraHubOnTop/vuraaax/refs/heads/main/gamelist/RideAPet.lua",
    [107778070777162] = "https://raw.githubusercontent.com/VuraHubOnTop/vuraaax/refs/heads/main/gamelist/StealAnEgg.lua",
    [89469502395769]  = "https://raw.githubusercontent.com/VuraHubOnTop/vuraaax/refs/heads/main/gamelist/KickALuckyBlock.lua",
    
    -- ===== TAMBAHIN SENDIRI DI SINI =====
    -- [PLACEID] = "LINK_RAW_SCRIPT",
}

-- Jangan diubah di bawah sini
local url = scripts[game.PlaceId]

if not url then
    warn("[Loader] Game ini belum didukung. PlaceId: " .. game.PlaceId)
    return
end

local ok, err = pcall(function()
    loadstring(game:HttpGet(url))()
end)

if not ok then
    warn("[Loader] Error: " .. tostring(err))
end
