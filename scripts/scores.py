#!/usr/bin/env python3
"""Waybar sports module — today's matches for a fixed set of teams, shown inline
(upcoming → kickoff time, live → score + status with a red dot, finished → dimmed
final). Live status is ESPN's shortDetail, so it reads HT / ET / 90'+3' / FT-Pens
rather than freezing on a minute. Pipe-divided; reports class "live" when any match
is in progress (waybar
draws the red outline). Empty output hides the whole module.

Polling is self-gated so we don't hammer ESPN (waybar's interval is fixed):
  • a small fixture cache (~/.cache/waybar-scores.json) holds today's matches
  • the network is hit ONLY while a match is in its window (kickoff ≤ now and not
    finalized) — then every tick (set waybar interval to 10s) for live score/clock
  • otherwise fixtures refresh at most every IDLE_REFRESH seconds (no live hammering)
  • any fetch error keeps the last good data (graceful under rate limits / outages)

  scores.py          print waybar JSON (default; polled on an interval)
  scores.py mock     print hardcoded sample matches to preview the look

Source: ESPN public API (no key). SofaScore is wider but Cloudflare-blocks scripts.
"""
import json
import os
import sys
import time
import urllib.request
from datetime import datetime

# (ESPN sport/league path, team-name substring — or None for "all matches")
WATCH = [
    ("soccer/mex.1",      "UNAM"),      # Liga MX  — Pumas UNAM
    ("soccer/ita.1",      "Juventus"),  # Serie A  — Juventus
    ("soccer/esp.1",      "Betis"),     # La Liga  — Real Betis
    ("soccer/fifa.world", None),        # FIFA World Cup — every match
]
API = "https://site.api.espn.com/apis/site/v2/sports/{}/scoreboard"
CACHE = os.path.expanduser("~/.cache/waybar-scores.json")
IDLE_REFRESH = 900          # seconds between fixture refreshes when nothing is live
SHOW_WINDOW = 4 * 3600      # how long a match stays visible after kickoff — covers
                            # 90' + ET + pens, so a late game survives local midnight
RED, DIM, SEP = "#f38ba8", "#6c7086", "#45475a"
DOT = "●"


def fetch(league):
    """Events list on success, None on any error (so callers can keep the cache)."""
    try:
        req = urllib.request.Request(API.format(league), headers={"User-Agent": "waybar"})
        with urllib.request.urlopen(req, timeout=6) as r:
            return json.load(r).get("events", [])
    except Exception:
        return None


def parse(ev, league, tf):
    try:
        cs = ev["competitions"][0]["competitors"]
        names = " ".join(c["team"].get("displayName", "") for c in cs)
        if tf and tf.lower() not in names.lower():
            return None
        when = datetime.fromisoformat(ev["date"].replace("Z", "+00:00")).astimezone()
        ts, day = when.timestamp(), when.date().isoformat()
        if not relevant(ts, day):
            return None
        home = next(c for c in cs if c["homeAway"] == "home")
        away = next(c for c in cs if c["homeAway"] == "away")
        ab = lambda c: c["team"].get("abbreviation") or c["team"].get("shortDisplayName", "?")
        return {
            "league": league,
            "ts": ts,
            "day": day,
            "hhmm": when.strftime("%H:%M"),
            "state": ev["status"]["type"]["state"],            # pre | in | post
            "clock": (ev["status"]["type"].get("shortDetail")  # 67' · HT · ET · FT · FT-Pens
                      or ev["status"].get("displayClock", "")),
            "home": ab(home), "away": ab(away),
            "hs": home.get("score", "0"), "as": away.get("score", "0"),
            "hp": home.get("shootoutScore"), "ap": away.get("shootoutScore"),
        }
    except Exception:
        return None


def fetch_leagues(wanted):
    """Fetch the given leagues. Returns (matches, ok_set); a league only lands in
    ok_set if its request succeeded, so failures fall back to cached data."""
    matches, ok = [], set()
    for league, tf in WATCH:
        if league not in wanted:
            continue
        evs = fetch(league)
        if evs is None:
            continue
        ok.add(league)
        for ev in evs:
            m = parse(ev, league, tf)
            if m:
                matches.append(m)
    return matches, ok


def load_cache():
    try:
        d = json.load(open(CACHE))
        return d.get("full_ts", 0), d.get("matches", [])
    except Exception:
        return 0, []


def save_cache(full_ts, matches):
    try:
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        json.dump({"full_ts": full_ts, "matches": matches}, open(CACHE, "w"))
    except Exception:
        pass


def _today():
    return datetime.now().astimezone().date().isoformat()


def relevant(ts, day, now=None):
    """Show a match while it's today, or kicked off within SHOW_WINDOW — so a late
    game still on the pitch survives the local-midnight date rollover instead of
    vanishing when the calendar date ticks over."""
    now = now or time.time()
    return day == _today() or ts >= now - SHOW_WINDOW


def visible(matches, now=None):
    now = now or time.time()
    return [m for m in matches if relevant(m["ts"], m["day"], now)]


def current_matches():
    now = time.time()
    full_ts, cached = load_cache()
    cached = visible(cached, now)
    # leagues with a match that should be live now (kicked off, not finalized)
    live = {m["league"] for m in cached if m["ts"] <= now and state_of(m) != "post"}

    if live:                                   # live window → fetch only those leagues
        new, ok = fetch_leagues(live)
        if ok:
            cached = [m for m in cached if m["league"] not in ok] + new
            save_cache(full_ts, cached)
    elif now - full_ts >= IDLE_REFRESH:        # nothing live → occasional fixture refresh
        new, ok = fetch_leagues({lg for lg, _ in WATCH})
        if ok:
            cached = [m for m in cached if m["league"] not in ok] + new
            save_cache(now, cached)
    return visible(cached, now)


def _final(clock):
    """ESPN's shortDetail once play is over — full time, after extra time, penalties."""
    c = (clock or "").upper()
    return c.startswith("FT") or c.startswith("AET") or "FULL" in c or c == "FINAL"


def state_of(m):
    """Effective state. ESPN can lag flipping 'in'→'post' for minutes after the
    whistle; a full-time clock label demotes the match so the red dot doesn't linger."""
    if m["state"] == "in" and _final(m["clock"]):
        return "post"
    return m["state"]


def fmt(m):
    hp, ap = m.get("hp"), m.get("ap")
    pens = f" ({hp}-{ap}p)" if hp is not None and (hp or ap) else ""
    st = state_of(m)
    if st == "in":
        return (f"<span color='{RED}'>{DOT}</span> {m['home']} <b>{m['hs']}-{m['as']}</b> "
                f"{m['away']}{pens} <span color='{RED}'>{m['clock'] or 'LIVE'}</span>")
    if st == "pre":
        return f"{m['home']}-{m['away']} <span color='{DIM}'>{m['hhmm']}</span>"
    return (f"<span color='{DIM}'>{m['home']} {m['hs']}-{m['as']} {m['away']}{pens} "
            f"{m['clock'] or 'FT'}</span>")


def render(matches):
    if not matches:
        return {"text": ""}
    matches.sort(key=lambda m: m["ts"])
    text = f" <span color='{SEP}'>|</span> ".join(fmt(m) for m in matches)
    cls = "live" if any(state_of(m) == "in" for m in matches) else "idle"
    return {"text": text, "class": cls}


MOCK = [
    {"state": "in",  "ts": 1, "hhmm": "13:00", "clock": "67'",     "home": "PUM", "away": "AME", "hs": "2", "as": "1"},
    {"state": "in",  "ts": 2, "hhmm": "13:00", "clock": "HT",      "home": "JUV", "away": "MIL", "hs": "0", "as": "0"},
    {"state": "in",  "ts": 3, "hhmm": "13:00", "clock": "",        "home": "BET", "away": "SEV", "hs": "1", "as": "1"},   # no clock → LIVE
    {"state": "in",  "ts": 4, "hhmm": "13:00", "clock": "FT",      "home": "ARS", "away": "TOT", "hs": "2", "as": "0"},   # ESPN lag → demoted, no dot
    {"state": "pre", "ts": 5, "hhmm": "19:00", "clock": "",        "home": "PSG", "away": "OM",  "hs": "0", "as": "0"},
    {"state": "post","ts": 0, "hhmm": "11:00", "clock": "FT-Pens", "home": "RMA", "away": "BAR", "hs": "1", "as": "1", "hp": 4, "ap": 2},
]

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "mock":
        print(json.dumps(render(MOCK)))
    else:
        print(json.dumps(render(current_matches())))
