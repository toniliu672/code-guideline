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

## Command Reference

The global executable is located at `/usr/local/bin/guidelines`.

### Core Commands

| Command | Description |
|---|---|
| `guidelines` | Executes full audit suite based on active configuration |
| `guidelines --config` | Displays current active configuration and profile |
| `guidelines --wizard` | Launches terminal interactive setup wizard |
| `guidelines --update` | Updates binary executable and global rules from upstream repository |
| `guidelines core` | Runs core audits only (Zero inline comments, file line limits) |
| `guidelines lint` | Runs static analysis and syntax validation |
| `guidelines test` | Executes configured automated test suites |
| `guidelines frontend` | Validates frontend component structure and design system rules |
| `guidelines design` | Validates color tokens and class string length limits |
| `guidelines arch` | Validates architectural pattern boundaries |
| `guidelines security` | Validates ISO 27001, 27701, and 25010 security rules |
| `guidelines --uninstall` | Removes global executable binary and cleans global AI rules |
| `guidelines <target_dir>` | Installs pre-commit hook into target project |

### CLI Flags (Runtime Overrides)

Configuration options can be overridden dynamically per execution:

```bash
# Strictness level (standard | strict | super-strict)
guidelines --level=super-strict

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

### Configuration File (`config.env`)
Configuration is maintained in `scripts/rules/config.env`:

```bash
# Strictness level: standard | strict | super-strict
STRICTNESS_LEVEL="standard"

# Frontend adapter (Laravel Blade is currently validated)
FRONTEND_APPROACH="auto"
BLADE_APPROACH="standard"

# System Architecture: auto | mvc | modular | service-layer | microservices | none
ARCHITECTURE_APPROACH="auto"

# Automated Test Suites (comma-separated: pest, phpunit, vitest, jest, k6, flutter)
TEST_SUITES="pest"
```

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
