# count_tokens.py - approximate pico-8 token count for citysim.p8 (+includes)
# rules: words/numbers/strings/operators = 1 token; bracket pairs and strings
# count as 1; commas, periods, semicolons, colons, 'local', 'end', comments free.
import re, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))

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

code = lua_of(os.path.join(HERE, "citysim.p8"))
code = re.sub(r"--\[\[.*?\]\]", " ", code, flags=re.S)
code = re.sub(r"--[^\n]*", " ", code)

tok_re = re.compile(
    r'"[^"]*"|\'[^\']*\''            # strings
    r"|[a-zA-Z_][a-zA-Z0-9_]*"       # words
    r"|\d+\.?\d*|\.\d+|0x[0-9a-fA-F.]+"  # numbers
    r"|==|~=|<=|>=|\.\.|\+=|-=|\*=|/=|%=|\^=|\\|//"
    r"|[+\-*/%^#<>=(){}\[\]@$?]"     # single ops + openers
)
FREE = {"local", "end"}
n = 0
prev = ""
for m in tok_re.finditer(code):
    t = m.group(0)
    if t in FREE or t in ")]}":
        prev = t
        continue
    # unary minus folded into a number literal
    if t == "-" and (prev == "" or prev in "+-*/%^<>=(,{[" or prev in ("==","~=","<=",">=","..","and","or","not","return",",")):
        prev = t
        continue
    n += 1
    prev = t

print("approx tokens:", n, "/ 8192 (%.0f%%)" % (n * 100.0 / 8192))
