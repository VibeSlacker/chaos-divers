Chaos Divers: Dissidents Among Us 1.1.0
by vibeslacker
Made with AI. Gameplay change for HellForge (Bingus Shared Loader mod).

CHANGELOG
1.1.0  A harder, more chaotic fight, and you choose how hard.
       The intel is now a walk, not a stroll: it is picked 60 to 250 m from
       your squad's starting area (the same spot in every squadmate's game),
       never right on top of you. If you cannot reach it (a ledge, a rock,
       inside a structure, out of the map), a re-roll key throws it away and
       picks another. There is no key by default: set one on the game's
       bindings page (MODS > CHAOS DIVERS > Re-roll Intel) or put a key
       number in ChaosDivers.cfg (reroll = 121 is F10). In a squad, everyone
       presses it to stay on the same intel.
       You choose how many SEAF turn. Two new sliders on the MODS options
       page: HOSTILE SEAF (PERCENT) (5 to 100, default 50) and MAX HOSTILE
       SEAF AT ONCE (6 to 40, default 30; hostile_cap in ChaosDivers.cfg,
       0 = no cap). SEAF that drop together (squads are six) turn, or stay
       loyal, as one, so you get a hostile squad next to a loyal one: a
       little chaos and fog of war. A squad that would take the count past
       the cap stays loyal for good. Loyal SEAF stay on your side and shoot
       the turned ones. A squad that is to turn stays friendly while it
       comes down, so the loyal SEAF do not shoot it out of the sky and give
       the game away; it turns once it is seen on the ground, and never
       later than drop_wait seconds after it appeared (default 7; 0 = 25
       seconds). SEAF already standing there when you take the intel turn at
       once. Without the options menu, hostile = 1 to 100 in
       ChaosDivers.cfg. The log says how far each intel candidate was and
       how many SEAF were kept loyal.
1.0.1  The intel now uses your game's own interact key instead of a fixed E,
       so players who rebound it can take the intel. If the game's key can't
       be read, it falls back to E. A number in ChaosDivers.cfg (interact) still
       forces a key.
1.0.0  First release.

THE STORY
It starts as a routine drop. Then the truth comes out: there is a cell
of enemy sympathizers, the ones who have been building the broadcast
towers and sabotaging Super Earth from the inside. Caught in the open,
they turn on the Helldivers and fight alongside whoever holds the
planet. Command is desperate for intel package. It needs to be returned
to the Super Destroyer at mission completion.

WHAT IT DOES
- About half a minute into a mission on a planet with SEAF, "NEW
  INTELLIGENCE DISCOVERED" shows and an INTEL ring appears on your
  tactical map, 60 to 250 m from where your squad starts. The intel is one
  of the lore objects inside the ring.
- Press your interact key (E by default) at the intel to take it (walking
  past does nothing). That exposes the cell: "DISSIDENT CELL DISCOVERED"
  shows, and SEAF squads turn hostile and side with the enemy holding the
  planet (squids, bugs or bots).
- Not every squad turns. The HOSTILE SEAF slider on the MODS options page
  (default 50 percent) sets how many squads turn, and each squad is decided
  as one, so you get a hostile squad next to a loyal one. The MAX HOSTILE
  SEAF AT ONCE slider (default 30) caps how many turned SEAF can be alive at
  the same time; a squad that would go past it stays loyal.
- A squad that is to turn stays friendly while it drops in, so the loyal
  SEAF do not shoot it out of the sky and give it away. It turns once it
  is seen on the ground, and never later than 7 seconds after it appeared.
  SEAF already standing there when you take the intel turn at once.
- Your guard dog and sentries stay on your side and fight the rebels.
- Killing rebels does not mark you as a traitor and the destroyer does not
  come for you.
- It switches itself off when the mission ends, and the surviving soldiers
  go back to normal.
- It stays on when you die and reinforce.

REQUIREMENTS
- HellForge (game build 25480438) with Bingus Shared Loader v15 or newer.
  Put the loader LAST in your load order.
- SEAF have to be on the map. HellForge does not apply the Heavy SEAF
  Presence planet modifier, so no SEAF drop in by themselves. It was tested
  with the HellForge mod Heavy SEAF Presence Everywhere, which drops SEAF
  squads in. Without some source of SEAF, the mod loads and the intel
  shows, but there is nothing to turn.
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
- Everyone with the mod sees the same intel and the same ring, and any
  player can take the intel with their own interact key.
- The SEAF AI runs on the host, so the host's sliders (share and cap) are
  the ones that count. Friends' sliders do not change what the SEAF do.
- Squadmates without the mod still get shot at by the rebels, and their
  kills are kept off the traitor count, but they see no banners and no ring.
- Not proven: whether a squadmate taking the intel (not the host) turns
  the SEAF for the whole squad, or only on their own machine. The host
  taking it is the sure way.

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
- hostile_cap = 30  The most turned SEAF alive at once (6 to 60).
                   0 = no cap. The slider on the MODS page wins.
- drop_wait = 7  The longest a SEAF squad that is to turn is held after it
                appears, so the loyal SEAF do not shoot it in its drop ship.
                It turns sooner once seen on the ground. 0 = 25 seconds.
- hostile = 50   The share of SEAF that turn, 1 to 100. The slider on the MODS
                options page is used instead when it is there.
- key = 0       0 = no manual key. Set a key number to get one.
- reroll = 0    0 = no key in this file. A key number (121 = F10) throws the
                current intel away and picks another one. Can also be set
                on the bindings page.

KNOWN LIMITS
- Tested on HellForge 0.3.0 (Linux) with Heavy SEAF Presence Everywhere:
  the intel, the SEAF turning, squads, the landing wait and both sliders
  work. Windows and co-op are not tested.
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

LICENSE
MIT License, copyright (c) 2026 vibeslacker. The full text is in LICENSE.txt.
If you use this mod or its idea in your own work, please credit vibeslacker for the idea.

THANKS
CowboyBingus for Bingus Shared Loader.
