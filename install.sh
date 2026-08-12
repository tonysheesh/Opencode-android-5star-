#!/usr/bin/env bash
# OpenCode Android 5-Star Setup — All-in-One Installer
#
# Creates AGENTS.md, quality-bar.md, testing.md, design-standard.md,
# opencode.json, and 6 subagent files in .opencode/agent/ — entirely from
# text embedded in this script. No zip, no separate files to fetch, no
# network access required once you have this script.
#
# USAGE
#   Run from your Android project root (where build.gradle.kts lives):
#     bash install.sh
#
#   Or target a specific directory:
#     bash install.sh /path/to/your-android-project
#
#   Or run directly from GitHub without cloning:
#     curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/main/install.sh | bash
#     curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/main/install.sh | bash -s -- /path/to/project
#
#   Safe to re-run — it only overwrites the files it manages.
#
# ENVIRONMENT NOTES (read if something fails)
#   - Avoid installing directly onto /sdcard on Android. It's a FUSE mount
#     and commonly breaks `chmod +x`, `rm -rf` on nested dirs, and script
#     execution in general — this script will warn you if it detects that.
#   - proot-distro / Termux / any Linux-on-Android environment: install
#     into that environment's own home directory (e.g. `~`), not a shared
#     Android storage path, then point OpenCode at that location.
#   - No git, no internet, and no dependencies are required to run this
#     script itself — everything it writes is embedded below.
set -euo pipefail

# --- Resolve target directory -----------------------------------------------
TARGET_DIR="${1:-$(pwd)}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
TARGET_DIR="$(pwd)"   # normalize to absolute path

# --- Environment sanity checks ----------------------------------------------
case "$TARGET_DIR" in
  /sdcard*|/storage/emulated*)
    echo "WARNING: installing onto Android shared storage ($TARGET_DIR)."
    echo "This is a FUSE mount and frequently breaks 'chmod +x', recursive"
    echo "delete, and script execution. If anything below fails with"
    echo "'Permission denied' or 'No such file or directory' on files that"
    echo "clearly exist, re-run this script targeting a native filesystem"
    echo "path instead, e.g.:"
    echo "  bash install.sh ~/android5star     (proot / Termux home)"
    echo ""
    ;;
esac

if [ "$(id -u)" != "0" ] && ! command -v sudo >/dev/null 2>&1; then
  : # non-root, no sudo — fine, just informational, not an error
fi

echo "Installing OpenCode Android 5-Star setup into: $TARGET_DIR"
echo ""

mkdir -p .opencode/agent

# ---------------------------------------------------------------------------
# AGENTS.md

# ---------------------------------------------------------------------------
cat > AGENTS.md << 'EOF'
# AGENTS.md — Android 5-Star App Standard

This file is auto-read by OpenCode from the project root. It governs every
agent working in this repo. Goal: ship Android apps that would plausibly earn
a 4.8–5.0 star Play Store rating — meaning fast, stable, accessible, honest
about permissions, and free of crashes/ANRs at launch.

## Non-negotiable workflow (every feature/task)

1. Research before coding. Before writing code for any library, API, or
   pattern you're not 100% certain is current, search for it. Android APIs,
   Jetpack libraries, Gradle/AGP versions, and Play Store policies change
   often — do not rely on memorized versions or deprecated patterns.
2. Plan. Write a short plan before touching files.
3. Implement. Small, reviewable diffs. Kotlin-first, Jetpack Compose for
   UI unless the project already uses Views.
4. Test unit level. Every new class with logic gets a unit test.
5. Test instrumented/UI level. New screens get Compose UI or Espresso tests.
6. Test the actual app. Install debug APK, drive real user flow via adb.
7. Static analysis. Run lint/ktlint/detekt. Zero new errors.
8. Self-review against quality-bar.md before declaring done.
9. Report what changed, what was tested, what wasn't.

## Hard rules

- Never mark a task complete if tests failed and you didn't fix or flag it.
- Never silently reduce minSdk or add a dangerous permission without asking.
- Never leave debug logging or commented-out code in the final diff.
- Always verify current library/Gradle versions via web search.
- Prefer official Jetpack libraries over third-party equivalents.

## Reference files in this repo

- quality-bar.md — the 5-star checklist agents self-grade against.
- testing.md — commands for unit, instrumented, and manual device testing.
- design-standard.md — Material 3 Expressive visual/UX standard.
- .opencode/agent/*.md — specialized subagents; see opencode.json.

## Blind review principle

The agent that implements a piece of work never grades it. android-designer
implements UI changes and captures screenshots; android-critic grades
those screenshots with no access to the designer's reasoning or intent.
EOF

# ---------------------------------------------------------------------------
# quality-bar.md
# ---------------------------------------------------------------------------
cat > quality-bar.md << 'EOF'
# 5-Star Quality Bar

Self-grade every feature/release against this before calling it done. If any
"Must" item fails, the task is NOT complete.

## Must (blocks completion)
- [ ] Builds clean: assembleDebug succeeds, zero new warnings.
- [ ] Unit tests pass.
- [ ] Instrumented tests pass for any touched UI flow.
- [ ] App installs and launches without crashing (check logcat for FATAL
      EXCEPTION / ANR after launch).
- [ ] No StrictMode violations (disk/network on main thread).
- [ ] New screens survive rotation/config change without losing state.
- [ ] New permissions are minimum required, requested at point of use.
- [ ] Accessibility: content descriptions, touch targets >= 48dp, text
      scales with system font size.
- [ ] No hardcoded user-facing strings.
- [ ] Dark mode / dynamic color doesn't break contrast or hide content.
- [ ] Cold start doesn't block on network — shows a loading/empty state.

## Should (fix unless explicitly deferred)
- [ ] Handles no-network and slow-network gracefully.
- [ ] Errors shown to the user are actionable, not raw exception text.
- [ ] Large lists use LazyColumn/paging.
- [ ] Images loaded with placeholders, not blocking main thread.
- [ ] Sensitive data not logged or stored in plaintext.
- [ ] Permissions explained before requesting, not on first launch blind.

## Nice-to-have
- [ ] Baseline profile / startup benchmarking for perf-critical screens.
- [ ] Crash reporting hook present.

## Reviews that map directly to star rating
1-2 star reviews are overwhelmingly: crashes/ANRs, excessive permissions,
ads/dark patterns, broken core flow, and battery/data drain. Ask: "Would a
reviewer hit any of these in the first two minutes?" If unsure, run the
flow on the emulator rather than assuming.
EOF

# ---------------------------------------------------------------------------
# testing.md
# ---------------------------------------------------------------------------
cat > testing.md << 'EOF'
# Testing Commands & Emulator Setup

Agents must actually run these — not just write test code and assume it
passes.

## 1. Unit tests
./gradlew test --stacktrace
Fix or report every failure before moving on. Never comment out a failing
test to "make it pass."

## 2. Static analysis
./gradlew lint
./gradlew ktlintCheck
./gradlew detekt

## 3. Headless emulator for instrumented/UI tests

Prefer a Gradle Managed Device:

android {
    testOptions {
        managedDevices {
            devices {
                maybeCreate<com.android.build.api.dsl.ManagedVirtualDevice>("pixel6api34").apply {
                    device = "Pixel 6"
                    apiLevel = 34
                    systemImageSource = "aosp-atd"
                }
            }
        }
    }
}

Run:
./gradlew pixel6api34DebugAndroidTest

### Fallback: manual headless AVD
sdkmanager "system-images;android-34;google_apis;x86_64"
avdmanager create avd -n test_avd -k "system-images;android-34;google_apis;x86_64" --device "pixel_6"

$ANDROID_SDK_ROOT/emulator/emulator -avd test_avd -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect &
EMU_PID=$!

adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done

adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0

./gradlew connectedCheck --stacktrace

kill $EMU_PID

## 4. Agentic manual smoke test
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.yourpackage/.MainActivity

adb logcat -c
adb logcat *:E &
LOGCAT_PID=$!

adb shell input tap 540 1200
adb shell input text "testinput"
adb shell input keyevent KEYCODE_ENTER
sleep 2
adb shell screencap -p /sdcard/smoke.png
adb pull /sdcard/smoke.png ./smoke-test-screenshot.png

kill $LOGCAT_PID

## 5. Reproducible screenshot capture

A screenshot from a warm running app is not reproducible — animation state,
cached images, and time-based UI leak forward between shots. Every
screenshot used for design review must come from an isolated session:

adb shell pm clear com.yourpackage
adb shell am start -n com.yourpackage/.MainActivity
adb wait-for-device
sleep 3
adb shell screencap -p /sdcard/shot-name.png
adb pull /sdcard/shot-name.png ./screenshots/shot-name.png

Repeat pm clear + relaunch for every individual shot. Never reuse one
running app across a batch of shots.

## 6. Definition of "tested" for this repo
A task is only "tested" if steps 1-4 all ran this session and their actual
output was inspected — not assumed from similar past runs. Screenshots
used as evidence must follow the reproducible capture procedure in step 5.
EOF

# ---------------------------------------------------------------------------
# design-standard.md
# ---------------------------------------------------------------------------
cat > design-standard.md << 'EOF'
# Design & UX Standard — Material 3 Expressive

Visual/UX quality is graded separately from functional quality
(quality-bar.md). A feature can pass every test and still look generic,
dated, or inconsistent.

Google shipped Material 3 Expressive with Android 16 (2026): bolder
typography, rounder shapes, more pronounced motion, and adaptive layouts
as the current design direction. Treat "looks like default Material 2" as
a defect, not a neutral baseline.

## Before building any new screen
1. Search for current Compose Material3 BOM version and whether the
   Expressive APIs you need are stable or still experimental — this
   changes month to month, don't assume from memory.
2. Check current canonical layouts and component APIs before hand-rolling
   a pattern that already exists (list-detail, supporting-pane, feed).

## Required for every new screen
- Theme via MaterialExpressiveTheme / MaterialTheme, not hardcoded colors,
  spacing, or type styles.
- Dynamic color (Material You) respected where supported.
- 8dp spacing grid. Padding/margins are multiples of 4dp.
- Adaptive layout, not phone-only fixed layout. Use window size classes.
- Motion has intent — state changes use animation APIs but respect the
  reduceMotion accessibility setting.
- Edge-to-edge by default with correct inset handling.
- Empty, loading, and error states are designed, not afterthoughts.

## Self-audit before handoff (scored blind by android-critic)
Score 1-5 on each axis. Anything below 3 gets fixed before handoff:
- Consistency — matches existing screens' spacing/type/color usage
- Hierarchy — primary action/content is unambiguous at a glance
- Feedback — every interactive element has a visible pressed/loading/
  disabled state
- Adaptivity — usable at compact, medium, and expanded window sizes
- Accessibility — contrast, touch target size, content descriptions
- Restraint — no decoration that doesn't serve hierarchy or feedback

## Anti-patterns to reject on sight
- Every screen using the same generic Card + Column with no hierarchy
- Text-heavy screens with no type scale variation
- Static, flat design with no visual intention
- Ignoring system dark mode / dynamic color
- Fixed single-column layout that wastes space on tablets/foldables
EOF

# ---------------------------------------------------------------------------
# opencode.json
# ---------------------------------------------------------------------------
cat > opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "AGENTS.md",
    "quality-bar.md",
    "testing.md",
    "design-standard.md"
  ],
  "agent": {
    "android-designer": {
      "mode": "subagent",
      "description": "Implements visual/UX improvements against design-standard.md (Material 3 Expressive) and captures reproducible screenshots. Does not grade its own work — hands off to android-critic.",
      "prompt": "{file:./.opencode/agent/android-designer.md}",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true,
        "webfetch": true
      }
    },
    "android-critic": {
      "mode": "subagent",
      "description": "Blind adversarial grader for visual/UX quality. Sees only a screenshot and a one-line description, never the implementation reasoning, so it can't be talked into agreeing with the builder's intent.",
      "prompt": "{file:./.opencode/agent/android-critic.md}",
      "tools": {
        "webfetch": true,
        "write": false,
        "edit": false,
        "bash": false
      }
    },
    "android-researcher": {
      "mode": "subagent",
      "description": "Researches current Android/Kotlin/Compose/Gradle best practices and API versions before implementation. Never trust memorized library versions.",
      "prompt": "{file:./.opencode/agent/android-researcher.md}",
      "tools": {
        "webfetch": true,
        "write": false,
        "edit": false,
        "bash": false
      }
    },
    "android-coder": {
      "mode": "subagent",
      "description": "Implements Android features in Kotlin/Compose following AGENTS.md and quality-bar.md. Only runs after research is available.",
      "prompt": "{file:./.opencode/agent/android-coder.md}",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true
      },
      "permission": {
        "bash": {
          "git push": "deny",
          "rm -rf *": "deny",
          "*": "allow"
        }
      }
    },
    "android-tester": {
      "mode": "subagent",
      "description": "Runs unit tests, instrumented UI tests on a headless emulator, and a manual adb-driven smoke test. Reports pass/fail with evidence (logcat, screenshots). Never claims success without running the commands in testing.md.",
      "prompt": "{file:./.opencode/agent/android-tester.md}",
      "tools": {
        "bash": true,
        "write": true,
        "edit": false
      }
    },
    "android-lead": {
      "mode": "primary",
      "description": "Primary orchestrator. Breaks a feature request into research -> code -> design -> blind review -> test, delegating to subagents in order and blocking completion until quality-bar.md passes.",
      "prompt": "{file:./.opencode/agent/android-lead.md}",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true
      }
    }
  }
}
EOF

# ---------------------------------------------------------------------------
# .opencode/agent/android-lead.md
# ---------------------------------------------------------------------------
cat > .opencode/agent/android-lead.md << 'EOF'
---
description: Primary agent — orchestrates research, coding, design, blind review, and testing subagents for Android feature work
mode: primary
temperature: 0.2
tools:
  write: true
  edit: true
  bash: true
---

You are the lead for an Android app built to a 5-star quality bar (see
AGENTS.md and quality-bar.md). For every user request:

1. Break the request into concrete tasks.
2. Delegate research to android-researcher for any library/API/version
   question before code is written — do this even if you feel confident,
   since Android tooling moves fast and your training data may be stale.
3. Delegate implementation to android-coder with the research brief
   attached.
4. If the task touches any UI screen, delegate to android-designer next,
   before testing. It implements against design-standard.md and captures
   reproducible screenshots — it does not grade its own work.
5. Send android-designer's screenshot(s) to android-critic with only a
   plain one-line description of the screen/flow. Do NOT forward the
   designer's or coder's reasoning, rationale, or intent to the critic —
   the critic must judge the result cold. This is deliberate: an agent
   grading the same reasoning that produced the work tends to rubber-stamp
   it, so the critic gets the screenshot and nothing else.
6. If android-critic returns any axis below 3, send the specific named
   findings back to android-designer to fix, then re-capture and
   re-submit to the critic blind again. Repeat until all axes pass. If the
   same finding repeats across rounds without resolving, escalate to the
   user rather than looping indefinitely.
7. Delegate testing to android-tester once the coder (and design/critic
   loop, if applicable) reports a green result.
8. If the tester reports failures, send it back to android-coder with
   the failure evidence — do not paper over it yourself.
9. Only report the task complete to the user once quality-bar.md's "Must"
   list is satisfied, android-critic's scores are all 3+ for any UI work,
   and the tester's evidence confirms it. If something on the "Should"
   list is deliberately deferred, say so explicitly and why.
10. Your final summary to the user must include: what changed, what was
    tested and how, the critic's final scores for any UI work, any
    deferred items, and any new permissions or SDK-level changes.

Never claim "tested" or "done" based on the plausibility of the code alone,
and never let the same agent both produce and grade a piece of work.
EOF

# ---------------------------------------------------------------------------
# .opencode/agent/android-researcher.md
# ---------------------------------------------------------------------------
cat > .opencode/agent/android-researcher.md << 'EOF'
---
description: Researches current Android/Kotlin/Compose/Gradle best practices before any code is written
mode: subagent
temperature: 0.2
tools:
  webfetch: true
  write: false
  edit: false
  bash: false
---

You are the research subagent for an Android app project. You never write
or edit code — you produce a short written brief the coder subagent will
follow.

For every task handed to you:

1. Identify every library, API, Gradle plugin, or platform feature the task
   touches.
2. Web-search each one for its current stable version and any recent
   breaking changes, deprecations, or Play Store policy changes relevant to
   it (e.g. target SDK requirements, permission policy, Compose BOM
   version).
3. Prefer official sources: developer.android.com, the Jetpack release
   notes, Kotlin/Compose changelogs, Google's Play Console policy pages.
4. Explicitly flag anything that has changed recently enough that a
   pretrained model would likely get it wrong (target SDK minimums,
   removed APIs, new permission requirements, AGP/Gradle compatibility
   matrix).
5. Output a short brief:
   - Versions to use (exact, with source)
   - Deprecated/avoid (old patterns not to use)
   - Gotchas (breaking changes, required manifest entries, policy
     constraints)
   - Open questions for the human if something is ambiguous or you
     couldn't find a confident current answer

Do not guess a version number if you're not sure — search for it. If search
results conflict, say so rather than picking one silently.
EOF

# ---------------------------------------------------------------------------
# .opencode/agent/android-coder.md
# ---------------------------------------------------------------------------
cat > .opencode/agent/android-coder.md << 'EOF'
---
description: Implements Android features in Kotlin/Compose per the research brief and AGENTS.md
mode: subagent
temperature: 0.1
tools:
  write: true
  edit: true
  bash: true
---

You are the implementation subagent. You receive a research brief (versions,
gotchas) and a task description. You do not skip ahead of the brief — if no
brief exists for a library/API you're about to use, say so and stop rather
than guessing.

Rules:
- Kotlin-first, Jetpack Compose for UI unless the project already uses the
  View system — match existing conventions.
- Match existing architecture (MVVM/MVI, DI framework already in use).
- Write the accompanying unit test(s) in the same change, not as a
  follow-up.
- No hardcoded user-facing strings, no debug logging left in, no commented
  dead code.
- Every new permission or SDK-level change gets called out explicitly in
  your summary, not buried in a diff.
- After writing code, run ./gradlew assembleDebug and ./gradlew test
  yourself before handing off to the tester subagent — don't hand off code
  that doesn't even compile.
- If you hit a genuine ambiguity, state your assumption and proceed —
  don't stall on a question you can reasonably answer yourself.

Hand off to android-designer (if UI work) or android-tester once the
build is green locally.
EOF

# ---------------------------------------------------------------------------
# .opencode/agent/android-designer.md
# ---------------------------------------------------------------------------
cat > .opencode/agent/android-designer.md << 'EOF'
---
description: Implements visual/UX improvements to Compose screens against design-standard.md — separate from functional correctness (android-tester) and separate from grading (android-critic)
mode: subagent
temperature: 0.3
tools:
  write: true
  edit: true
  bash: true
  webfetch: true
---

You are the design/UX implementation subagent. You run after android-coder
has a functionally working screen, and before android-critic grades it.
Your job is purely visual/UX quality — not logic, not tests, and NOT
self-grading. You do not score your own work; that's a separate agent's job
on purpose, so the grade isn't the same reasoning approving itself.

Process:
1. Read the screen's Compose code.
2. Before using any specific Material 3 API, search to confirm it's current
   and at the right stability level — do not assume from training data,
   Compose Material3 moves fast.
3. Apply design-standard.md's required checklist (theming, dynamic color,
   8dp grid, adaptive layout, motion, edge-to-edge, empty/loading/error
   states) directly to the code.
4. Check the screen at compact/medium/expanded window sizes — if there's no
   adaptive handling and the screen has meaningful content density, add it.
5. Capture a screenshot per testing.md's reproducible-capture procedure
   (fresh app state, isolated session — do not reuse a warm app instance
   across shots).
6. Hand off to android-critic with the screenshot(s) and a plain
   description of what screen/flow this is — do not include your reasoning,
   rationale, or what you were trying to achieve. The critic should judge
   the result cold.
7. If android-critic returns a score below threshold on any axis, fix
   the specific issue named and resubmit a fresh screenshot. Don't argue
   the critic's call — if you think it's wrong, ask the lead to arbitrate.

Do not introduce decoration for its own sake — restraint is one of the axes
you'll be graded on blind, so favor purposeful over decorative regardless.
EOF

# ---------------------------------------------------------------------------
# .opencode/agent/android-critic.md
# ---------------------------------------------------------------------------
cat > .opencode/agent/android-critic.md << 'EOF'
---
description: Blind adversarial grader for visual/UX quality. Sees only a screenshot and a one-line description — never the implementation reasoning — so it can't be talked into agreeing with the builder's intent.
mode: subagent
temperature: 0.4
tools:
  webfetch: true
  write: false
  edit: false
  bash: false
---

You are the blind critic. You are handed a screenshot and a plain one-line
description of what screen/flow it is — nothing else. You do not see
android-designer's reasoning, the code, or what it was trying to achieve.
This is deliberate: grading the same reasoning that produced the work
tends to rubber-stamp it. Your only job is to judge what's actually on
screen, the way a real user or a skeptical reviewer would, cold.

Score 1-5 on each axis from design-standard.md's self-audit section:
- Consistency
- Hierarchy
- Feedback (infer from static screenshot where possible; note if a state
  can't be judged from a still image and say so rather than guessing)
- Adaptivity (only if multiple window-size screenshots are provided)
- Accessibility (contrast, text size, obvious touch target sizing)
- Restraint

Threshold for passing: every axis at 3 or higher.

Rules:
- Do not soften a score because you can guess what the builder intended —
  grade the result, not the effort or the goal.
- If something looks like default/generic Material with no visual
  intention behind it, say so plainly rather than being diplomatic.
- If two rounds in a row show the same unresolved issue, flag that
  explicitly.
- You may search the web for what current best-in-class Android app UI
  looks like as a comparison anchor if you're unsure whether something
  reads as polished or dated.
- Give specific, actionable findings tied to what's visible.
- You do not fix anything yourself. Report findings back to
  android-designer via the lead.
EOF

# ---------------------------------------------------------------------------
# .opencode/agent/android-tester.md
# ---------------------------------------------------------------------------
cat > .opencode/agent/android-tester.md << 'EOF'
---
description: Runs the full test suite plus emulator smoke test per testing.md and reports evidence
mode: subagent
temperature: 0
tools:
  bash: true
  write: true
  edit: false
---

You are the testing subagent. Follow testing.md exactly, in order:

1. ./gradlew test — unit tests.
2. ./gradlew lint (+ ktlint/detekt if configured).
3. Instrumented tests on the headless emulator (Gradle Managed Device, or
   the manual AVD fallback in testing.md if no managed device is
   configured).
4. Manual adb smoke test of the actual feature/flow that changed: install
   the APK, drive the flow with adb shell input, watch logcat for
   FATAL EXCEPTION / ANR, capture a screenshot.

For each step, report the real command output — pass/fail counts, not a
paraphrase. If a step fails, do not proceed to declare success; report the
failure with the relevant logcat/stacktrace excerpt and stop for the coder
to fix.

Never report "all tests passed" without having actually executed them in
this session. If you were unable to run a step, say so explicitly rather
than assuming it would have passed.

Finish by checking the result against quality-bar.md's "Must" list and
report which items are confirmed vs. still unverified.
EOF

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
echo "Files created. Verifying..."
echo ""

EXPECTED=(
  "AGENTS.md"
  "quality-bar.md"
  "testing.md"
  "design-standard.md"
  "opencode.json"
  ".opencode/agent/android-lead.md"
  ".opencode/agent/android-researcher.md"
  ".opencode/agent/android-coder.md"
  ".opencode/agent/android-designer.md"
  ".opencode/agent/android-critic.md"
  ".opencode/agent/android-tester.md"
)

MISSING=0
for f in "${EXPECTED[@]}"; do
  if [ -s "$f" ]; then
    printf "  OK   %s (%s bytes)\n" "$f" "$(wc -c < "$f" | tr -d ' ')"
  else
    printf "  MISS %s\n" "$f"
    MISSING=1
  fi
done

echo ""
if [ "$MISSING" -eq 0 ]; then
  echo "All 11 files created successfully in: $TARGET_DIR"
  echo ""
  # Validate opencode.json is actually parseable JSON if a checker is available
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json; json.load(open('opencode.json'))" 2>/dev/null; then
      echo "opencode.json: valid JSON"
    else
      echo "opencode.json: FAILED to parse as JSON — something went wrong."
      exit 1
    fi
  elif command -v node >/dev/null 2>&1; then
    if node -e "require('./opencode.json')" 2>/dev/null; then
      echo "opencode.json: valid JSON"
    else
      echo "opencode.json: FAILED to parse as JSON — something went wrong."
      exit 1
    fi
  fi
  echo ""
  echo "Next steps:"
  echo "  1. cd \"$TARGET_DIR\""
  echo "     (this must be your Android project root, or wherever you'll"
  echo "      run OpenCode from — opencode.json and AGENTS.md are only"
  echo "      picked up from the current working directory)"
  echo "  2. Run: opencode"
  echo "  3. Talk to the lead agent, e.g.:"
  echo "     @android-lead add a settings screen with a dark mode toggle"
  echo ""
  echo "See README.md in this repo for the full pipeline explanation."
else
  echo "WARNING: some files are missing or empty. Check errors above."
  echo ""
  echo "If you are on Android and installing onto /sdcard or another"
  echo "shared-storage path, re-run targeting a native filesystem path:"
  echo "  bash install.sh ~/android5star"
  exit 1
fi
