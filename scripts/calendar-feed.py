#!/usr/bin/env python3
"""Print events from the calendars in ~/.config/calendars.yaml as JSON.

Usage: calendar-feed.py [--offline] [--window | START_DATE [DAYS]] (default: today, 1 day;
--window: the whole range the Calendar dropdown can page through).

A calendar is read from `url:` (an iCal feed) or `gcalcli:` (a Google calendar by name, through
the Calendar API, for accounts whose admin disables secret iCal addresses). Every source is
cached, so an unreachable one falls back to the last copy and --offline reads only the cache.
Cancelled events and ones the calendar's owner declined are left out.
"""

import argparse
import csv
import http.client
import json
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
from datetime import date, datetime, time, timedelta
from pathlib import Path

import icalendar
import recurring_ical_events
import yaml

CONFIG = Path.home() / ".config" / "calendars.yaml"
CACHE = Path.home() / ".cache" / "calendar"

DEFAULT_STYLES = {
    "work": {"color": "#83a598", "bar": True},
    "personal": {"color": "#d3869b", "bar": False},
    "events": {"color": "#d8a657", "bar": False},
    "sports": {"color": "#e78a4e", "bar": False},
    "family": {"color": "#a9b665", "bar": False},
    "other": {"color": "#928374", "bar": False},
}

CALL_LINK = re.compile(
    # Stops at a backslash too: gcalcli's TSV writes newlines as a literal \n.
    r"https://(?:meet\.google\.com|[\w.-]*zoom\.us|teams\.microsoft\.com|teams\.live\.com)/[^\s<>\"')\\]+"
)

# The Calendar dropdown pages within this window around today; gcalcli is fetched over all of it.
WINDOW = (timedelta(days=-190), timedelta(days=380))


def warn(name: str, message: str) -> None:
    """Report a calendar that could not be read, without failing the others."""
    print(f"calendar-feed: {name}: {message}", file=sys.stderr)


def cache_path(name: str, suffix: str) -> Path:
    """Return the cache file for a calendar."""
    return CACHE / f"{re.sub(r'[^A-Za-z0-9_-]', '_', name)}.{suffix}"


def read_cache(path: Path) -> str:
    """Return a cached source, or an empty string when there is none."""
    return path.read_text() if path.exists() else ""


def epoch_ms(value) -> int:
    """Return a date or datetime as local epoch milliseconds; dates start at local midnight."""
    if not isinstance(value, datetime):
        value = datetime.combine(value, time())
    if value.tzinfo is None:
        value = value.astimezone()
    return int(value.timestamp() * 1000)


def call_link(*texts: str) -> str:
    """Return the first video-call link found in the texts, or an empty string."""
    for text in texts:
        match = CALL_LINK.search(text)
        if match:
            return match.group(0)
    return ""


def fetch_ical(name: str, url: str, offline: bool) -> str:
    """Return the iCal feed, refreshing its cache; offline or unreachable, the cached copy."""
    cached = cache_path(name, "ics")
    if offline:
        return read_cache(cached)
    # webcal:// is a subscribe hint for calendar apps; the feed itself is served over https.
    url = re.sub(r"^webcal://", "https://", url)
    try:
        # Some feed hosts refuse Python's default user agent.
        request = urllib.request.Request(url, headers={"User-Agent": "calendar-feed/1"})
        with urllib.request.urlopen(request, timeout=15) as response:
            data = response.read().decode("utf-8", "replace")
    except (OSError, http.client.HTTPException) as error:
        warn(name, str(error))
        return read_cache(cached)
    # A share or embed link, or a revoked secret, answers with Google's sign-in page.
    if not data.lstrip().startswith("BEGIN:VCALENDAR"):
        warn(name, "not an iCal feed; use the secret iCal address")
        return read_cache(cached)
    cached.write_text(data)
    return data


def owner(url: str) -> str:
    """Return the calendar id in a Google secret address (the owner's email for a primary one)."""
    match = re.search(r"/ical/([^/]+)/", url)
    return urllib.parse.unquote(match.group(1)).lower() if match else ""


def declined(event, me: str) -> bool:
    """Return whether the calendar's owner declined the event."""
    attendees = event.get("ATTENDEE", [])
    if not isinstance(attendees, list):
        attendees = [attendees]
    return any(
        str(a).lower().removeprefix("mailto:") == me
        and a.params.get("PARTSTAT") == "DECLINED"
        for a in attendees
    )


def ical_events(calendar: dict, start: date, end: date, offline: bool) -> list[dict]:
    """Return the feed's events overlapping [start, end)."""
    data = fetch_ical(calendar["name"], calendar["url"], offline)
    if not data:
        return []
    me = owner(calendar["url"])
    events = []
    feed = recurring_ical_events.of(icalendar.Calendar.from_ical(data))
    for event in feed.between(start - timedelta(days=1), end + timedelta(days=1)):
        if str(event.get("STATUS", "")).upper() == "CANCELLED" or declined(event, me):
            continue
        begin = event["DTSTART"].dt
        all_day = not isinstance(begin, datetime)
        # RFC 5545: a bare all-day event lasts the day; give a bare timed one an hour.
        default_length = timedelta(days=1) if all_day else timedelta(hours=1)
        finish = event["DTEND"].dt if "DTEND" in event else begin + default_length
        fields = ("X-GOOGLE-CONFERENCE", "LOCATION", "DESCRIPTION", "URL")
        call = call_link(*(str(event.get(f, "")) for f in fields))
        events.append(
            {
                "title": str(event.get("SUMMARY", "Busy")),
                "start": epoch_ms(begin),
                "end": epoch_ms(finish),
                "allDay": all_day,
                "link": call or str(event.get("URL", "")),
                "call": bool(call),
            }
        )
    return events


def fetch_gcalcli(name: str, calendar: str, offline: bool) -> str:
    """Return gcalcli's TSV agenda for the window, refreshing its cache."""
    cached = cache_path(name, "tsv")
    if offline:
        return read_cache(cached)
    if not shutil.which("gcalcli"):
        warn(name, "gcalcli is not installed")
        return read_cache(cached)
    today = date.today()
    first, last = (today + offset for offset in WINDOW)
    details = ("time", "title", "conference", "url", "location", "description")
    command = ["gcalcli", "--nocolor", "agenda", "--calendar", calendar, "--tsv"]
    command += ["--nodeclined", *(f"--details={d}" for d in details)]
    command += [first.isoformat(), last.isoformat()]
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, timeout=30, check=True
        )
    except (subprocess.SubprocessError, OSError) as error:
        stderr = getattr(error, "stderr", "") or ""
        warn(name, stderr.strip().splitlines()[-1] if stderr.strip() else str(error))
        return read_cache(cached)
    cached.write_text(result.stdout)
    return result.stdout


def gcalcli_events(calendar: dict, start: date, end: date, offline: bool) -> list[dict]:
    """Return the Google calendar's events overlapping [start, end)."""
    data = fetch_gcalcli(calendar["name"], calendar["gcalcli"], offline)
    events = []
    for row in csv.DictReader(
        data.splitlines(), delimiter="\t", quoting=csv.QUOTE_NONE
    ):
        all_day = not row["start_time"]
        begin = epoch_ms(
            datetime.fromisoformat(
                f"{row['start_date']} {row['start_time'] or '00:00'}"
            )
        )
        finish = epoch_ms(
            datetime.fromisoformat(f"{row['end_date']} {row['end_time'] or '00:00'}")
        )
        texts = (
            row.get(k, "")
            for k in ("conference_uri", "hangout_link", "location", "description")
        )
        events.append(
            {
                "title": row["title"] or "Busy",
                "start": begin,
                "end": finish,
                "allDay": all_day,
                "link": (call := call_link(*texts)),
                "call": bool(call),
            }
        )
    return events


def main() -> None:
    """Print the range's events across every configured calendar, all-day first, then by start."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--window", action="store_true")
    parser.add_argument(
        "start", nargs="?", type=date.fromisoformat, default=date.today()
    )
    parser.add_argument("days", nargs="?", type=int, default=1)
    args = parser.parse_args()

    config = yaml.safe_load(CONFIG.read_text()) if CONFIG.exists() else {}
    styles = DEFAULT_STYLES | (config.get("styles") or {})
    CACHE.mkdir(parents=True, exist_ok=True)
    # Event titles are as private as the feeds they came from.
    CACHE.chmod(0o700)

    if args.window:
        args.start, end = (date.today() + offset for offset in WINDOW)
    else:
        end = args.start + timedelta(days=args.days)
    events = []
    for calendar in config.get("calendars") or []:
        read = gcalcli_events if "gcalcli" in calendar else ical_events
        try:
            found = read(calendar, args.start, end, args.offline)
        except (ValueError, KeyError) as error:
            warn(calendar["name"], f"unreadable ({error.__class__.__name__}: {error})")
            continue
        # Sources compare ranges in UTC; keep only what overlaps the range in local time.
        lo, hi = epoch_ms(args.start), epoch_ms(end)
        found = [e for e in found if e["start"] < hi and e["end"] > lo]
        style = styles.get(calendar.get("style", "other"), DEFAULT_STYLES["other"])
        for event in found:
            event |= {
                "calendar": calendar["name"],
                "color": style.get("color", DEFAULT_STYLES["other"]["color"]),
                "bar": bool(style.get("bar", False)),
            }
        events += found

    events.sort(key=lambda e: (not e["allDay"], e["start"]))
    json.dump(events, sys.stdout)


if __name__ == "__main__":
    main()
