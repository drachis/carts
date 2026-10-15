"""notes_lines.py - keep the notes in notes/ on the code they are about.

usage: py notes_lines.py            check, and say where any note's code went
       py notes_lines.py --fix      move each heading's line to its code
       py notes_lines.py --anchor   give each heading without one a quote of its line

Run it in the project folder. Each module's notes are in notes/<module>.md
(CODE_NOTES.md is the guide and index). A note's heading is

    **module.lua:N** `the start of line N, stripped`

The quote is what the note is about; N only says where it was last seen.
A heading is stale when line N no longer starts with the quote (or, with no
quote, when N is blank or past the module's end), or when it is in another
module's notes file. --fix looks for the quote in the module and moves N to
it: the match nearest the old line, if the quote appears more than once. A
quote found nowhere means the code itself changed: read the note and the
code, and rewrite the note and its quote. run_tests.py runs the check
before any cart, and fails if a note is stale.
"""
import glob
import os
import re
import sys

HEADING = re.compile(r"^\*\*([\w.]+\.lua):(\d+)\*\*(?: `(.*)`)?\s*$")
QUOTE_LENGTH = 60


def quote_of(code_line):
    return code_line.strip()[:QUOTE_LENGTH]


def note_files(where):
    return sorted(glob.glob(os.path.join(where, "notes", "*.md")))


def read_lines(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read().split("\n")


def module_lines(where, modules, module):
    if module not in modules:
        source = os.path.join(where, module)
        modules[module] = read_lines(source) if os.path.exists(source) else None
    return modules[module]


def where_now(lines, quote, old):
    """The line (from 1) nearest `old` that starts with `quote`, or None."""
    found = [number for number, line in enumerate(lines, 1) if line.strip().startswith(quote)]
    return min(found, key=lambda number: abs(number - old)) if found else None


def headings(path):
    """(index in the file, module, line, quote or None) for each heading."""
    for index, line in enumerate(read_lines(path)):
        heading = HEADING.match(line)
        if heading:
            yield index, heading.group(1), int(heading.group(2)), heading.group(3)


def stale_notes(where="."):
    """Stale headings, as "notes/file: module:N (why)"; [] if all is well."""
    found, modules = [], {}
    for path in note_files(where):
        name = "notes/" + os.path.basename(path)
        for _, module, number, quote in headings(path):
            where_from = "%s: %s:%d" % (name, module, number)
            if os.path.basename(path) != module[:-len(".lua")] + ".md":
                found.append(where_from + " (belongs in notes/%s.md)" % module[:-len(".lua")])
                continue
            lines = module_lines(where, modules, module)
            if lines is None:
                found.append(where_from + " (no such module)")
                continue
            here = lines[number - 1] if 1 <= number <= len(lines) else None
            if quote is None:
                if here is None:
                    found.append(where_from + " (past the end, %d lines)" % len(lines))
                elif not here.strip():
                    found.append(where_from + " (a blank line)")
            elif here is None or not here.strip().startswith(quote):
                now = where_now(lines, quote, number)
                found.append(where_from + (" (now at %d: py notes_lines.py --fix)" % now if now
                                           else " (its code changed: rewrite the note)"))
    return found


def rewrite(where, change):
    """Apply `change(lines, number, quote)` -> (number, quote) or None to every heading."""
    modules, changed = {}, 0
    for path in note_files(where):
        notes = read_lines(path)
        for index, module, number, quote in headings(path):
            lines = module_lines(where, modules, module)
            new = lines and change(lines, number, quote)
            if new:
                notes[index] = "**%s:%d** `%s`" % (module, new[0], new[1])
                changed += 1
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write("\n".join(notes))
    return changed


def anchored(lines, number, quote):
    if quote is None and 1 <= number <= len(lines) and lines[number - 1].strip():
        return number, quote_of(lines[number - 1])
    return None


def fixed(lines, number, quote):
    if quote is None:
        return None
    if 1 <= number <= len(lines) and lines[number - 1].strip().startswith(quote):
        return None
    now = where_now(lines, quote, number)
    return (now, quote) if now else None


def main(argv):
    if "--anchor" in argv:
        print("quoted %d headings" % rewrite(".", anchored))
    if "--fix" in argv:
        print("moved %d headings" % rewrite(".", fixed))
    stale = stale_notes(".")
    for note in stale:
        print("stale: " + note)
    print("%d stale notes in %d files" % (len(stale), len(note_files("."))))
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
