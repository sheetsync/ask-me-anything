# Ask

Ask is a small OCaml CLI that turns:

```sh
ask why is my dune build failing?
```

into a one-shot Codex run:

```sh
codex exec -m gpt-5.4 --ephemeral --skip-git-repo-check -c 'model_reasoning_effort="medium"' "why is my dune build failing?"
```

It is intentionally boring in the good way: one command, a small config file, and no shell-string gymnastics.

Bash supports the natural form:

```sh
ask why is my dune build failing?
```

The shell passes those words as separate arguments, and Ask joins them into one prompt. Quote or escape text only when your question includes shell syntax such as `&&`, `|`, `>`, `*`, quotes, variables, or semicolons.

Options must come before the prompt. Ask treats the first non-option token as the beginning of the prompt, and everything after it is prompt text:

```sh
ask --model gpt-5.4-mini explain why --this is not parsed as an Ask option
```

## CLI Surface

```sh
ask [OPTIONS] [MESSAGE...]
```

Useful options:

- `--verb ask|do|review|raw`
- `--model MODEL`
- `--reasoning-effort minimal|low|medium|high|xhigh`
- `--profile PROFILE`
- `--cwd DIR`
- `--sandbox read-only|workspace-write|danger-full-access`
- `--search`
- `--image FILE`
- `--config FILE`
- `--dry-run`
- `--save-session`

The default `--verb ask` is a plain `codex exec` run using `gpt-5.4` with reasoning effort `medium`. `--verb do` also uses `codex exec`, but defaults the Codex sandbox to `workspace-write` unless you specify another sandbox. `--verb review` runs `codex exec review --uncommitted`.

If `MESSAGE` is omitted, Ask prints syntax help without calling Codex.

Piped stdin still works well as extra context when you provide a prompt:

```sh
git diff | ask summarize this patch
```

## Configuration

Ask reads YAML configuration from the first available path:

1. `--config FILE`
2. `$ASK_CONFIG`
3. `$XDG_CONFIG_HOME/ask/config.yaml`
4. `$XDG_CONFIG_HOME/ask/config.yml`
5. `~/.config/ask/config.yaml`
6. `~/.config/ask/config.yml`

Example:

```yaml
provider: codex
codex_binary: codex
default_verb: ask
model: gpt-5.4
reasoning_effort: medium
profile: null
cwd: null
sandbox: null
search: false
ephemeral: true
skip_git_repo_check: null
color: auto
codex_extra_args: []
```

Command-line options override config values.

## Development

```sh
dune build
dune runtest
dune exec ./bin/main.exe -- --dry-run explain the shape of this project
```

The public executable is `ask`; the package and repository are `ask-me-anything`.
