#!/usr/bin/env python3
"""Read-only Android soak collector. Run the game first; no save/input changes.

Example: python3 scripts/android_soak.py --serial DEVICE --seconds 600
Results/logs/screens go to ignored build/android-soak/ by default.
"""
import argparse
import json
from pathlib import Path
import re
import statistics
import subprocess
import time

PACKAGE = "com.omer.moorush"
PERF = re.compile(r"^\s*(\d+\.\d+).*MOO_PERF fps=([\d.]+) frame_p95_ms=([\d.]+) draw_cpu_ms=([\d.]+)")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default=str(Path.home() / "Library/Android/sdk/platform-tools/adb"))
    parser.add_argument("--serial", required=True)
    parser.add_argument("--seconds", type=int, default=600)
    parser.add_argument("--resume", action="store_true", help="Continue an interrupted collection for the same running app")
    parser.add_argument("--output", type=Path, default=Path("build/android-soak"))
    args = parser.parse_args()
    if not 30 <= args.seconds <= 1800:
        parser.error("--seconds must be between 30 and 1800")
    args.output.mkdir(parents=True, exist_ok=True)
    prefix = [args.adb, "-s", args.serial]

    reconnects = []
    def adb(*command, binary=False):
        for attempt in range(4):
            try:
                result = subprocess.run(prefix + list(command), capture_output=True, timeout=15, check=True)
                return result.stdout if binary else result.stdout.decode("utf-8", errors="replace")
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
                if attempt == 3: raise
                reconnects.append(dict(epoch=time.time(), command=list(command), attempt=attempt + 1, error=str(exc)))
                time.sleep(attempt + 1)

    pid = adb("shell", "pidof", PACKAGE).strip()
    if not pid or not pid.isdigit():
        raise RuntimeError("Open Moo Rush before collecting; expected one running process")
    previous_path = args.output / "summary.json"
    previous = json.loads(previous_path.read_text()) if args.resume else {}
    if previous and (previous["pid"] != pid or previous["requested_s"] != args.seconds):
        raise RuntimeError("Resume requires the original app process and duration")
    recovered_clock = previous.get("recovered_clock", bool(previous) and "started_epoch" not in previous)
    started = previous.get("started_epoch", previous_path.stat().st_mtime - previous["elapsed_s"] if previous else time.time())
    began = time.monotonic() - (time.time() - started)
    samples = previous.get("samples", [])
    checkpoints = previous.get("checkpoints", [])
    errors = previous.get("errors", [])
    reconnects = previous.get("reconnects", []) + reconnects
    log_path = args.output / "app.log"
    log_lines = log_path.read_text().splitlines() if previous and log_path.exists() else []
    seen = set(log_lines)
    completed = False
    failure = None
    try:
        while True:
            elapsed = time.monotonic() - began
            if adb("shell", "pidof", PACKAGE).strip() != pid:
                raise RuntimeError("Moo Rush process changed during the run")
            lines = adb("logcat", "-d", "-v", "epoch", "--pid=" + pid, "-T", f"{started:.3f}").splitlines()
            for line in lines:
                if line in seen:
                    continue
                seen.add(line)
                log_lines.append(line)
                match = PERF.search(line)
                if match:
                    stamp, fps, p95, draw = map(float, match.groups())
                    if stamp < started or any(abs(row["elapsed_s"] - (stamp - started)) < 0.5 for row in samples): continue
                    samples.append(dict(elapsed_s=round(stamp - started, 2), fps=fps, frame_p95_ms=p95, draw_cpu_ms=draw))
                if any(token in line for token in ["SCRIPT ERROR", "Parse Error", "FATAL EXCEPTION", "Fatal signal"]):
                    if line not in errors: errors.append(line)
            log_path.write_text("\n".join(log_lines) + "\n")
            battery = adb("shell", "dumpsys", "battery")
            def number(key):
                match = re.search(r"^\s*" + key + r":\s*(-?\d+)", battery, re.M)
                return int(match[1]) if match else None
            temp = number("temperature")
            windows = adb("shell", "dumpsys", "window")
            focus = next((line.strip() for line in windows.splitlines() if "mCurrentFocus=" in line), "unavailable")
            checkpoint = dict(elapsed_s=round(elapsed, 1), battery_percent=number("level"), battery_temp_c=temp / 10 if temp is not None else None, game_focused=PACKAGE in focus)
            checkpoints.append(checkpoint)
            if elapsed >= 30 and not samples:
                raise RuntimeError("No gameplay timing windows: unlock the screen and start a slot")
            (args.output / "progress.json").write_text(json.dumps(dict(pid=pid, samples=len(samples), last_fps=samples[-1]["fps"] if samples else None, checkpoint=checkpoint), indent=2))
            print(json.dumps(dict(elapsed_s=checkpoint["elapsed_s"], samples=len(samples), last_fps=samples[-1]["fps"] if samples else None, battery_temp_c=checkpoint["battery_temp_c"], focused=checkpoint["game_focused"])), flush=True)
            if elapsed >= args.seconds:
                completed = True
                break
            time.sleep(min(30, max(0, args.seconds - (time.monotonic() - began))))
    except (Exception, KeyboardInterrupt) as exc:
        failure = str(exc) or type(exc).__name__
    finally:
        def mean_window(rows):
            return {key: round(statistics.mean(row[key] for row in rows), 2) for key in ["fps", "frame_p95_ms", "draw_cpu_ms"]} if rows else None
        valid_gameplay = completed and not recovered_clock and len(samples) >= args.seconds / 5 * 0.85 and all(row["game_focused"] for row in checkpoints)
        summary = dict(started_epoch=started, recovered_clock=recovered_clock, reconnects=reconnects, completed=completed, valid_gameplay=valid_gameplay, requested_s=args.seconds, elapsed_s=round(time.monotonic() - began, 1), pid=pid, sample_count=len(samples), overall=mean_window(samples), first_minute=mean_window([row for row in samples if row["elapsed_s"] <= 60]), last_minute=mean_window([row for row in samples if row["elapsed_s"] >= args.seconds - 60]), errors=errors, failure=failure, checkpoints=checkpoints, samples=samples)
        (args.output / "summary.json").write_text(json.dumps(summary, indent=2))
    if failure or not valid_gameplay or errors:
        raise SystemExit("Gameplay collection incomplete, interrupted or app errors; inspect summary.json")
    print("Collected run; engine frame intervals are not compositor FPS or a thermal diagnosis.")


if __name__ == "__main__":
    main()
