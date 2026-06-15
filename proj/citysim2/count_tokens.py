# count_tokens.py - approximate pico-8 token count for citysim2.p8 (+includes)
# rules (verified vs PICO-8, see LEARNINGS): words/numbers/strings/operators = 1;
# bracket pairs and strings count 1; commas/periods/colons/semicolons/local/end/
# comments are free; '..' = 1; negative literals fold in. Within ~6 of PICO-8;
# it slightly UNDER-counts, so leave a little margin. PICO-8 -x is authoritative.
#
# usage:
#   py count_tokens.py            # whole cart (resolves #include)
#   py count_tokens.py map.lua    # a single module file (for delegating/verifying)
#   py count_tokens.py tree       # per-include, per-function breakdown of the cart
import re, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))

tok_re = re.compile(
    r'"[^"]*"|\'[^\']*\''
    r"|[a-zA-Z_][a-zA-Z0-9_]*"
    r"|\d+\.?\d*|\.\d+|0x[0-9a-fA-F.]+"
    r"|==|~=|<=|>=|\.\.|\+=|-=|\*=|/=|%=|\^=|\\|//"
    r"|[+\-*/%^#<>=(){}\[\]@$?]"
)
FREE = {"local", "end"}

def count(code):
    code = re.sub(r"--\[\[.*?\]\]", " ", code, flags=re.S)
    code = re.sub(r"--[^\n]*", " ", code)
    n, prev = 0, ""
    for m in tok_re.finditer(code):
        t = m.group(0)
        if t in FREE or t in ")]}":
            prev = t
            continue
        if t == "-" and (prev == "" or prev in "+-*/%^<>=(,{[" or
                         prev in ("==","~=","<=",">=","..","and","or","not","return",",")):
            prev = t
            continue
        n += 1
        prev = t
    return n

def lua_of(cart):
    src = open(cart, encoding="utf-8").read()
    lua = src.split("__lua__\n", 1)[1]
    lua = re.split(r"\n__(gfx|gff|map|sfx|music|label)__\n", lua)[0]
    out = []
    for line in lua.splitlines():
        m = re.match(r"\s*#include\s+(\S+)", line)
        if m:
            out.append(open(os.path.join(os.path.dirname(cart), m.group(1)), encoding="utf-8").read())
        else:
            out.append(line)
    return "\n".join(out)

def includes_of(cart):
    # ordered list of (label, code): each #include file, plus the cart's own
    # glue lines collected under "(glue)".
    src = open(cart, encoding="utf-8").read()
    lua = src.split("__lua__\n", 1)[1]
    lua = re.split(r"\n__(gfx|gff|map|sfx|music|label)__\n", lua)[0]
    out, glue = [], []
    for line in lua.splitlines():
        m = re.match(r"\s*#include\s+(\S+)", line)
        if m:
            out.append((m.group(1),
                        open(os.path.join(os.path.dirname(cart), m.group(1)), encoding="utf-8").read()))
        else:
            glue.append(line)
    out.append(("(glue)", "\n".join(glue)))
    return out

def funcs_of(code):
    # top-level functions as (name, tokens), sorted desc, + the file-level
    # remainder (data tables / statements outside any function).
    clean = re.sub(r"--\[\[.*?\]\]", " ", code, flags=re.S)
    clean = re.sub(r"--[^\n]*", " ", clean)
    depth, start, name, fns = 0, None, None, []
    for m in tok_re.finditer(clean):
        w = m.group(0)
        if w == "function":
            if depth == 0:
                start = m.start()
                nm = re.match(r"function\s+([\w.:]+)", clean[m.start():])
                name = nm.group(1) if nm else "(anon)"
            depth += 1
        elif w in ("if", "for", "while"):
            depth += 1
        elif w == "end":
            depth -= 1
            if depth == 0 and start is not None:
                fns.append((name, count(clean[start:m.end()])))
                start = None
    fns.sort(key=lambda x: -x[1])
    rem = count(clean) - sum(t for _, t in fns)
    return fns, rem

def tree():
    cart = os.path.join(HERE, "citysim2.p8")
    total = count(lua_of(cart))
    print("citysim2.p8  [%d / 8192  %.0f%%]" % (total, total * 100.0 / 8192))
    for label, code in includes_of(cart):
        print("- %s  [%d]" % (label, count(code)))
        fns, rem = funcs_of(code)
        for nm, t in fns:
            print("- - %s  [%d]" % (nm, t))
        if rem > 0:
            print("- - (top-level)  [%d]" % rem)

if len(sys.argv) > 1 and sys.argv[1] == "tree":
    tree()
elif len(sys.argv) > 1:
    f = os.path.join(HERE, sys.argv[1])
    print("approx tokens:", count(open(f, encoding="utf-8").read()), "in", sys.argv[1])
else:
    n = count(lua_of(os.path.join(HERE, "citysim2.p8")))
    print("approx tokens:", n, "/ 8192 (%.0f%%)" % (n * 100.0 / 8192))
