-- HD2-Addon: mods/vibeslacker/chaos_divers
-- Chaos Divers: Dissident Discovery (was "Rebel SEAF", then "Dissident Crackdown"), test build 0.10, for Bingus Shared Loader v15+.
--
-- Rebel mode: one key (F9 unless the settings file says otherwise) turns the
-- SEAF soldiers into an enemy side. The same key switches it off again. Off at
-- every game start. Helldivers, guard dogs and sentries are never written, so
-- your own dog and sentries stay on your side and fight the soldiers.
-- What it writes, per SEAF soldier (record number 24), each value read back:
--   the soldier's side in the game's unit list, the copy in its record, and the
--   copy its detector keeps (the one it judges targets against): three 4-byte
--   values, 0x1 -> the rebel side. Soldiers are set as they appear, a few
--   times a second, while the mode is on and a Helldiver is on the ground.
-- The rebel side (side = 0, the default): the rebels join whatever enemy holds
--   the map. The mod counts the living enemy units on each enemy side (0x2,
--   0x4 = the Illuminate, 0x8) and takes the side with the most, once at least
--   three are seen; until then the soldiers are left alone. The side is kept
--   until the mode goes off and chosen again the next time it goes on.
--   side = 2, 4 or 8 forces that side instead.
-- It only switches on when: you are in a mission, every Helldiver in it reads
-- the normal 0x1, yours is the only one unless squad = 1, and the SEAF kill
-- count reads like a kill count. Otherwise the key press is logged with the
-- reason and nothing is written.
-- It puts the living soldiers back to 0x1 (only where a value still reads what
-- this mod set) when: the key is pressed again, another Helldiver appears while
-- squad = 0, or the game shuts down. Back on the ship the mode is always off.
-- Guard (guard = 1), two parts, both only in a mission while rebel mode is on:
-- 1. The traitor tally. The game keeps 16 tallies of friendly kills (one per
--    killer); each kill adds one, ten seconds without a kill takes one off, and
--    six makes you a traitor and brings the destroyer. A rebel soldier still
--    counts as a friendly kill. Every frame, any tally that reads 1 to 64 is
--    set back to 0. This is what keeps the destroyer away.
-- 2. The SEAF kill count (the fine and end-of-mission figure) is set back to 0
--    the frame it reaches guard_at (1 = after every kill).
-- Each is a 4-byte write, read back like the others, only on a value that
-- reads like what it should be. The tally's ids and timer are never written.
-- The requisition fine for SEAF kills is not touched on purpose.
--
-- It also logs, on every change, where you are, each Helldiver's side, the
-- SEAF kill count (+0x2FC84 of the mission state) and the value before it.
--
-- Banner (banner = 1, new in 0.8): when rebel mode switches on, "DISSIDENT CELL DISCOVERED" shows across
-- the upper middle of the screen for five seconds and fades out over one. Drawn with the game's own Gui and
-- font, the way the Passive Picker draws its box (the engine's debug font if the game's is not found). Only
-- draws; it writes nothing to the game. If drawing fails it switches itself off and the mod carries on.
-- 0.9: restyled after the game's own MISSION COMPLETED banner (from a screenshot of it, 2026-10-14):
-- orange title on a dark band that fades at its ends, three orange speed stripes either side, and the
-- line under it in white capitals on its own dark box. Sizes are the screenshot's at 1080 lines, scaled.
--
-- Host only (new in 0.9): the key works only in the game that hosts the mission. The game's network
-- context (the "network" signature; the layout Better Lobby Management reads in build 25480438) holds this
-- player's peer id at +0xB398 and the host's at +0xB3A8; equal means this game hosts (solo is always the host).
-- If it cannot be read, the key is refused. Rebel mode that is on is put back if this game stops being the host.
--
-- Key on the game's own bindings page (new in 0.9): with Mod Bindings Menu (Vanilla Plus) installed,
-- "Rebel Mode On/Off" sits on the MODS tab under CHAOS DIVERS. The row starts empty; the settings-file key (F9)
-- counts until a key set there is first used, then only that key counts for the rest of the session. Without
-- the menu, or if it stops answering, the settings-file key works as before.
--
-- 0.10: renamed to Dissident Discovery; files, global, loader path and bindings id renamed with it
--       (the files were RebelSEAF.*). No other change.
-- Settings: Logs/ChaosDivers.cfg (key, side, guard, guard_at, squad, banner; read again at every key press)
-- Log: Logs/ChaosDivers.log (in the CowboyBingus log folder); the last session's
--      is kept as ChaosDivers.previous.log.
--
-- How the game stores it (worked out 2026-10-11 to 2026-10-13, build 25480438):
--   faction manager -> capacity 0x200 at +0x12030, unit count at +0x1203C,
--                      per slot: unit pointer (+0x12068), 0x60-byte record
--                      (+0x12070; record number at +0, a copy of the side at
--                      +0xC), side value (+0x12078)
--   a unit starts with an 8-byte type code (the Helldiver's is 4d1c334d294dfa97)
--   and its 4-byte id at +8
--   record number 28 = Helldiver in a mission, 90 = on the ship, 24 = SEAF soldier
--   detector        -> lookup table of (id, slot) pairs at +0x30 (size +0x38,
--                      empty marker +0x3C, step +0x40), records of 0x13F8 bytes
--                      at +0x50; a record's +0x13E8 is the unit's own copy of
--                      its side. A target is hostile to a unit when that copy
--                      and the target's side share no bit.
--   mission state   -> one object; the game reads the kill count as
--                      [game.dll slot] + 0x2FC84
if rawget(_G, "ChaosDivers") then return true end
local REVISION = "Chaos Divers: Dissident Discovery test 0.10"
local state = { revision = REVISION, frames = 0, status = "starting" }
rawset(_G, "ChaosDivers", state)

local ffi = require("ffi")
local bit = require("bit")
local DIR = (os.getenv("LOCALAPPDATA") or ".") .. "/CowboyBingus/Helldivers2/Logs/"
local LOG = DIR .. "ChaosDivers.log"
pcall(function () local old = DIR .. "ChaosDivers.previous.log" os.remove(old) os.rename(LOG, old) end)
pcall(function () local f = io.open(LOG, "w") if f then f:write(REVISION .. "\n") f:close() end end)
local lines = 0
local function log(text)
	state.status = text
	lines = lines + 1
	if lines > 4000 then return end
	pcall(function ()
		local f = io.open(LOG, "a")
		if f then f:write(os.date("%H:%M:%S") .. " [frame " .. state.frames .. "] " .. text, "\n") f:close() end
	end)
end

-- ------------------------------------------------------------------ data
-- Filled in by build.py from data/sigs.json.
local SIGS = --@SIGS@

-- ------------------------------------------------------------------ memory
pcall(ffi.cdef, [[
typedef struct {
  void *base; void *allocation_base; uint32_t allocation_protection;
  uint16_t partition; uint16_t reserved; size_t size;
  uint32_t state; uint32_t protection; uint32_t type;
} CD_Region;]])
pcall(ffi.cdef, "size_t VirtualQuery(const void *address, void *region, size_t size);")
pcall(ffi.cdef, "void *GetModuleHandleA(const char *name);")
pcall(ffi.cdef, "short GetAsyncKeyState(int key);")
pcall(ffi.cdef, "void *GetForegroundWindow(void);")
pcall(ffi.cdef, "uint32_t GetWindowThreadProcessId(void *window, uint32_t *pid);")
pcall(ffi.cdef, "uint32_t GetCurrentProcessId(void);")
local kernel = ffi.load("kernel32")
local user = ffi.load("user32")
local MEM_COMMIT = 0x1000
local READABLE = { [0x02] = true, [0x04] = true, [0x08] = true, [0x20] = true, [0x40] = true, [0x80] = true }
local LOW, HIGH = 0x10000, 0x7FFFFFFFFFFF
local region = ffi.new("CD_Region[1]")
local RSIZE = ffi.sizeof(region[0])

local function query(addr)
	if type(addr) ~= "number" or addr < LOW or addr > HIGH then return nil end
	if kernel.VirtualQuery(ffi.cast("void *", addr), region, RSIZE) ~= RSIZE then return nil end
	local r = region[0]
	return tonumber(ffi.cast("uintptr_t", r.base)), tonumber(r.size),
		r.state == MEM_COMMIT and READABLE[tonumber(r.protection)] == true, tonumber(r.protection)
end

-- true when [a, a+n) is committed, readable memory (may span regions)
local function readable(a, n)
	if type(a) ~= "number" then return false end
	local stop = a + n
	while a < stop do
		local b, s, ok = query(a)
		if not ok then return false end
		a = b + s
	end
	return true
end

local function u32(a) return tonumber(ffi.cast("const uint32_t *", a)[0]) end
local function ptr(a)
	local p = ffi.cast("const uint32_t *", a)
	local lo, hi = tonumber(p[0]), tonumber(p[1])
	if hi >= 32768 then return nil end
	local v = lo + hi * 4294967296
	if v < LOW then return nil end
	return v
end
local function need(a, n, what)
	if not (a and readable(a, n)) then error(what .. " unreadable", 0) end
	return a
end

-- ------------------------------------------------------------------ writing
-- The one kind of write this mod makes: a 4-byte value into plain writable
-- memory, read back afterwards. Page protections are never changed.
local function put32(a, v)
	local _, _, ok, prot = query(a)
	if not ok or not readable(a, 4) then return false, "unreadable" end
	if prot ~= 0x04 then return false, "not plain writable memory (protection " .. tostring(prot) .. ")" end
	ffi.cast("uint32_t *", a)[0] = v
	if u32(a) ~= v then return false, "read-back differs" end
	return true
end

-- ------------------------------------------------------------------ keys
local pidbox = ffi.new("uint32_t[1]")
local function game_focused()
	local w = user.GetForegroundWindow()
	if w == nil then return false end
	user.GetWindowThreadProcessId(w, pidbox)
	return pidbox[0] == kernel.GetCurrentProcessId()
end
local held = {}
local function pressed(vk)
	local down = bit.band(user.GetAsyncKeyState(vk), 0x8000) ~= 0
	local edge = down and not held[vk]
	held[vk] = down
	return edge and game_focused()
end

-- The key on the game's bindings page, through Mod Bindings Menu (optional). Registration is retried once a
-- 60 frames (about a second) for 60 tries, since addons load in no fixed order. is_down is a level; the edge is worked out here.
local MENU_ID, MENU_LABEL, MENU_CATEGORY = "vibeslacker.chaos_divers.rebel_mode", "Rebel Mode On/Off", "Chaos Divers"
local menu_key = { registered = false, tries = 0, next_try = 0, was = nil, taken = false, last = nil, file_frame = -1000 }
local function bindings_menu()
	local m = rawget(_G, "ModBindingsMenu")
	if type(m) ~= "table" or rawget(m, "api") ~= 1 or type(rawget(m, "version")) ~= "number" or m.version < 2 then return nil end
	return m
end
local function menu_pressed(frame)
	local m = bindings_menu()
	if not m then return false end
	if not menu_key.registered then
		if menu_key.tries >= 60 or frame < menu_key.next_try then return false end
		menu_key.next_try, menu_key.tries = frame + 60, menu_key.tries + 1
		local ok, done, why = pcall(m.register_binding, MENU_ID, MENU_LABEL, nil, { category = MENU_CATEGORY })
		if ok and done == true then
			menu_key.registered = true
			log("key: on the game's bindings page under MODS > CHAOS DIVERS (" .. MENU_LABEL .. "); the settings-file key counts until a key set there is used")
		else
			local note = "key: the bindings page refused it (" .. tostring(ok and why or done) .. "); the settings-file key is used"
			if note ~= menu_key.last then menu_key.last = note; log(note) end
		end
		return false
	end
	local ok, down = pcall(m.is_down, MENU_ID)
	if not ok or down == nil then menu_key.was = nil return false end
	local was = menu_key.was
	menu_key.was = down == true
	return down == true and was == false and game_focused()
end

-- This frame's on/off press, from the bindings page or the settings-file key.
local function key_pressed(frame, vk)
	local from_menu, from_file = menu_pressed(frame), pressed(vk)
	if from_file then menu_key.file_frame = frame end
	if from_menu and not menu_key.taken then
		menu_key.taken = true
		log("key: a key set on the bindings page was used; only it counts from now on (the settings-file key is ignored until the game restarts)")
		-- the same key set in both places, seen a few frames apart: one press, not two
		if frame - menu_key.file_frame <= 10 then return false end
	end
	return from_menu or (from_file and not menu_key.taken)
end

-- ------------------------------------------------------------------ settings
local CFG = DIR .. "ChaosDivers.cfg"
local DEFAULTS = { key = 120, side = 0, guard = 1, guard_at = 1, squad = 0, banner = 1 }
local BAD_KEYS = { [117] = "F6 is the Passive Picker's", [118] = "F7 is the Reroller's", [122] = "F11 is Steam's", [123] = "F12 is Steam's" }
local function defaults() local t = {} for k, v in pairs(DEFAULTS) do t[k] = v end return t end
local cfg = defaults()
local cfg_note = nil
local function parse_cfg(text)
	local out, notes = defaults(), {}
	for line in (text or ""):gmatch("[^\r\n]+") do
		local name, value = line:gsub("#.*$", ""):match("^%s*([%a_]+)%s*=%s*(%S+)%s*$")
		local n = value and tonumber(value)
		if name == "key" and n then
			n = math.floor(n)
			if n < 1 or n > 254 then notes[#notes + 1] = "key " .. value .. " is not a key number; using F9"
			elseif BAD_KEYS[n] then notes[#notes + 1] = "key " .. n .. " refused (" .. BAD_KEYS[n] .. "); using F9"
			else out.key = n end
		elseif name == "side" and n then
			if n == 0 or n == 2 or n == 4 or n == 8 then out.side = n
			else notes[#notes + 1] = "side " .. value .. " refused (only 0, 2, 4 or 8); using 0 (join the enemy on the map)" end
		elseif (name == "guard" or name == "squad" or name == "banner") and n then
			if n == 0 or n == 1 then out[name] = n
			else notes[#notes + 1] = name .. " " .. value .. " refused (only 0 or 1); using " .. DEFAULTS[name] end
		elseif name == "guard_at" and n then
			n = math.floor(n)
			if n >= 1 and n <= 8 then out.guard_at = n
			else notes[#notes + 1] = "guard_at " .. value .. " refused (1 to 8); using 1" end
		end
	end
	return out, table.concat(notes, "; ")
end
local function load_cfg()
	local f = io.open(CFG)
	if not f then
		pcall(function ()
			local w = io.open(CFG, "w")
			if w then
				w:write("# Chaos Divers settings. Read again every time the key is pressed.\n",
					"# key: Windows key number of the on/off key. 120 = F9. (F6, F7, F11, F12 are refused.)\n",
					"#   With Mod Bindings Menu installed you can also set it in the game: Options, bindings, MODS tab, CHAOS DIVERS.\n",
					"#   Once a key set there is used, this one is ignored until the game restarts.\n",
					"key = 120\n",
					"# side: the side the SEAF soldiers are put on while rebel mode is on.\n",
					"#   0 = join whatever enemy holds the map (squids, bugs or bots), chosen each time the mode goes on.\n",
					"#   4 = always the squids' side.   2 or 8 = always that side (the bugs' and bots' sides; which is which is not known yet).\n",
					"side = 0\n",
					"# guard: 1 = while rebel mode is on, the traitor tally and the SEAF kill count are kept at 0 so the destroyer never comes. 0 = off.\n",
					"guard = 1\n",
					"# guard_at: the count is set back to 0 when it reaches this (1 to 8). 1 = after every kill.\n",
					"guard_at = 1\n",
					"# squad: 0 = solo only. 1 = also with other Helldivers in the mission (private lobby, friends who know).\n",
					"squad = 0\n",
					"# banner: 1 = show DISSIDENT CELL DISCOVERED on screen when rebel mode switches on. 0 = off.\n",
					"banner = 1\n")
				w:close()
			end
		end)
		return
	end
	local text = f:read("*a"); f:close()
	local new, note = parse_cfg(text)
	if note ~= "" and note ~= cfg_note then log("settings: " .. note) end
	cfg_note = note
	local changed = false
	for k in pairs(DEFAULTS) do if new[k] ~= cfg[k] then changed = true end end
	if changed then
		log(string.format("settings: key %d, side 0x%X, guard %d at %d, squad %d, banner %d", new.key, new.side, new.guard, new.guard_at, new.squad, new.banner))
	end
	cfg = new
end

-- ------------------------------------------------------------------ signatures
local function unhex(h)
	local t = {}
	for i = 1, #h, 2 do t[#t + 1] = tonumber(h:sub(i, i + 1), 16) end
	return t
end

local base, image_size
local scan = nil
local globals = nil   -- name -> absolute address of the global slot

local function prepare_scan()
	local handle = kernel.GetModuleHandleA("game.dll")
	if handle == nil then error("game.dll not loaded", 0) end
	base = tonumber(ffi.cast("uintptr_t", handle))
	need(base, 0x1000, "game.dll header")
	local pe = base + u32(base + 0x3C)
	need(pe, 0x100, "game.dll PE header")
	if u32(pe) ~= 0x00004550 then error("game.dll PE signature missing", 0) end
	image_size = u32(pe + 0x50)
	if image_size < 0x100000 or image_size > 0x20000000 then error("game.dll size rejected", 0) end
	state.pe_timestamp = u32(pe + 8)
	for _, s in ipairs(SIGS) do
		s.bytes, s.maskb, s.anchorb = unhex(s.hex), unhex(s.mask), unhex(s.anchor)
		local a = s.anchorb
		s.key = a[1] + a[2] * 256 + a[3] * 65536 + a[4] * 16777216
		s.hits = {}
	end
	scan = { cursor = base }
	log(string.format("game.dll at 0x%X, size %d, stamp %d; scanning for %d signatures",
		base, image_size, state.pe_timestamp, #SIGS))
end

local function matches(s, at)
	local p = ffi.cast("const uint8_t *", at)
	local b, m = s.bytes, s.maskb
	for i = 1, #b do
		if m[i] ~= 0 and p[i - 1] ~= b[i] then return false end
	end
	return true
end

local SLICE = 0.004
local function scan_step()
	local deadline = os.clock() + SLICE
	local stop_all = base + image_size
	while os.clock() < deadline do
		if scan.cursor >= stop_all then return true end
		local b, s, ok = query(scan.cursor)
		if not b or s <= 0 then return true end
		local rend = math.min(b + s, stop_all)
		if ok then
			local from = scan.cursor
			local to = math.min(rend, from + 262144)
			local p = ffi.cast("const uint8_t *", from)
			local last = to - from - 4
			for i = 0, last do
				local v = p[i] + p[i + 1] * 256 + p[i + 2] * 65536 + p[i + 3] * 16777216
				for k = 1, #SIGS do
					local sig = SIGS[k]
					if v == sig.key then
						local start = from + i - sig.anchor_offset
						if start >= base and start + #sig.bytes <= stop_all
							and readable(start, #sig.bytes) and matches(sig, start) then
							sig.hits[#sig.hits + 1] = start
						end
					end
				end
			end
			-- step back 3 bytes so a key straddling two chunks is not missed
			scan.cursor = (to < rend) and (to - 3) or rend
		else
			scan.cursor = rend
		end
	end
	return false
end

local function resolve_globals()
	globals = {}
	for _, s in ipairs(SIGS) do
		local seen, count, first = {}, 0, nil
		for _, at in ipairs(s.hits) do
			if not seen[at] then seen[at] = true; count = count + 1; first = first or at end
		end
		if count ~= 1 and s.optional then
			log(string.format("signature %s matched %d times; %s", s.name, count, s.symbol == "network"
				and "the key is refused, since this game cannot tell who hosts" or "the banner uses the engine's debug font instead"))
		elseif count ~= 1 then
			error(string.format("signature %s matched %d times (need exactly 1); the game was probably updated", s.name, count), 0)
		end
		if count == 1 then
			local rel = u32(first + s.extract_offset)
			if rel >= 2147483648 then rel = rel - 4294967296 end
			local slot = first + s.extract_end + rel
			if slot < base or slot + 8 > base + image_size then
				error("signature " .. s.name .. " points outside game.dll", 0)
			end
			if globals[s.symbol] and globals[s.symbol] ~= slot then
				error("signatures disagree about " .. s.symbol, 0)
			end
			globals[s.symbol] = slot
			log(string.format("signature %s at game.dll+0x%X -> %s slot game.dll+0x%X",
				s.name, first - base, s.symbol, slot - base))
		end
	end
	if not (globals.faction_manager and globals.mission_state and globals.traitor_tally and globals.detector) then error("a needed signature is missing from this build", 0) end
end

-- ------------------------------------------------------------------ the unit list
local HD_LO, HD_HI = 0x294dfa97, 0x4d1c334d   -- the Helldiver's type code, low and high half
local REC_MISSION, REC_SHIP, REC_SEAF = 28, 90, 24
local SIDE_HOME = 0x1

-- One readable-memory answer is kept while a pass walks neighbouring addresses.
local span_lo, span_hi = 0, 0
local function near(a, n)
	if a >= span_lo and a + n <= span_hi then return true end
	local b, s, ok = query(a)
	if not ok then return false end
	span_lo, span_hi = b, b + s
	return a + n <= span_hi or readable(a, n)
end

-- Returns a table: where ("none", "ship", "mission", "other"), divers and soldiers_list (lists of
-- { side, copy, record, unit, id, at_side, at_copy }; soldiers_list holds the living SEAF soldiers),
-- soldiers (how many), units; or nil and why.
-- A slot number is only good for the frame it was read in: units move up when one leaves.
local function read_units()
	span_lo, span_hi = 0, 0
	if not readable(globals.faction_manager, 8) then return nil, "unit list slot unreadable" end
	local mgr = ptr(globals.faction_manager)
	if not mgr then return nil, "no unit list yet" end
	if not readable(mgr + 0x12030, 0x50) then return nil, "unit list unreadable" end
	local cap, n = u32(mgr + 0x12030), u32(mgr + 0x1203C)
	if cap ~= 0x200 then return nil, string.format("unit list does not look right (capacity 0x%X, expected 0x200)", cap) end
	if n > cap then return nil, "unit list does not look right (count " .. n .. ")" end
	local out = { where = "none", divers = {}, soldiers = 0, soldiers_list = {}, units = n, enemy = { [2] = 0, [4] = 0, [8] = 0 } }
	if n == 0 then return out end
	local ents, recs, masks = ptr(mgr + 0x12068), ptr(mgr + 0x12070), ptr(mgr + 0x12078)
	if not (ents and recs and masks and readable(ents, 8 * n) and readable(recs, 0x60 * n) and readable(masks, 4 * n)) then
		return nil, "unit list arrays unreadable"
	end
	local records = {}
	for i = 0, n - 1 do
		local side, record = u32(masks + 4 * i), u32(recs + 0x60 * i)
		local unit = ptr(ents + 8 * i)
		if unit and near(unit, 12) and u32(unit) == HD_LO and u32(unit + 4) == HD_HI then
			out.divers[#out.divers + 1] = { side = side, copy = u32(recs + 0x60 * i + 0xC), record = record,
				unit = unit, id = u32(unit + 8), at_side = masks + 4 * i, at_copy = recs + 0x60 * i + 0xC }
			records[record] = true
		elseif record == REC_SEAF and side ~= 0 then
			out.soldiers = out.soldiers + 1
			if unit and near(unit, 12) then
				out.soldiers_list[#out.soldiers_list + 1] = { side = side, copy = u32(recs + 0x60 * i + 0xC), record = record,
					unit = unit, id = u32(unit + 8), at_side = masks + 4 * i, at_copy = recs + 0x60 * i + 0xC }
			end
		elseif out.enemy[side] then
			out.enemy[side] = out.enemy[side] + 1
		end
	end
	if #out.divers > 0 then
		local only = next(records)
		if next(records, only) ~= nil then out.where = "other"
		elseif only == REC_MISSION then out.where = "mission"
		elseif only == REC_SHIP then out.where = "ship"
		else out.where = "other" end
	end
	return out
end

-- ------------------------------------------------------------------ the kill count
-- Returns count, value before it, the count's address; or nil and why.
local OFF_BEFORE, OFF_COUNT = 0x2FC80, 0x2FC84
local function read_count()
	if not readable(globals.mission_state, 8) then return nil, "mission state slot unreadable" end
	local ms = ptr(globals.mission_state)
	if not ms then return nil, "mission state not set yet" end
	if not readable(ms + OFF_BEFORE, 8) then return nil, "mission state unreadable" end
	return u32(ms + OFF_COUNT), u32(ms + OFF_BEFORE), ms + OFF_COUNT
end

-- ------------------------------------------------------------------ the traitor tally
-- 16 four-byte tallies at +0x450 of the object the traitor_tally slot points to.
-- Returns the address of the first tally, or nil and why.
local OFF_TALLY, TALLY_SLOTS = 0x450, 16
local function read_tally()
	if not readable(globals.traitor_tally, 8) then return nil, "traitor tally slot unreadable" end
	local obj = ptr(globals.traitor_tally)
	if not obj then return nil, "traitor tally not set yet" end
	if not readable(obj + OFF_TALLY, 4 * TALLY_SLOTS) then return nil, "traitor tally unreadable" end
	return obj + OFF_TALLY
end

-- ------------------------------------------------------------------ the detector
-- Returns the lookup table (tab, size, empty, step, records), or nil and why.
local OFF_DET_COPY, DET_RECORD = 0x13E8, 0x13F8
local function detector_table()
	if not readable(globals.detector, 8) then return nil, "detector slot unreadable" end
	local det = ptr(globals.detector)
	if not det then return nil, "detector not set yet" end
	if not readable(det + 0x30, 0x28) then return nil, "detector unreadable" end
	local t = { tab = ptr(det + 0x30), size = u32(det + 0x38), empty = u32(det + 0x3C), step = u32(det + 0x40), records = ptr(det + 0x50) }
	if not (t.tab and t.records) then return nil, "detector table not set yet" end
	if t.size < 16 or t.size > 65536 or bit.band(t.size, t.size - 1) ~= 0 then return nil, "detector table does not look right (size " .. t.size .. ")" end
	if not readable(t.tab, 8 * t.size) then return nil, "detector table unreadable" end
	return t
end
-- low 32 bits of a * b, as the game's own 32-bit multiply gives
local function mul32(a, b)
	local al, ah = a % 65536, math.floor(a / 65536)
	return (al * b + ((ah * b) % 65536) * 65536) % 4294967296
end
-- The address of a unit's detector copy of its side, or nil when it has no detector record.
local function detector_copy_at(t, id)
	local h = mul32(t.step, id)
	for i = 0, t.size - 1 do
		local e = t.tab + 8 * ((i + h) % t.size)
		local eid = u32(e)
		if eid == id then
			local slot = u32(e + 4)
			if slot == 4294967295 then return nil end
			local a = t.records + slot * DET_RECORD + OFF_DET_COPY
			if readable(a, 4) then return a end
			return nil
		elseif eid == t.empty then return nil end
	end
end

-- ------------------------------------------------------------------ the host
local NET_LOCAL, NET_HOST = 0xB398, 0xB3A8
-- true when this game hosts, false when someone else does, nil and why when it cannot be read.
local function is_host()
	if not globals.network then return nil, "the network signature was not found in this build" end
	if not readable(globals.network, 8) then return nil, "the network slot is unreadable" end
	local ctx = ptr(globals.network)
	if not ctx then return nil, "no network context yet" end
	if not (readable(ctx + NET_LOCAL, 8) and readable(ctx + NET_HOST, 8)) then return nil, "the network context is unreadable" end
	local me, host = ffi.cast("const uint32_t *", ctx + NET_LOCAL), ffi.cast("const uint32_t *", ctx + NET_HOST)
	return me[0] == host[0] and me[1] == host[1]
end

-- ------------------------------------------------------------------ may rebel mode switch on?
local function would_arm(units, count)
	if not units then return false, "the unit list cannot be read" end
	if units.where ~= "mission" then return false, "not in a mission (" .. units.where .. ")" end
	local host, unknown = is_host()
	if host == nil then return false, "cannot tell who hosts (" .. unknown .. ")" end
	if not host then return false, "this game is not the host (only the host's key works)" end
	if #units.divers > 1 and cfg.squad ~= 1 then return false, #units.divers .. " Helldivers in the mission (squad = 0: solo only)" end
	for _, d in ipairs(units.divers) do
		if d.side ~= SIDE_HOME or d.copy ~= SIDE_HOME then
			return false, string.format("a Helldiver's side reads 0x%X/0x%X, not 0x1/0x1", d.side, d.copy)
		end
	end
	if not count then return false, "the kill count cannot be read" end
	if count > 64 then return false, "the kill count reads " .. count .. ", which is not a kill count" end
	return true
end

-- ------------------------------------------------------------------ the rebel side
local FRONT = { [2] = "0x2 (bugs or bots)", [4] = "0x4 (the Illuminate)", [8] = "0x8 (bugs or bots)" }
local ENEMY_MIN = 3
-- The side the rebels join: the settings file's, or with side = 0 the enemy side with the most living units
-- (at least ENEMY_MIN). Returns the side and how it was chosen, or nil while no enemy is on the map.
local function pick_side(units)
	if cfg.side ~= 0 then return cfg.side, "set in the settings file" end
	local best, most = nil, 0
	for _, side in ipairs({ 2, 4, 8 }) do
		if units.enemy[side] > most then best, most = side, units.enemy[side] end
	end
	if most < ENEMY_MIN then return nil end
	return best, string.format("the enemy on the map (%d on 0x2, %d on 0x4, %d on 0x8)", units.enemy[2], units.enemy[4], units.enemy[8])
end

-- ------------------------------------------------------------------ banner
-- "DISSIDENT CELL DISCOVERED" across the upper middle of the screen when rebel mode switches on.
-- Drawn on a screen surface in a world other than the main one, as the Passive Picker and Drone Remote
-- Control draw theirs. A surface keeps what was drawn on it, so it is only rebuilt when the fade steps.
local engine = rawget(_G, "stingray")
local BANNER_TITLE = "DISSIDENT CELL DISCOVERED"
local BANNER_SUB = "SEAF FORCES HAVE TURNED HOSTILE."
local BANNER_SHOW, BANNER_FADE, BANNER_STEPS = 5.0, 1.0, 10
local DEBUG_FONT = "core/performance_hud/debug"
local banner = { dead = false }
state.banner = banner

local function id_hex(a)   -- the 8 bytes at a as 16 hex digits
	local p = ffi.cast("const uint32_t *", a)
	local lo, hi = tonumber(p[0]), tonumber(p[1])
	if lo == 0 and hi == 0 then return nil end
	return string.format("%08x%08x", hi, lo)
end

-- The game's own font, its atlas and its material, or nil and why.
local function game_font()
	if not (globals.font and globals.atlas and globals.material) then return nil, "font signatures not found" end
	if not (readable(globals.font, 8) and readable(globals.atlas, 8) and readable(globals.material, 8)) then
		return nil, "font slots unreadable"
	end
	local holder = ptr(globals.material)
	if not holder or not readable(holder + 24, 8) then return nil, "font material not ready" end
	local font, atlas, material = id_hex(globals.font), id_hex(globals.atlas), id_hex(holder + 24)
	if not (font and atlas and material) then return nil, "font not ready" end
	return { font = font, atlas = atlas, material = material }
end

local function banner_clear()
	if banner.gui and banner.world and engine then
		for _, w in ipairs(engine.Application.worlds() or {}) do
			if w == banner.world then engine.World.destroy_gui(banner.world, banner.gui) break end
		end
	end
	banner.gui, banner.world, banner.step = nil, nil, nil
end

local function banner_draw(alpha)
	local App, World, Gui = engine.Application, engine.World, engine.Gui
	local main, target = App.main_world(), nil
	for _, w in ipairs(App.worlds() or {}) do if w ~= main then target = w break end end
	banner_clear()
	if not target then return end
	local gui = World.create_screen_gui(target, "scale", 1, 1)
	if not gui then error("screen surface unavailable", 0) end
	banner.gui, banner.world = gui, target
	local font, material
	local handles, why = game_font()
	if handles then
		local ids = engine.IdString64.from_hex
		font, material = ids(handles.font), ids(handles.material)
		local ink = Gui.material(gui, material)
		if not ink then error("font material unavailable", 0) end
		-- the font material's settings, as DiverKit and the Passive Picker set them for plain text
		local function slot(h) return ids(h .. "00000000") end
		for _, h in ipairs({ "8035c266", "5e8455fe", "309e7783", "82b803a8" }) do
			engine.Material.set_scalar(ink, slot(h), 0)
		end
		engine.Material.set_vector2(ink, slot("e13777ce"), engine.Vector2(1, -1))
		engine.Material.set_vector4(ink, slot("7701209e"), engine.Color(0, 0, 0, 0))
		engine.Material.set_texture(ink, slot("88bac99b"), ids(handles.atlas))
		if banner.font ~= "game" then banner.font = "game"; log("banner: drawn in the game's own font") end
	else
		if not (App.can_get("font", DEBUG_FONT) and App.can_get("material", DEBUG_FONT)) then
			error("no font: " .. why .. ", and the engine's debug font is not loaded", 0)
		end
		font, material = DEBUG_FONT, DEBUG_FONT
		if banner.font ~= "debug" then banner.font = "debug"; log("banner: the game's font is not available (" .. why .. "); drawn in the engine's debug font") end
	end
	local gw, gh = Gui.resolution()
	if not (type(gw) == "number" and type(gh) == "number" and gw >= 480 and gh >= 320) then error("screen size unreadable", 0) end
	local function color(r, g, b, a) return engine.Color(math.floor(a * alpha + 0.5), r, g, b) end
	local function measure(value, size)
		local lo, hi = Gui.text_extents(gui, value, font, size)
		if not (lo and hi) then return #value * size * 0.6, 0 end
		return engine.Vector2.x(hi) - engine.Vector2.x(lo), engine.Vector2.x(lo)
	end
	-- Laid out in the screenshot's pixels at 1080 lines (measured from the top), scaled by u.
	-- Gui y runs from the bottom of the screen, so a top-down distance t is gh - t * u.
	local u = gh / 1080
	local function top(t) return gh - t * u end
	local ORANGE, WHITE = { 255, 130, 31 }, { 238, 242, 246 }
	local function rect(x, t, w, h, rgb, a, z)   -- x, w in screen units; t, h in screenshot pixels
		Gui.rect(gui, engine.Vector3(x, top(t + h), z), engine.Vector2(w, h * u), color(rgb[1], rgb[2], rgb[3], a))
	end
	local title_size, sub_size = 47 * u, 20 * u
	local tw, tl = measure(BANNER_TITLE, title_size)
	local sw, sl = measure(BANNER_SUB, sub_size)
	local mid = 314   -- the title's centre line
	local tx = (gw - tw) / 2
	-- the dark band behind the title and stripes, solid in the middle and fading out at both ends
	local gap, reach = 27 * u, 103 * u
	local inner = tw + 2 * (gap + reach + 24 * u)
	rect((gw - inner) / 2, mid - 28, inner, 56, { 0, 0, 0 }, 150, 960)
	for i = 1, 4 do
		local fw = 22 * u
		rect((gw - inner) / 2 - i * fw, mid - 28, fw, 56, { 0, 0, 0 }, 150 - i * 30, 960)
		rect((gw + inner) / 2 + (i - 1) * fw, mid - 28, fw, 56, { 0, 0, 0 }, 150 - i * 30, 960)
	end
	-- three stripes either side, 6 pixels thick, 10 apart, flush at the title end, the far end cut on a slant
	for s, stripe in ipairs({ { -12.5, 103 }, { -2.5, 94 }, { 7.5, 51 } }) do
		for r = 0, 5 do
			local len = (stripe[2] - r) * u
			local t = mid + stripe[1] + r
			rect(tx - gap - len, t, len, 1, ORANGE, 255, 961)
			rect(tx + tw + gap, t, len, 1, ORANGE, 255, 961)
		end
	end
	Gui.text(gui, BANNER_TITLE, font, title_size, material,
		engine.Vector3(tx - tl, top(mid + 0.35 * 47), 963), color(ORANGE[1], ORANGE[2], ORANGE[3], 255))
	-- the line under it: white capitals on their own dark box
	local sub_mid, box_w = 369, sw + 20 * u
	rect((gw - box_w) / 2, sub_mid - 15, box_w, 30, { 0, 0, 0 }, 160, 960)
	Gui.text(gui, BANNER_SUB, font, sub_size, material,
		engine.Vector3((gw - sw) / 2 - sl, top(sub_mid + 0.35 * 20), 963), color(WHITE[1], WHITE[2], WHITE[3], 255))
end

local function banner_show()
	if banner.dead or cfg.banner ~= 1 then return end
	if not engine then banner.dead = true; log("banner off: the game's engine table is not available") return end
	banner.start, banner.step = os.clock(), nil
	log("BANNER: " .. BANNER_TITLE)
end

-- Every frame: draw while it shows, step the fade, clear it when done.
local function banner_tick()
	if not banner.start or banner.dead then return end
	local ok, err = pcall(function ()
		local t = os.clock() - banner.start
		if t >= BANNER_SHOW + BANNER_FADE then banner_clear(); banner.start = nil return end
		local alpha = t < BANNER_SHOW and 1 or 1 - (t - BANNER_SHOW) / BANNER_FADE
		local step = math.floor(alpha * BANNER_STEPS + 0.5)
		if step == banner.step and banner.gui then return end
		banner_draw(step / BANNER_STEPS)
		banner.step = step
	end)
	if not ok then
		banner.dead, banner.start = true, nil
		pcall(banner_clear)
		log("banner off for this game session, it could not draw: " .. tostring(err) .. ". Rebel mode is not affected.")
	end
end

-- ------------------------------------------------------------------ rebel mode
local rebel = { on = false, side = nil, set = 0, resets = 0, kept = 0, tally_resets = 0, tally_kept = 0 }
local guard_ok = false   -- set by the unit pass: in a mission (or between Helldivers), solo unless squad = 1
state.rebel = rebel

local function forget()
	if rebel.set > 0 then log(string.format("rebel mode set %d SEAF soldiers while it was on", rebel.set)) end
	if rebel.resets > 0 then log(string.format("count guard: %d resets while it was on, %d SEAF kills kept off the count", rebel.resets, rebel.kept)) end
	if rebel.tally_resets > 0 then log(string.format("tally guard: %d resets while it was on, %d kills kept off the traitor tally", rebel.tally_resets, rebel.tally_kept)) end
	rebel.on = false; rebel.side = nil; rebel.blind = nil; rebel.set = 0; rebel.said = nil
	rebel.resets = 0; rebel.kept = 0; rebel.tally_resets = 0; rebel.tally_kept = 0; rebel.guard_failed = nil; rebel.tally_failed = nil; guard_ok = false
end
local function say_once(what, text)
	rebel.said = rebel.said or {}
	if not rebel.said[what] then rebel.said[what] = true; log(text) end
end

-- Writes value `to` into each of a soldier's three places that reads `from`; when one write fails, the ones
-- already made are undone. Returns how many were written, or nil and why.
local function move(s, copy_at, from, to)
	local places, done = { s.at_side, s.at_copy, copy_at }, {}
	for _, at in ipairs(places) do
		if u32(at) == from then
			local ok, err = put32(at, to)
			if not ok then
				for _, back in ipairs(done) do put32(back, from) end
				return nil, err
			end
			done[#done + 1] = at
		end
	end
	return #done
end

-- Every living soldier still on 0x1 gets the rebel side, in all three places.
local function set_soldiers(units)
	if not rebel.side then
		local side, how = pick_side(units)
		if not side then say_once("wait", "no enemy on the map yet; the soldiers are left alone until one shows up") return end
		rebel.side = side
		log("REBEL SIDE: " .. FRONT[side] .. ", " .. how .. ". Kept until rebel mode goes off.")
	end
	local t, why = detector_table()
	if not t then say_once("table", "rebel mode is on but the detector table cannot be read (" .. why .. "); soldiers are left alone until it can") return end
	local side, n = rebel.side, 0
	for _, s in ipairs(units.soldiers_list) do
		local function fits(v) return v == SIDE_HOME or v == side end
		if fits(s.side) and fits(s.copy) then
			local at = detector_copy_at(t, s.id)
			if not at then say_once("nodet", "a SEAF soldier has no detector record; such soldiers are left alone")
			elseif fits(u32(at)) then
				local wrote, err = move(s, at, SIDE_HOME, side)
				if not wrote then say_once("write", "could not set a soldier, nothing changed on him: " .. err)
				elseif wrote > 0 then n = n + 1 end
			end
		end
	end
	if n > 0 then
		rebel.set = rebel.set + n
		log(string.format("SEAF SET: %d soldier%s now on side 0x%X (%d so far)", n, n == 1 and "" or "s", side, rebel.set))
	end
end

-- Living soldiers go back to 0x1, only where a value still reads what this mod set.
local function restore_soldiers(units, why)
	local n, failed = 0, 0
	if units then
		local t = detector_table()
		for _, s in ipairs(units.soldiers_list) do
			local at = t and detector_copy_at(t, s.id)
			if s.side == rebel.side or s.copy == rebel.side or (at and u32(at) == rebel.side) then
				local wrote = move({ at_side = s.at_side, at_copy = s.at_copy }, at or s.at_side, rebel.side, SIDE_HOME)
				if wrote then n = n + 1 else failed = failed + 1 end
			end
		end
	end
	log(string.format("REBEL MODE OFF (%s): %d living soldier%s put back to 0x1%s", why, n, n == 1 and "" or "s",
		(not units and "; THE UNIT LIST COULD NOT BE READ, nothing put back") or (failed > 0 and ("; " .. failed .. " COULD NOT BE PUT BACK") or "")))
	forget()
end

local function switch_on(units, count)
	local ok, no = would_arm(units, count)
	if not ok then log("key ignored, rebel mode stays off: " .. no) return end
	local t, why = detector_table()
	if not t then log("key ignored, rebel mode stays off: " .. why) return end
	rebel.on, rebel.side = true, nil
	log(string.format("REBEL MODE ON: SEAF soldiers are set to %s as they appear; Helldivers, dogs and sentries are not touched. Same key switches it off.%s",
		cfg.side == 0 and "the side of the enemy on the map" or string.format("side 0x%X", cfg.side), cfg.guard == 1 and " Guard on (traitor tally and kill count)." or " No guard: six friendly kills without a ten-second gap bring the destroyer."))
	banner_show()
	set_soldiers(units)
end

-- While it is on: set the new soldiers, and let go when the mission is over.
local function rebel_check(units, why)
	if not units then
		if not rebel.blind then rebel.blind = true; log("rebel mode is on but the unit list cannot be read (" .. tostring(why) .. "); will look again") end
		return
	end
	rebel.blind = nil
	if units.where == "ship" or units.where == "other" then
		log("REBEL MODE OFF: no longer in a mission (" .. units.where .. ")")
		forget()
	elseif units.where == "mission" then
		if is_host() == false then restore_soldiers(units, "this game is no longer the host")
		elseif #units.divers > 1 and cfg.squad ~= 1 then restore_soldiers(units, "another Helldiver is in the mission and squad = 0")
		else set_soldiers(units) end
	end
end

-- ------------------------------------------------------------------ driver
local previous_update = rawget(_G, "update")
if type(previous_update) ~= "function" then
	log("stopped: game update callback unavailable")
	return true
end

state.test = { parse_cfg = parse_cfg }   -- for the offline test harness only
local phase, wait = "start", 240
local last_units, last_count, last_seen = nil, nil, 0
local function watch()
	banner_tick()
	local count, before, count_at = read_count()
	local ctext = count and string.format("kill count %d (value before it %d)", count, before) or ("kill count: " .. before)
	if ctext ~= last_count then last_count = ctext; log(ctext) end
	if rebel.on and guard_ok and cfg.guard == 1 and count and count >= cfg.guard_at and count <= 64 then
		local ok, err = put32(count_at, 0)
		if ok then
			rebel.resets, rebel.kept = rebel.resets + 1, rebel.kept + count
			log(string.format("COUNT GUARD: was %d, now %d (%d kept off the count so far)", count, u32(count_at), rebel.kept))
			count = 0
			last_count = string.format("kill count %d (value before it %d)", count, before)
		elseif not rebel.guard_failed then
			rebel.guard_failed = true
			log("COUNT GUARD could not write: " .. err .. ". The count is NOT being held down.")
		end
	end
	if rebel.on and guard_ok and cfg.guard == 1 then
		local tally_at, no = read_tally()
		if tally_at then
			for i = 0, TALLY_SLOTS - 1 do
				local at = tally_at + 4 * i
				local n = u32(at)
				if n >= 1 and n <= 64 then
					local ok, err = put32(at, 0)
					if ok then
						rebel.tally_resets, rebel.tally_kept = rebel.tally_resets + 1, rebel.tally_kept + n
						log(string.format("TALLY GUARD: slot %d was %d, now %d (%d kept off the traitor tally so far)%s", i, n, u32(at), rebel.tally_kept,
							n >= 6 and " - IT REACHED SIX BEFORE THE RESET, the destroyer may still come" or ""))
					elseif not rebel.tally_failed then
						rebel.tally_failed = true
						log("TALLY GUARD could not write: " .. err .. ". The traitor tally is NOT being held down.")
					end
				end
			end
		elseif not rebel.tally_failed then
			rebel.tally_failed = true
			log("TALLY GUARD cannot read the tally: " .. no .. ". The traitor tally is NOT being held down.")
		end
	end
	local key = key_pressed(state.frames, cfg.key)
	if not (key or state.frames % (rebel.on and 5 or 15) == 0) then return end
	local units, why = read_units()
	if key then
		load_cfg()
		if rebel.on then
			if units then restore_soldiers(units, "key pressed") else log("key ignored: the unit list cannot be read (" .. tostring(why) .. "); rebel mode is still on") end
		else
			switch_on(units, count)
		end
		units, why = read_units()
	elseif rebel.on then
		rebel_check(units, why)
	end
	local text
	if units then
		local sides = {}
		for i, d in ipairs(units.divers) do sides[i] = string.format("0x%X/0x%X", d.side, d.copy) end
		text = string.format("%s; Helldivers %d; side %s", units.where, #units.divers, #sides > 0 and table.concat(sides, " ") or "-")
	else
		text = why
	end
	local ok, no = would_arm(units, count)
	guard_ok = rebel.on and units ~= nil and (units.where == "mission" or units.where == "none")
		and (#units.divers <= 1 or cfg.squad == 1)
	if rebel.on then text = text .. "; rebel mode ON"
	else text = text .. (ok and "; rebel mode off, ready" or ("; rebel mode off, would refuse: " .. no)) end
	if text ~= last_units then last_units = text; log(text) end
	if units and units.where == "mission" and state.frames - last_seen >= 3600 then
		last_seen = state.frames
		log(string.format("in mission: %d units registered, %d SEAF soldiers alive", units.units, units.soldiers))
	end
	state.units, state.count, state.before, state.would_arm = units, count, count and before or nil, ok
end

local function tick()
	state.frames = state.frames + 1
	if phase == "dead" then return end
	if wait > 0 then wait = wait - 1 return end
	if phase == "start" then
		prepare_scan(); phase = "scan"
	elseif phase == "scan" then
		if scan_step() then
			resolve_globals()
			load_cfg()
			log(string.format("READY - rebel mode is off. Key %d switches it on in a mission (soldiers to %s, guard %d at %d, squad %d).",
				cfg.key, cfg.side == 0 and "the enemy's side" or string.format("side 0x%X", cfg.side), cfg.guard, cfg.guard_at, cfg.squad))
			phase = "watch"
		end
	elseif phase == "watch" then
		watch()
	end
end

rawset(_G, "update", function (...)
	local r = { pcall(previous_update, ...) }
	local ok, err = pcall(tick)
	if not ok then
		log("stopped on error: " .. tostring(err))
		phase = "dead"
	end
	if not r[1] then error(r[2], 0) end
	return unpack(r, 2, table.maxn(r))
end)

local previous_shutdown = rawget(_G, "shutdown")
if type(previous_shutdown) == "function" then
	rawset(_G, "shutdown", function (...)
		pcall(banner_clear)
		pcall(function ()
			if rebel.on then
				local units = read_units()
				restore_soldiers(units, "game shutting down")
			else
				log("shutdown: rebel mode was off, nothing to put back")
			end
		end)
		return previous_shutdown(...)
	end)
end

log("loaded (" .. REVISION .. ")")
return true
