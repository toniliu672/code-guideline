# Guidelines & Multi-Stack Code Rules Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Language-Bash%20Shell-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![Code Quality](https://img.shields.io/badge/Audit-Strict%20Enforcement-success.svg)](scripts/guidelines.sh)

An automated code quality audit, architectural compliance, clean code enforcement, and security inspection engine.

Currently validated on **Laravel (Blade / Pest / PHPUnit)**, with an extensible architecture designed for multi-framework adapters.

---

## Background & Motivation

Autonomous AI coding assistants (such as Antigravity CLI powered by Gemini models, alongside other agentic tools) are inherently probabilistic. Over long conversational contexts or across separate working sessions, rules defined solely through soft prompt instructions (system prompts, skill definitions, or `AGENTS.md`) frequently suffer from **instruction drift** and **attention degradation**:

- Agents regress into generating dead inline comments inside function bodies and templates.
- Source files expand beyond single-responsibility limits (> 100 lines) without decomposition.
- View templates accumulate monolithic utility class strings ("train-track classes") and unmapped ad-hoc colors.
- Development debug routines (`dd`, `dump`, `console.log`) unintentionally slip into production branches.

Relying exclusively on self-regulation by an LLM is insufficient because prompt compliance degrades non-deterministically. 

This engine provides a **deterministic gatekeeper outside the model's reasoning loop**. Through standalone compiled executable audits (`/usr/local/bin/guidelines`) and automated Git pre-commit hooks, code changes are physically verified and blocked upon any violation, ensuring absolute adherence to codebase standards regardless of model session state.

---

## Installation & Usage

### Option A: Quick Install — No Clone Required (Recommended)
Download the standalone pre-compiled binary from **GitHub Releases** (already bundles all audit rules, templates, and AI skills):

**Global Install** (available in all projects):
```bash
sudo curl -fsSL https://github.com/toniliu672/code-guideline/releases/latest/download/guidelines -o /usr/local/bin/guidelines
sudo chmod +x /usr/local/bin/guidelines
guidelines --skills    # optional: sync bundled AI skills (e.g. bugbot)
```

Or one-line installer (downloads binary + syncs global AI rules & skills):
```bash
curl -fsSL https://raw.githubusercontent.com/toniliu672/code-guideline/main/scripts/install.sh | bash -s -- --update
```

**Project-Only** (single local binary, zero global changes):
```bash
cd /path/to/your-project
curl -fsSL https://github.com/toniliu672/code-guideline/releases/latest/download/guidelines -o ./guidelines
chmod +x ./guidelines
./guidelines
```

### Option B: Install From Source (After Cloning)
```bash
git clone https://github.com/toniliu672/code-guideline.git guide-rules
cd guide-rules

# Global install (builds binary -> /usr/local/bin/guidelines + syncs rules & skills)
bash scripts/install.sh --global
# Or interactive setup wizard:
bash scripts/install.sh --wizard
```

To run **project-only from source** without installing globally:
```bash
cd /path/to/your-project
bash /path/to/guide-rules/guidelines.sh
```

For per-project settings without touching global config, add `.guidelines.env` and/or `.guidelinesignore` to your project root and commit them to Git.

---

## Command Reference

The global executable is located at `/usr/local/bin/guidelines`.

### Core Commands

| Command | Description |
|---|---|
| `guidelines` | Executes full audit suite based on active configuration |
| `guidelines --config` | Displays current active configuration and profile |
| `guidelines --wizard` | Launches terminal interactive setup wizard |
| `guidelines --skills` | Syncs bundled AI skills (e.g. `bugbot`) to global Gemini/Antigravity skill directories |
| `guidelines --update` | Updates binary executable, global rules, and bundled skills from upstream repository |
| `guidelines core` | Runs core audits only (Zero inline comments, file line limits, syntax/lint) |
| `guidelines lint` | Runs static analysis and syntax validation |
| `guidelines test` | Executes configured automated test suites |
| `guidelines runtime` | Crawls live routes across roles (Chromium/Playwright or HTTP fallback) to block HTTP 5xx, JS `pageerror`, `console.error`, and server log exceptions |
| `guidelines frontend` | Validates frontend component structure and design system rules |
| `guidelines design` | Validates color tokens and class string length limits |
| `guidelines arch` | Validates architectural pattern boundaries |
| `guidelines security` | Validates ISO 27001, 27701, and 25010 security rules |
| `guidelines --uninstall` | Removes global executable binary, synced skills, and global AI rules |
| `guidelines <target_dir>` | Installs pre-commit hook into target project |

### CLI Flags (Runtime Overrides)

Configuration options can be overridden dynamically per execution:

```bash
# Strictness level (standard | moderate | strict)
guidelines --level=strict

# Frontend framework (auto | blade | react | next | svelte | flutter | none)
guidelines --frontend=blade --blade=standard

# Architecture pattern (auto | mvc | modular | service-layer | microservices | none)
guidelines --arch=mvc

# Skip specific audit layers
guidelines --no-core
guidelines --no-security
```

---

## Configuration

### Inspect Active Settings
```bash
guidelines --config
```

Example output:
```text
================================================================
   GUIDELINES ACTIVE CONFIGURATION & PROFILE                   
================================================================
   Framework Approach    : auto
   Blade Architecture    : auto
   Strictness Level      : standard
   Architecture Paradigm : auto
   Linter & Analysis     : auto
   Testing Suites        : pest,k6
   RTK Integration       : auto
   Core Limits           : Max 100 lines (Layouts: 250)
================================================================
```

### Interactive Wizard
An interactive terminal checklist is available to configure presets:
```bash
guidelines --wizard
```

### Configuration File (`config.env` & Per-Project `.guidelines.env`)
Global defaults are maintained in `scripts/rules/config.env`. For project-specific overrides, copy the full template below into `.guidelines.env` at the root of your target project and **commit it to Git** (all variables are optional; unset values fall back to their defaults):

```bash
# ==============================================================================
# PER-PROJECT GUIDELINES CONFIGURATION (.guidelines.env)
# ==============================================================================

# 1. Project & Core Rules
PROJECT_NAME=""                         # Auto-detected from folder name if empty
ENABLE_CORE=true                        # true | false
MAX_LINES=100                           # Max lines for logic/controllers/components
MAX_LAYOUT_LINES=250                    # Max lines for layout files
STRICT_LINES=true                       # true (fail) | false (warning only)
LINE_EXCLUDES="database/migrations|database/seeders|config/"
CODE_DIRS="app src lib routes components pages"

# 2. Syntax & Static Analysis
LINTER_TOOL="auto"                      # auto | php-laravel | js-ts | svelte | flutter | syntax-only | none
CHECK_SYNTAX=true                       # true | false (php -l)
CHECK_STATIC_ANALYSIS=true              # true | false (PHPStan, Pint, ESLint, svelte-check, dart analyze)

# 3. Frontend & Blade Rules
FRONTEND_APPROACH="auto"                # auto | blade | react | next | svelte | flutter | none
VIEWS_DIR="resources/views"             # Blade views root directory
BLADE_APPROACH="auto"                   # auto | standard | admin-separated | atomic
STRICTNESS_LEVEL="standard"             # standard | moderate | strict
BLADE_RAW_TAGS=""                       # Optional regex override, e.g. "input|select|textarea|button"
MAX_BLADE_PHP_LINES=3                   # Max lines allowed inside @php...@endphp in page views

# 4. Design System & Tailwind Rules
CHECK_COLOR_TOKENS=true                 # true | false (canonical color token allowlist)
CHECK_TRAIN_TRACK=true                  # true | false (prevent bloated class strings in pages)
CHECK_CLASS_CONFLICTS=true              # true | false (e.g. hidden + flex)
CHECK_CANONICAL_CLASSES=true            # true | false (prefer p-4 over p-[16px])
MAX_CLASS_CHARS=100                     # Max characters in a single class attribute on pages
MAX_CLASS_WORDS=10                      # Max utility classes in a single class attribute on pages

# 5. Architecture Rules
ARCHITECTURE_APPROACH="auto"            # auto | mvc | service-layer | modular | microservices | none

# 6. Automated Testing
ENABLE_TESTING=false                    # true | false (include tests when running `guidelines` all)
RUN_AUTOMATED_TESTS=true                # true | false (toggle runner for `guidelines test`)
TEST_SUITES="laravel,k6"                # Comma-separated: laravel, pest, phpunit, frontend, vitest, jest, flutter, k6, none

# 7. Security (ISO 27001 / 27701 / 25010) & CLI
ENABLE_SECURITY=true                    # true | false
CHECK_DEBUG_STATEMENTS=true             # true | false (block dd, dump, var_dump)
USE_RTK="auto"                          # auto | yes | no

# 8. Universal Runtime & Browser Error Guard (`guidelines runtime` / `guidelines crawl`)
ENABLE_RUNTIME_GUARD=false              # true | false (include runtime crawl in `guidelines` all)
RUNTIME_BASE_URL=""                     # Target dev/test server URL (e.g. http://127.0.0.1:8000)
RUNTIME_CONFIG=".guidelines.runtime.json" # Multi-role login & seed routes config (see scripts/rules/runtime/runtime.json.example)
RUNTIME_ROUTES="/"                      # Comma-separated fallback routes when RUNTIME_CONFIG is absent
RUNTIME_FAIL_ON_4XX=false               # true to fail on unexpected 403/404/422 during page load
RUNTIME_FAIL_ON_CONSOLE_ERROR=true      # true to fail on browser console.error
RUNTIME_LOG_FILE=""                     # Optional server log file to scan for newly appended exceptions
RUNTIME_MAX_PAGES=50                    # Max auto-discovered pages crawled per role
RUNTIME_TIMEOUT_MS=15000                # Navigation timeout in milliseconds
```

### Ignoring Files Per Project (`.guidelinesignore`)
Test files (`tests/`, `test/`, `__tests__/`, `*.test.*`, `*.spec.*`, `cypress/`, `e2e/`, `playwright/`, `k6/`) and framework/system files (`bootstrap/app.php`, `bootstrap/cache/`, `public/index.php`, `public/build/`, `resources/views/errors/`, `resources/views/mail/`, `database/factories/`, `*.config.*`, `artisan`) are **excluded automatically by default**.

For project-specific exclusions (e.g. legacy files), create `.guidelinesignore` in the project root using `.gitignore` syntax and **commit it to Git**:

```text
app/Legacy/OldExport.php
resources/views/custom-pdf/**
```

**Anti-Tamper Protection (`HEAD`-Only)**:
- `guidelines` automatically respects committed **`HEAD:.gitignore`** patterns (so local gitignored secrets/keys like `*.key` or `certs/` do not trigger false positives, while tracked secrets are still blocked by ISO 27001).
- `guidelines` reads `.guidelinesignore` and `.guidelines.env` **only from the latest Git commit (`HEAD`)**, never from uncommitted working tree edits.
- If an AI agent modifies or creates either file without a human commit, `guidelines` prints a `[WARNING]` with the diff and **ignores the uncommitted changes**.

---

## Bundled AI Skills (`bugbot`)

This repository bundles reusable AI agent skills under `skills/`:

- **`bugbot`** (`skills/bugbot/SKILL.md`): High-signal automated code reviewer for git diffs, staged changes, and commits. Focuses strictly on real bugs, regressions, security vulnerabilities, and runtime/data risks without style nitpicks.

### Syncing Skills
- **Global sync**: Automatically synced during `bash scripts/install.sh --global` or `guidelines --update`, or manually via:
  ```bash
  guidelines --skills
  # or directly from the repo:
  bash scripts/sync-skills.sh
  ```
- **Project-only usage**: Copy `skills/bugbot` into your project or reference `skills/bugbot/SKILL.md` directly in your AI session when asking for a pre-push diff review.
- **Note**: `bugbot` is an AI agent skill triggered via prompt (e.g. *"run bugbot"*), not a bash step executed inside `guidelines` pre-commit audits.

---

## Audit Architecture

The master runner coordinates 5 auditing layers:

```text
┌────────────────────────────────────────────────────────────────────────┐
│             MASTER ORCHESTRATOR RUNNER (guidelines)                    │
├────────────────────────────────────────────────────────────────────────┤
│ 1. CORE RULES                                                          │
│    - check-comments.sh     : Zero Inline Comments in function bodies   │
│    - check-lines.sh        : Max 100 Lines per File (Layouts max 250) │
│    - check-syntax-lint.sh  : Syntax integrity and static analysis      │
├────────────────────────────────────────────────────────────────────────┤
│ 2. FRONTEND & DESIGN SYSTEM                                            │
│    - check-design-system.sh: Color token allowlist & class limit checks│
│    - check-blade-components.sh: Blade component structure (Validated) │
│    - Framework adapters    : React, Svelte, Flutter (Experimental)     │
├────────────────────────────────────────────────────────────────────────┤
│ 3. ARCHITECTURE AUDIT                                                  │
│    - check-mvc.sh          : Model-View-Controller separation          │
│    - check-modular.sh      : Modular / domain boundary separation      │
│    - check-service-layer.sh: Thin controllers and service delegation   │
│    - check-microservices.sh: Containerization and health checks        │
├────────────────────────────────────────────────────────────────────────┤
│ 4. AUTOMATED TESTING AUDIT                                             │
│    - check-testing.sh      : Pest, PHPUnit, Vitest, Jest, Flutter, k6  │
├────────────────────────────────────────────────────────────────────────┤
│ 5. SECURITY & ISO STANDARDS COMPLIANCE                                 │
│    - ISO/IEC 27001 (A.8.12, A.8.24, A.8.28): Secrets, storage, uploads │
│    - ISO/IEC 27701 (Cl. 7.4): Data minimization and PII protection      │
│    - ISO/IEC 25010 (Cl. 4.3): Modularity and clean production code     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Design System & Styling Rules

The design system audit enforces consistency and prevents bloated styling:

1. **Closed Canonical Color Token Allowlist**:
   - Allowed tokens: `background`, `foreground`, `surface`, `card`, `popover`, `primary`, `secondary`, `muted`, `accent`, `success`, `warning`, `danger`/`destructive`, `info`, `border`, `input`, `ring`.
   - Prohibits hardcoded hex/RGB values, raw unmapped palette names, numeric shade suffixes (`-50` through `-950`), manual `dark:` utility overrides in views, and unauthorized synonym tokens.

2. **Class String Limits**:
   - Elements in view/page templates are constrained to avoid class concatenation exceeding 10 utility classes or 100 characters per element. Reusable components must be extracted when styling exceeds this threshold.

3. **Scale Utilities & Conflict Prevention**:
   - Canonical Tailwind scale classes are preferred over arbitrary pixel brackets.
   - Mutually conflicting utility classes on the same element are flagged.

---

## Automated Testing Support

Test validation guidelines covering feature flows, data flows, and k6 load testing are documented in:
- [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)

Audit execution:
```bash
guidelines test
```

---

## Pre-Commit Hook Integration

To register pre-commit verification in a target Git repository:

```bash
guidelines /path/to/target-project
```

This installs `.git/hooks/pre-commit` referencing `/usr/local/bin/guidelines` and validates all rules before commit creation.

---

## Uninstallation

To remove the global guidelines binary and clean up global AI instruction blocks:

```bash
guidelines --uninstall
# or via installer:
bash scripts/install.sh --uninstall
```

To remove the pre-commit hook from a specific target project as well:
```bash
guidelines --uninstall=/path/to/target-project
```

This procedure:
1. Removes `/usr/local/bin/guidelines`.
2. Strips injected `<!-- BEGIN GUIDE-RULES -->` blocks from `~/.claude/CLAUDE.md` and `~/.gemini/GEMINI.md`.
3. Removes project Git pre-commit hooks that reference the guidelines binary.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
