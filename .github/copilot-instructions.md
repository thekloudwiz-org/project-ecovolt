<!--
  Lightweight Copilot instructions for the `project-ecovolt` repository.
  Generated: 2025-11-21
  Notes: This project currently contains only a `README.md`. Update this file
  when the repository adds code, CI, or other language-specific files.
-->

# Copilot / AI Agent Instructions

Summary
- This repository currently contains only a `README.md` and no build, test,
  or source code files. The default branch is `main` and active branch is `dev`.

What to do first
- Inspect `README.md` and the repository root to discover added files.
- If you find language files (e.g. `package.json`, `pyproject.toml`, `go.mod`),
  stop and summarize the language, package manager, and expected build/test commands.
- If no code files exist, propose a minimal project scaffold (ask for permission
  before creating files) and list recommended files to add (CI, linter, test harness).

Repository-specific conventions discovered
- Current repo state: minimal; no detected code structure to follow.
- Branching: the repo uses `dev` for current work and `main` as the default.

If you add or modify code
- When introducing a new language or framework, update this file with:
  - language and runtime (e.g. Node.js 18, Python 3.11)
  - build and test commands (exact CLI invocations)
  - any required environment variables or secret names
- Example: if you add a Node project with `package.json`, note `npm ci` and
  `npm test` as canonical commands and where to run them (local vs CI).

PR and commit guidance for AI-generated changes
- Keep commits small and focused, with messages describing intent.
- For code changes, open a PR targeting `dev` and include a short summary that:
  - explains why the change is needed
  - lists files changed
  - provides manual test steps (or commands) to verify behavior

How to help the human developer
- If repository lacks structure, show 2 concrete scaffold suggestions (e.g.,
  a minimal Node app or a minimal Python package) and the exact files to add.
- When unsure, ask one clarifying question before making large changes.

Where to look next (priority)
- `README.md` (root): current project description and initial guidance.
- `.github/` (if present): CI workflows and other repository automation.

Housekeeping for future agents
- Keep this file succinct and always update with concrete commands discovered
  from new manifest files (examples: `package.json` -> `npm ci`, `pyproject.toml` -> `pip install -r requirements.txt`).
- Do not add generic advice — only document patterns and commands that are
  discoverable from files in the repo.

If anything is unclear or you expect certain frameworks/tools to be present,
ask the repository maintainer before making assumptions.

-- End of file --
