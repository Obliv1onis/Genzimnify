<img src="assets/genzimnify-mark.svg" width="88" alt="Genzimnify logo">

# Genzimnify

**A native programming language with Gen Z syntax. If it vibes, it runs.**

Genzimnify is a standalone programming language with a native runtime written in
Nim. A Genzimnify program is called a **vibe**. Running it is **vibing**. Errors
are **cap**. Debugging is **checking the vibe**. Since 2.0, normal execution does
not generate Python or require Python to be installed.

```gzim
for real i up in vibes(1, 101):
    vibecheck i % 15 == 0:
        yap("FizzBuzz")
    or i % 3 == 0:
        yap("Fizz")
    or i % 5 == 0:
        yap("Buzz")
    otherwise:
        yap(i)
```

## Quick start

Install the release runtime on macOS, Ubuntu, or Kali Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/Obliv1onis/Genzimnify/master/scripts/install.sh | sh
gzim examples/fizzbuzz.gzim
```

On Windows 10+, run the PowerShell installer:

```powershell
irm https://raw.githubusercontent.com/Obliv1onis/Genzimnify/master/scripts/install.ps1 | iex
```

See the [full documentation](https://obliv1onis.github.io/Genzimnify/) for
Homebrew, manual installation, the language guide, and tooling setup.

## CLI

```sh
gzim <file.gzim> [args]       # run directly in the native runtime
gzim run <file.gzim> [args]   # explicit spelling of the same command
gzim check <file.gzim>        # parse + semantic vibecheck only
gzim repl                     # native interactive vibe loop
gzim init                     # create main.gzim + gzim.toml
gzim add <name> <source>      # add a Git or local-path package
gzim install                  # restore packages from gzim.toml
gzim packages                 # list project packages
gzim remove <name>            # remove a project package
gzim doctor                   # show runtime/platform information
gzim emit-python <file.gzim>  # optional interoperability export
```

## The language

File extension is `.gzim`. Single-line comments start with `#`; multi-line
comments are `#[[ ... ]]#`. Statements end with a newline; `fr` is an optional
explicit terminator (and lets several statements share a line). A colon opens a
block; indentation closes it.

### Keywords

| Genzimnify      | Python      | Genzimnify        | Python        |
|-----------------|-------------|-------------------|---------------|
| `let` / `lock`  | decl / const| `vibe`            | `while`       |
| `be` (`be+`…)   | `=` (`+=`…) | `for real … up in`| `for … in`    |
| `nocap` / `cap` | `True` / `False` | `dip` / `next` | `break` / `continue` |
| `ghost`         | `None`      | `deadass`         | `pass`        |
| `both` / `either` / `aint` | `and` / `or` / `not` | `cook` | `def` |
| `same as` / `nah` | `==` / `!=` | `send it` / `drop` | `return` / `yield` |
| `literally` / `aint literally` | `is` / `is not` | `call up … yo` | call |
| `up in` / `aint up in` | `in` / `not in` | `clique` / `new` / `fam` / `ancestor` | `class` / `__init__` / `self` / `super` |
| `vibecheck` / `or` / `otherwise` | `if` / `elif` / `else` | `pull up` / `outta` | `import` / `from` |
| `f_around` / `find_out` / `no_matter_what` | `try` / `except` / `finally` | `throw shade` | `raise` |
| `roll with` | `with` | `on timing` / `wait up` | `async` / `await` |
| `mini vibe` | `lambda` | `fit check` / `fit` | `match` / `case` |
| `worldwide` / `localish` | `global` / `nonlocal` | `cancel` / `on god` | `del` / `assert` |

### Types & collections

`num` (int), `drip` (float), `text` (str), `truth` (bool), `ghost` (None);
`stack` (list), `map` (dict), `squad` (set), `crew` (tuple).

Type hints: `let x be 5 as num`, `stack[num]` → `list[int]`,
`map[text, num]` → `dict[str, int]`, `num or text` → `int | str`,
`num?` → `int | None`, `whatever` → `Any`. Functions: `cook add(a as num, b as num) gives num:`.

### Function calls

Calls are expressions wrapped in `call up … yo`:

```gzim
yap(call up add(4, 3) yo)
let n be call up how many(stack) yo
```

### Highlights

- f-strings: `yap(glow"{fam.name} says woof")`
- comprehensions: `let evens be [x for real x up in vibes(10) sus x % 2 == 0]`
- generators: `drop n` inside a `cook` (bare `drop` yields `None`)
- classes, inheritance, `ancestor.new(fam, ...)` → `super().__init__(...)`
- exceptions: `f_around` / `find_out BadVibe as e` / `no_matter_what`
- pattern matching: `fit check x:` / `fit 1:` / `otherwise:`
- context managers: `roll with unlock("file.txt") as f:`
- async: `on timing cook fetch():`, run with `call up timing.run(fetch()) yo`

### Native modules & exceptions

The native runtime implements `math`, `system`, `luck`, `clock`, `timing`,
`json`, `path`, and `encoding`
natively, plus relative imports of local `.gzim` modules. Native exception
types include `L`, `BadVibe`, `WrongType`, `OutOfPocket`, `Ghosted`,
`SplitByZero`, `NoPullUp`, `CapDetected`, and `StopTheCap`.

## Optional Python library bridge

The native core still has no Python dependency. When Python interoperability is
useful, import through the explicit `py.` namespace:

```gzim
pull up py.math as pymath
outta py.json pull up dumps

yap(call up pymath.sqrt(81) yo)
yap(call up dumps({"ready": nocap}, sort_keys be nocap) yo)
```

Third-party packages work the same way when installed in the selected Python
environment, including JSON-compatible NumPy scalar and array results. Each
bridge call is isolated; normal programs that never import `py.*` never start or
require Python.

## Projects and packages

`gzim init` creates a `gzim.toml` manifest. Dependencies can point at a Git URL,
an optional `#tag`/`#branch`/`#commit`, or a local directory:

```sh
gzim add cool https://github.com/example/cool.git#v1.0.0
gzim add local ../my-local-package
gzim install
```

Packages are restored to `.gzim/packages/` and imported with the normal
`pull up cool` syntax. Resolved Git commits are stored in `gzim.lock`; commit
the manifest and lockfile, but leave the package cache untracked.

## Architecture (in Nim, under `src/genzimnify/`)

1. `lexer.nim`, tokens, INDENT/DEDENT stack, `fr`, multi-word keywords
2. `parser.nim`, recursive descent statements + Pratt expressions
3. `ast.nim`, variant AST nodes
4. `semantic.nim`, the vibecheck: scoping, locks, mis-scoped slang
5. `runtime.nim`, native values, scopes, calls, cliques, modules, and execution
6. `emit.nim`, optional Python interoperability emitter + source map
7. `cli.nim`, run / check / repl / init / doctor / export

Semantic rules enforced at compile time: reassignment requires a prior `let`,
`lock` vars can't be rebound, `send it` only inside `cook`, `dip`/`next` only
inside loops, `fam` only inside clique methods, `wait up` only inside
`on timing cook`, `drop` marks generators.

## Browser IDE (`studio/`)

Genzimnify Studio is a static, local-first IDE in the repository's `studio/`
folder. It can be hosted by any static web provider and includes live
diagnostics, syntax highlighting, line numbers, code completion, a
generated-Python view, examples, import/export, share links, themes, find,
formatting, keyboard shortcuts, autosave, and a resizable console/problems
panel. The `docs/` folder contains the full GitHub Pages documentation site.

```sh
# rebuild the in-browser transpiler (Nim -> JS) after touching the core:
nim js -d:release --out:studio/transpiler.js src/genzimnify/web.nim

# then just open it:
open studio/index.html     # or: python3 -m http.server -d studio
```

The current browser Studio remains a separate web preview that uses the
JavaScript transpiler and Pyodide. The installable `gzim` tool is the
authoritative native runtime and has no Python dependency.

## Tooling: LSP + Zed extension

### gzim-lsp (language server)

Build with `nim c -o:build/gzim-lsp src/gzimlsp.nim` (or `nimble build`). Speaks
JSON-RPC/LSP over stdio and provides:

- **Diagnostics**, parse + semantic cap, published live as you type
- **Hover**, slang keyword docs (with the Python equivalent), variable/cook/clique
  signatures, `fam`/`ancestor` explainers
- **Go-to-definition**, jump to `let` / `cook` / `clique` / param declarations
- **Completion**, all slang keywords, builtins, modules + file-local decls
- **Document symbols**, outline of cooks, cliques and variables

```sh
tests/lsp_test.sh   # scripted end-to-end protocol test
```

### Zed extension (`zed-genzimnify/`)

```
zed-genzimnify/
├── extension.toml                    # extension + grammar + language + server manifest
├── Cargo.toml / src/lib.rs           # wasm glue: locates gzim-lsp for Zed
├── languages/genzimnify/
│   ├── config.toml                   # .gzim files -> Genzimnify language
│   └── highlights.scm                # tree-sitter highlight queries
└── grammars/genzimnify/
    ├── grammar.js                    # the tree-sitter grammar
    ├── tree-sitter.json
    └── src/{parser.c,scanner.c,...}   # generated parser + external scanner
                                      # (NEWLINE/INDENT/DEDENT + glow f-strings)
```

Install as a dev extension: Zed → command palette → `zed: install dev extension`
→ select the `zed-genzimnify` folder. Zed compiles the tree-sitter grammar to
wasm and registers the language for `.gzim` files; the extension's Rust glue
spawns `gzim-lsp` from your PATH for diagnostics/hover/completion/navigation.

Build `gzim-lsp` first and keep it on PATH (e.g. `~/.local/bin`), otherwise
Zed will error when it tries to start the server.

To regenerate the parser after editing `grammar.js`:

```sh
cd grammars/genzimnify && tree-sitter generate
cp src/parser.c src/scanner.c src/node-types.json src/grammar.json \
   ../../zed-genzimnify/grammars/genzimnify/src/
```

## Tests

```sh
tests/run_tests.sh
tests/regression_test.sh
tests/lsp_test.sh
```

## v1.1

- Fixed multiline string emission and nested function scope validation.
- Invalid assignment targets, malformed try/match blocks, invalid parameter
  lists, and misordered or duplicate call arguments now fail at compile time.
- LSP tests are portable and no longer depend on the original author's path.
- The browser playground became Genzimnify Studio and now lives in `studio/`.

## v2.0

- Added a standalone native runtime; `gzim file.gzim` no longer invokes Python.
- Added native values, collections, functions, generators, cliques, exceptions,
  local modules, files, and standard modules.
- Added Windows, macOS (Apple Silicon and Intel), Ubuntu, and Kali release builds.
- Added shell, PowerShell, and Homebrew installation paths.
- Rebuilt `docs/` as a searchable language documentation site.

## v2.1

- Added explicit optional Python imports through `py.*`, including
  positional and keyword arguments plus native value conversion.
- Added `gzim.toml` projects and Git/local-path package commands.
- Added native `json`, `path`, and `encoding`
  standard-library modules.

## Notes & limits

- Same-quote nesting inside `glow` strings is unsupported; use mixed quotes.
- Comparison chains are evaluated left-associatively; write explicit `both` chains.
- The 2.1 timing API is cooperative; a full native event loop is planned.
- Python is only required if you explicitly run output from `gzim emit-python`.
- Python is also required when a program explicitly imports a `py.*` module.

---

**Genzimnify**, because code can be serious without sounding serious.
