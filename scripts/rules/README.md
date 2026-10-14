# Rules Audit Modules & Software Engineering Paradigms

This directory houses modular code quality and architectural compliance audit modules across 4 primary domains: **Core**, **Frontend**, **Architecture**, and **Security (ISO Compliance)**. All modules can be orchestrated and toggled via the Master Runner `guidelines.sh` or through `config.env`.

---

## 1. Core Modules (`core/`)
Universal foundation rules applicable to all programming languages and stacks:

| Script | Purpose & Rule Enforced |
| :--- | :--- |
| **`check-comments.sh`** | Enforces **Zero Inline Comments** inside function bodies and template logic (prevents commented-out dead code and clutter). |
| **`check-lines.sh`** | Enforces **100 Lines per File** on logic/components (Single Responsibility Principle) with smart tolerance (up to 250 lines) for structural layouts, migrations, and configs to avoid over-fragmentation. |
| **`check-syntax-lint.sh`** | Enforces **Syntax & Type Safety**: runs `php -l`, prevents anti-pattern `throw_if` with `new Exception()`, and bridges to project static analyzers (PHPStan / Larastan / Pint). |

---

## 2. Frontend Paradigms (`frontend/`)
Component-based modular architecture and design system compliance checks:

| Script | Framework / Approach | Inspection Focus |
| :--- | :--- | :--- |
| **`check-component-based.sh`** | Master Router | Automatically detects or routes frontend audits according to the configured approach. |
| **`check-design-system.sh`**   | Design System & Styling | **Global Color Tokens, Anti-Train-Track & Class Conflicts**: Enforces colors defined globally (`app.css`/`globals.css`), flags arbitrary color utilities (`bg-[#...]`), blocks long class strings in pages, and flags conflicting Tailwind utilities (e.g. `hidden flex`, `text-left text-right`). |
| **`check-blade-components.sh`** | Laravel Blade | Enforces **Component-Based & Layout Architecture** (`standard` folder-based with admin separation or strict `atomic`). Page views compose `<x-...>` components. |
| **`check-component-react.sh`**  | React / Next.js | Enforces separation between page routes (`app/` or `pages/`) and reusable modular components in `components/`. |
| **`check-component-svelte.sh`** | Svelte / SvelteKit | Enforces separation between route files (`+page.svelte`) and component modules in `$lib/components/`. |
| **`check-component-flutter.sh`**| Flutter | Enforces extracting custom widgets to `lib/widgets/` to avoid massive monolithic widget pyramids in screens/pages. |

---

## 3. Architecture Paradigms (`architecture/`)
Structural and domain organization standards for backend and system design:

| Script | Architecture Pattern | Inspection Focus |
| :--- | :--- | :--- |
| **`check-architecture.sh`** | Master Router | Detects or routes architecture audits based on project configuration. |
| **`check-mvc.sh`** | Model-View-Controller | Enforces *Separation of Concerns*: Controllers remain thin without raw SQL queries, and Views are prohibited from running direct database queries. |
| **`check-modular.sh`** | Modular / DDD | Enforces domain feature boundaries and forbids illegal cross-module internal state mutations. |
| **`check-service-layer.sh`** | Service Layer | Enforces *Thin Controllers*: concentrates transactional and business workflows inside Service classes (`*Service`). |
| **`check-microservices.sh`** | Microservices | Validates containerization configs (`Dockerfile`), health check probe endpoints (`/health` / `/healthz`), and `.env.example` isolation. |

---

## 4. Security & ISO Standards Compliance (`security/`)

Universal software engineering standards based on international benchmarks:

| Script | Standard | 5 Audited Universal Clauses |
| :--- | :--- | :--- |
| **`check-iso-compliance.sh`** | **ISO/IEC 27001, 27701 & 25010** | **Clause 1 (ISO 27001 A.8.12)**: Data Leakage Prevention (.env & private key isolation).<br>**Clause 2 (ISO 27001 A.8.24)**: Storage Isolation (no confidential files on public disks).<br>**Clause 3 (ISO 27701 Cl.7.4)**: Data Minimization & PII Protection (password & credential masking).<br>**Clause 4 (ISO 27001 A.8.28)**: Secure Coding & Input Sanitization (mandatory file upload MIME validation).<br>**Clause 5 (ISO 25010 Cl.4.3)**: Maintainability & Clean Code (no leftover debug statements in production). |

---

## Custom Configuration (`config.env`)

Copy `config.env.example` to `config.env` to configure active paradigms:

```bash
cp scripts/rules/config.env.example scripts/rules/config.env
```

Configuration example for **Next.js with Shadcn / UI**:
```bash
FRONTEND_APPROACH="next"
ARCHITECTURE_APPROACH="modular"
CHECK_COLOR_TOKENS=true
CHECK_TRAIN_TRACK=true
MAX_CLASS_CHARS=100
MAX_CLASS_WORDS=10
```

Configuration example for **Laravel Blade (Components & Layouts)**:
```bash
FRONTEND_APPROACH="blade"
BLADE_APPROACH="standard"
ARCHITECTURE_APPROACH="mvc"
CHECK_COLOR_TOKENS=true
CHECK_TRAIN_TRACK=true
```
