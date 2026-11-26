"""Skin check, part 1: the repo scan (team/requirements/m1-core-loop-gate.md, "The skin check"; M1-01).

The rule (team/CLAUDE.md, "The skin is separate from the rules"): nothing outside src/ReplicatedStorage/Skins/
contains a display name, a hex or RGB colour literal, or an asset id.

Run from anywhere:   python tools/check_skin.py          exit 0 = no hits, 1 = hits, 2 = a file did not lex
                     python tools/check_skin.py --verbose   also lists hits found only in comments

What it scans: every *.lua under src/ except src/ReplicatedStorage/Skins/ (the stub skin included, it is a
skin). Comments are stripped first: a comment is not something a player sees, so hits there are listed as
notes (with --verbose) and never fail the check (TEAM CALL M1-01).
What counts as a hit, in code:
  * asset ids: rbxassetid, roblox.com/asset, Content.fromAssetId, and an asset property (SoundId, Image,
    AnimationId, MeshId, TextureID, ColorMap, ...) set to a literal number of 5+ digits
  * colours: Color3.fromRGB, Color3.fromHex, Color3.new, BrickColor.new, a "#RRGGBB" (or #RGB / #RRGGBBAA) string
  * names: any creature, zone, hazard or product name from Skins/brickbrawl/Names.lua (case-insensitive), as far
    as that file holds them (all 36 / 6 / 6 / 19 are checked at M3)
One explicit exception: src/ReplicatedStorage/Shared/Skin.lua, inside `function Skin.assetUrl ... end` only, may
hold the asset scheme (it is the one builder of content strings, M1-01b). Any other line of that file, and every
other file, is still scanned.
It also lexes every scanned file and every Skins/ file (strings, long strings, comments, bracket balance), which
is the only syntax check available without a Luau parser: a file that does not lex fails with exit 2.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
SKINS = SRC / "ReplicatedStorage" / "Skins"
NAMES = SKINS / "brickbrawl" / "Names.lua"
NAME_KEYS = ("creatures", "zones", "hazards", "products")
ID_LIKE = re.compile(r"^(z\d+_t\d+|pass_\w+|product_\w+)$")

CODE_RULES = [
    ("asset id", re.compile(r"rbxassetid", re.I)),
    ("asset id", re.compile(r"roblox\.com/asset", re.I)),
    ("asset id", re.compile(r"Content\.fromAssetId")),
    ("asset id", re.compile(r"\b(SoundId|Image|AnimationId|MeshId|TextureID|TextureId|Texture|ColorMap|NormalMap|"
                            r"RoughnessMap|MetalnessMap|ImageContent)\s*=\s*[\"']?\d{5,}")),
    ("colour literal", re.compile(r"Color3\.(fromRGB|fromHex|new)\s*\(")),
    ("colour literal", re.compile(r"BrickColor\.new\s*\(")),
]
HEX_IN_STRING = re.compile(r"^#(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$")


class LexError(Exception):
    pass


def lex(text):
    """Split Lua source into (code_without_comments, strings, comments). code keeps line breaks so line numbers
    hold; strings are replaced by a placeholder in code and returned as (line, value)."""
    code, strings, comments = [], [], []
    i, n, line = 0, len(text), 1
    depth = []  # bracket stack: (char, line)
    pairs = {")": "(", "]": "[", "}": "{"}

    def long_bracket(at):
        m = re.match(r"\[(=*)\[", text[at:])
        return m

    while i < n:
        c = text[i]
        if c == "\n":
            line += 1
            code.append(c)
            i += 1
        elif text.startswith("--", i):
            m = long_bracket(i + 2)
            if m:
                close = "]" + m.group(1) + "]"
                end = text.find(close, i + 2 + len(m.group(0)))
                if end < 0:
                    raise LexError(f"line {line}: unclosed long comment")
                body = text[i:end + len(close)]
            else:
                end = text.find("\n", i)
                end = n if end < 0 else end
                body = text[i:end]
                close = ""
            comments.append((line, body))
            nl = body.count("\n")
            code.append("\n" * nl)
            line += nl
            i += len(body)
        elif c in "\"'":
            j = i + 1
            buf = []
            while True:
                if j >= n or text[j] == "\n":
                    raise LexError(f"line {line}: unclosed string")
                if text[j] == "\\":
                    buf.append(text[j:j + 2])
                    j += 2
                    continue
                if text[j] == c:
                    break
                buf.append(text[j])
                j += 1
            strings.append((line, "".join(buf)))
            body = "".join(buf)
            code.append(c + (body if body.isdigit() else "S") + c)  # digit strings stay: SoundId = "123456"
            i = j + 1
        elif c == "`":
            j = text.find("`", i + 1)
            if j < 0:
                raise LexError(f"line {line}: unclosed interpolated string")
            body = text[i + 1:j]
            strings.append((line, body))
            code.append("`S`")
            line += body.count("\n")
            code.append("\n" * body.count("\n"))
            i = j + 1
        elif c == "[" and long_bracket(i):
            m = long_bracket(i)
            close = "]" + m.group(1) + "]"
            end = text.find(close, i + len(m.group(0)))
            if end < 0:
                raise LexError(f"line {line}: unclosed long string")
            body = text[i + len(m.group(0)):end]
            strings.append((line, body))
            code.append('"S"' + "\n" * body.count("\n"))
            line += body.count("\n")
            i = end + len(close)
        else:
            if c in "([{":
                depth.append((c, line))
            elif c in ")]}":
                if not depth or depth[-1][0] != pairs[c]:
                    raise LexError(f"line {line}: unbalanced '{c}'")
                depth.pop()
            code.append(c)
            i += 1
    if depth:
        raise LexError(f"line {depth[-1][1]}: '{depth[-1][0]}' never closed")
    return "".join(code), strings, comments


def block_after_key(text, key):
    """The text of `key = { ... }` (brace-matched), or None."""
    m = re.search(r"(?<![\w.])" + key + r"\s*=\s*\{", text)
    if not m:
        return None
    i = m.end() - 1
    d = 0
    for j in range(i, len(text)):
        if text[j] == "{":
            d += 1
        elif text[j] == "}":
            d -= 1
            if d == 0:
                return text[i:j + 1]
    return None


def read_names():
    names = {}
    if not NAMES.exists():
        return names
    text = NAMES.read_text(encoding="utf-8")
    try:
        _, _, comments = lex(text)
    except LexError:
        return names
    for _, body in comments:  # drop comments before parsing blocks
        text = text.replace(body, "")
    for key in NAME_KEYS:
        block = block_after_key(text, key)
        if not block:
            continue
        vals = re.findall(r"\"([^\"]+)\"|'([^']+)'", block)
        for a, b in vals:
            v = (a or b).strip()
            if v and not ID_LIKE.match(v) and len(v) >= 3:
                names[v.lower()] = (key, v)
    return names


ASSET_URL_FILE = "src/ReplicatedStorage/Shared/Skin.lua"


def asset_url_lines(text):
    """Line numbers (1-based) of `function Skin.assetUrl` through its closing unindented `end`."""
    lines = text.splitlines()
    for i, l in enumerate(lines):
        if re.match(r"function Skin\.assetUrl", l):
            for j in range(i + 1, len(lines)):
                if lines[j].startswith("end"):
                    return set(range(i + 1, j + 2))
    return set()


def main():
    verbose = "--verbose" in sys.argv
    names = read_names()
    name_res = [(re.compile(re.escape(low), re.I), cat, orig) for low, (cat, orig) in names.items()]

    hits, notes, lex_errors = [], [], []
    scanned = 0
    for p in sorted(SRC.rglob("*.lua")):
        rel = p.relative_to(ROOT).as_posix()
        in_skin = SKINS in p.parents
        text = p.read_text(encoding="utf-8")
        try:
            code, strings, comments = lex(text)
        except LexError as e:
            lex_errors.append(f"{rel}: {e}")
            continue
        if in_skin:
            continue
        scanned += 1
        exempt = asset_url_lines(text) if rel == ASSET_URL_FILE else set()
        code_lines = code.split("\n")
        for ln, src in enumerate(code_lines, 1):
            for what, rx in CODE_RULES:
                if rx.search(src) and ln not in exempt:
                    hits.append(f"{rel}:{ln}: {what}: {src.strip()[:100]}")
        for ln, s in strings:
            if ln in exempt:
                continue
            if HEX_IN_STRING.match(s.strip()):
                hits.append(f"{rel}:{ln}: colour literal: \"{s}\"")
            if re.search(r"rbxassetid|roblox\.com/asset", s, re.I):
                hits.append(f"{rel}:{ln}: asset id: \"{s[:80]}\"")
            for rx, cat, orig in name_res:
                if rx.search(s):
                    hits.append(f"{rel}:{ln}: name ({cat}) '{orig}' in a string: \"{s[:80]}\"")
        for ln, body in comments:
            for rx, cat, orig in name_res:
                if rx.search(body):
                    notes.append(f"{rel}:{ln}: comment names '{orig}'")
            for what, rx in CODE_RULES:
                if rx.search(body):
                    notes.append(f"{rel}:{ln}: comment mentions {what}")

    hits = sorted(set(hits))
    for h in hits:
        print("HIT  " + h)
    for e in lex_errors:
        print("LEX  " + e)
    if verbose:
        for nline in sorted(set(notes)):
            print("NOTE " + nline)
    by_cat = {}
    for _, (cat, _) in names.items():
        by_cat[cat] = by_cat.get(cat, 0) + 1
    counts = ", ".join(f"{k} {by_cat.get(k, 0)}" for k in NAME_KEYS)
    print(f"check_skin: {scanned} files scanned outside Skins/, names read from Names.lua: {counts}")
    print(f"check_skin: {len(hits)} hits, {len(lex_errors)} files that do not lex, {len(set(notes))} comment notes")
    if lex_errors:
        return 2
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
