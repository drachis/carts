"""levels.py - designs crestbeat's stages and writes levels.lua.

usage: py levels.py

A stage is designed as its *plan*: the intended route of targets, a window
of beats for each, in which the shock rifle (the starting gun, a shot every
beat) is in the target's street. From the plan the generator works out when
each enemy must be sent so it is on the hill for its window, and writes two
strings a character a beat: the chart the game plays, and the plan, the
street the gun should be in on that beat ("1" left, "2" centre, "3" right,
"." anything). Down arrow shows the plan in the game.

Swarm tokens, each taking a window from the current beat:
    aL  alien in street L, 2 beats (half a bar)
    bL  brute, 4 beats      hL  hulk, 6 beats
    wL  weaver starting in street L, 2 beats; its plan follows its sweep
    .   a rest window, 2 beats
and distractions, which take no window:
    gL  a golden alien entering from side L (1 left, 3 right); it is off the
        plan, so getting it means fitting its 8 shots into the plan's slack
    cL  a civilian fleeing down street L; the plan stays out of street L
        while it is on the hill
Titan tokens, 2 beats each: qL opens the hot spot over street L; aL as
above; ".". Any window may carry "/s": the titan spits on the window's
second beat down the street the plan is in, and it lands two beats later,
when the plan has moved on: the user's "get out of this lane by beat x".
The warning counts the beats down. "/sL" names the street instead.

`slack` is how many beats an enemy's last planned shot comes before it
would reach the bottom: the margin for falling behind the plan. It shrinks
level by level.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
KEYS = {"a": "123", "b": "456", "h": "789", "w": "rty", "g": "zxc", "c": "jkl"}
SHOTS = {"a": 2, "b": 4, "h": 6, "w": 2}
WALK = 8
GOLD_TRACK, GOLD_DEPTH, GOLD_SHOTS = 4, 0.45, 8
CIVILIAN_WALK = 4
IDLE = 4
SPIT, OPEN = "asd", "qwe"

STAGES = [
    dict(name="hill", slack=5, tickets=1, margin=6, title="they're over the hill!",
         seq="a1 a2 a3 a2 g1 . . . . a3 a1 b1"),
    dict(name="climb", fly=1, beats=8, title="up the hill!"),
    dict(name="titan", bars=4, colour=3, tickets=2, margin=8, title="titan! shoot its hot spots",
         seq="q1 q2 q3 q2/s q1 q3 q2 q1 q3"),
    dict(name="streets", slack=3, heal=1, tickets=2, margin=4, title="run for it!",
         seq="a1 a3 c2 a1 a3 a2 c3 b1 a2 g3 . a1 a1 a3 a3"),
    dict(name="climb", fly=1, beats=8, title="to the crest!"),
    dict(name="behemoth", bars=4, colour=13, tickets=3, margin=2, title="a behemoth!",
         seq="q2 q1 a3 q3/s q1 a2 q2/s q3 a1 q1/s q2 q3"),
    dict(name="crest", slack=1, tickets=3, margin=2, title="they keep coming!",
         seq="a2 a1 a3 h2 c3 a1 w1 a2 g1 a3 a3"),
    dict(name="climb", fly=1, beats=8, title="the hive queen awaits"),
    dict(name="queen", bars=6, colour=14, crown=1, heal=1, tickets=4, slack=2, margin=1, title="the hive queen!",
         seq="q1 q2 a3 q3/s q2 a1 q1 q3/s w2 q2/s q1 a3 q3/s q2 a1 q1/s q3"),
]
for giants in (False, True):
    FIGHTS = [spec for spec in STAGES if "margin" in spec and ("bars" in spec) == giants]
    assert all(a["margin"] >= b["margin"] for a, b in zip(FIGHTS, FIGHTS[1:])), \
        "the survival margin must shrink (or hold) from %s to %s" % (
            " ".join(s["name"] for s in FIGHTS), "the end")


def weave_lane(turn):
    return (-1, 0, 1, 0)[int(turn // 1) % 4]


def weaver_street(first, sent, beat):
    """The street a weaver counts as in on a whole beat, as aliens.lua works it out."""
    step = beat - sent
    turn = step / 2 + first + 1
    here, there = weave_lane(turn), weave_lane(turn + 1)
    pos = here + (there - here) * (turn % 1)
    return int((pos + 0.5) // 1)


def gold_in_the_way(stage, side, sent):
    """The beats on which a golden alien sent at `sent` would stand in front
    of the plan's target in the plan's street: the plan must steer round it."""
    clashes = []
    for beat in range(sent, sent + 14):
        street = gold_street(side, sent, beat)
        if street is not None and stage.plan.get(beat) == street and beat in stage.walker:
            if (beat - stage.walker[beat] - 1) / WALK <= GOLD_DEPTH + 0.1:
                clashes.append(beat)
    return clashes


def gold_street(side, sent, beat):
    """The street a golden alien sent at `sent` counts as in on a whole beat,
    or None once it is off the streets."""
    start, way = (-2, 1) if side < 0 else (2, -1)
    steps = (beat - sent) / GOLD_TRACK
    pos = start + way * (steps // 1 + min(1, steps % 1 * 3))
    if abs(pos) > 1.6:
        return None
    street = int((pos + 0.5) // 1)
    return street if -1 <= street <= 1 else None


def golden_route(stage, side, sent, depth):
    """The plan that takes the golden alien: from its arrival, each beat it is
    in front in its street the gun is on it, until its 8 shots are in; the
    plan's other shots wait their turn, a beat later for each gold shot not
    taken in a rest. A target pushed past the bottom of the hill costs a
    heart. Returns the route, the hearts it costs, and whether it gets the
    gold. Knockback is left out, so the cost is an upper bound."""
    route = {b: l for b, l in stage.plan.items() if b < sent}
    queue = [(b, i) for i, t in enumerate(stage.targets) for b in t["beats"] if b >= sent]
    queue.sort()
    shots_left = {i: sum(1 for _, j in queue if j == i) for i in range(len(stage.targets))}
    leaked, gold_shots, beat = set(), GOLD_SHOTS, sent
    while queue or (gold_shots and beat < sent + 4 * GOLD_TRACK):
        for i, target in enumerate(stage.targets):
            if shots_left.get(i) and i not in leaked and beat > target["sent"] + WALK:
                leaked.add(i)
        queue = [(b, i) for b, i in queue if i not in leaked]
        street = gold_street(side, sent, beat)
        shields = [i for i, t in enumerate(stage.targets)
                   if t["kind"] != "w" and t["lane"] == street and shots_left.get(i) and i not in leaked
                   and depth < (beat - t["sent"] - 1) / WALK < 1]
        fleeing = any(lane == street and depth < (beat - when - 1) / CIVILIAN_WALK < 1
                      for lane, when in stage.civilians)
        if fleeing:
            shields = []
        if gold_shots and street is not None and not shields and not fleeing:
            route[beat] = street
            gold_shots -= 1
        elif gold_shots and shields:
            i = max(shields, key=lambda j: beat - stage.targets[j]["sent"])
            queue.remove(next(entry for entry in queue if entry[1] == i))
            route[beat] = street
            shots_left[i] -= 1
        elif queue and queue[0][0] <= beat:
            _, i = queue.pop(0)
            target = stage.targets[i]
            route[beat] = weaver_street(target["lane"], target["sent"], beat) if target["kind"] == "w" else target["lane"]
            shots_left[i] -= 1
        beat += 1
        if beat > sent + 80:
            break
    return route, len(leaked), gold_shots == 0


def bell_route(stage, spits):
    """The route that rings a giant's bell: the first time each hot spot
    opens it takes one shot and moves on to the next window's street a beat
    early; a spot already lit is not shot again until the bell has rung (a
    second shot would put the lamps out). After the bell, the plan."""
    route, lit = dict(stage.plan), set()
    for start, lane in stage.openings:
        if len(lit) == 3:
            break
        ahead = stage.plan.get(start + 2)
        if lane in lit:
            route[start] = route[start + 1] = ahead
        else:
            lit.add(lane)
            route[start + 1] = ahead
    assert len(lit) == 3, "the bell route never reaches all three hot spots"
    for token, lane, beat in spits:
        assert route.get(beat + 2) != lane, "the bell route stands in %s's spit" % token
    return route


class Stage:
    def __init__(self):
        self.chart, self.plan, self.walker, self.gold = {}, {}, {}, ""
        self.targets, self.golden, self.gold_cost, self.civilians, self.openings = [], {}, "", [], []

    def put(self, beat, char, earliest=0, latest=None):
        """Puts a character on the chart at beat, or the nearest free beat
        between earliest and latest (beat itself if latest is not given)."""
        latest = beat if latest is None else latest
        for distance in range(0, 12):
            for at in (beat + distance, beat - distance):
                if max(earliest, 0) <= at <= latest and at not in self.chart:
                    self.chart[at] = char
                    return at
        raise ValueError("no free beat for %s between %d and %d" % (char, earliest, latest))

    def strings(self, end=0):
        length = max(list(self.chart) + list(self.plan) + list(self.golden) + [end - 1]) + 1
        chart = "".join(self.chart.get(b, ".") for b in range(length))

        def street(route, b):
            return str(route[b] + 2) if route.get(b) is not None else "."
        plan = "".join(street(self.plan, b) for b in range(length))
        golden = "".join(street(self.golden, b) for b in range(length)) if self.golden else ""
        return chart, plan, self.gold, golden, self.gold_cost


def build(spec):
    stage = Stage()
    if spec.get("fly"):
        stage.chart[spec["beats"] - 1] = "."
        return stage.strings()
    slack = spec.get("slack", 3)
    titan = "bars" in spec
    window = 2 if titan else max(2, WALK - 1 - slack)
    sent_in = {}
    civilians, spits, golds = [], [], []
    for token in spec["seq"].split():
        token, _, spit = token.partition("/")
        kind, lane = token[0], int(token[1:] or 0) - 2
        start = window
        if kind == ".":
            window += 2
        elif kind == "q":
            stage.chart[start] = OPEN[lane + 1]
            stage.openings.append((start, lane))
            for b in range(start, start + 2):
                stage.plan[b] = lane
            window += 2
        elif kind in SHOTS:
            shots = SHOTS[kind]
            latest = start - 1
            earliest = start + shots - 1 - WALK
            sent = stage.put(min(latest, earliest + slack), KEYS[kind][lane + 1], earliest, latest)
            assert sent > sent_in.get(lane, -99) or kind == "w", "%s sent out of order" % token
            sent_in[lane] = sent
            stage.targets.append(dict(kind=kind, lane=lane, sent=sent, beats=list(range(start, start + shots))))
            for b in range(start, start + shots):
                stage.plan[b] = weaver_street(lane, sent, b) if kind == "w" else lane
                stage.walker[b] = sent
            window += shots
        elif kind == "g":
            golds.append((lane, start))
        elif kind == "c":
            sent = stage.put(start - 1, KEYS["c"][lane + 1], start - 3)
            civilians.append((lane, sent))
            stage.civilians.append((lane, sent))
        if spit:
            lane = int(spit[1:]) - 2 if spit[1:] else None
            spits.append((token, lane, stage.put(start + 1, "?", start)))
    for token, lane, beat in spits:
        lands = beat + 2
        if lane is None:
            lane = stage.plan.get(beat)
        assert lane is not None and stage.plan.get(lands) not in (None, lane), \
            "%s: the plan is still in street %s when the spit lands" % (token, lane)
        stage.chart[beat] = SPIT[lane + 1]
    for side, wanted in golds:
        tries = sorted((b for b in range(wanted - 6, wanted + 7) if b >= 0 and b not in stage.chart),
                       key=lambda b: (len(gold_in_the_way(stage, side, b)), abs(b - wanted)))
        best = tries[0]
        clashes = gold_in_the_way(stage, side, best)
        assert not clashes, "%s: the plan shoots behind the golden alien at beats %s; steer it round" % (
            spec["name"], clashes)
        stage.chart[best] = KEYS["g"][side + 1]
        stage.gold = GOLD_DEPTH
        stage.golden, stage.gold_cost, got = golden_route(stage, side, best, GOLD_DEPTH)
        assert got, "%s: the golden route cannot get the golden alien" % spec["name"]
        for b in stage.plan:
            stage.golden.setdefault(b, None)
    for lane, sent in civilians:
        for b in range(sent + 1, sent + 5):
            assert stage.plan.get(b) != lane, "civilian in street %d crosses the plan at beat %d" % (lane + 2, b)
    if titan:
        stage.golden, stage.gold_cost = bell_route(stage, spits), 0
        run, longest, last = 0, 0, None
        for b in list(range(window)) * 2:
            here = stage.plan.get(b, last)
            run = run + 1 if here == last else 1
            last, longest = here, max(longest, run)
        assert longest < IDLE + 2, "%s: the plan stays in one street %d beats; the idle spit (after %d) would hit it" % (
            spec["name"], longest, IDLE)
        per_opening = 2 * 2
        needed = -(-spec["bars"] * 8 / 3 // per_opening)
        for lane in (-1, 0, 1):
            openings = sum(1 for c in stage.chart.values() if c == OPEN[lane + 1])
            assert openings >= needed, "%s opens street %d %d times, needs %d" % (spec["name"], lane + 2, openings, needed)
    return stage.strings(window)


def lua_rows():
    lines = ["name,chart,plan,golden,gold_cost,bars,colour,crown,fly,heal,tickets,margin,title"]
    costs = []
    for spec in STAGES:
        chart, plan, gold, golden, cost = build(spec)
        lines.append(",".join(str(v) for v in (
            spec["name"], chart, plan, golden, cost, spec.get("bars", ""), spec.get("colour", ""),
            spec.get("crown", ""), spec.get("fly", ""), spec.get("heal", ""), spec.get("tickets", ""),
            spec.get("margin", ""), spec["title"])))
        if gold:
            costs.append(cost)
            print("%-9s golden alien crosses at depth %s; the golden route costs %d hearts" % (spec["name"], gold, cost))
        print("%-9s %3d beats  %s" % (spec["name"], len(chart), chart))
        print("%-9s            %s" % ("", plan))
        if gold:
            print("%-9s            %s" % ("golden", golden))
    assert costs[0] == 0 and costs == sorted(costs) and costs[-1] > 0, \
        "the golden alien should be free early and cost hearts later: %s" % costs
    return lines


def main():
    rows = lua_rows()
    text = "stages=parse_table[[\n" + "\n".join(rows) + "\n]]\n"
    with open(os.path.join(HERE, "levels.lua"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)
    print("wrote levels.lua")


if __name__ == "__main__":
    main()
