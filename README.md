# Chaos Divers: Dissidents Among Us

Helldivers 2 mod by **vibeslacker**. Release 1.0.0, made for HellForge. Made with AI: the code is written by an AI and tested in the game by a human.

Find the dissidents' intel in a mission (press E at it) and the SEAF soldiers turn out to be dissidents: they turn on the Helldivers and fight alongside whoever holds the planet. Your guard dog and sentries stay loyal, and killing rebels brings no traitor mark and no destroyer. The story is in [`BACKSTORY.txt`](BACKSTORY.txt); the tester readme (install, settings, what to send back) is [`release/README.txt`](release/README.txt).

- **Download:** the newest zip under [Releases](../../releases).
- **Needs:** [Bingus Shared Loader](https://github.com/CowboyBingus/BingusSharedLoader) v15 or newer, loaded last, and a mission with SEAF in it (the Heavy SEAF Presence planet modifier). HellForge does not apply mission modifiers yet, so no SEAF drop in there for now; the intel and ring work.
- **Bug reports:** send `ChaosDivers.log` and `ChaosDivers.previous.log` from `%LOCALAPPDATA%\CowboyBingus\Helldivers2\Logs` with what you saw, as an issue here.

## Building from source

Python 3 and LuaJIT, run from `addon/`.

```
python3 build.py                                                     # build/: the mod
luajit test/harness.lua build/chaos_divers.built.lua data/sigs.json <scratch dir> [side8|fresh|auto|nosig|banner]
luajit check.lua build/chaos_divers.built.lua                        # accidental globals; no output = clean
python3 ../tools/make_release.py build ../release Chaos-Divers-Dissidents-Among-Us-<version>.zip
```

- `addon/src/chaos_divers.lua` is the one source; its header explains what it writes and why.
- `addon/data/` holds the code signatures for game build 25480438; `addon/tools/make_sigs.py` remakes them from a dump of the game's code after an update.
- `addon/test/harness.lua` runs the built mod against a fake game, frame by frame. It proves the mod's own logic, not the game's layout.

## Thanks

CowboyBingus for Bingus Shared Loader.

## Support

If you like my mods, you can support me at https://ko-fi.com/vibeslacker
