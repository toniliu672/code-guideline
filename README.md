# Guidelines & Multi-Stack Code Rules Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/Language-Bash%20Shell-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![Code Quality](https://img.shields.io/badge/Audit-Strict%20Enforcement-success.svg)](scripts/guidelines.sh)

A master repository providing automated code quality auditing, architectural compliance, clean code enforcement, and security inspection designed to be **completely universal and multi-stack**.

This repository is not coupled to any single language or framework. It can be easily configured and adopted across **Laravel Blade**, **React / Next.js**, **Svelte / SvelteKit**, and **Flutter**, supporting architectural patterns such as **MVC**, **Modular / Domain-Driven Design**, **Service Layer**, and **Microservices**, as well as international **ISO/IEC software engineering standards**.

---

## Master Runner Architecture (`guidelines.sh`)

Audits are orchestrated by a single **Master Runner** (`guidelines.sh`) governing 4 domain layers:

```
┌────────────────────────────────────────────────────────────────────────┐
│             MASTER ORCHESTRATOR RUNNER (guidelines.sh)                 │
├────────────────────────────────────────────────────────────────────────┤
│ 1. CORE RULES (Universal Multi-Stack)                                  │
│    - check-comments.sh     : Zero Inline Comments (No // in functions) │
│    - check-lines.sh        : Max 100 Lines per File (SRP Modularity)   │
│    - check-syntax-lint.sh  : Syntax & Static Analysis (PHP/Linter)     │
├────────────────────────────────────────────────────────────────────────┤
│ 2. FRONTEND PARADIGMS & DESIGN SYSTEM                                  │
│    - check-design-system.sh: Color Tokens, Anti-Train-Track & Conflicts│
│    - check-blade-components.sh: Component & Layout Architecture (Laravel)│
│    - check-component-react.sh: Modular Components (React / Next.js)   │
│    - check-component-svelte.sh: Component Separation (SvelteKit)     │
│    - check-component-flutter.sh: Custom Widget Separation (Flutter)   │
├────────────────────────────────────────────────────────────────────────┤
│ 3. ARCHITECTURE PARADIGMS (System Organization)                        │
│    - check-mvc.sh          : Model-View-Controller Separation          │
│    - check-modular.sh      : Modular & Feature-Driven Boundaries       │
│    - check-service-layer.sh: Thin Controllers & Business Services      │
│    - check-microservices.sh: Container, Health Probe, Env Isolation   │
├────────────────────────────────────────────────────────────────────────┤
│ 4. SECURITY & ISO STANDARDS COMPLIANCE (check-iso-compliance.sh)       │
│    - Clause 1 (ISO 27001 A.8.12): Data Leakage & Secret Isolation      │
│    - Clause 2 (ISO 27001 A.8.24): Storage Isolation (No public leaks)  │
│    - Clause 3 (ISO 27701 Cl.7.4): PII Protection & Data Minimization   │
│    - Clause 4 (ISO 27001 A.8.28): Input Sanitization (MIME Validation) │
│    - Clause 5 (ISO 25010 Cl.4.3): Maintainability (No debug calls)     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Design System & Styling Rules

AI coding assistants frequently introduce UI anti-patterns when generating styles. This suite enforces two critical design system constraints via `check-design-system.sh`:

1. **Global Color Tokens Enforcement**:
   - Colors must be defined globally in `globals.css`, `app.css`, or theme configuration (CSS variables or semantic Tailwind tokens like `bg-primary`, `text-muted-foreground`).
   - Arbitrary hardcoded utility colors (e.g. `bg-[#1a2b3c]`, `text-[#ff0000]`) or inline hex colors are flagged as violations.

2. **Anti-Train-Track Class Strings ("Anti-Rel Kereta Panjang")**:
   - In page and route files (`page.tsx`, `+page.svelte`, views), AI often dumps 15–30 utility classes into monolithic elements.
   - Any element exceeding the configured threshold (default: > 10 classes or > 100 characters) is flagged as a violation.
   - Requires extracting styling into modular UI components (e.g. Shadcn/UI variants, CVA, or custom components).

---

## International ISO/IEC Software Standards

This repository aligns software development with three recognized ISO/IEC software engineering standards:

1. **ISO/IEC 27001 (Information Security / SSDLC)**:
   - **Annex A.8.12**: Enforces environment secrets (`.env`, `.pem`, `.key`) are excluded from version control and private keys are never hardcoded.
   - **Annex A.8.24**: Enforces storage isolation so confidential user uploads cannot be traversed publicly.
   - **Annex A.8.28**: Enforces binary input sanitization and MIME verification for all uploaded files.

2. **ISO/IEC 27701 (Privacy Information Management / PII Protection)**:
   - **Clause 7.4**: Enforces *Data Minimization* and *Privacy by Design* by ensuring authentication attributes (passwords, tokens) are hidden in data models.

3. **ISO/IEC 25010 (Software Product Quality / SQuaRE)**:
   - **Maintainability (Clause 4.3)**: Enforces modularity ($\le 100$ lines per file), clean code (zero dead inline comments), and purges internal debug calls (`dd`, `dump`, `var_dump`) from production code.

---

## Project Paradigm Configuration

You can configure active audit rules directly at the top of `scripts/guidelines.sh` or via `scripts/rules/config.env`:

```bash
# Configuration in scripts/rules/config.env
ENABLE_CORE=true

# Frontend Paradigm: auto | blade | react | next | svelte | flutter | none
FRONTEND_APPROACH="auto"
# Blade Approach: standard (components/admin/, components/, layouts/) | atomic
BLADE_APPROACH="standard"

# Design System & Styling Rules
CHECK_COLOR_TOKENS=true
CHECK_TRAIN_TRACK=true
MAX_CLASS_CHARS=100
MAX_CLASS_WORDS=10

# Architecture Paradigm: auto | mvc | modular | service-layer | microservices | none
ARCHITECTURE_APPROACH="auto"

ENABLE_SECURITY=true
```

> [!NOTE]
> The `"auto"` mode intelligently detects project signatures (e.g. `pubspec.yaml` for Flutter, `next.config` for Next.js, or `resources/views` for Blade).

---

## Installation into New Projects

Install this entire guidelines and audit suite into any future project with a single command:

```bash
# Syntax:
bash /home/dev/projects/guide-rules/scripts/install.sh <target_project_path>

# Examples:
bash /home/dev/projects/guide-rules/scripts/install.sh /home/dev/projects/project-flutter
bash /home/dev/projects/guide-rules/scripts/install.sh /home/dev/projects/project-nextjs
```

The installer automatically:
1. Copies the `scripts/` directory and root `guidelines.sh` shortcut.
2. Applies execution permissions (`chmod +x`) to all `.sh` scripts.
3. Sets up the initial configuration file `scripts/rules/config.env`.
4. Installs `AGENTS.md` and `CLAUDE.md` in the target project root.
5. Installs a **Git Pre-Commit Hook** (`.git/hooks/pre-commit`) in the target project, automatically verifying compliance before every commit.

---

## How to Use

### 1. Run Complete Audit Suite
```bash
# Using RTK (Rust Token Killer - recommended):
rtk bash guidelines.sh

# Or standard bash:
bash guidelines.sh
```

### 2. Run Specific Audit Domains
```bash
bash guidelines.sh core       # Universal core rules (zero comments & 100 lines)
bash guidelines.sh frontend   # Frontend components & design system audit
bash guidelines.sh design     # Design system color tokens & class-soup audit
bash guidelines.sh arch       # Architecture pattern audit
bash guidelines.sh iso        # ISO 27001, 27701 & 25010 compliance audit
```

### 3. CLI Overrides for Specific Paradigms
```bash
# Test a Flutter project with Modular Architecture:
bash guidelines.sh --frontend=flutter --arch=modular

# Test a Next.js project with Feature-Driven Architecture:
bash guidelines.sh --frontend=next --arch=modular

# Test a Laravel MVC project:
bash guidelines.sh --frontend=blade --arch=mvc
```

---

## Directory Structure

```text
guide-rules/
├── guidelines.sh                    # Master runner root shortcut
├── README.md                        # Documentation
├── LICENSE                          # MIT License
├── .gitignore                       # Git ignore definitions
├── .editorconfig                    # Text formatting standards
│
├── git-hooks/
│   └── pre-commit                   # Git pre-commit hook template
│
└── scripts/
    ├── guidelines.sh                # Master Orchestrator Runner (<= 100 lines)
    ├── install.sh                   # Universal project installer (<= 100 lines)
    ├── README.md                    # Technical documentation
    └── rules/
        ├── config.env.example       # Paradigm configuration template
        ├── README.md                # Rules technical documentation
        ├── core/                    # Universal Core Rules
        │   ├── check-comments.sh    # Zero Inline Comments
        │   ├── check-lines.sh       # Maximum Lines per File & Layout Tolerance
        │   └── check-syntax-lint.sh # Syntax Integrity & Static Analysis
        ├── frontend/                # Frontend & Design System Paradigms
        │   ├── check-component-based.sh  (Master Router)
        │   ├── check-design-system.sh    (Global Color Tokens & Anti-Train-Track)
        │   ├── check-blade-components.sh (Laravel Blade: Standard & Atomic)
        │   ├── check-atomic-blade.sh     (Legacy wrapper)
        │   ├── check-component-react.sh  (React / Next.js)
        │   ├── check-component-svelte.sh (Svelte / SvelteKit)
        │   └── check-component-flutter.sh (Flutter)
        ├── architecture/            # Architecture Paradigms
        │   ├── check-architecture.sh     (Master Router)
        │   ├── check-mvc.sh              (Model-View-Controller)
        │   ├── check-modular.sh          (Modular / Feature-First)
        │   ├── check-service-layer.sh    (Thin Controller + Service)
        │   └── check-microservices.sh    (Container & Health Probe)
        └── security/                # Universal ISO Compliance
            └── check-iso-compliance.sh   (ISO 27001, 27701, and 25010)
```

---

## License

This repository is licensed under the [MIT](LICENSE) License.
