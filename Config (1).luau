--!strict
-- Semua angka gameplay ada di sini. Ubah di sini untuk balancing.
-- Catatan: file ini bisa dibaca client; pengecekan asli tetap terjadi di server.

export type CarDef = {
	id: string,
	name: string,
	basePrice: number, -- harga mobil kondisi sempurna (tanpa bonus)
	minLevel: number,
	weight: number, -- makin besar makin sering muncul di dealer
	body: Vector3,
	cabin: Vector3,
	cabinOffsetZ: number,
	wheelRadius: number,
}

export type TaskDef = {
	id: string,
	label: string,
	stat: string?, -- nil = pengecatan
	costPct: number, -- persen dari basePrice (diskalakan oleh tingkat kerusakan)
	seconds: number,
	xp: number,
}

local carList: { CarDef } = {
	{ id = "city_hatch", name = "City Hatch", basePrice = 4500, minLevel = 1, weight = 12,
		body = Vector3.new(4.6, 1.5, 8.5), cabin = Vector3.new(4.0, 1.3, 4.2), cabinOffsetZ = 0.6, wheelRadius = 1.0 },
	{ id = "old_sedan", name = "Old Sedan", basePrice = 7500, minLevel = 1, weight = 12,
		body = Vector3.new(5.0, 1.5, 10), cabin = Vector3.new(4.4, 1.3, 5), cabinOffsetZ = 0.2, wheelRadius = 1.1 },
	{ id = "pickup", name = "Work Pickup", basePrice = 12000, minLevel = 2, weight = 9,
		body = Vector3.new(5.4, 1.7, 11), cabin = Vector3.new(4.8, 1.5, 3.6), cabinOffsetZ = -2.2, wheelRadius = 1.4 },
	{ id = "wagon", name = "Family Wagon", basePrice = 16000, minLevel = 3, weight = 8,
		body = Vector3.new(5.0, 1.6, 11), cabin = Vector3.new(4.4, 1.5, 7.2), cabinOffsetZ = 0.8, wheelRadius = 1.15 },
	{ id = "muscle", name = "Muscle GT", basePrice = 28000, minLevel = 4, weight = 6,
		body = Vector3.new(5.4, 1.5, 10.8), cabin = Vector3.new(4.5, 1.2, 4.4), cabinOffsetZ = 1.0, wheelRadius = 1.25 },
	{ id = "sport_coupe", name = "Sport Coupe", basePrice = 45000, minLevel = 6, weight = 4,
		body = Vector3.new(5.2, 1.3, 10), cabin = Vector3.new(4.3, 1.1, 3.8), cabinOffsetZ = 0.6, wheelRadius = 1.2 },
	{ id = "classic_roadster", name = "Classic Roadster", basePrice = 70000, minLevel = 8, weight = 3,
		body = Vector3.new(5.0, 1.4, 9.6), cabin = Vector3.new(4.0, 0.9, 3.0), cabinOffsetZ = 0.8, wheelRadius = 1.15 },
	{ id = "supercar", name = "Hyper GT", basePrice = 140000, minLevel = 11, weight = 2,
		body = Vector3.new(5.6, 1.2, 10.6), cabin = Vector3.new(4.4, 1.0, 3.6), cabinOffsetZ = 0.4, wheelRadius = 1.25 },
}

local tasks: { [string]: TaskDef } = {
	wash = { id = "wash", label = "Cuci", stat = "dirt", costPct = 0.012, seconds = 3, xp = 5 },
	dents = { id = "dents", label = "Ketok Magic", stat = "dents", costPct = 0.06, seconds = 6, xp = 15 },
	rust = { id = "rust", label = "Anti Karat", stat = "rust", costPct = 0.08, seconds = 8, xp = 20 },
	engine = { id = "engine", label = "Servis Mesin", stat = "engine", costPct = 0.10, seconds = 10, xp = 30 },
	paint = { id = "paint", label = "Cat Ulang", stat = nil, costPct = 0.035, seconds = 5, xp = 10 },
}

local paintColors: { string } = {
	"#D63A3A", "#2F6FDB", "#F2C230", "#2FA35B", "#F2F2F2", "#1B1B1F", "#8A3FD1", "#F58A1F",
}

local Config = {
	-- Pemain
	StartCash = 7500,
	StartSlots = 3,
	MaxSlots = 12,
	SlotBaseCost = 6000, -- biaya slot = SlotBaseCost * 2^(slot - StartSlots)

	-- Dealer & pasar
	StockSize = 6,
	StockRefreshSeconds = 90,
	MarketRefreshSeconds = 45,
	MarketMin = 0.85,
	MarketMax = 1.25,
	DealerDiscountMin = 0.80, -- harga dealer = nilai (mesin diasumsikan) x acak di rentang ini
	DealerDiscountMax = 1.00,
	DealerAssumedEngine = 0.35, -- kondisi mesin tersembunyi; dealer menebak rata-rata

	-- Rentang kondisi awal mobil di dealer (0 = sempurna, 1 = terburuk)
	StatRanges = {
		dirt = { min = 0.30, max = 1.00 },
		dents = { min = 0.00, max = 0.85 },
		rust = { min = 0.00, max = 0.90 },
		engine = { min = 0.05, max = 0.90 },
	},

	-- Rumus nilai mobil
	ValueWeights = { dirt = 0.05, dents = 0.20, rust = 0.25, engine = 0.30 },
	ShowroomBonus = 0.10, -- semua kondisi sempurna
	PaintBonus = 0.05, -- sudah dicat ulang

	-- Progres
	XpPerLevel = 150, -- level = floor(sqrt(xp / XpPerLevel)) + 1
	SellXpBase = 25,
	SellXpPerProfit = 1 / 40,

	-- Penyimpanan
	AutosaveSeconds = 60,
	LockTimeoutSeconds = 150,

	CarList = carList,
	Cars = {} :: { [string]: CarDef },
	Tasks = tasks,
	TaskOrder = { "wash", "dents", "rust", "engine", "paint" },
	PaintColors = paintColors,
	PaintColorSet = {} :: { [string]: boolean },
}

for _, def in carList do
	Config.Cars[def.id] = def
end
for _, hex in paintColors do
	Config.PaintColorSet[hex] = true
end

return Config
