---
name: bugbot
description: >-
  Automated Bugbot-style code reviewer for git diffs, staged changes, and commits.
  Activate when the user asks to run bugbot, review changes/diff/commit/PR, or check
  for bugs, regressions, and security issues before committing or pushing.
---

# Bugbot Code Review

Perform a focused, high-signal defect review of repository changes without style nitpicks.

## 1. Determine Review Target

Select the target diff based on the user's request (defaulting to the first non-empty source in order):

1. Explicit commit, range, or branch requested by user (e.g. `git show <sha>` or `git diff <base>..HEAD`).
2. Unstaged + staged changes (`git status --short`, `git diff`, `git diff --cached`).
3. Latest commit (`git show HEAD`) when the working tree is clean.

Always respect workspace shell prefix rules (e.g. `rtk git ...` if required by project rules).

## 2. Inspect Context

- Read the full diff first.
- Read surrounding code in modified files (and callers/callees or configs) before reporting a bug.
- For large diffs spanning many files or security-sensitive areas, spawn read-only subagents (`TypeName: research`, `Model: inherit`) in parallel to audit distinct angles:
  1. **Logic & Regressions**: broken conditionals, null/undefined dereferences, wrong types, off-by-one, unhandled edge cases, broken imports/routes/env keys.
  2. **Security & Auth**: missing auth/authorization checks, IDOR, injection (SQL/XSS/command), mass assignment, leaked secrets/tokens, unsafe file handling.
  3. **Data & Performance**: N+1 queries, missing transactions, race conditions, destructive migrations, unbounded loops.

## 3. Filtering Rules (High Signal Only)

- Report **ONLY** real bugs, regressions, security vulnerabilities, broken configurations, or clear runtime/data risks.
- Do **NOT** report formatting, naming preferences, or speculative refactors.
- Verify every finding against actual code before including it; never guess.

## 4. Output Format

If no real defects are found:
- State **"Bugbot: No bugs found"** followed by a concise 1-2 line summary of the scope reviewed.

If defects are found, sort by severity (`Critical`, `High`, `Medium`) and list each finding:

- **Location**: clickable file and line link
- **Bug**: concrete explanation of what breaks and under what scenario
- **Fix**: exact recommended code or configuration change

End with a brief **Verdict**: `Safe to push` or `Fix before push (N blocking issues)`.
