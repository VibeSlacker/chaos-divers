# Chaos Divers: Dissident Discovery

Helldivers 2 mod by **vibeslacker**. Test builds, private while it is being tested. Made with AI: the code is written by an AI and tested in the game by a human.

Press F9 in a mission and the SEAF soldiers turn out to be dissidents: they turn on the Helldivers and fight alongside whoever holds the planet. Your guard dog and sentries stay loyal, and killing rebels brings no traitor mark and no destroyer. The story is in [`BACKSTORY.txt`](BACKSTORY.txt); the tester readme (install, settings, what to send back) is [`release/README.txt`](release/README.txt).

- **Download:** the newest zip under [Releases](../../releases).
- **Needs:** [Bingus Shared Loader](https://github.com/CowboyBingus/BingusSharedLoader) v15 or newer, loaded last, and a planet with SEAF on it (Heavy SEAF Presence).
- **Testers:** send `ChaosDivers.log` and `ChaosDivers.previous.log` from `%LOCALAPPDATA%\CowboyBingus\Helldivers2\Logs` with what you saw, as an issue here.

## Building from source

Python 3 and LuaJIT, run from `addon/`.

```
python3 build.py                                                     # build/: the mod
luajit test/harness.lua build/chaos_divers.built.lua data/sigs.json <scratch dir> [side8|fresh|auto|nosig|banner]
luajit check.lua build/chaos_divers.built.lua                        # accidental globals; no output = clean
python3 ../tools/make_release.py build ../release Chaos-Divers-Dissident-Discovery-test-<version>.zip
```

- `addon/src/chaos_divers.lua` is the one source; its header explains what it writes and why.
- `addon/data/` holds the code signatures for game build 25480438; `addon/tools/make_sigs.py` remakes them from a dump of the game's code after an update.
- `addon/test/harness.lua` runs the built mod against a fake game, frame by frame. It proves the mod's own logic, not the game's layout.

## Thanks

CowboyBingus for Bingus Shared Loader.
