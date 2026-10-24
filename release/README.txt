Chaos Divers: Dissidents Among Us 1.0.0
by vibeslacker
Made with AI. Gameplay change for HellForge (Bingus Shared Loader mod).

THE STORY
It starts as a routine drop. Then the truth comes out: the SEAF squads on
the ground are enemy sympathisers, the ones who have been building the
broadcast towers and sabotaging Super Earth from the inside. Caught in the
open, and too arrogant to hide it, they turn on the Helldivers and fight
alongside whoever holds the planet. Command is behind, lacking the intel,
and still calls SEAF in as friendly support. They are not.

Those broadcast towers are a jamming net. The towers spoof the feed, so
from orbit every SEAF traitor still reads as a loyal friendly. That is why
command keeps sending Pelicans of "reinforcements," and why no penalty
comes down when you put a traitor in the dirt. You are alone down here.
Complete the mission.

WHAT IT DOES
- About half a minute into a mission on a planet with SEAF, "NEW
  INTELLIGENCE DISCOVERED" shows and an INTEL ring appears on your
  tactical map. The intel is one of the lore objects inside the ring.
- Press E at the intel to take it (walking past does nothing). That
  exposes the cell: "DISSIDENT CELL DISCOVERED" shows, and every SEAF
  soldier on the map, and every squad that lands after, turns hostile
  and sides with the enemy holding the planet (squids, bugs or bots).
- Your guard dog and sentries stay on your side and fight the rebels.
- Killing rebels does not mark you as a traitor and the destroyer does not
  come for you.
- It switches itself off when the mission ends, and the surviving soldiers
  go back to normal.
- It stays on when you die and reinforce.

REQUIREMENTS
- HellForge (game build 25480438) with Bingus Shared Loader v15 or newer.
  Put the loader LAST in your load order.
- SEAF have to be on the map. The mod needs the Heavy SEAF Presence planet
  modifier (SEAF squads dropping in to help you), and HellForge does not
  apply mission modifiers yet: on Partion and Esker, both marked Heavy SEAF
  Presence in the war, no SEAF ever dropped and the modifier's audio cue
  never played. Until HellForge supports it, the mod loads and the intel
  shows, but there is nothing to turn. It will start working by itself once
  SEAF appear in missions.
- After a game update the mod checks the game's code first. If something
  has changed it switches itself off and says why in its log.

INSTALL (HellForge)
1. Close the game.
2. Drop this zip, and the Bingus Shared Loader zip, into your HellForge
   mods folder (Documents/HellForge/mods) or add them on the Mods page.
3. Enable both. Loader last.
4. Start the game, drop on a planet with SEAF, find the intel.

PLAYING TOGETHER
- Use it in a private lobby with friends who know. Never in a public game.
- Everyone with the mod sees the same intel and the same ring. Any player
  who presses E at the intel exposes the cell in their own game.
- Squadmates without the mod still get shot at by the rebels, and their
  kills are kept off the traitor count, but they see no banners and no ring.
- Not proven: whether a squadmate's E (not the host's) turns the SEAF for
  the whole squad, or only on their own machine. The SEAF AI runs on the
  host, so the host pressing E is the sure way.

SETTINGS AND FILES
In the CowboyBingus log folder (Logs):
- ChaosDivers.cfg           settings, each one explained in the file.
                            Written the first time the game starts with
                            the mod.
- ChaosDivers.log           what the mod did this session.
- ChaosDivers.previous.log  the session before.

The main settings:
- side = 0      0 = join whatever enemy holds the map. 2 = bugs,
                4 = squids, 8 = bots (bots not tested).
- squad = 1     1 = works with other players in the mission. 0 = solo only.
- banner = 1    0 turns off the on-screen banner.
- marker = 1    1 = ring and label on the map, 2 ring, 3 label, 0 none.
- key = 0       0 = no manual key. Set a key number to get one.

KNOWN LIMITS
- HellForge: the intel banner, the INTEL ring on the map and taking the
  intel with E all work (tested on Esker). Turning SEAF hostile could not be
  tested there, because no SEAF drop in (see REQUIREMENTS). It was proven on
  the same game build with other loaders before.
- The requisition fine for killing SEAF may still apply. The story says the
  ship never hears about it; that part is not fully built, so you may still
  be charged. If the mission recap shows a fine, tell the author.
- Bot missions with SEAF are untested.
- A game update can switch the intel, ring and voice call off until the
  mod's addresses are updated.

GOOD TO KNOW
- This mod changes game memory while the game runs. It is a gameplay change
  in an online game. Use it at your own risk, solo or with friends who know.
- No network access. Nothing leaves your computer.
- Bug reports: send ChaosDivers.log and ChaosDivers.previous.log and say
  what you saw.

UNINSTALL
Close the game, disable or remove the mod. Delete the ChaosDivers files in
the log folder if you want no trace.

THANKS
CowboyBingus for Bingus Shared Loader.
