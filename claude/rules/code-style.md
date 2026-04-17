# Code and Writing Style

## Writing style
- Never use em dashes. Use commas, semicolons, parentheses, or separate sentences.
- Never use causal framing ("This is because..."). State the fact directly.
- No emojis in code, comments, commit messages, or prose unless requested.
- Commit messages: imperative mood, concise, no trailing period.

## Shell command formatting
- Multi-line commands with backslash continuations are fine for readability. Only split at argument or flag boundaries, never inside a quoted string. A backslash continuation must appear outside of all quotes — breaking a quoted string across lines causes bash to treat the continuation lines as separate commands. When in doubt, print the command on a single line.
- In code blocks containing shell commands, do not indent the command itself. Keep it flush-left within the block.
