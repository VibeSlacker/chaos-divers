Chaos Divers: Dissident Discovery - TEST BUILD 0.10
by vibeslacker
Made with AI. For testers, not a public release.

THE STORY
It starts as a routine drop. Then the truth comes out: the SEAF squads on
the ground are enemy sympathisers, the ones who have been building the
broadcast towers and sabotaging Super Earth from the inside. Caught in the
open, and too arrogant to hide it, they turn on the Helldivers and fight
alongside whoever holds the planet. Command is behind, lacking the intel,
and still calls SEAF in as friendly support. They are not.

Those broadcast towers are a jamming net. Once the cell is exposed, your
uplink to the Super Destroyer drops to static: no voice, no data, no kill
reports going up. The towers spoof the feed, so from orbit every SEAF
traitor still reads as a loyal friendly. That is why command keeps sending
Pelicans of "reinforcements," and why no penalty comes down when you put a
traitor in the dirt. Only the stratagem beacon's short coordinates burst
gets through: the Destroyer still drops what you ask for, it just has no
idea who you are aiming it at. You are alone down here. Complete the
mission.

WHAT IT DOES
- Press F9 in a mission. "DISSIDENT CELL DISCOVERED" shows on screen and
  every SEAF soldier on the map, and every squad that lands after, turns
  hostile and sides with the enemy holding the planet (squids, bugs or
  bots).
- Your guard dog and sentries stay on your side and fight the rebels.
- Killing rebels does not mark you as a traitor and the destroyer does not
  come for you.
- Press F9 again to switch it off. The surviving soldiers go back to
  normal. It also switches itself off when the mission ends.
- It stays on when you die and reinforce.

REQUIREMENTS
- Bingus Shared Loader v15 or newer. Put the loader LAST in your load order.
- Made for game build 25480438. After a game update the mod checks the
  game's code first. If something has changed it switches itself off and
  says why in its log.
- SEAF have to be on the map. Look for planets with the Heavy SEAF Presence
  modifier on the Galactic War map.
- Optional: Vanilla Plus Megapack (its Mod Bindings Menu) lets you set your
  own key in the game: Options, key bindings, MODS tab, CHAOS DIVERS.

INSTALL
1. Close the game.
2. Add this zip to your mod manager, along with Bingus Shared Loader.
3. Enable both and deploy. Loader last.
4. Start the game, drop on a planet with SEAF, press F9.

SETTINGS AND FILES
In %LOCALAPPDATA%\CowboyBingus\Helldivers2\Logs:
- ChaosDivers.cfg           settings, each one explained in the file.
                            Written the first time the game starts with
                            the mod. Read again every time you press the key.
- ChaosDivers.log           what the mod did this session.
- ChaosDivers.previous.log  the session before.

The main settings:
- key = 120     the on/off key as a Windows key number (120 = F9).
- side = 0      0 = join whatever enemy holds the map. 2 = bugs,
                4 = squids, 8 = bots (bots not tested yet).
- squad = 0     0 = solo only. 1 = also with other players (private lobby,
                friends who know; not tested yet).
- banner = 1    0 turns off the on-screen banner.

KNOWN LIMITS (this is a test build)
- Solo only by default. With another player in the mission it will not
  switch on. Multiplayer has not been tested.
- Only the host's key works.
- The requisition fine for killing SEAF still applies in this test build.
  The story says the ship never hears about it; that part is not built
  yet, so you may still be charged. If the mission recap shows a fine,
  tell us.
- Brewed on Linux with Proton. Windows is untested so far, which is why you
  are testing it.

WHAT TO SEND BACK
After a test mission, send ChaosDivers.log and ChaosDivers.previous.log from the
folder above, and say what you saw: did the banner show, did the SEAF turn
on you, did your dog and sentries stay loyal, did anything crash.

GOOD TO KNOW
- This mod changes game memory while the game runs. It is a gameplay change
  in an online game. Use it at your own risk, solo or with friends who know.
- No network access. Nothing leaves your computer.

UNINSTALL
Close the game, disable or remove the mod, deploy. Delete the ChaosDivers
files in the folder above if you want no trace.

THANKS
CowboyBingus for Bingus Shared Loader.
