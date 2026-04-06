# Documentation Audit

Audit documentation files for accuracy against current project state.

## Scope
$ARGUMENTS — optional path or glob pattern. Defaults to all `README.md` and `CLAUDE.md` files in the repo.

## Process

For each documentation file found:

1. **Commands**: Verify every shell command or code snippet actually works or references real paths/targets
2. **File references**: Confirm every referenced file path still exists
3. **Make targets**: Cross-reference documented `make` targets against actual Makefile
4. **Architecture claims**: Check that described components, directories, and data flows match the current codebase structure
5. **Dependencies**: Verify documented dependency versions match lock files
6. **Stale sections**: Flag any section describing removed features, old workflows, or completed migration steps

## Output format

Group findings by file. For each issue:
- **File**: path
- **Line/Section**: where the issue is
- **Issue**: what is wrong
- **Suggestion**: how to fix it

End with a summary: N files audited, N issues found, N critical (blocks onboarding), N minor (cosmetic).

Do NOT make changes. Report only. The user will decide what to fix.
