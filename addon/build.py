#!/usr/bin/env python3
"""Build the Chaos Divers addon: fill the signatures into the Lua and pack it.

  build.py   -> build/9ba626afa44a3aa3.patch_0 (+ two empty side files)
                and build/chaos_divers.built.lua (what the tests run)

data/sigs.json is made by tools/make_sigs.py from a copy of game.dll's code
taken from the running game (../gamedump/). After a game update the signatures
may stop matching; the addon then stops itself and says so in its log.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pack  # noqa: E402


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    if sys.argv[1:]:
        sys.exit("usage: build.py")
    sigs = json.load(open(os.path.join(HERE, "data", "sigs.json"), encoding="utf-8"))
    sig_lua = "{\n" + "".join(
        "\t{ name = %s, symbol = %s, anchor_offset = %d, extract_offset = %d, extract_end = %d,\n"
        "\t  hex = %s,\n\t  mask = %s,\n\t  anchor = %s },\n" % (
            lua_str(s["name"]), lua_str(s["symbol"]), s["anchor_offset"], s["extract_offset"], s["extract_end"],
            lua_str(s["hex"]), lua_str(s["mask"]), lua_str(s["anchor"]))
        for s in sigs) + "}"
    with open(os.path.join(HERE, "src", "chaos_divers.lua"), encoding="utf-8") as fh:
        src = fh.read()
    if src.count("--@SIGS@") != 1:
        sys.exit("placeholder --@SIGS@ must appear exactly once")
    src = src.replace("--@SIGS@", sig_lua)
    out = os.path.join(HERE, "build")
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "chaos_divers.built.lua"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(src)
    name, blob = pack.build(src.encode("utf-8"))
    base = os.path.join(out, pack.ARCHIVE + ".patch_0")
    with open(base, "wb") as fh:
        fh.write(blob)
    for ext in (".gpu_resources", ".stream"):
        open(base + ext, "wb").close()
    print("built %s: %d bytes of Lua -> %s" % (name, len(src.encode("utf-8")), base))


if __name__ == "__main__":
    main()
