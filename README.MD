# OpenCode Android 5-Star Setup

A multi-agent OpenCode configuration for building Android apps to a 5-star
quality bar: research → code → design → blind review → test, with no step
skippable and no agent grading its own work.

Point `@android-lead` at a feature request and it orchestrates the rest —
research current library versions, implement in Kotlin/Compose, review
against a Material 3 Expressive design standard, get graded blind by a
separate critic agent, then run real tests on a headless emulator with
logcat/screenshot evidence. See "How it works" below for the full pipeline.

## Quick install

From your Android project root (wherever `build.gradle.kts` lives):

```bash
git clone https://github.com/tonysheesh/Opencode-android-5star-.git /tmp/ocsetup
bash /tmp/ocsetup/install.sh
rm -rf /tmp/ocsetup
```

This copies `AGENTS.md`, `quality-bar.md`, `testing.md`,
`design-standard.md`, `opencode.json`, and `.opencode/agent/*.md` into your
project. It's safe to re-run — it just overwrites.

**If you don't have an Android project yet**, run the same commands inside
an empty folder first; the config will be waiting when you create the
Gradle project around it.

### If `install.sh` won't execute (FUSE / `/sdcard` permission issues)

On some Android terminal setups (proot, Termux with `/sdcard` involved),
`chmod +x` doesn't stick on FUSE-mounted storage. Work around it by running
the script explicitly through bash instead of relying on the execute bit:

```bash
bash /tmp/ocsetup/install.sh
```

If that still fails with `Permission denied` or `No such file or
directory` errors, clone into your app's native filesystem (e.g. proot's
`~`, or Termux's `~`) rather than `/sdcard`, then run the commands above
from there. `/sdcard` is a FUSE mount and is unreliable for scripts and
execute permissions in general — don't develop directly on it.

## Verify the install

```bash
find . -maxdepth 2 -iname "AGENTS.md" -o -iname "opencode.json" -o -path "./.opencode/agent/*.md"
```

You should see 11 files: 5 in the project root, 6 under `.opencode/agent/`.

## Using it

Start OpenCode from your project root, then talk to the lead agent by
name so it orchestrates the pipeline rather than working ad hoc:

```
@android-lead add a settings screen with a dark mode toggle
```

The lead will:
1. Delegate research to `@android-researcher` for any library/API version
   it isn't certain is current (Android tooling moves fast — don't trust
   memorized versions).
2. Delegate implementation to `@android-coder`.
3. If the task touches UI, delegate to `@android-designer`, which
   implements against `design-standard.md` and captures a reproducible
   screenshot — but does **not** grade its own work.
4. Send that screenshot **blind** (no code, no reasoning) to
   `@android-critic`, which scores it 1–5 on six axes. Anything below 3
   goes back to the designer to fix, repeat until it passes.
5. Delegate testing to `@android-tester`, which runs the real test suite
   on a headless emulator and reports pass/fail with actual logcat/
   screenshot evidence — never claims "tested" without having run it.
6. Only reports the task complete once `quality-bar.md`'s Must-list,
   the critic's scores, and the tester's evidence all check out.

## How it works — file map

| File | Purpose |
|---|---|
| `opencode.json` | Registers all 6 agents and wires `instructions` so every agent reads the 4 standard docs below automatically. |
| `AGENTS.md` | The workflow every agent follows: research → plan → implement → test → self-review → report. Also states the blind-review principle. |
| `quality-bar.md` | The 5-star checklist. "Must" items block task completion (crashes, permissions, accessibility, rotation handling, etc.) |
| `design-standard.md` | Material 3 Expressive visual/UX standard — theming, adaptive layout, motion, the 6-axis scoring rubric used by the critic. |
| `testing.md` | Exact commands: unit tests, lint, headless emulator setup (Gradle Managed Device + manual AVD fallback), adb smoke test, reproducible screenshot capture. |
| `.opencode/agent/android-lead.md` | Primary orchestrator (`mode: primary`). Routes work through the other 5 agents in order. |
| `.opencode/agent/android-researcher.md` | Read-only. Searches for current library/API versions before code is written. |
| `.opencode/agent/android-coder.md` | Implements features in Kotlin/Compose. Writes tests alongside code. |
| `.opencode/agent/android-designer.md` | Implements UI/UX polish against `design-standard.md`. Captures screenshots. Does not self-grade. |
| `.opencode/agent/android-critic.md` | Blind grader — sees only a screenshot + one-line description, never the designer's reasoning. Scores 1–5 per axis. |
| `.opencode/agent/android-tester.md` | Runs the real test suite and reports evidence, not assumptions. |

## Design principles baked into this setup

- **No agent grades its own work.** The designer implements; the critic
  grades, blind, with zero access to the designer's rationale. This
  exists because self-grading (or grading-with-full-context) tends to
  rubber-stamp — an independent, context-stripped review catches more.
- **"Tested" means actually executed this session.** Agents are
  instructed to never report a pass without having run the command and
  inspected real output — no assuming from a similar past run.
- **Screenshots must be reproducible.** Every screenshot used as evidence
  comes from a freshly-cleared app state (`pm clear` + relaunch), not a
  warm running instance — otherwise animation/cache state leaks between
  shots and undermines before/after comparisons.
- **Research before code, every time.** Android/Kotlin/Compose/Gradle
  move fast enough that a model's training data is a poor substitute for
  a live search on version numbers and current API stability.

## Updating this setup

Edit the relevant `.md`/`.json` file in this repo, commit, then re-run
the Quick Install steps in any project using it — `install.sh` overwrites
existing copies. There's no versioning/pinning here by design; keep it
simple and just re-pull when you want the latest.
