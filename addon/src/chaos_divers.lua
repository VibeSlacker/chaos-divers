-- HD2-Addon: mods/vibeslacker/chaos_divers
-- Chaos Divers: Dissidents Among Us (was "Rebel SEAF", "Dissident Crackdown", then "Dissident Discovery"), release 1.0.0 (built from test 0.31; probe logging off by default; 0.30: no host check: any player's E or key switches rebel mode in their own game, squad defaults to 1; the key card taken with E only, the same key card on every machine, a lost card replaced by the nearest lore object, one enemy unit enough to pick the rebel side, map marker rebuilt on every move (no Gui.update_text), step-by-step trace kept, voice call address fixed, sentries left alone, voice call), for Bingus Shared Loader v15+.
--
-- Rebel mode: one key (none by default from 0.30; the settings file can name one, F9 in test) turns the
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
-- squad = 1, or the game shuts down. Back on the ship the mode is always off.
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
-- 0.11: renamed to Dissidents Among Us. Only the name shown changes; files, global, loader path and
--       bindings id stay chaos_divers. No other change.
-- 0.12: position probe for the lore key card. In a mission it logs, read-only, which engine
--       functions exist for units, worlds and the camera, then tries a few unit positions. Three
--       rounds a minute apart, every call guarded; it writes nothing to the game. (It crashed the game:
--       engine calls on arbitrary units. Rolled back the same morning; removed in 0.13.)
-- 0.13: key card. About 30 s into a mission one lore object (zone type 49, in 0.14 12, in the game's interactable
--       manager) is picked at random; the interact key (E) within 2.5 m of it switches rebel mode on.
--       Every interact press logs the nearest interactable and its zone type. Settings: card, interact.
-- 0.14: map marker. The card's search area (40 m around a spot 5 to 25 m off it) is drawn on the tactical
--       map while it is open (layout from Th3chef's Treasure Map), and a TRANSMISSION INTERCEPTED banner
--       shows when the card is picked. Gone once the card is found. The card is now picked from zone type 12
--       (a note, seen in the game; 49 vanished mid-mission); each pick logs how many of each type are on the map,
--       and each interact press the three nearest.
-- 0.15: diagnostics only: each pick logs every lore object's position; each E press logs the Helldivers'
--       positions and the three nearest objects' positions (a far vending machine read 1.0 m in 0.14).
--       SEAF SET lines name the unit types set (turrets the game files with SEAF turned hostile in 0.14).
-- 0.16: the Helldivers' gas mortar sentry (type 299c0d3dfd2f0994, filed by the game with SEAF's record 24) is never set
--       or counted as a soldier.
-- 0.17: voice call. When a batch of SEAF drops while rebel mode is on, mission control follows the game's own
--       SEAF line with "Enemy reinforcements inbound" / "Hostiles incoming" / "Unidentified hostiles incoming"
--       (six takes, random, no line twice running, at most every 45 s).
-- 0.18: the map marker redone: a smooth thin ring and a faint fill (triangles) with one label, DISSIDENT DATA;
--       the surface stays while the map is open and only the ring is redrawn on a move (no flicker).
-- 0.19: the pick no longer gives the twist away: NEW INTEL DISCOVERED / LOCATION MARKED ON YOUR TACTICAL MAP,
--       and the map label reads INTEL. DISSIDENT CELL DISCOVERED stays for the card itself.
--       Positions now come from the game's unit table (the engine lookup found units attached to the Helldiver:
--       the card sat on him and any E press fired it); lore objects are zone type 49.
-- 0.20: diagnostics for the freeze on opening the map after the pick (every 0.19 mission, 2026-10-17):
--       the first 25 marker draws log a line before and after each engine call, map open/close is logged,
--       and a new setting picks what is drawn: marker = 1 ring and label, 2 ring only, 3 label only, 0 nothing.
-- 0.21: the freeze fixed. The 0.20 trace caught the game hanging inside Gui.update_text when the label was moved
--       to -1000, -1000 to hide it (the area slid off the map for a frame while the map animated open). Now no
--       text is ever placed off screen: off the map, the whole surface is cleared (the close-map clean-up), and
--       it is drawn fresh when the area comes back; the label is created at its real place. Trace kept.
-- 0.22: 0.21 still froze, and its trace showed why: Gui.update_text hangs the game on any frame after the text
--       was made, wherever it is moved to (same-frame calls worked; 0.18 escaped because its ring never moved).
--       Gui.update_text and Gui.destroy_triangle are gone: any move throws the whole surface away and draws
--       it fresh (ring and label), the way 0.14 drew. Trace kept. (In the game 2026-10-17 23:28: no freeze, no flicker.)
-- 0.23: the voice call's engine world list read from helldivers2.exe+0x1A10308, a typo for HD2Runtime's 0x1A10208
--       (27329032), so it always stopped at "the engine world list is unreadable" (first live chance 23:36).
--       Checked live, read-only: 0x1A10208 lists 7 worlds with the Game World once, at index 1.
--       Also: the log names 0x2 the Terminids and 0x8 the Automatons (was "bugs or bots").
-- 0.24: one enemy unit on the map is enough to pick the rebel side (was three). On 2026-10-18 00:10 the card switched
--       rebel mode on with 12 SEAF standing and one bug on the map, so it waited and the SEAF stayed friendly.
-- 0.25: when the card's object leaves the game (destroyed or cleaned up), the replacement is the lore object nearest
--       to where it was (was: random anywhere; on 2026-10-18 00:48 the ring jumped 500 m with no notice), and an
--       INTEL MOVED banner says so.
-- 0.26: the pick's banner reads NEW INTELLIGENCE DISCOVERED / FIND THE INTEL AND GET IT TO THE DESTROYER. (Wilson
--       2026-10-18; was NEW INTEL DISCOVERED / FIND THE INTEL. AREA MARKED ON YOUR TACTICAL MAP.).
-- 0.27: the card's banner line reads ENEMY SYMPATHIZERS HAVE TURNED HOSTILE. (Wilson 2026-10-18: the only place the
--       banners said SEAF; was SEAF FORCES HAVE TURNED HOSTILE.).
-- 0.28: co-op (Wilson 2026-10-18: "other players in the lobby need to be able to do the intel mission. see the map and
--       such"). The card is the same on every machine in the mission: the lore objects sorted by where they stand,
--       the pick and the search area's offset taken from a hash of their positions (logged as the fingerprint), so
--       a squadmate's copy marks the same spot. Any Helldiver within reach of it finds it, by walking up or with E.
--       In a game that is not the host it only shows (banners and the map marker); the host's game switches the SEAF.
--       The pick no longer skips lore objects near a Helldiver (that differs per machine).
-- 0.29: the card is taken with E only (Wilson 2026-10-19: walking past it should not fire it; everyone has the mod,
--       each player selects it with E). The walk-up check (0.28's card_near) is gone. (Until 0.30 a squadmate's E showed only in
--       their own game and only the host's E turned the SEAF.)
-- 0.30: host check removed (Wilson 2026-10-19: "scratch the host only activation"). Everyone has the mod: any player's E at
--       the card, or the on/off key, switches rebel mode on in that player's own game; nothing asks who hosts. squad now
--       defaults to 1 (0 would block the mod once a second Helldiver joins). Whether a non-host's writes change what the
--       host's simulation does is unproven; the log says what each copy did.
-- 0.31: logging only. A co-op probe (setting probe = 1) writes PROBE lines: this game's host/squadmate role, the SEAF side
--       values as this machine sees them (and when they change), and every change in the lore objects' and the
--       Helldivers' interaction state blocks. One log from each machine in a two-player mission shows whether the host
--       can see a squadmate's E and whether a squadmate's game can see the host's flip. Nothing else changed.
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
local REVISION = "Chaos Divers: Dissidents Among Us 1.0.0"
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
	if vk == 0 then return false end   -- 0.30: no manual key by default (Wilson); the intel is the only way in
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
local DEFAULTS = { key = 0, side = 0, guard = 1, guard_at = 1, squad = 1, banner = 1, card = 1, interact = 69, marker = 1, probe = 0 }
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
			if n == 0 then out.key = 0
			elseif n < 1 or n > 254 then notes[#notes + 1] = "key " .. value .. " is not a key number; using no key"
			elseif BAD_KEYS[n] then notes[#notes + 1] = "key " .. n .. " refused (" .. BAD_KEYS[n] .. "); using no key"
			else out.key = n end
		elseif name == "side" and n then
			if n == 0 or n == 2 or n == 4 or n == 8 then out.side = n
			else notes[#notes + 1] = "side " .. value .. " refused (only 0, 2, 4 or 8); using 0 (join the enemy on the map)" end
		elseif name == "interact" and n then
			n = math.floor(n)
			if n < 1 or n > 254 then notes[#notes + 1] = "interact " .. value .. " is not a key number; using E (69)"
			else out.interact = n end
		elseif (name == "guard" or name == "squad" or name == "banner" or name == "card" or name == "probe") and n then
			if n == 0 or n == 1 then out[name] = n
			else notes[#notes + 1] = name .. " " .. value .. " refused (only 0 or 1); using " .. DEFAULTS[name] end
		elseif name == "marker" and n then
			if n == 0 or n == 1 or n == 2 or n == 3 then out.marker = n
			else notes[#notes + 1] = "marker " .. value .. " refused (0 to 3); using 1" end
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
					"# key: 0 = no manual key; the intel is the only way to switch rebel mode on. (Test builds only: a Windows key number, 120 = F9.)\n",
					"key = 0\n",
					"# side: the side the SEAF soldiers are put on while rebel mode is on.\n",
					"#   0 = join whatever enemy holds the map (squids, bugs or bots), chosen each time the mode goes on.\n",
					"#   4 = always the squids' side.   2 = always the bugs' side.   8 = always the bots' side.\n",
					"side = 0\n",
					"# guard: 1 = while rebel mode is on, the traitor tally and the SEAF kill count are kept at 0 so the destroyer never comes. 0 = off.\n",
					"guard = 1\n",
					"# guard_at: the count is set back to 0 when it reaches this (1 to 8). 1 = after every kill.\n",
					"guard_at = 1\n",
					"# squad: 1 = also with other Helldivers in the mission (private lobby, friends who know). 0 = solo only.\n",
					"squad = 1\n",
					"# banner: 1 = show DISSIDENT CELL DISCOVERED on screen when rebel mode switches on. 0 = off.\n",
					"banner = 1\n",
					"# card: 1 = one lore object per mission (the ones that only show text) holds the dissidents' data.\n",
					"#   Press the interact key next to it to take it; walking past does nothing. In any player's game that switches that game's rebel mode on.\n",
					"#   Squadmates with the mod see the same marker, and their own banner when they press it. The on/off key still works. 0 = off.\n",
					"card = 1\n",
					"# interact: Windows key number of the game's interact key. 69 = E.\n",
					"interact = 69\n",
					"# marker: what the card's search area shows on the tactical map. 1 = ring and label, 2 = ring only, 3 = label only, 0 = nothing.\n",
					"marker = 1\n",
					"# probe: 1 = log extra PROBE lines for co-op debugging. 0 = off (the default).\n",
					"probe = 0\n")
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
		log(string.format("settings: key %d, side 0x%X, guard %d at %d, squad %d, banner %d, card %d, interact %d, marker %d", new.key, new.side, new.guard, new.guard_at, new.squad, new.banner, new.card, new.interact, new.marker))
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
				and "the host check is gone (0.30), nothing changes" or "the banner uses the engine's debug font instead"))
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

-- Units the game files with record 24 that are not SEAF soldiers: never set, never counted.
-- 299c0d3dfd2f0994: the Helldivers' gas mortar sentry (set by 0.14 on 2026-10-17; it shelled him once the SEAF
-- were dead). The gatling sentry is not record 24. Other mortar sentries likely are; SEAF SET lines log types.
local NOT_SEAF = { { 0xfd2f0994, 0x299c0d3d } }
local function not_seaf(unit)
	if not (unit and near(unit, 8)) then return false end
	local lo, hi = u32(unit), u32(unit + 4)
	for _, t in ipairs(NOT_SEAF) do if lo == t[1] and hi == t[2] then return true end end
	return false
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
		elseif record == REC_SEAF and side ~= 0 and not not_seaf(unit) then
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

-- ------------------------------------------------------------------ may rebel mode switch on?
local function would_arm(units, count)
	if not units then return false, "the unit list cannot be read" end
	if units.where ~= "mission" then return false, "not in a mission (" .. units.where .. ")" end
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
local FRONT = { [2] = "0x2 (the Terminids)", [4] = "0x4 (the Illuminate)", [8] = "0x8 (the Automatons)" }   -- 0x2 proven 10-14 and 10-17; 0x8 by elimination
local ENEMY_MIN = 1   -- (was 3 to 0.23: a map with one bug left 12 SEAF friendly, 2026-10-18)
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
local BANNER_SUB = "ENEMY SYMPATHIZERS HAVE TURNED HOSTILE."
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

-- The font and material to write text on a screen surface with: the game's own font when its handles are
-- ready, else the engine's debug font. Returns font, material, "game" or "debug", and why not the game's.
local function text_ink(gui)
	local App, Gui = engine.Application, engine.Gui
	local handles, why = game_font()
	if handles then
		local ids = engine.IdString64.from_hex
		local font, material = ids(handles.font), ids(handles.material)
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
		return font, material, "game"
	end
	if not (App.can_get("font", DEBUG_FONT) and App.can_get("material", DEBUG_FONT)) then
		error("no font: " .. why .. ", and the engine's debug font is not loaded", 0)
	end
	return DEBUG_FONT, DEBUG_FONT, "debug", why
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
	local font, material, kind, why = text_ink(gui)
	if kind == "game" then
		if banner.font ~= "game" then banner.font = "game"; log("banner: drawn in the game's own font") end
	elseif banner.font ~= "debug" then banner.font = "debug"; log("banner: the game's font is not available (" .. why .. "); drawn in the engine's debug font") end
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
	local title, sub = banner.title or BANNER_TITLE, banner.sub or BANNER_SUB
	local tw, tl = measure(title, title_size)
	local sw, sl = measure(sub, sub_size)
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
	Gui.text(gui, title, font, title_size, material,
		engine.Vector3(tx - tl, top(mid + 0.35 * 47), 963), color(ORANGE[1], ORANGE[2], ORANGE[3], 255))
	-- the line under it: white capitals on their own dark box
	local sub_mid, box_w = 369, sw + 20 * u
	rect((gw - box_w) / 2, sub_mid - 15, box_w, 30, { 0, 0, 0 }, 160, 960)
	Gui.text(gui, sub, font, sub_size, material,
		engine.Vector3((gw - sw) / 2 - sl, top(sub_mid + 0.35 * 20), 963), color(WHITE[1], WHITE[2], WHITE[3], 255))
end

local function banner_show(title, sub)
	if banner.dead or cfg.banner ~= 1 then return end
	if not engine then banner.dead = true; log("banner off: the game's engine table is not available") return end
	banner.start, banner.step = os.clock(), nil
	banner.title, banner.sub = title, sub
	log("BANNER: " .. (title or BANNER_TITLE))
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

-- ------------------------------------------------------------------ voice call (0.17)
-- When SEAF reinforcements drop while rebel mode is on, mission control follows the game's own "SEAF inbound"
-- line with one of six of its own lines (rotated at random, never the same line twice running): "Enemy
-- reinforcements inbound, prepare for contact", "Hostiles incoming", "Unidentified hostiles incoming", two takes
-- each. Event ids from the game's sound bank (archive 7c221cf5b12213ac, read with RaidingForPants's
-- hd2-audio-modder); Wwise posts the FNV-1 hash of the name it is given, so each name below hashes to its
-- event's id. Posted the way SkyeShade's HD2Runtime posts its UI sounds: on the Game World's WwiseWorld, the
-- world matched by pointer in the engine's world list (a wrong world crashes the game natively; pcall cannot
-- catch it), and only after Wwise.has_event says the sound engine knows the event.
local VOICE_LINES = {
	{ line = "reinforcements", name = "bhhbahfd", id = 148239244 }, { line = "reinforcements", name = "bhhbahfg", id = 148239247 },
	{ line = "hostiles", name = "tfrmagno", id = 97901441 }, { line = "hostiles", name = "tfrmagnl", id = 97901442 },
	{ line = "unidentified", name = "mgqhanez", id = 4091941746 }, { line = "unidentified", name = "mgqhaney", id = 4091941745 },
}
local VOICE_TEXT = { reinforcements = "Enemy reinforcements inbound, prepare for contact", hostiles = "Hostiles incoming",
	unidentified = "Unidentified hostiles incoming" }
local VOICE_STAMP = 1790161983   -- game.dll build 25480438; any other build keeps the voice call silent
local GAME_CONTEXT_RVA, CTX_GAME_WORLD, CTX_WWISE_WORLD = 0x3326340, 0x10E8, 0x10F8   -- game.dll
local EXE_APPLICATION, APP_WORLD_COUNT, APP_WORLD_ARRAY = 0x1A10208, 1424, 1432          -- helldivers2.exe (HD2Runtime application = 27329032)
local VOICE_DELAY, VOICE_GAP, VOICE_SETTLE, VOICE_BATCH = 300, 2700, 600, 2   -- frames: after the drop, between calls, after switch-on; soldiers
local voice = { dead = false, pending = nil, last_frame = -1000000, last_line = nil }
state.voice = voice

local function voice_off(why)
	if not voice.dead then voice.dead = true; log("voice call off for this game session: " .. why) end
end

local function fnv1(name)
	local h = 0x811C9DC5
	for i = 1, #name do
		local c = name:byte(i)
		if c >= 65 and c <= 90 then c = c + 32 end
		h = (h * 0x193 + (h % 256) * 16777216) % 4294967296
		h = bit.bxor(h, c) % 4294967296
		if h < 0 then h = h + 4294967296 end
	end
	return h
end

-- The engine's World value of the game's own Game World, or nil and why.
local function game_world()
	if state.pe_timestamp ~= VOICE_STAMP then return nil, "game.dll is not build 25480438" end
	local slot = base + GAME_CONTEXT_RVA
	if not readable(slot, 8) then return nil, "game context slot unreadable" end
	local ctx = ptr(slot)
	if not (ctx and readable(ctx + CTX_GAME_WORLD, 24)) then return nil, "no game context" end
	local gw, ww = ptr(ctx + CTX_GAME_WORLD), ptr(ctx + CTX_WWISE_WORLD)
	if not (gw and ww) then return nil, "the game has no Game World with a WwiseWorld" end
	local exe = kernel.GetModuleHandleA(nil)
	if exe == nil then return nil, "helldivers2.exe not found" end
	exe = tonumber(ffi.cast("uintptr_t", exe))
	if not readable(exe + EXE_APPLICATION, 8) then return nil, "application slot unreadable" end
	local app = ptr(exe + EXE_APPLICATION)
	if not (app and readable(app + APP_WORLD_COUNT, 16)) then return nil, "no application" end
	local count, array = u32(app + APP_WORLD_COUNT), ptr(app + APP_WORLD_ARRAY)
	if not (array and count > 0 and count <= 64 and readable(array, 8 * count)) then return nil, "the engine world list is unreadable" end
	local index
	for k = 0, count - 1 do
		if ptr(array + 8 * k) == gw then
			if index then return nil, "the Game World is listed twice" end
			index = k + 1
		end
	end
	if not index then return nil, "the Game World is not in the engine world list" end
	local list = engine.Application.worlds()
	if type(list) ~= "table" or #list ~= count then return nil, "Application.worlds does not match the engine list" end
	if list[index] == nil then return nil, "no world value at index " .. index end
	return list[index]
end

local function voice_play()
	local S = engine
	local Wwise, WwiseWorld = S and S.Wwise, S and S.WwiseWorld
	if not (type(Wwise) == "table" and type(WwiseWorld) == "table" and type(Wwise.wwise_world) == "function"
		and type(Wwise.has_event) == "function" and type(WwiseWorld.trigger_event) == "function") then
		voice_off("the engine's Wwise functions are not available") return
	end
	local pool = {}
	for _, v in ipairs(VOICE_LINES) do if v.line ~= voice.last_line then pool[#pool + 1] = v end end
	local pick = pool[math.random(#pool)]
	if fnv1(pick.name) ~= pick.id then voice_off("the name " .. pick.name .. " does not hash to its event id") return end
	local w, why = game_world()
	if not w then log("voice call skipped: " .. why) return end
	local has = Wwise.has_event(pick.name)
	if has ~= true then log("voice call skipped: the sound engine does not know event " .. pick.id .. " here") return end
	local playing = WwiseWorld.trigger_event(Wwise.wwise_world(w), pick.name)
	if type(playing) ~= "number" or playing == 0 then log("voice call: the sound engine did not post event " .. pick.id) return end
	voice.last_line, voice.last_frame = pick.line, state.frames
	log(string.format("VOICE CALL: \"%s\" (event %d, playing id %s)", VOICE_TEXT[pick.line], pick.id, tostring(playing)))
end

-- A batch of SEAF soldiers was just set while rebel mode is on.
local function voice_cue(n)
	if voice.dead or not engine or n < VOICE_BATCH or voice.pending then return end
	if not rebel.on_frame or state.frames - rebel.on_frame < VOICE_SETTLE then return end
	if state.frames - voice.last_frame < VOICE_GAP then return end
	voice.pending = state.frames + VOICE_DELAY
end

local function voice_tick()
	if voice.dead or not voice.pending then return end
	if not rebel.on then voice.pending = nil return end
	if state.frames < voice.pending then return end
	voice.pending = nil
	local ok, err = pcall(voice_play)
	if not ok then voice_off("stopped on error: " .. tostring(err)) end
end


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
	local side, n, types = rebel.side, 0, {}
	for _, s in ipairs(units.soldiers_list) do
		local function fits(v) return v == SIDE_HOME or v == side end
		if fits(s.side) and fits(s.copy) then
			local at = detector_copy_at(t, s.id)
			if not at then say_once("nodet", "a SEAF soldier has no detector record; such soldiers are left alone")
			elseif fits(u32(at)) then
				local wrote, err = move(s, at, SIDE_HOME, side)
				if not wrote then say_once("write", "could not set a soldier, nothing changed on him: " .. err)
				elseif wrote > 0 then
					n = n + 1
					local t = readable(s.unit, 8) and id_hex(s.unit) or "?"
					types[t] = (types[t] or 0) + 1
				end
			end
		end
	end
	if n > 0 then
		rebel.set = rebel.set + n
		voice_cue(n)
		local tl = {}
		for t, k in pairs(types) do tl[#tl + 1] = t .. (k > 1 and (" x" .. k) or "") end
		table.sort(tl)
		log(string.format("SEAF SET: %d soldier%s now on side 0x%X (%d so far); types %s", n, n == 1 and "" or "s", side, rebel.set, table.concat(tl, ", ")))
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
	rebel.on, rebel.side, rebel.on_frame = true, nil, state.frames
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
		if #units.divers > 1 and cfg.squad ~= 1 then restore_soldiers(units, "another Helldiver is in the mission and squad = 0")
		else set_soldiers(units) end
	end
end

-- ------------------------------------------------------------------ driver
local previous_update = rawget(_G, "update")
if type(previous_update) ~= "function" then
	log("stopped: game update callback unavailable")
	return true
end

state.test = { parse_cfg = parse_cfg, set_cfg = function (k, v) cfg[k] = v end }   -- for the offline test harness only

-- ------------------------------------------------------------------ key card (0.13)
-- One lore object per mission is the dissidents' data. The interact key pressed with a Helldiver within CARD_RANGE
-- of it finds it; in the host's game that switches rebel mode on, as the on/off key does. The candidates come from the game's interactable
-- manager (layout from CarrotLouis's Ban Supply FRV Reloaded, build 25480438): each record names the
-- object's resource and its unit (+12), each state block its interaction zone types. Positions come from the
-- game's unit table (see unit_pos), read from memory: no engine calls on units (0.12 crashed the game that way).
local CARD_STAMP = 1790161983        -- game.dll build 25480438; any other build switches the card off
local INTERACTABLE_RVA = 0x3326D68   -- interactable manager slot
local IT_HEADER, IT_STATE, IT_ZONES, IT_ZONE_TYPE = 0x14038, 0x370, 0x340, 0x44
local LORE_TYPES = { [49] = true }   -- zone type of the read-only lore objects: Wilson stood at a note and the nearest world
                                     -- object was type 49 (2026-10-17 08:40). 0.14 to 0.18 used 12, which is attached to the Helldiver.
local DIVER_RES = "4d1c334d294dfa97" -- the Helldiver
local CARD_RANGE = 2.5               -- metres
local CARD_WAIT, CARD_RETRY = 1800, 1800   -- frames after landing before the first look; between looks
-- The pick's banner: it says where to look, not what is there (Wilson 2026-10-17: "it gives away too much. I want the
-- presentation to start with new Intel discovered"); the reveal waits for the card.
local PICK_TITLE, PICK_SUB = "NEW INTELLIGENCE DISCOVERED", "FIND THE INTEL AND GET IT TO THE DESTROYER."
local MOVED_TITLE, MOVED_SUB = "INTEL MOVED", "THE NEW LOCATION IS MARKED ON YOUR TACTICAL MAP."
local AREA_RADIUS, AREA_OFF_MIN, AREA_OFF_MAX = 40, 5, 25   -- metres: the map marker's search area around a spot this far off the card
local card = { off = nil, mission = false, since = 0, next_look = 0, chosen = nil, found = false, lore = nil }
state.card = card
math.randomseed(os.time())

local function card_off(why)
	if not card.off then card.off = why; log("key card off: " .. why) end
end

-- Every interactable: { res = 16 hex digits, zone = first zone type }; or nil and why.
local function read_interactables()
	if state.pe_timestamp ~= CARD_STAMP then return nil, "game.dll stamp " .. tostring(state.pe_timestamp) .. " is not build 25480438" end
	local slot = base + INTERACTABLE_RVA
	if not readable(slot, 8) then return nil, "interactable slot unreadable" end
	local mgr = ptr(slot)
	if not mgr or not readable(mgr + IT_HEADER, 72) then return nil, "no interactable manager" end
	local h = mgr + IT_HEADER
	local cap, active = u32(h), u32(h + 8)
	if cap > 16384 or active > cap then return nil, string.format("interactable counts look wrong (%d of %d)", active, cap) end
	local recs, states = ptr(h + 48), ptr(h + 56)
	if active == 0 then return {} end
	if not (recs and states and readable(recs, 8 * active) and readable(states, IT_STATE * active)) then return nil, "interactable arrays unreadable" end
	local out = {}
	for i = 0, active - 1 do
		local rec = ptr(recs + 8 * i)
		if rec and readable(rec, 8) then
			local st = states + IT_STATE * i
			local zones = u32(st + IT_ZONES)
			out[#out + 1] = { res = id_hex(rec), unit = readable(rec + 12, 4) and u32(rec + 12) or nil,
				zone = zones > 0 and zones <= 16 and u32(st + IT_ZONE_TYPE) or nil }
		end
	end
	return out
end

local function f32(a) return tonumber(ffi.cast("const float *", a)[0]) end
local function finite(x) return type(x) == "number" and x == x and x > -1e9 and x < 1e9 end

-- A unit's world position from helldivers2.exe's unit table (Th3chef's Treasure Map reads supply positions this way):
-- [exe+0x1A100F0] -> objects +0x88, count +0x98; the object at index (unit & 0x3FFFFF) holds the unit's own id at +8
-- (a stale id means the unit is gone) and its world poses at +0x88, the root's x, y, z at +48/+52/+56.
-- 0.13 to 0.18 asked the engine (World.units_by_resource) instead; for the lore type it found the interaction units
-- attached to the Helldiver, so the card sat on him and any E press fired it.
local EXE_UNITS, UNIT_OBJECTS, UNIT_COUNT, UNIT_POSES, POSE_ROOT = 0x1A100F0, 0x88, 0x98, 0x88, 48
local function unit_table()
	local exe = kernel.GetModuleHandleA(nil)
	if exe == nil then return nil end
	exe = tonumber(ffi.cast("uintptr_t", exe))
	if not readable(exe + EXE_UNITS, 8) then return nil end
	local reg = ptr(exe + EXE_UNITS)
	if not (reg and readable(reg + UNIT_OBJECTS, 0x14)) then return nil end
	local objs, n = ptr(reg + UNIT_OBJECTS), u32(reg + UNIT_COUNT)
	if not objs or n == 0 or n > 0x400000 then return nil end
	return { objs = objs, n = n }
end
local function unit_pos(t, unit)
	if not (t and unit) then return nil end
	local i = bit.band(unit, 0x3FFFFF)
	if i >= t.n or not readable(t.objs + 8 * i, 8) then return nil end
	local obj = ptr(t.objs + 8 * i)
	if not (obj and readable(obj + 8, UNIT_POSES)) or u32(obj + 8) ~= unit then return nil end
	local poses = ptr(obj + UNIT_POSES)
	if not (poses and readable(poses + POSE_ROOT, 12)) then return nil end
	local x, y, z = f32(poses + POSE_ROOT), f32(poses + POSE_ROOT + 4), f32(poses + POSE_ROOT + 8)
	if not (finite(x) and finite(y) and finite(z)) or math.abs(x) > 1e5 or math.abs(y) > 1e5 then return nil end
	return { x = x, y = y, z = z }
end
local function position(unit) return unit_pos(unit_table(), unit) end

local function dist(a, b)
	local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- The lore object nearest to a spot (the lost card's), for the replacement.
local function nearest_lore(lore, pos)
	local best, bd
	for _, it in ipairs(lore) do local d = dist(pos, it.pos) if not bd or d < bd then best, bd = it, d end end
	return best, bd
end
state.test.nearest_lore = nearest_lore

-- Every interactable with a position, { res, zone, unit, pos }, and the Helldivers' positions (their own records).
local function inventory()
	local items, why = read_interactables()
	if not items then return nil, why end
	local t = unit_table()
	if not t then return nil, "the unit table is unreadable" end
	local out, divers = {}, {}
	for _, it in ipairs(items) do
		local p = unit_pos(t, it.unit)
		if p then
			if it.res == DIVER_RES then divers[#divers + 1] = p
			else out[#out + 1] = { res = it.res, zone = it.zone, unit = it.unit, pos = p } end
		end
	end
	return out, nil, divers
end

local function where(p) return string.format("%.1f %.1f %.1f", p.x, p.y, p.z) end

-- The same card on every machine in the mission (0.28): the lore objects sorted by where they stand (to the
-- metre), and the pick and the search area's offset taken from a hash of all their positions. Two games that
-- see the same objects pick the same card; the fingerprint in the log shows whether they did. Sorts lore.
local function card_pick(lore)
	local function key(it) return { math.floor(it.pos.x + 0.5), math.floor(it.pos.y + 0.5), math.floor(it.pos.z + 0.5) } end
	for _, it in ipairs(lore) do it.key = key(it) end
	table.sort(lore, function (a, b)
		for i = 1, 3 do if a.key[i] ~= b.key[i] then return a.key[i] < b.key[i] end end
		return a.res < b.res
	end)
	local parts = {}
	for i, it in ipairs(lore) do parts[i] = it.key[1] .. "," .. it.key[2] .. "," .. it.key[3] end
	local text = table.concat(parts, ";")
	local seed, spin = fnv1(text), fnv1(text .. ";area")
	local a = (spin % 3600) / 3600 * 2 * math.pi
	local off = AREA_OFF_MIN + (math.floor(spin / 3600) % 1000) / 1000 * (AREA_OFF_MAX - AREA_OFF_MIN)
	return lore[seed % #lore + 1], a, off, seed
end
state.test.card_pick = card_pick

local function card_look()
	local all, why, divers = inventory()
	if not all then card_off(why) return end
	local lore, census = {}, {}
	for _, it in ipairs(all) do
		if it.zone and LORE_TYPES[it.zone] then lore[#lore + 1] = it end
		local z = tostring(it.zone)
		census[z] = (census[z] or 0) + 1
	end
	card.lore = lore
	local pick, a, off, seed
	if #lore > 0 then pick, a, off, seed = card_pick(lore) end
	for i, it in ipairs(lore) do log(string.format("key card: lore object %d of %d: %s at %s", i, #lore, it.res, where(it.pos))) end
	local parts = {}
	for z, n in pairs(census) do parts[#parts + 1] = { z = z, n = n } end
	table.sort(parts, function (a, b) return (tonumber(a.z) or 999) < (tonumber(b.z) or 999) end)
	for i, p in ipairs(parts) do parts[i] = p.z .. ":" .. p.n end
	log("key card: interactables by zone type " .. table.concat(parts, " "))
	if #lore == 0 then
		log(string.format("key card: %d interactables on the map, no lore object (zone type 49) yet; will look again", #all))
		return
	end
	local lost = card.lost_at
	card.lost_at = nil
	local moved
	if lost then card.chosen, moved = nearest_lore(lore, lost) else card.chosen = pick end
	log(string.format("key card: fingerprint %08x over %d lore objects (the same in every game that sees the same map)", seed, #lore))
	card.area = { x = card.chosen.pos.x + off * math.cos(a), y = card.chosen.pos.y + off * math.sin(a) }
	log(string.format("map marker: search area %.0f m around %.1f %.1f (the card is %.0f m from its centre)", AREA_RADIUS, card.area.x, card.area.y, off))
	if moved then
		log(string.format("key card: the replacement is the lore object nearest the lost one, %.0f m from where it was", moved))
		banner_show(MOVED_TITLE, MOVED_SUB)
	elseif not card.notified then
		card.notified = true
		banner_show(PICK_TITLE, PICK_SUB)
	end
	local d = divers and divers[1] and dist(divers[1], card.chosen.pos)
	log(string.format("KEY CARD: %d lore objects among %d interactables; the card is %s at %s%s",
		#lore, #all, card.chosen.res, where(card.chosen.pos), d and string.format(", %.0f m from you", d) or ""))
end

-- Called with the unit pass: tracks the mission and picks the card.
local function card_tick(units)
	if card.off or cfg.card ~= 1 or not engine then return end
	if not units or units.where ~= "mission" then
		if card.mission then card.mission, card.chosen, card.found, card.lore, card.area, card.notified, card.lost_at = false, nil, false, nil, nil, nil, nil end
		return
	end
	if not card.mission then
		card.mission, card.since = true, state.frames
		card.next_look = state.frames + CARD_WAIT
	end
	if card.found or state.frames < card.next_look then return end
	if card.chosen and not position(card.chosen.unit) then
		log("key card: the chosen lore object is gone; picking the one nearest to where it was")
		card.lost_at = card.chosen.pos
		card.chosen = nil
	end
	if not card.chosen then
		card.next_look = state.frames + CARD_RETRY
		card_look()
	end
end

-- 0.31 co-op probe (read-only, logging only). Wilson 2026-10-19: every diver should get the banners and the hostile
-- flag whoever takes the intel. The copies do not talk and the SEAF obey the host, so two things have to be learned
-- from a real two-player mission, one log from each machine:
--   (1) the host's copy: does a squadmate's E at the intel change anything in the host's memory (the lore object's
--       state block and record, or the interaction units each Helldiver carries)?  Lines: PROBE CHANGE.
--   (2) the squadmate's copy: when the host flips the SEAF, do their side values turn hostile in this machine's
--       memory too (then this copy can fire its own banner)?  Lines: PROBE SEAF SIDES.
-- Warm-up 15 s: bytes that change then are timers and ignored. A byte that changes more than 6 times is masked.
local PROBE_ZONE, PROBE_REC, PROBE_WARM_S, PROBE_EVERY, PROBE_MAX_LINES, PROBE_MAX_FLIPS = 49, 0x40, 15, 30, 600, 6
local probe = { next = 0, start = nil, lines = 0, prev = {}, noisy = {}, flips = {}, sides = nil, net = nil, mission = false }
state.test.probe = probe
local function probe_say(text)
	if probe.lines < PROBE_MAX_LINES then
		probe.lines = probe.lines + 1
		log("PROBE " .. text)
		if probe.lines == PROBE_MAX_LINES then log("PROBE: line limit reached, no more PROBE lines this mission") end
	end
end
-- The state block and record bytes of every lore object and of every Helldiver's interaction units.
local function probe_scan()
	if state.pe_timestamp ~= CARD_STAMP then return nil end
	local slot = base + INTERACTABLE_RVA
	if not readable(slot, 8) then return nil end
	local mgr = ptr(slot)
	if not mgr or not readable(mgr + IT_HEADER, 72) then return nil end
	local h = mgr + IT_HEADER
	local cap, active = u32(h), u32(h + 8)
	if cap > 16384 or active == 0 or active > cap then return nil end
	local recs, states = ptr(h + 48), ptr(h + 56)
	if not (recs and states and readable(recs, 8 * active) and readable(states, IT_STATE * active)) then return nil end
	local t = unit_table()
	local out = {}
	for i = 0, active - 1 do
		local rec = ptr(recs + 8 * i)
		if rec and readable(rec, 16) then
			local rn = readable(rec, PROBE_REC) and PROBE_REC or 16   -- the record is longer than 16 bytes in the game
			local st = states + IT_STATE * i
			local zones = u32(st + IT_ZONES)
			local zone = zones > 0 and zones <= 16 and u32(st + IT_ZONE_TYPE) or nil
			local res = id_hex(rec)
			local unit = u32(rec + 12)
			local what = res == DIVER_RES and "diver" or (zone == PROBE_ZONE and "lore" or nil)
			if what then
				out[what .. " " .. res .. " " .. string.format("%08x", unit) .. " #" .. i] = {
					what = what, st = ffi.string(ffi.cast("const char *", st), IT_STATE), rb = ffi.string(ffi.cast("const char *", rec), rn),
					pos = unit_pos(t, unit) }
			end
		end
	end
	return out
end
local function probe_tick(units)
	if not units or units.where ~= "mission" then
		if probe.mission then probe.mission = false; probe.prev, probe.noisy, probe.flips, probe.sides, probe.lines = {}, {}, {}, nil, 0 end
		return
	end
	if state.frames < probe.next then return end
	probe.next = state.frames + PROBE_EVERY
	if not probe.mission then
		probe.mission, probe.start = true, os.time()
		log(string.format("PROBE: mission started; warming up %d s (stand still, nobody press E)", PROBE_WARM_S))
	end
	local warm = os.time() - probe.start < PROBE_WARM_S
	-- who this game thinks the host is
	if globals.network and readable(globals.network, 8) then
		local ctx = ptr(globals.network)
		if ctx and readable(ctx + 0xB398, 8) and readable(ctx + 0xB3A8, 8) then
			local me, host = ffi.cast("const uint64_t *", ctx + 0xB398)[0], ffi.cast("const uint64_t *", ctx + 0xB3A8)[0]
			local text = string.format("this peer %016X, host %016X: %s; Helldivers in the mission %d", tonumber(me % 0x100000000), tonumber(host % 0x100000000),
				me == host and "THIS GAME HOSTS" or "this game is a squadmate's", #units.divers)
			if text ~= probe.net then probe.net = text; probe_say("NET " .. text .. " (low 32 bits of the ids)") end
		end
	end
	-- (2) the SEAF side values as this machine sees them
	local tally, order = {}, {}
	for _, sd in ipairs(units.soldiers_list) do
		local k = string.format("0x%X/0x%X", sd.side, sd.copy)
		if not tally[k] then tally[k] = 0; order[#order + 1] = k end
		tally[k] = tally[k] + 1
	end
	table.sort(order)
	local parts = {}
	for i, k in ipairs(order) do parts[i] = k .. " x" .. tally[k] end
	local sides = #parts > 0 and table.concat(parts, ", ") or "none alive"
	if sides ~= probe.sides then
		local was = probe.sides
		probe.sides = sides
		if was then
			probe_say(string.format("SEAF SIDES: %s (was: %s); this copy's rebel mode is %s; local E found the card: %s", sides, was, rebel.on and "ON" or "off", tostring(card.found)))
		else
			probe_say("SEAF SIDES: " .. sides .. " (first look)")
		end
	end
	-- (1) the interactable state blocks
	local scan = probe_scan()
	if not scan then return end
	local _, _, divers = inventory()
	for key, cur in pairs(scan) do
		local old = probe.prev[key]
		if old then
			local mask, flips = probe.noisy[key] or {}, probe.flips[key] or {}
			probe.noisy[key], probe.flips[key] = mask, flips
			local changes = {}
			for _, part in ipairs({ { "state", old.st, cur.st }, { "record", old.rb, cur.rb } }) do
				local name, a, b = part[1], part[2], part[3]
				if a ~= b then
					for off = 1, math.min(#a, #b) do
						if a:byte(off) ~= b:byte(off) then
							local id = name .. off
							if warm then mask[id] = true
							elseif not mask[id] then
								flips[id] = (flips[id] or 0) + 1
								if flips[id] > PROBE_MAX_FLIPS then mask[id] = true
								elseif #changes < 24 then changes[#changes + 1] = string.format("%s+0x%X %02x->%02x", name, off - 1, a:byte(off), b:byte(off)) end
							end
						end
					end
				end
			end
			if #changes > 0 then
				local near = "no Helldiver position"
				if cur.pos and divers and #divers > 0 then
					local bd
					for _, p in ipairs(divers) do local d = dist(p, cur.pos) if not bd or d < bd then bd = d end end
					near = string.format("nearest Helldiver %.1f m", bd)
				end
				probe_say(string.format("CHANGE %s at %s, %s, E pressed here lately: %s: %s", key, cur.pos and where(cur.pos) or "no position", near, tostring(card.found), table.concat(changes, ", ")))
			end
		elseif not warm then
			probe_say("appeared " .. key)
		end
	end
	for key in pairs(probe.prev) do if not scan[key] and not warm then probe_say("gone " .. key) end end
	probe.prev = scan
end

-- The interact key was pressed: log the nearest interactable; true when it is the card, within reach.
local function card_interact(units)
	if card.off or cfg.card ~= 1 or not engine or card.found then return false end
	if not units or units.where ~= "mission" then return false end
	local all, _, divers = inventory()
	all, divers = all or {}, divers or {}
	if #divers == 0 then return false end
	-- the three nearest within 6 m
	local near = {}
	for _, it in ipairs(all) do
		local bd
		for _, p in ipairs(divers) do local d = dist(p, it.pos) if not bd or d < bd then bd = d end end
		if bd and bd <= 6 then near[#near + 1] = { it = it, d = bd } end
	end
	table.sort(near, function (a, b) return a.d < b.d end)
	local dv = {}
	for i, p in ipairs(divers) do dv[i] = where(p) end
	log(string.format("interact: E pressed; Helldivers at %s; %d interactables within 6 m", table.concat(dv, " / "), #near))
	for i = 1, math.min(3, #near) do
		local it, d = near[i].it, near[i].d
		log(string.format("interact: %s interactable %s, zone type %s, %.1f m, at %s%s", i == 1 and "nearest" or ("number " .. i), it.res, tostring(it.zone), d, where(it.pos),
			card.chosen and it.res == card.chosen.res and " (a card-type object)" or ""))
	end
	if not card.chosen then return false end
	local cp = position(card.chosen.unit)
	if not cp then return false end
	for _, p in ipairs(divers) do
		if dist(p, cp) <= CARD_RANGE then card.found = true return true end
	end
	return false
end

-- ------------------------------------------------------------------ map marker (0.14)
-- While the tactical map is open, the card's search area is drawn on it: a thin orange ring with a faint fill
-- around a spot 5 to 25 m off the card (so it still takes a search), labelled DISSIDENT DATA. The map's place
-- and scale come from the game's HUD manager, as Th3chef's Treasure Map reads them (build 25480438): HUD slot
-- game.dll+0x346D538; tactical map at +0x3EF168 in it: open flag +405 (byte), centre x/y +288/+292, pan x/y
-- +304/+308, zoom +328; its frame at +10464: size +36/+40, scale +100, screen x/y +148/+156. A world point
-- lands at the frame's middle plus (point - (centre - pan)) * zoom * scale. Read only; drawn on our own
-- screen surface in the overlay world, above the game's map layers.
local MARKER_LABEL = "INTEL"   -- (Wilson 2026-10-17: "it gives away too much"; was DISSIDENT DATA)
local MAP_HUD_RVA, MAP_VIEW, MAP_OPEN, MAP_V, MAP_FRAME = 0x346D538, 0x3EF168, 405, 288, 10464
local MARKER_LAYER = 950
local marker = { dead = false, gui = nil, world = nil, key = nil }
state.marker = marker


-- The open map's view, false while the map is closed, nil when there is no HUD (no mission) or it reads wrong.
local function map_view()
	local slot = base + MAP_HUD_RVA
	if not readable(slot, 8) then return nil end
	local hud = ptr(slot)
	if not hud then return nil end
	local v = hud + MAP_VIEW
	if not readable(v + MAP_OPEN, 1) then return nil end
	if ffi.cast("const uint8_t *", v + MAP_OPEN)[0] ~= 1 then return false end
	if not (readable(v + MAP_V, 44) and readable(v + MAP_FRAME + 36, 124)) then return nil end
	local f = v + MAP_FRAME
	local out = { cx = f32(v + MAP_V), cy = f32(v + MAP_V + 4), px = f32(v + MAP_V + 16), py = f32(v + MAP_V + 20),
		zoom = f32(v + MAP_V + 40), w = f32(f + 36), h = f32(f + 40), scale = f32(f + 100), x = f32(f + 148), y = f32(f + 156) }
	for _, k in ipairs({ "cx", "cy", "px", "py", "zoom", "w", "h", "scale", "x", "y" }) do if not finite(out[k]) then return nil end end
	if out.zoom <= 0 or out.scale <= 0 or out.w <= 0 or out.h <= 0 then return nil end
	return out
end

-- Where the area lands on screen: centre x, y and ring radius in screen units, and whether it is on the map.
local function area_on_screen(v, area)
	local s = v.scale
	local mx, my = v.x + v.w * s * 0.5, v.y + v.h * s * 0.5
	local k = v.zoom * s
	local x, y = mx + (area.x - (v.cx - v.px)) * k, my + (area.y - (v.cy - v.py)) * k
	local r = math.max(AREA_RADIUS * k, 14)
	local reach = math.min(v.w, v.h) * s * 0.5
	local dx, dy = x - mx, y - my
	return x, y, r, math.sqrt(dx * dx + dy * dy) <= reach + r
end

-- 0.20 trace: the first MARKER_TRACE draws (and every clear while tracing) log a line before and after each
-- engine call, so a freeze shows as a "before" line with no "after".
local MARKER_TRACE = 0
local function mtrace(text) if marker.trace then log("map trace " .. (marker.draws or 0) .. ": " .. text) end end

local function marker_clear()
	if marker.gui and marker.world and engine then
		mtrace("clear: Application.worlds")
		for _, w in ipairs(engine.Application.worlds() or {}) do
			if w == marker.world then
				mtrace("clear: World.destroy_gui")
				engine.World.destroy_gui(marker.world, marker.gui)
				mtrace("clear: World.destroy_gui done")
				break
			end
		end
	end
	marker.gui, marker.world, marker.key = nil, nil, nil
end

-- Every draw builds a new surface: any old one is thrown away first (World.destroy_gui, the close-map clean-up).
-- No Gui.update_text or Gui.destroy_triangle: update_text on a text made in an earlier frame hung the game (0.21).
-- Triangles take Vector3(x, 0, y) and a layer, as Treasure Map draws them.
local RING_SEGMENTS, RING_WIDTH, FILL_SEGMENTS = 72, 2, 48
local function marker_draw(v, area)
	local App, World, Gui = engine.Application, engine.World, engine.Gui
	if type(Gui.triangle) ~= "function" then error("this game version lacks Gui.triangle", 0) end
	local ring, label = cfg.marker ~= 3, cfg.marker ~= 2
	local x, y, r, shown = area_on_screen(v, area)
	if marker.gui then
		mtrace(string.format("moved (area now at %.1f %.1f): throwing the old surface away", x, y))
		marker_clear()
		mtrace("old surface gone")
	end
	if not shown then return end
	marker.draws = (marker.draws or 0) + 1
	marker.trace = marker.draws <= MARKER_TRACE
	mtrace(string.format("start (marker %d); area at %.1f %.1f, ring %.1f; map frame %.0f x %.0f at %.0f %.0f, scale %.3f, zoom %.3f",
		cfg.marker, x, y, r, v.w, v.h, v.x, v.y, v.scale, v.zoom))
	mtrace("Application.main_world / worlds")
	local main, target = App.main_world(), nil
	for _, w in ipairs(App.worlds() or {}) do if w ~= main then target = w break end end
	mtrace(target and "overlay world found" or "no overlay world; nothing drawn")
	if not target then return end
	mtrace("World.create_screen_gui")
	local gui = World.create_screen_gui(target, "scale", 1, 1)
	mtrace("World.create_screen_gui done")
	if not gui then error("screen surface unavailable", 0) end
	marker.gui, marker.world = gui, target
	if ring then
		local V3 = engine.Vector3
		local function tri(ax, ay, bx, by, cx, cy, layer, color)
			Gui.triangle(gui, V3(ax, 0, ay), V3(bx, 0, by), V3(cx, 0, cy), layer, color)
		end
		-- a faint fill: the area, not a target
		mtrace("Gui.triangle x" .. FILL_SEGMENTS .. " (fill)")
		local FILL = engine.Color(48, 255, 140, 40)
		for i = 0, FILL_SEGMENTS - 1 do
			local a0, a1 = i * 2 * math.pi / FILL_SEGMENTS, (i + 1) * 2 * math.pi / FILL_SEGMENTS
			tri(x, y, x + r * math.cos(a0), y + r * math.sin(a0), x + r * math.cos(a1), y + r * math.sin(a1), MARKER_LAYER, FILL)
		end
		-- a smooth, thin ring
		mtrace("Gui.triangle x" .. RING_SEGMENTS * 2 .. " (ring)")
		local RING = engine.Color(235, 255, 140, 40)
		local ri, ro = r - RING_WIDTH / 2, r + RING_WIDTH / 2
		for i = 0, RING_SEGMENTS - 1 do
			local a0, a1 = i * 2 * math.pi / RING_SEGMENTS, (i + 1) * 2 * math.pi / RING_SEGMENTS
			local c0, s0, c1, s1 = math.cos(a0), math.sin(a0), math.cos(a1), math.sin(a1)
			tri(x + ri * c0, y + ri * s0, x + ro * c0, y + ro * s0, x + ro * c1, y + ro * s1, MARKER_LAYER + 1, RING)
			tri(x + ri * c0, y + ri * s0, x + ro * c1, y + ro * s1, x + ri * c1, y + ri * s1, MARKER_LAYER + 1, RING)
		end
		mtrace("Gui.triangle done")
	end
	if label then
		mtrace("font and material")
		marker.font, marker.material = text_ink(gui)   -- the ink is set on each new surface's own material
		if not marker.text_w then
			mtrace("Gui.resolution")
			local _, gh = Gui.resolution()
			marker.size = 15 * ((type(gh) == "number" and gh >= 320) and gh / 1080 or 1)
			mtrace("Gui.text_extents")
			local lo, hi = Gui.text_extents(gui, MARKER_LABEL, marker.font, marker.size)
			marker.text_w = (lo and hi) and (engine.Vector2.x(hi) - engine.Vector2.x(lo)) or 14 * marker.size * 0.6
		end
		local lx, ly = x - marker.text_w / 2, y + r + 5
		mtrace(string.format("Gui.text x2 (shadow, label) at %.0f %.0f", lx, ly))
		Gui.text(gui, MARKER_LABEL, marker.font, marker.size, marker.material, engine.Vector3(lx + 1, ly - 1, MARKER_LAYER + 2), engine.Color(200, 0, 0, 0))
		Gui.text(gui, MARKER_LABEL, marker.font, marker.size, marker.material, engine.Vector3(lx, ly, MARKER_LAYER + 2), engine.Color(255, 255, 140, 40))
		mtrace("Gui.text done")
	end
	mtrace("done")
end

-- Every frame: one byte read while the map is closed; redrawn only when the area moves half a pixel or more.
local function marker_tick()
	if marker.dead then return end
	local area = card.area
	if card.off or cfg.card ~= 1 or not engine or not card.chosen or card.found or not area then
		if marker.gui then marker_clear() end
		return
	end
	local v = map_view()
	local open = v and true or false
	if open ~= (marker.open or false) then
		marker.open = open
		log(open and "map opened" or ("map closed" .. (v == nil and " (or unreadable)" or "")))
		marker.beat_at = os.clock() + 1
	end
	if not v or cfg.marker == 0 then
		if marker.gui then marker_clear() end
		return
	end
	local x, y, r = area_on_screen(v, area)
	local key = marker.key
	if marker.gui and key and math.abs(key[1] - x) < 0.5 and math.abs(key[2] - y) < 0.5 and math.abs(key[3] - r) < 0.5 then return end
	marker_draw(v, area)
	marker.key = { x, y, r }
	if marker.gui and not marker.said then marker.said = true; log(string.format("map marker: drawn on the tactical map (search area at %.0f %.0f on screen, ring %.0f)", x, y, r)) end
end

local phase, wait = "start", 240
local last_units, last_count, last_seen = nil, nil, 0
local function watch()
	banner_tick()
	voice_tick()
	local okm, errm = pcall(marker_tick)
	if not okm then marker.dead = true; pcall(marker_clear); log("map marker off for this game session: " .. tostring(errm)) end
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
	local interact = cfg.card == 1 and not card.off and not rebel.on and pressed(cfg.interact)
	if not (key or interact or state.frames % (rebel.on and 5 or 15) == 0) then return end
	local units, why = read_units()
	local found = false
	if interact and not key then
		local okf, res = pcall(card_interact, units)
		if okf then found = res else card_off("stopped on error: " .. tostring(res)) end
	end
	if found then
		load_cfg()
		log("KEY CARD FOUND: the dissidents' data is read; switching rebel mode on")
		switch_on(units, count)
		units, why = read_units()
	elseif key then
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
	if cfg.probe == 1 then local okp, errp = pcall(probe_tick, units); if not okp then cfg.probe = 0; log("PROBE stopped on error: " .. tostring(errp)) end end
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
	local okc, errc = pcall(card_tick, units)
	if not okc then card_off("stopped on error: " .. tostring(errc)) end
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
			log(string.format("READY - rebel mode is off. %s switches it on in a mission (soldiers to %s, guard %d at %d, squad %d).",
				cfg.key == 0 and "The intel" or ("Key " .. cfg.key), cfg.side == 0 and "the enemy's side" or string.format("side 0x%X", cfg.side), cfg.guard, cfg.guard_at, cfg.squad))
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
