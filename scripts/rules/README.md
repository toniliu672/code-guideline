# Rules Audit Modules & Software Engineering Paradigms

This directory houses modular code quality and architectural compliance audit modules across 4 primary domains: **Core**, **Frontend**, **Architecture**, and **Security**. All modules can be orchestrated and toggled via the Master Runner `guidelines.sh` or through `config.env`.

---

## 1. Core Modules (`core/`)
Universal foundation rules applicable to all programming languages and stacks:

| Script | Purpose & Rule Enforced |
| :--- | :--- |
| **`check-comments.sh`** | Enforces **Zero Inline Comments** inside function bodies and template logic (prevents commented-out dead code and clutter). |
| **`check-lines.sh`** | Enforces a maximum threshold of **100 Lines per File** (Single Responsibility Principle) on changed files in `git status`. |

---

## 2. Frontend Paradigms (`frontend/`)
Component-based modular architecture and design system compliance checks:

| Script | Framework / Approach | Inspection Focus |
| :--- | :--- | :--- |
| **`check-component-based.sh`** | Master Router | Automatically detects or routes frontend audits according to the configured approach. |
| **`check-design-system.sh`**   | Design System & Styling | **Global Color Tokens & Anti-Train-Track**: Enforces colors defined globally (`app.css`/`globals.css`), flags arbitrary color utilities (`bg-[#...]`, `text-[#...]`), and blocks long monolithic class-soup strings in page files. |
| **`check-atomic-blade.sh`**     | Laravel Blade | Enforces **Atomic Design** (`atoms`, `molecules`, `organisms`) and forbids raw HTML elements (`<form>`, `<input>`, `<button>`) outside atoms. |
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

## 4. Security & Data Privacy (`security/`)

| Script | Security Standard | Inspection Focus |
| :--- | :--- | :--- |
| **`check-security.sh`** | General Security | Prevents storing sensitive files in public disks, ensures sensitive model attributes are hidden (`$hidden`), validates upload MIME types, checks `.env` exposure, and blocks leftover debug calls (`dd`, `dump`). |
| **`check-iso-security.sh`** | ISO 27001 / 27701 | Executes general security audit plus authorization protection and audit trail checks. |

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
