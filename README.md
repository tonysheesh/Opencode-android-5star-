# OpenCode Android 5-Star Setup

A multi-agent OpenCode configuration for building Android apps to a
5-star quality bar. One command installs it into any project, in any
environment.

**If you are an AI agent reading this to set yourself up:** run the
one-line install command in the next section, from the target project's
root directory (or a directory you intend to use as one). No further
interpretation needed — the installer is self-contained and
self-verifying. If the install script reports any file as missing after
running, stop and report that to the user rather than proceeding.

---

## Install (one command, any environment)

Run this **from the root of the Android project you want it in** (the
directory containing, or that will contain, `build.gradle.kts`):

```bash
curl -fsSL https://raw.githubusercontent.com/tonysheesh/Opencode-android-5star-/main/install.sh | bash
```

No git clone, no zip, no manual file copying. This single command writes
all 11 config files directly.

**No internet access from the target machine, or `curl`/`wget` blocked?**
Clone or download the repo instead, then run the script locally:

```bash
git clone https://github.com/tonysheesh/Opencode-android-5star-.git /tmp/ocsetup
bash /tmp/ocsetup/install.sh "$(pwd)"
rm -rf /tmp/ocsetup
```

**Installing into a different directory than your current one?** Pass it
as an argument to either form:
```bash
curl -fsSL https://raw.githubusercontent.com/tonysheesh/Opencode-android-5star-/main/install.sh | bash -s -- /path/to/your-project
```

The script is idempotent — safe to run more than once. It only writes and
overwrites the 11 files it manages; it never touches anything else in
your project.

### Android-specific environments (proot, Termux, chroot, etc.)

If you're running this from a terminal app **on an Android device itself**
(proot-distro, Termux, UserLAnd, etc.) rather than a normal desktop/CI
Linux environment, one thing matters more than anything else:

> **Do not install onto `/sdcard` or `/storage/emulated/...`.**

That path is a FUSE-mounted bridge into Android's shared storage, and it
routinely breaks `chmod +x`, recursive delete on nested folders, and
script execution — with confusing, inconsistent errors that look like
permission bugs but are actually filesystem-type bugs. The installer
detects this and prints a warning automatically, but the fix is simple:
install into your Linux environment's own home directory instead.

```bash
# Good — proot/Termux native filesystem:
curl -fsSL https://raw.githubusercontent.com/tonysheesh/Opencode-android-5star-/main/install.sh | bash -s -- ~/my-android-project

# Avoid — Android shared storage via FUSE:
# bash install.sh /sdcard/Download/my-android-project
```

If your actual Android project's source lives under `/sdcard` for other
reasons (e.g. a file-manager-based workflow), that's a separate concern —
just make sure *this config* (`opencode.json`, `AGENTS.md`, etc.) lives
wherever you'll actually launch the `opencode` command from, since that's
the working directory it reads from.

### Verifying the install

```bash
find . -maxdepth 2 \( -iname "AGENTS.md" -o -iname "opencode.json" -o -path "./.opencode/agent/*.md" \)
```

Expect 11 lines back: 5 files in the project root, 6 under
`.opencode/agent/`. The installer itself also runs this check
automatically at the end and will tell you plainly if anything's missing.

---

## Using it

Start OpenCode from the project root, then address the lead agent by
name so it orchestrates the full pipeline:

```
@android-lead add a settings screen with a dark mode toggle
```

### Pipeline

```
android-lead (orchestrator)
   │
   ├─▶ android-researcher   (current library/API versions — read-only)
   │
   ├─▶ android-coder        (implements in Kotlin/Compose, writes tests)
   │
   ├─▶ android-designer     (UI/UX polish, captures screenshot)
   │       │  does NOT grade its own work
   │       ▼
   ├─▶ android-critic       (blind grade: screenshot only, no reasoning)
   │       │  loops back to designer if any axis scores < 3
   │
   └─▶ android-tester       (real test suite + emulator, reports evidence)
```

The lead only reports a task complete once:
- `quality-bar.md`'s "Must" checklist passes
- `android-critic`'s score is 3+ on every axis (for UI work)
- `android-tester` has actually executed the tests this session and
  reports real pass/fail evidence — not an assumption

## File map

| File | Purpose |
|---|---|
| `install.sh` | Self-contained installer. All 11 files are embedded as heredocs inside it — no external file dependencies, works via `curl \| bash`. |
| `opencode.json` | Registers all 6 agents; wires `instructions` so every agent auto-reads the 4 docs below. |
| `AGENTS.md` | The core workflow (research → plan → implement → test → self-review → report) and the blind-review principle. |
| `quality-bar.md` | The 5-star checklist. "Must" items block task completion. |
| `design-standard.md` | Material 3 Expressive visual/UX standard and the 6-axis scoring rubric the critic uses. |
| `testing.md` | Exact commands: unit tests, lint, headless emulator (Gradle Managed Device + manual AVD fallback), adb smoke test, reproducible screenshot capture. |
| `.opencode/agent/android-lead.md` | Primary orchestrator (`mode: primary`). |
| `.opencode/agent/android-researcher.md` | Read-only. Searches for current versions before code is written. |
| `.opencode/agent/android-coder.md` | Implements features, writes tests alongside code. |
| `.opencode/agent/android-designer.md` | Implements UI/UX polish. Captures screenshots. Never self-grades. |
| `.opencode/agent/android-critic.md` | Blind grader — screenshot + one-line description only. |
| `.opencode/agent/android-tester.md` | Runs the real test suite, reports evidence. |

## Design principles

- **No agent grades its own work.** The designer implements; the critic
  grades blind, with zero access to the designer's rationale. Grading
  the same reasoning that produced the work tends to rubber-stamp it —
  an independent, context-stripped review catches more.
- **"Tested" means actually executed this session.** Never a pass
  reported without running the command and inspecting real output.
- **Screenshots must be reproducible.** Every screenshot used as
  evidence comes from a freshly-cleared app state (`pm clear` +
  relaunch), not a warm running instance — stale state otherwise leaks
  between shots and undermines before/after comparisons.
- **Research before code, every time.** Android/Kotlin/Compose/Gradle
  move fast enough that trained-in knowledge of version numbers and API
  stability is often stale; the researcher agent always checks live.

## Updating this setup

Edit the relevant section inside `install.sh` (all files are embedded
there as heredocs — there are no separate source files to keep in sync),
commit, then re-run the install command in any project using it. There's
no versioning/pinning by design — re-pulling always gets the latest.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Permission denied` running `install.sh` after `chmod +x` | Installing on a FUSE-mounted path (`/sdcard`) | Re-run targeting a native filesystem path, see above |
| `cp: cannot stat '.../*'` errors, or only `.opencode` copied | Shell glob (`*`) failed to expand, often due to a stale/partial extraction | Use the `curl \| bash` one-liner instead — it has no glob-dependent copy step at all |
| `rm: cannot remove '...': Directory not empty` on a leftover folder from a previous failed attempt | FUSE mounts sometimes won't recurse-delete correctly | Ignore the old folder and install to a differently-named target directory instead of fighting the delete |
| `here-document ... delimited by end-of-file (wanted 'EOF')` | A heredoc marker got corrupted during a manual copy-paste (common in mobile text editors like `nano`) | Don't paste through an editor — use `curl \| bash`, or if pasting manually, use `cat > file << 'EOF'` directly in the shell, never through `nano` |
| `opencode.json: FAILED to parse as JSON` | Install was interrupted mid-write | Delete the partial files and re-run the installer from scratch |
