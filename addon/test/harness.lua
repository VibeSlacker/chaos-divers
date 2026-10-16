-- Offline test for the Chaos Divers addon (test build 0.10 renames it to Dissident Discovery; 0.9 restyles the banner after the game's MISSION COMPLETED and makes the key host-only; 0.8 adds the on-screen banner; 0.7: rebel mode sets the SEAF soldiers, never a Helldiver,
-- on the side of the enemy holding the map unless the settings file forces one).
-- Builds a fake game in memory (a fake game.dll image holding the four signatures, a faction manager with a
-- unit list, a detector table with records, a mission-state object with the kill count, the traitor tally),
-- then runs the built addon against it frame by frame and reads its log.
--   luajit test/harness.lua <built lua> <data/sigs.json> <scratch dir> [side8|fresh|auto|nosig|banner]   (stdin closed)
-- banner: a stand-in for the game's engine table records what the banner draws.
-- auto: side = 0, the rebels join whichever enemy has the most units on the map.
-- no mode and side8: guard off at first, then on.   fresh: no settings file, so the defaults.
-- nosig: a game update broke a signature.
-- Windows calls are replaced with stand-ins, so this proves the addon's own logic, not the game's layout.
local built, sigs_path, scratch, mode = arg[1], arg[2], arg[3], arg[4]
local ffi = require("ffi")

local failures = 0
local function check(ok, what)
	if ok then print("  ok    " .. what) else failures = failures + 1 print("  FAIL  " .. what) end
end

-- ---------------------------------------------------------------- fake memory
local buffers = {}
local function alloc(n)
	local b = ffi.new("uint8_t[?]", n)
	local at = tonumber(ffi.cast("uintptr_t", b))
	buffers[#buffers + 1] = { b = b, at = at, n = n, prot = 0x04 }
	return at
end
local function protect(at, prot) for _, b in ipairs(buffers) do if b.at == at then b.prot = prot end end end
local function snapshot() local t = {} for i, b in ipairs(buffers) do t[i] = ffi.string(b.b, b.n) end return t end
-- addresses of every byte that differs from a snapshot
local function changed(snap)
	local out = {}
	for i, b in ipairs(buffers) do
		if ffi.string(b.b, b.n) ~= snap[i] then
			for k = 0, b.n - 1 do if b.b[k] ~= snap[i]:byte(k + 1) then out[#out + 1] = b.at + k end end
		end
	end
	return out
end
local function w32(a, v) ffi.cast("uint32_t *", a)[0] = v end
local function r32(a) return tonumber(ffi.cast("uint32_t *", a)[0]) end
local update_ref
local function wptr(a, v) ffi.cast("uint64_t *", a)[0] = v end
local function checksum()
	local sum = 0
	for _, b in ipairs(buffers) do
		for i = 0, b.n - 1 do sum = (sum * 31 + b.b[i]) % 4294967291 end
	end
	return sum
end

local sigs = {}
do
	local f = assert(io.open(sigs_path)); local text = f:read("*a"); f:close()
	for obj in text:gmatch("%b{}") do
		sigs[#sigs + 1] = { name = obj:match('"name": "(.-)"'), hex = obj:match('"hex": "(.-)"'),
			symbol = obj:match('"symbol": "(.-)"'), off = tonumber(obj:match('"extract_offset": (%d+)')),
			stop = tonumber(obj:match('"extract_end": (%d+)')) }
	end
	assert(#sigs == 8, "expected 8 signatures (4 needed, 3 font, 1 network), got " .. #sigs)
end

local IMAGE = 0x200000
local image = alloc(IMAGE)
w32(image + 0x3C, 0x100); w32(image + 0x100, 0x00004550); w32(image + 0x108, 12345); w32(image + 0x150, IMAGE)
local slot_of, next_slot, next_code = {}, 0x100000, 0x1000
for _, s in ipairs(sigs) do
	slot_of[s.symbol] = image + next_slot; next_slot = next_slot + 16
	if not (mode == "nosig" and s.symbol == "mission_state") then
		local at = image + next_code; next_code = next_code + 0x1000
		local p = ffi.cast("uint8_t *", at)
		for i = 1, #s.hex, 2 do p[(i - 1) / 2] = tonumber(s.hex:sub(i, i + 1), 16) end
		ffi.cast("int32_t *", at + s.off)[0] = slot_of[s.symbol] - (at + s.stop)
	end
end

-- faction manager: room for 512 units
local HD = { 0x294dfa97, 0x4d1c334d }
local mgr = alloc(0x12100)
local ents, recs, masks = alloc(8 * 512), alloc(0x60 * 512), alloc(4 * 512)
w32(mgr + 0x12030, 0x200)
wptr(mgr + 0x12068, ents); wptr(mgr + 0x12070, recs); wptr(mgr + 0x12078, masks)
-- detector: a lookup table of (id, slot) pairs and records of 0x13F8 bytes, the side copy at +0x13E8
local DSIZE, DEMPTY, DSTEP = 64, 0xFFFFFFFF, 2654435761
local det, dtab, drecs = alloc(0x60), alloc(8 * DSIZE), alloc(0x13F8 * 40)
wptr(det + 0x30, dtab); w32(det + 0x38, DSIZE); w32(det + 0x3C, DEMPTY); w32(det + 0x40, DSTEP); wptr(det + 0x50, drecs)
local dslots = 0
local function det_at(u) return drecs + u.dslot * 0x13F8 + 0x13E8 end
local function set_units(list)   -- { { type = "hd"|"other", side =, record =, copy =, det = side copy or nil }, ... }
	for k = 0, DSIZE - 1 do w32(dtab + 8 * k, DEMPTY); w32(dtab + 8 * k + 4, DEMPTY) end
	for i, u in ipairs(list) do
		if not u.at then u.at = alloc(16); u.id = u.id or (0x1000000 + #buffers) end
		local unit = u.at
		w32(unit + 8, u.id)
		if u.type == "hd" then w32(unit, HD[1]); w32(unit + 4, HD[2]) else w32(unit, 0x11111111); w32(unit + 4, 0x22222222) end
		wptr(ents + 8 * (i - 1), unit)
		w32(recs + 0x60 * (i - 1), u.record); w32(recs + 0x60 * (i - 1) + 0xC, u.copy or u.side)
		w32(masks + 4 * (i - 1), u.side)
		u.at_side, u.at_copy = masks + 4 * (i - 1), recs + 0x60 * (i - 1) + 0xC
		if u.det then
			if not u.dslot then u.dslot = dslots; dslots = dslots + 1 end
			local h = tonumber((ffi.cast("uint64_t", DSTEP) * u.id) % 4294967296ULL)
			local k = h % DSIZE
			while r32(dtab + 8 * k) ~= DEMPTY do k = (k + 1) % DSIZE end
			w32(dtab + 8 * k, u.id); w32(dtab + 8 * k + 4, u.dslot)
			w32(det_at(u), u.det)
		end
	end
	w32(mgr + 0x1203C, #list)
end

-- mission state: the kill count at +0x2FC84, the value before it at +0x2FC80
local ms = alloc(0x30000)
-- traitor tally object: 16 ids at +0x410, 16 tallies at +0x450, next slot at +0x490, timer at +0x494
local tl = alloc(0x500)

-- ---------------------------------------------------------------- fake Windows
local kernel = {
	VirtualQuery = function (address, region, size)
		local a = tonumber(ffi.cast("uintptr_t", address))
		local r = region[0]
		for _, b in ipairs(buffers) do
			if a >= b.at and a < b.at + b.n then
				r.base = ffi.cast("void *", b.at); r.size = b.n; r.state = 0x1000; r.protection = b.prot
				return size
			end
		end
		r.base = ffi.cast("void *", a - a % 4096); r.size = 4096; r.state = 0x10000; r.protection = 1
		return size
	end,
	GetModuleHandleA = function () return ffi.cast("void *", image) end,
	GetCurrentProcessId = function () return 42 end,
}
local keys, focused = {}, true
local window = ffi.cast("void *", 0x1234)
local user = {
	GetAsyncKeyState = function (vk) return keys[vk] and -32768 or 0 end,
	GetForegroundWindow = function () return focused and window or nil end,
	GetWindowThreadProcessId = function (_, pid) ffi.cast("uint32_t *", pid)[0] = 42 return 1 end,
}
ffi.load = function (name) assert(name == "kernel32" or name == "user32", "asked for " .. name) return name == "kernel32" and kernel or user end

local frames = 0
rawset(_G, "update", function () frames = frames + 1 end)
local shut = false
rawset(_G, "shutdown", function () shut = true end)

-- ---------------------------------------------------------------- run
local getenv = os.getenv
os.getenv = function (name) if name == "LOCALAPPDATA" then return scratch end return getenv(name) end
os.execute('mkdir -p "' .. scratch .. '/CowboyBingus/Helldivers2/Logs"')
local LOGDIR = scratch .. "/CowboyBingus/Helldivers2/Logs/"
do
	local f = assert(io.open(LOGDIR .. "ChaosDivers.log", "w")); f:write("OLD SESSION\n"); f:close()
	f = assert(io.open(LOGDIR .. "ChaosDivers.previous.log", "w")); f:write("STALE\n"); f:close()
	os.remove(LOGDIR .. "ChaosDivers.cfg")
	if mode == "side8" then f = assert(io.open(LOGDIR .. "ChaosDivers.cfg", "w")); f:write("# mine\r\nkey = 119   # F8\r\nside = 8\r\nreapply = 0\r\nguard = 0\r\n"); f:close()
	elseif mode == "auto" then f = assert(io.open(LOGDIR .. "ChaosDivers.cfg", "w")); f:write("side = 0\nguard = 0\n"); f:close()
	elseif mode ~= "fresh" then f = assert(io.open(LOGDIR .. "ChaosDivers.cfg", "w")); f:write("side = 4\nguard = 0\n"); f:close() end
end
local function write_cfg(text) local f = assert(io.open(LOGDIR .. "ChaosDivers.cfg", "w")); f:write(text); f:close() end
local KEY = mode == "side8" and 119 or 120
local SIDE = mode == "side8" and 8 or 4
local function press(vk) keys[vk or KEY] = true; update_ref(1); keys[vk or KEY] = nil; update_ref(1) end
-- the game's engine table, for the banner: records surfaces, rectangles and text
local drawn = { live = {}, made = 0, destroyed = 0, texts = {}, rects = {}, fail = false }
local clock = 0
if mode == "banner" then
	local font_holder = alloc(64)
	ffi.cast("uint64_t *", slot_of.font)[0] = 0x1111222233334444ULL
	ffi.cast("uint64_t *", slot_of.atlas)[0] = 0x5555666677778888ULL
	wptr(slot_of.material, font_holder); ffi.cast("uint64_t *", font_holder + 24)[0] = 0x99990000AAAABBBBULL
	local MAIN, UI = { "main" }, { "ui" }
	local V2 = setmetatable({ x = function (v) return v[1] end }, { __call = function (_, x, y) return { x, y } end })
	rawset(_G, "stingray", {
		Application = { main_world = function () return MAIN end, worlds = function () return { MAIN, UI } end,
			can_get = function () return true end },
		World = {
			create_screen_gui = function (w) assert(w == UI, "drawn in the main world"); drawn.made = drawn.made + 1
				local g = { n = drawn.made }; drawn.live[g] = true; drawn.texts, drawn.rects = {}, {} return g end,
			destroy_gui = function (w, g) assert(drawn.live[g], "destroyed an unknown surface"); drawn.live[g] = nil; drawn.destroyed = drawn.destroyed + 1 end,
		},
		Gui = {
			resolution = function () return 1920, 1080 end,
			material = function (_, m) drawn.material = m return { ink = true } end,
			text_extents = function (_, text, _, size) return { 0, 0 }, { #text * size * 0.5, size } end,
			text = function (g, text, font, size, material, pos, color)
				if drawn.fail then error("stand-in drawing failure", 0) end
				drawn.texts[#drawn.texts + 1] = { text = text, font = font, size = size, pos = pos, color = color } end,
			rect = function (g, pos, size, color) drawn.rects[#drawn.rects + 1] = { pos = pos, size = size, color = color } end,
		},
		Material = { set_scalar = function () end, set_vector2 = function () end, set_vector4 = function () end, set_texture = function () end },
		IdString64 = { from_hex = function (h) return "id:" .. h end },
		Vector2 = V2,
		Vector3 = function (x, y, z) return { x, y, z } end,
		Color = function (a, r, g, b) return { a, r, g, b } end,
	})
	os.clock = function () return clock end
end
local function live_count() local n = 0 for _ in pairs(drawn.live) do n = n + 1 end return n end
-- default mode: a stand-in for Mod Bindings Menu (Vanilla Plus), refusing the first registration try
local menu = { registered = {}, down = false, refuse = 1 }
if mode == nil then
	rawset(_G, "ModBindingsMenu", { api = 1, version = 3,
		register_binding = function (id, label, slot, options)
			if menu.refuse > 0 then menu.refuse = menu.refuse - 1 return false, "stand-in not ready" end
			menu.registered[id] = { label = label, slot = slot, category = options and options.category } return true end,
		is_down = function (id) if not menu.registered[id] then return nil end return menu.down end })
end
assert(assert(loadfile(built))() == true)
local update = rawget(_G, "update")
local function run(n) for _ = 1, n do update() end end
update_ref = run
local function file(name) local f = io.open(LOGDIR .. name); if not f then return "" end local t = f:read("*a"); f:close(); return t end
local function log_text() return file("ChaosDivers.log") end
local function last_line(pattern)
	local found
	for line in log_text():gmatch("[^\n]+") do if line:find(pattern, 1, true) then found = line end end
	return found
end
local function count_lines(pattern)
	local n = 0
	for line in log_text():gmatch("[^\n]+") do if line:find(pattern, 1, true) then n = n + 1 end end
	return n
end
local addon = rawget(_G, "ChaosDivers")

print("start")
check(addon ~= nil and addon.revision == "Chaos Divers: Dissident Discovery test 0.10", "the addon registered itself as test 0.10")
check(file("ChaosDivers.previous.log") == "OLD SESSION\n", "the last session's log was kept as the previous log")
check(loadfile(built)() == true and count_lines("loaded (") == 1, "loading it a second time does nothing")
local before_sum = checksum()
run(3000)
if mode == "nosig" then
	print("a game update: one signature gone")
	check(last_line("stopped on error") ~= nil and last_line("mission_state matched 0 times") ~= nil, "it stops and names the missing signature")
	check(last_line("READY") == nil, "it never reports ready")
	local lines = count_lines("")
	run(600)
	check(count_lines("") == lines, "a stopped addon logs nothing more")
	check(frames >= 3600, "the game's own update still runs every frame")
	check(checksum() == before_sum, "nothing in the fake game was changed")
	print(failures == 0 and "ALL PASSED" or (failures .. " FAILED"))
	os.exit(failures == 0 and 0 or 1)
end
check(last_line("READY") ~= nil and last_line("signature detector") ~= nil, "all four signatures found, reports ready")
check(last_line("no unit list yet; rebel mode off, would refuse") ~= nil, "empty unit-list slot: says so, would refuse")
press(); check(last_line("key ignored, rebel mode stays off: the unit list cannot be read") ~= nil, "key before the game has a unit list: ignored")
check(checksum() == before_sum, "nothing in the fake game was changed while waiting")

print("on the ship")
wptr(slot_of.faction_manager, mgr); wptr(slot_of.mission_state, ms); wptr(slot_of.traitor_tally, tl); wptr(slot_of.detector, det)
-- the network context: this player's peer id at +0xB398, the host's at +0xB3A8 (same = hosting)
local net = alloc(0xB400)
local function set_peers(me_id, host_id)
	ffi.cast("uint64_t *", net + 0xB398)[0] = me_id; ffi.cast("uint64_t *", net + 0xB3A8)[0] = host_id
end
set_peers(0x0110000100001234ULL, 0x0110000100001234ULL)
wptr(slot_of.network, net)
local ship = {}
for i = 1, 48 do ship[i] = { type = i == 5 and "hd" or "other", side = 1, record = i == 5 and 90 or 83 } end
set_units(ship); run(40)
check(last_line("ship; Helldivers 1; side 0x1/0x1; rebel mode off, would refuse: not in a mission (ship)") ~= nil, "on the ship: would refuse")
do
	local snap = snapshot(); press(); run(20)
	check(last_line("key ignored, rebel mode stays off: not in a mission (ship)") ~= nil and #changed(snap) == 0, "key on the ship: ignored, not one byte changed")
end

print("solo mission")
local squid = { type = "other", side = 4, record = 35, det = 4 }
local me = { type = "hd", side = 1, record = 28 }
local A, B = { type = "other", side = 1, record = 24, det = 1 }, { type = "other", side = 1, record = 24, det = 1 }
local corpse = { type = "other", side = 0, record = 24, det = 1 }
local dog = { type = "other", side = 1, record = 33, det = 1 }
local nodet = { type = "other", side = 1, record = 24 }
local mission = { squid, me, A, B, corpse, dog, nodet }
set_units(mission); run(40)
check(last_line("mission; Helldivers 1; side 0x1/0x1; rebel mode off, ready") ~= nil, "solo in a mission on 0x1: ready")
check(addon.would_arm == true and addon.units.soldiers == 3, "three living SEAF soldiers counted, the dead one left out")
local function is(u, v) return r32(u.at_side) == v and r32(u.at_copy) == v and (not u.det or r32(det_at(u)) == v) end

if mode == "banner" then
	print("banner")
	check(last_line("signature ui_font at") ~= nil and last_line("signature ui_atlas at") ~= nil and last_line("signature ui_material at") ~= nil, "the three font signatures found")
	check(drawn.made == 0, "nothing drawn before rebel mode goes on")
	clock = 100; press(); run(2)
	check(addon.rebel.on and last_line("BANNER: DISSIDENT CELL DISCOVERED") ~= nil, "F9 on: rebel mode on and the banner logged")
	check(live_count() == 1 and #drawn.texts == 2 and drawn.texts[1].text == "DISSIDENT CELL DISCOVERED" and drawn.texts[2].text == "SEAF FORCES HAVE TURNED HOSTILE.", "one surface, the title and the line under it")
	check(drawn.texts[1].color[1] == 255 and drawn.texts[1].color[2] == 255 and drawn.texts[1].color[3] == 130 and drawn.texts[1].color[4] == 31, "the title is solid orange")
	check(drawn.texts[1].font == "id:1111222233334444" and drawn.material == "id:99990000aaaabbbb" and last_line("banner: drawn in the game's own font") ~= nil, "drawn in the game's own font")
	local tx = drawn.texts[1].pos[1]; local tw = #"DISSIDENT CELL DISCOVERED" * drawn.texts[1].size * 0.5
	check(math.abs(tx + tw / 2 - 960) < 1 and drawn.texts[1].pos[2] > 540 and drawn.texts[1].pos[2] < 1080, "centred across the screen, in the upper half")
	local orange, dark = 0, 0
	for _, r in ipairs(drawn.rects) do
		if r.color[2] == 255 and r.color[3] == 130 and r.color[4] == 31 then orange = orange + 1 end
		if r.color[2] == 0 and r.color[3] == 0 and r.color[4] == 0 then dark = dark + 1 end
		check(r.pos[1] >= 0 and r.pos[1] + r.size[1] <= 1920 and r.pos[2] >= 0 and r.pos[2] + r.size[2] <= 1080, "every rectangle on screen")
	end
	check(orange == 36 and dark == 10 and drawn.rects[1].color[1] == 150, "a dark band with faded ends, three orange stripes either side, a box under the title")
	local band = drawn.rects[1]
	check(drawn.texts[1].pos[2] > band.pos[2] and drawn.texts[1].pos[2] < band.pos[2] + band.size[2], "the title sits inside the band")
	check(drawn.texts[2].pos[2] < band.pos[2], "the line under it sits below the band")
	local made = drawn.made
	clock = 102; run(30)
	check(drawn.made == made and live_count() == 1, "while it shows it is not redrawn every frame")
	clock = 105.5; run(2)
	check(drawn.made > made and live_count() == 1 and drawn.texts[1].color[1] == 128, "half way through the fade it is redrawn at half strength")
	clock = 106.1; run(2)
	check(live_count() == 0 and addon.banner.start == nil, "after six seconds the surface is gone")
	check(addon.rebel.on, "rebel mode stays on after the banner")
	made = drawn.made; run(100)
	check(drawn.made == made, "nothing drawn after it is gone")
	press(); run(2)
	check(not addon.rebel.on and drawn.made == made, "F9 off: no banner")
	write_cfg("side = 4\nguard = 0\nbanner = 0\n"); clock = 200; press(); run(5)
	check(addon.rebel.on and drawn.made == made and count_lines("BANNER:") == 1, "banner = 0: rebel mode on, no banner")
	press(); run(2)
	write_cfg("side = 4\nguard = 0\nbanner = 1\n"); drawn.fail = true; clock = 300; press(); run(5)
	check(addon.rebel.on and addon.banner.dead and live_count() == 0 and last_line("banner off for this game session, it could not draw: stand-in drawing failure") ~= nil, "a drawing failure: the banner switches itself off and clears, rebel mode stays on")
	check(last_line("stopped on error") == nil, "a drawing failure does not stop the mod")
	drawn.fail = false; press(); run(2); clock = 400; press(); run(5)
	check(addon.rebel.on and drawn.made == made + 1 and live_count() == 0, "once off it stays off for the session")
	clock = 401; rawget(_G, "shutdown")()
	check(live_count() == 0 and last_line("REBEL MODE OFF (game shutting down)") ~= nil, "shutdown: nothing left on screen, soldiers put back")
	print(failures == 0 and "ALL PASSED" or (failures .. " FAILED"))
	os.exit(failures == 0 and 0 or 1)
end

if mode == "fresh" then
	print("defaults: no settings file")
	local text = file("ChaosDivers.cfg")
	check(text:find("key = 120", 1, true) and text:find("side = 0", 1, true) and text:find("guard = 1", 1, true)
		and text:find("guard_at = 1", 1, true) and text:find("squad = 0", 1, true) and text:find("banner = 1", 1, true), "the settings file was written with the defaults")
	check(last_line("READY - rebel mode is off. Key 120 switches it on in a mission (soldiers to the enemy's side, guard 1 at 1, squad 0)") ~= nil, "READY names the settings in use")
	mission = { squid, me, A, B, corpse, dog, nodet, { type = "other", side = 4, record = 35, det = 4 }, { type = "other", side = 4, record = 35, det = 4 } }
	set_units(mission); run(20)
	w32(ms + 0x2FC84, 1); run(300)
	check(r32(ms + 0x2FC84) == 1, "mode off: the count is left alone")
	press(); run(2)
	check(addon.rebel.on and is(A, 4) and is(B, 4) and is(me, 1) and last_line("Guard on (traitor tally and kill count).") ~= nil, "F9 on a squid map: soldiers join the squids (side 4), he is untouched, the log says the guard is on")
	check(last_line("REBEL SIDE: 0x4 (the Illuminate), the enemy on the map (0 on 0x2, 3 on 0x4, 0 on 0x8)") ~= nil, "the chosen side and why are logged")
	check(r32(ms + 0x2FC84) == 0 and last_line("COUNT GUARD: was 1, now 0 (1 kept off the count so far)") ~= nil, "the count of 1 is reset within two frames of switching on")
	rawget(_G, "shutdown")()
	check(is(A, 1) and is(B, 1) and last_line("REBEL MODE OFF (game shutting down): 2 living soldiers put back to 0x1") ~= nil, "shutdown puts the soldiers back and says so")
	check(last_line("stopped on error") == nil, "no error all run")
	print(failures == 0 and "ALL PASSED" or (failures .. " FAILED"))
	os.exit(failures == 0 and 0 or 1)
end

if mode == "auto" then
	local function enemies(side, n) local t = {} for i = 1, n do t[i] = { type = "other", side = side, record = 50, det = side } end return t end
	local function with(...) local t = {} for _, l in ipairs({ ... }) do for _, u in ipairs(l) do t[#t + 1] = u end end return t end
	local function home() for _, u in ipairs({ A, B }) do u.side, u.copy, u.det = 1, 1, 1 end end
	print("auto: no enemy on the map yet")
	do
		local snap = snapshot(); press(); run(60)
		check(addon.rebel.on and #changed(snap) == 0, "on with one squid on the map (under three): nothing written")
		check(count_lines("no enemy on the map yet") == 1, "it says it is waiting, once")
		check(last_line("REBEL MODE ON: SEAF soldiers are set to the side of the enemy on the map") ~= nil, "switching on names the auto side")
	end
	print("auto: a bug or bot map")
	local bots, others = enemies(2, 5), enemies(8, 2)
	do
		set_units(with({ squid, me, A, B, corpse, dog, nodet }, bots, others)); local snap = snapshot(); run(6)
		check(is(A, 2) and is(B, 2) and #changed(snap) == 6, "five on 0x2, two on 0x8, one on 0x4: soldiers join 0x2, six values and nothing else")
		check(last_line("REBEL SIDE: 0x2 (bugs or bots), the enemy on the map (5 on 0x2, 1 on 0x4, 2 on 0x8)") ~= nil, "the choice and the counts are logged")
		check(is(me, 1) and is(dog, 1) and is(squid, 4) and r32(bots[1].at_side) == 2, "he, his dog and the enemies are untouched")
		A.side, A.copy, A.det, B.side, B.copy, B.det = 2, 2, 2, 2, 2, 2
	end
	print("auto: the side is kept for the mission")
	do
		local C = { type = "other", side = 1, record = 24, det = 1 }
		set_units(with({ me, A, B, dog, C }, enemies(8, 20))); local snap = snapshot(); run(6)
		check(is(C, 2) and is(A, 2) and #changed(snap) == 3 and count_lines("REBEL SIDE") == 1, "twenty on 0x8 arrive: the side stays 0x2, a new soldier joins 0x2")
		C.side, C.copy, C.det = 2, 2, 2
		press()
		check(not addon.rebel.on and is(A, 1) and is(C, 1), "off: soldiers back to 0x1")
		home(); C.side, C.copy, C.det = 1, 1, 1
	end
	print("auto: chosen again next time")
	do
		set_units(with({ me, A, B, dog }, enemies(8, 4), enemies(4, 1))); run(20)
		press(); run(6)
		check(addon.rebel.on and is(A, 8) and is(B, 8) and last_line("REBEL SIDE: 0x8 (bugs or bots), the enemy on the map (0 on 0x2, 1 on 0x4, 4 on 0x8)") ~= nil, "on again on a 0x8 map: soldiers join 0x8")
		check(addon.units.enemy[4] == 1 and addon.units.enemy[8] == 4, "the rebel soldiers themselves are not counted as the enemy")
		press(); check(not addon.rebel.on and is(A, 1), "(off)")
		home()
	end
	print("forced side")
	do
		write_cfg("side = 2\nguard = 0\n"); set_units({ squid, me, A, B, dog }); run(20)
		press(); run(2)
		check(addon.rebel.on and is(A, 2) and is(B, 2) and last_line("REBEL SIDE: 0x2 (bugs or bots), set in the settings file") ~= nil, "side = 2 in the file: soldiers on 0x2 at once, even with one squid on the map")
		rawget(_G, "shutdown")()
		check(is(A, 1) and is(B, 1), "shutdown puts them back")
	end
	check(last_line("stopped on error") == nil, "no error all run")
	print(failures == 0 and "ALL PASSED" or (failures .. " FAILED"))
	os.exit(failures == 0 and 0 or 1)
end

print("the key")
local base_snap = snapshot()
do
	focused = false; press(); run(20); focused = true
	check(#changed(base_snap) == 0 and not addon.rebel.on, "key while another window has the focus: nothing happens")
	run(600)
	check(#changed(base_snap) == 0, "600 frames with the mode off: not one byte of the fake game changed")
	press()
	check(addon.rebel.on and is(A, SIDE) and is(B, SIDE), "key in a solo mission: both soldiers read the rebel side in all three places")
	check(#changed(base_snap) == 6, "exactly those six values changed, nothing else")
	check(is(me, 1) and is(dog, 1) and is(squid, 4) and r32(corpse.at_side) == 0 and r32(det_at(corpse)) == 1 and is(nodet, 1), "the Helldiver, his dog, the squid, the dead soldier and the soldier without a detector are untouched")
	check(last_line(string.format("SEAF SET: 2 soldiers now on side 0x%X (2 so far)", SIDE)) ~= nil and last_line("REBEL MODE ON: SEAF soldiers are set to side") ~= nil, "switching on and the set are logged")
	check(count_lines("a SEAF soldier has no detector record") == 1, "the soldier without a detector record is named once")
	run(600)
	check(#changed(base_snap) == 6 and count_lines("SEAF SET") == 1 and count_lines("no detector record") == 1, "600 frames with the mode on: still only those six values, nothing logged twice")
	check(last_line("mission; Helldivers 1; side 0x1/0x1; rebel mode ON") ~= nil, "the state line says the mode is on and his side is normal")
end
A.side, A.copy, A.det, B.side, B.copy, B.det = SIDE, SIDE, SIDE, SIDE, SIDE, SIDE

print("soldiers that arrive later")
local C = { type = "other", side = 1, record = 24, det = 1 }
do
	mission = { squid, me, A, B, corpse, dog, nodet, C }; set_units(mission)
	local snap = snapshot(); run(6)
	check(is(C, SIDE) and #changed(snap) == 3 and last_line("SEAF SET: 1 soldier now on side") ~= nil, "a soldier lands: set within 6 frames, three values and nothing else")
	C.side, C.copy, C.det = SIDE, SIDE, SIDE
	-- a unit ahead of them leaves the list: every slot moves up
	mission = { me, A, B, dog, nodet, C }; set_units(mission); snap = snapshot(); run(30)
	check(#changed(snap) == 0 and is(me, 1) and is(dog, 1), "the slots move up: nothing is written to whoever sits in the old slots")
	-- the game refreshes one soldier's list side from somewhere: the mod sets it again
	C.side = 1; set_units(mission); snap = snapshot(); run(6)
	check(is(C, SIDE) and #changed(snap) == 1, "one of a soldier's three places back on 0x1: that one is set again")
	C.side = SIDE
	local odd = { type = "other", side = 2, record = 24, det = 1 }
	mission = { me, A, B, dog, nodet, C, odd }; set_units(mission); snap = snapshot(); run(30)
	check(#changed(snap) == 0, "a soldier on a side this mod does not know is left alone")
	mission = { me, A, B, dog, nodet, C }; set_units(mission)
end

print("he dies and comes back")
do
	local D = { type = "other", side = 1, record = 24, det = 1 }
	set_units({ A, B, dog, nodet, C, D }); local snap = snapshot(); run(300)
	check(addon.rebel.on and #changed(snap) == 0, "no Helldiver on the ground for 300 frames: the mode stays on and writes nothing, not even to a new soldier")
	local me2 = { type = "hd", side = 1, record = 28 }
	set_units({ A, B, dog, nodet, C, D, me2 }); snap = snapshot(); run(6)
	check(is(D, SIDE) and is(me2, 1) and #changed(snap) == 3, "the reinforcement lands: the waiting soldier is set, the new Helldiver is untouched")
	D.side, D.copy, D.det = SIDE, SIDE, SIDE
	me = me2; mission = { A, B, dog, nodet, C, D, me }; set_units(mission)
end

print("switching off")
do
	local snap = snapshot(); press()
	check(not addon.rebel.on and is(A, 1) and is(B, 1) and is(C, 1) and is(mission[6], 1), "key again: every living soldier back on 0x1 in all three places")
	check(#changed(snap) == 12 and is(me, 1) and is(dog, 1), "twelve values changed, nothing else")
	check(last_line("REBEL MODE OFF (key pressed): 4 living soldiers put back to 0x1") ~= nil and last_line("rebel mode set 5 SEAF soldiers while it was on") ~= nil, "switching off is logged with the numbers (five sets: four soldiers, one of them set twice)")
	for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = 1, 1, 1 end end
	set_units(mission); snap = snapshot(); run(600)
	check(#changed(snap) == 0, "600 frames after switching off: nothing written")
	keys[KEY] = true; run(300); keys[KEY] = nil; run(2)
	check(addon.rebel.on, "a key held for 300 frames counts as one press"); press(); check(not addon.rebel.on and is(A, 1), "(off again)")
	for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = 1, 1, 1 end end
	set_units(mission); run(20)
end

print("refusals")
local function refuses(what, pattern)
	local snap = snapshot(); press(); run(20)
	check(not addon.rebel.on and #changed(snap) == 0 and last_line(pattern) ~= nil, what .. ": refused, nothing written")
end
me.side, me.copy = 8, 8; set_units(mission); run(20)
refuses("a Helldiver who is not on 0x1", "key ignored, rebel mode stays off: a Helldiver's side reads 0x8/0x8")
me.side, me.copy = 1, 1
local friend = { type = "hd", side = 1, record = 28 }
mission[#mission + 1] = friend; set_units(mission); run(20)
refuses("a second Helldiver with squad = 0", "key ignored, rebel mode stays off: 2 Helldivers in the mission (squad = 0: solo only)")
mission[#mission] = nil; set_units(mission)
w32(ms + 0x2FC84, 1000); run(20)
refuses("a count that is not a kill count", "key ignored, rebel mode stays off: the kill count reads 1000")
w32(ms + 0x2FC84, 0); run(20)
w32(det + 0x38, 100); run(20)
refuses("a detector table that does not look right", "key ignored, rebel mode stays off: detector table does not look right (size 100)")
w32(det + 0x38, DSIZE)
w32(mgr + 0x12030, 0x100); run(20)
refuses("a unit list that does not look right", "key ignored, rebel mode stays off: the unit list cannot be read")
w32(mgr + 0x12030, 0x200); run(20)
do
	protect(recs, 0x02)
	local snap = snapshot(); press(); run(20)
	check(addon.rebel.on and #changed(snap) == 0 and count_lines("could not set a soldier, nothing changed on him") == 1, "the record copy sits in read-only memory: the side write is undone, nothing changed, said once")
	protect(recs, 0x04); run(6)
	check(is(A, SIDE) and is(B, SIDE), "writable again: the soldiers are set")
	press(); check(not addon.rebel.on and is(A, 1) and is(B, 1), "(off)")
	set_units(mission); run(20)
end

print("it lets go by itself")
press(); check(addon.rebel.on and is(A, SIDE), "(on)")
do
	for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = SIDE, SIDE, SIDE end end
	mission[#mission + 1] = friend; set_units(mission); run(6)
	check(not addon.rebel.on and is(A, 1) and is(B, 1) and is(friend, 1) and last_line("REBEL MODE OFF (another Helldiver is in the mission and squad = 0)") ~= nil, "a second Helldiver appears with squad = 0: soldiers put back within 6 frames, mode off")
	for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = 1, 1, 1 end end
	write_cfg(string.format("key = %d\nside = %d\nguard = 0\nsquad = 1\n", KEY, SIDE))
	set_units(mission); run(20); local snap = snapshot(); press()
	check(addon.rebel.on and is(A, SIDE) and is(me, 1) and is(friend, 1) and #changed(snap) == 12, "squad = 1: on with two Helldivers, four soldiers set, neither Helldiver touched")
	check(last_line("mission; Helldivers 2; side 0x1/0x1 0x1/0x1; rebel mode ON") ~= nil, "and the state line shows both")
	press(); check(not addon.rebel.on and is(A, 1), "(off)")
	mission[#mission] = nil
	for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = 1, 1, 1 end end
	write_cfg(string.format("key = %d\nside = %d\nguard = 0\n", KEY, SIDE)); set_units(mission); run(20)
end
press(); check(addon.rebel.on, "(on)")
do
	local ship_me = { type = "hd", side = 1, record = 90 }
	set_units({ { type = "other", side = 1, record = 83 }, ship_me }); local snap = snapshot(); run(6)
	check(not addon.rebel.on and #changed(snap) == 0 and last_line("REBEL MODE OFF: no longer in a mission (ship)") ~= nil, "back on the ship: mode off, nothing written")
	run(600); check(not addon.rebel.on and #changed(snap) == 0, "and it stays off on the ship")
	for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = 1, 1, 1 end end
	set_units(mission); run(20)
end
press(); check(addon.rebel.on, "(on)")
w32(mgr + 0x12030, 0x100); run(30)
check(addon.rebel.on and last_line("rebel mode is on but the unit list cannot be read") ~= nil, "unit list unreadable while on: it waits and says so once")
w32(mgr + 0x12030, 0x200); run(6); check(addon.rebel.on, "readable again: still on")
press(); check(not addon.rebel.on, "(off)")
for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = 1, 1, 1 end end
set_units(mission); run(20)

print("the guards (guard = 1)")
local COUNT = ms + 0x2FC84
write_cfg(string.format("key = %d\nside = %d\nguard = 1\n", KEY, SIDE))
w32(COUNT, 3); run(60)
check(r32(COUNT) == 3, "mode off: a count of 3 is left alone")
press(); run(2)
check(addon.rebel.on and r32(COUNT) == 0 and last_line("COUNT GUARD: was 3, now 0 (3 kept off the count so far)") ~= nil, "switching on with 3 on the count: reset within two frames")
do
	local snap = snapshot()
	w32(COUNT, 7); run(1)
	check(r32(COUNT) == 0 and last_line("COUNT GUARD: was 7, now 0 (10 kept off the count so far)") ~= nil, "seven at once: reset the next frame, total kept")
	w32(tl + 0x410, 0x2d9); w32(tl + 0x490, 1); w32(tl + 0x494, 0x41200000)
	local tsnap = snapshot()
	w32(tl + 0x450, 1); run(1)
	check(r32(tl + 0x450) == 0 and last_line("TALLY GUARD: slot 0 was 1, now 0 (1 kept off the traitor tally so far)") ~= nil, "a kill on the traitor tally: back to 0 the next frame, logged")
	w32(tl + 0x450, 5); w32(tl + 0x48C, 2); run(1)
	check(r32(tl + 0x450) == 0 and r32(tl + 0x48C) == 0, "five in slot 0 and two in slot 15 (a friend's): both reset the next frame")
	w32(tl + 0x450, 6); run(1)
	check(r32(tl + 0x450) == 0 and last_line("IT REACHED SIX BEFORE THE RESET") ~= nil, "six at once: reset, and the log says it reached six")
	check(#changed(tsnap) == 0 and r32(tl + 0x410) == 0x2d9 and r32(tl + 0x494) == 0x41200000, "the tally's ids, next slot and timer are never touched")
	w32(tl + 0x450, 1000); run(30); check(r32(tl + 0x450) == 1000, "a value that is not a tally is left alone"); w32(tl + 0x450, 0)
	protect(tl, 0x02); w32(tl + 0x450, 2); run(30)
	check(r32(tl + 0x450) == 2 and count_lines("TALLY GUARD could not write") == 1, "tally in read-only memory: not written, said once")
	protect(tl, 0x04); run(2); check(r32(tl + 0x450) == 0, "writable again: reset")
	w32(ms + 0x2FC80, 5); run(5); check(r32(ms + 0x2FC80) == 5, "the value before the count is never touched")
	w32(COUNT, 1000); run(30); check(r32(COUNT) == 1000, "a value that is not a kill count is left alone"); w32(COUNT, 0)
end
do
	local alive = {}
	for _, u in ipairs(mission) do if u.type ~= "hd" then alive[#alive + 1] = u end end
	for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = SIDE, SIDE, SIDE end end
	set_units(alive); run(20); w32(COUNT, 4); w32(tl + 0x450, 3); run(2)
	check(addon.rebel.on and r32(COUNT) == 0 and r32(tl + 0x450) == 0, "while he is dead, the guards still hold the count and the tally")
	set_units(mission); run(6)
end
press(); w32(COUNT, 2); w32(tl + 0x450, 3); run(60)
check(not addon.rebel.on and r32(COUNT) == 2 and r32(tl + 0x450) == 3 and last_line("count guard: ") ~= nil and last_line("tally guard: ") ~= nil, "mode off by key: the guards stop with it and log their totals")
w32(COUNT, 0); w32(tl + 0x450, 0)
for _, u in ipairs(mission) do if u.record == 24 and u.det then u.side, u.copy, u.det = 1, 1, 1 end end
set_units(mission); run(20)
write_cfg(string.format("key = %d\nside = %d\nguard = 1\nguard_at = 4\n", KEY, SIDE))
press(); w32(COUNT, 3); run(30); check(r32(COUNT) == 3, "guard_at = 4: a count of 3 is left")
w32(COUNT, 4); run(1); check(r32(COUNT) == 0, "and 4 is reset")

print("settings")
do
	local parse = addon.test.parse_cfg
	local c, note = parse("key = 122\nside = 3\n")
	check(c.key == 120 and c.side == 0 and note:find("F11", 1, true) and note:find("only 0, 2, 4 or 8", 1, true), "F11 and side 3 are refused, defaults used")
	c = parse("side = 2\n"); check(c.side == 2, "side 2 can be forced")
	c = parse("# x\r\nkey=119 # F8\r\n side = 8\r\nrubbish\r\nreapply = 1\r\n")
	check(c.key == 119 and c.side == 8, "a hand-edited file with Windows line ends and an old reapply line is read")
	c, note = parse("key = 999\nkey = 117\n")
	check(c.key == 120 and note:find("F6", 1, true), "a number that is no key, and F6, are refused")
	c = parse("")
	check(c.key == 120 and c.side == 0 and c.guard == 1 and c.guard_at == 1 and c.squad == 0, "an empty file means the defaults: F9, join the enemy on the map, guard on at 1, solo only")
	c, note = parse("squad = 2\nguard = 7\nguard_at = 9\n")
	check(c.squad == 0 and c.guard == 1 and c.guard_at == 1 and note:find("guard_at 9 refused", 1, true) and note:find("squad 2 refused", 1, true), "out-of-range squad, guard and guard_at are refused")
	c = parse("squad = 1\nguard = 0\nguard_at = 8\n")
	check(c.squad == 1 and c.guard == 0 and c.guard_at == 8, "squad can be switched on, the guard off; guard_at up to 8")
end

if mode == nil then
	print("host only")
	check(addon.rebel.on and is(A, SIDE), "(on from above)")
	set_peers(0x0110000100001234ULL, 0x0110000100009999ULL); run(20)
	check(not addon.rebel.on and is(A, 1) and is(B, 1) and last_line("REBEL MODE OFF (this game is no longer the host)") ~= nil, "no longer the host: soldiers put back, mode off")
	check(last_line("rebel mode off, would refuse: this game is not the host (only the host's key works)") ~= nil, "someone else hosts: would refuse")
	do
		local snap = snapshot(); press(); run(20)
		check(not addon.rebel.on and last_line("key ignored, rebel mode stays off: this game is not the host") ~= nil and #changed(snap) == 0, "key in someone else's mission: ignored, not one byte changed")
	end
	wptr(slot_of.network, 0); run(20)
	check(last_line("would refuse: cannot tell who hosts (no network context yet)") ~= nil, "no network context: would refuse")
	press(); run(20)
	check(not addon.rebel.on and last_line("key ignored, rebel mode stays off: cannot tell who hosts") ~= nil, "no network context: key ignored")
	wptr(slot_of.network, net); set_peers(0x0110000100001234ULL, 0x0110000100001234ULL); run(20)
	press(); run(20)
	check(addon.rebel.on and is(A, SIDE), "hosting again, the key: rebel mode on, a soldier set")
end

if mode == nil then
	print("key on the game's bindings page")
	local row = menu.registered["vibeslacker.chaos_divers.rebel_mode"]
	check(row and row.label == "Rebel Mode On/Off" and row.category == "Chaos Divers" and row.slot == nil, "registered on the MODS tab under Chaos Divers, after a refused first try")
	check(last_line("key: on the game's bindings page under MODS > CHAOS DIVERS") ~= nil and last_line("key: the bindings page refused it (stand-in not ready)") ~= nil, "both logged")
	check(addon.rebel.on, "(on from above, switched by the settings-file key while the menu row was unused)")
	menu.down = true; run(3); menu.down = false; run(20)
	check(not addon.rebel.on and is(A, 1) and last_line("key: a key set on the bindings page was used") ~= nil, "the bindings-page key switches it off, and takes over")
	press(); run(20)
	check(not addon.rebel.on, "after that the settings-file key is ignored")
	menu.down = true; run(30); menu.down = false; run(20)
	check(addon.rebel.on and is(A, SIDE), "the bindings-page key switches it on again, once for one long press")
end

print("shutdown")
check(last_line("stopped on error") == nil, "no error all run")
check(addon.rebel.on and is(A, SIDE), "(still on from above)")
rawget(_G, "shutdown")()
check(shut and is(A, 1) and is(B, 1) and is(me, 1), "shutdown with the mode on: the soldiers are put back, shutdown passed on")
check(last_line("REBEL MODE OFF (game shutting down)") ~= nil, "and it is logged")
do
	local f = assert(io.open(built)); local text = f:read("*a"); f:close()
	check(not text:find("VirtualProtect", 1, true), "the built file never changes page protections")
	local writable = 0
	for cast in text:gmatch('ffi%.cast%("([^"]+)"') do
		if cast:find("%*") and not cast:find("^const ") and cast ~= "void *" then writable = writable + 1 end
	end
	check(writable == 1, "the built file has exactly one writable pointer into game memory (the 4-byte write)")
	local calls = 0
	for _ in text:gmatch("put32%(") do calls = calls + 1 end
	check(calls == 5, "that write is used in exactly four places (a soldier's value, its undo, the count, the traitor tally), plus its definition")
	check(not text:find("d.at_side", 1, true) and not text:find("d.at_copy", 1, true), "no code path writes to a Helldiver's side")
end
print(failures == 0 and "ALL PASSED" or (failures .. " FAILED"))
os.exit(failures == 0 and 0 or 1)
