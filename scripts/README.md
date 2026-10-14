# Scripts Guidelines & Code Rules Engine

This directory contains the orchestrator audit runner and compliance modules enforcing architectural standards, clean code, and application security across **diverse, multi-stack codebases**.

## Directory & Script Index

| Script | Purpose & Description |
| :--- | :--- |
| **`guidelines.sh`** | **Master Runner** orchestrator executing core, frontend, architecture, and security audits. |
| **`install.sh`** | One-click installer script to copy the guidelines suite and configure Git Pre-Commit Hooks in any target project. |
| **`rules/config.env.example`**| Configuration template for setting active paradigms (`FRONTEND_APPROACH`, `ARCHITECTURE_APPROACH`, styling limits, etc.). |
| **`rules/core/`** | Foundation rules: `check-comments.sh` (zero inline comments), `check-lines.sh` (max 100 lines). |
| **`rules/frontend/`** | Frontend paradigm modules: `check-component-based.sh` (router), `check-design-system.sh` (global color tokens & anti-train-track classes), `check-atomic-blade.sh`, `check-component-react.sh`, `check-component-svelte.sh`, `check-component-flutter.sh`. |
| **`rules/architecture/`** | Architecture pattern modules: `check-architecture.sh` (router), `check-mvc.sh`, `check-modular.sh`, `check-service-layer.sh`, `check-microservices.sh`. |
| **`rules/security/`** | Security modules: `check-security.sh`, `check-iso-security.sh`. |

## How to Use

### 1. Run Complete Audit Suite
```bash
# Using RTK (Rust Token Killer - recommended):
rtk bash scripts/guidelines.sh

# Or standard bash:
bash scripts/guidelines.sh
```

### 2. Run by Domain
```bash
bash scripts/guidelines.sh core        # Foundation rules only (zero comments & 100 lines)
bash scripts/guidelines.sh frontend    # Frontend component & design system audit
bash scripts/guidelines.sh design      # Color tokens & anti-train-track classes audit
bash scripts/guidelines.sh arch        # System architecture audit
bash scripts/guidelines.sh security    # Security & data privacy audit
```

### 3. Test Specific Paradigms via CLI
```bash
bash scripts/guidelines.sh --frontend=flutter --arch=modular
bash scripts/guidelines.sh --frontend=next --arch=modular
bash scripts/guidelines.sh --frontend=blade --arch=mvc
```

### 4. Install into Another Project
```bash
bash scripts/install.sh /path/to/target-project
```
