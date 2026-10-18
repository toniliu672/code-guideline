# AI Agent Instructions & Guidelines

As an AI coding agent working in this repository, you MUST strictly adhere to the following rules:

## 1. Mandatory Audit Verification
Before completing any task or proposing changes, ALWAYS run:
```bash
rtk bash guidelines.sh
# or:
bash guidelines.sh
```
All checks must pass 100% before concluding your turn.

## 2. Universal Core Rules
- **Zero Inline Comments**: Strictly forbidden to write comments (`//`, `<!--`, `{{--`) inside function bodies or template logic. Code must be self-explanatory.
- **Max 100 Lines per File**: No business logic, controller, service, or component file may exceed 100 lines. Break large units following Single Responsibility Principle (SRP). Structural layouts, database migrations, and configs are granted up to 250 lines to prevent confusing over-fragmentation.
- **Syntax & Type Safety**: Code must be free of syntax errors and static analysis type violations. In PHP/Laravel, pass exception class strings (e.g. `throw_if($cond, CustomException::class, 'message')`) instead of instantiating `new Exception()` to prevent PHP0406 diagnostic errors.

## 3. Frontend & Design System Standards
- **Global Color Tokens Only (Closed Canonical Allowlist)**: ONLY these semantic color tokens are permitted in `@theme` (`--color-*`) and utility classes: `background`, `foreground`, `surface` (`-muted`, `-elevated`, `-alt`), `card` (`-foreground`), `popover` (`-foreground`), `primary` (`-foreground`, `-soft`, `-hover`), `secondary` (`-foreground`, `-soft`), `muted` (`-foreground`), `accent` (`-foreground`, `-soft`), `success` (`-foreground`, `-soft`), `warning` (`-foreground`, `-soft`), `danger`/`destructive` (`-foreground`, `-soft`), `info` (`-foreground`, `-soft`), `border` (`-subtle`, `-strong`), `input`, and `ring`. Strictly forbidden to use hardcoded hex/rgb, raw Tailwind palettes (`zinc`, `sky`), numeric shades (`-50`..`-950`), `dark:text-*`/`dark:bg-*` in views, cross-role tokens (`text-card`, `bg-foreground`), or invented synonym aliases (`tone`, `pri`, `indi`, `mystic`, `royal`, `ruby`, `ink`).
- **Anti-Train-Track Classes**: Do not write 10+ utility classes or 100+ character class strings directly inside page files (`page.tsx`, `+page.svelte`, views). Extract styling into reusable modular components.
- **No Class Conflicts**: Avoid mutually exclusive utility classes on the same element (e.g. `hidden flex`, `text-left text-right`).
- **Canonical Tailwind Classes**: Always prefer standard Tailwind scale utilities over arbitrary pixel values when a canonical class exists (e.g. use `h-80` instead of `h-[320px]`, `p-4` instead of `p-[16px]`, `w-full` instead of `w-[100%]`).
- **Component-Based Modularity**: Keep pages clean and declarative; delegate UI styling to modular components.
  - **Laravel Blade**: Place reusable UI components in `resources/views/components/` (e.g., `components/admin/` for admin UI and `components/` for shared UI) and use layout-based templates in `resources/views/layouts/`. Page views must compose `<x-...>` component tags, extend layouts, and never declare verbose `@php` data arrays (pass data from Controllers or use compact inline `@foreach ([['Label', $val]] as [$label, $val])`).

## 4. Architecture Standards
- Respect the architecture pattern configured in `scripts/rules/config.env` (MVC, Modular, Service Layer, or Microservices).
- Keep controllers thin and free of direct raw database queries.

## 5. Security & Cleanliness
- Never track `.env` files or hardcode secrets/credentials.
- Store sensitive uploads in private storage disks (never public).
- Remove all debug calls (`dd`, `dump`, `var_dump`, `console.log`) before finishing.

## 6. Git Protocol
- Never execute `git commit` unless explicitly commanded by the user with the keyword "commit".
- Commit messages must follow Conventional Commits format (`type(scope): summary` + bullet points).
