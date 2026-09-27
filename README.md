<p align="center">
  <img src="assets/genzimnify-mark.svg" width="96" alt="Genzimnify logo">
</p>

<h1 align="center">Genzimnify</h1>

<p align="center">
  A native programming language with Python-like semantics and Gen Z syntax.
</p>

<p align="center">
  <a href="https://github.com/Obliv1onis/Genzimnify/actions/workflows/ci.yml"><img src="https://github.com/Obliv1onis/Genzimnify/actions/workflows/ci.yml/badge.svg" alt="Native runtime CI"></a>
  <a href="https://github.com/Obliv1onis/Genzimnify/releases/latest"><img src="https://img.shields.io/github/v/release/Obliv1onis/Genzimnify" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Obliv1onis/Genzimnify" alt="MIT license"></a>
</p>

<p align="center">
  <a href="https://obliv1onis.github.io/Genzimnify/">Documentation</a> ·
  <a href="https://obliv1onis.github.io/Genzimnify/installation.html">Installation</a> ·
  <a href="https://obliv1onis.github.io/Genzimnify/language-guide.html">Language guide</a> ·
  <a href="https://github.com/Obliv1onis/Genzimnify/releases">Releases</a>
</p>

Genzimnify is a standalone, dynamically typed programming language with a
runtime written in Nim. The `gzim` executable parses, checks, and executes
`.gzim` files directly—normal execution does not generate Python or require a
Python installation.

```gzim
cook fizzbuzz(limit as num):
    for real i up in vibes(1, limit + 1):
        vibecheck i % 15 == 0:
            yap("FizzBuzz")
        or i % 3 == 0:
            yap("Fizz")
        or i % 5 == 0:
            yap("Buzz")
        otherwise:
            yap(i)

call up fizzbuzz(100) yo
```

## Why Genzimnify?

- **Native execution:** lexer, parser, semantic checker, and interpreter ship
  in one compiled runtime.
- **Familiar semantics:** indentation-based blocks, functions, collections,
  comprehensions, classes, exceptions, matching, generators, and type hints.
- **Distinct syntax:** functions are `cook`, classes are `clique`, output is
  `yap`, and errors are `cap`.
- **Project tooling:** manifests, lockfiles, Git and local-path dependencies,
  a REPL, editor integration, and a language server.
- **Optional interoperability:** explicitly import Python libraries through
  `py.*` without making Python a dependency of ordinary programs.

## Quick start

### macOS and Linux

The shell installer supports Apple Silicon macOS, Ubuntu, and Kali Linux.
Genzimnify 2.0.2 and newer no longer publish Intel Mac binaries:

```sh
curl -fsSL https://raw.githubusercontent.com/Obliv1onis/Genzimnify/master/scripts/install.sh | sh
gzim doctor
```

### Windows

Run the PowerShell installer on Windows 10 or newer:

```powershell
irm https://raw.githubusercontent.com/Obliv1onis/Genzimnify/master/scripts/install.ps1 | iex
gzim doctor
```

Release packages include both `gzim` and `gzim-lsp`. See the
[installation guide](https://obliv1onis.github.io/Genzimnify/installation.html)
for Homebrew, manual downloads, supported architectures, and custom install
locations.

### Create a project

```sh
mkdir hello-gzim
cd hello-gzim
gzim init
gzim main.gzim
```

`gzim init` creates a starter `main.gzim` file and a `gzim.toml` project
manifest.

## Language at a glance

```gzim
# Variables and interpolation
let name be "world"
lock language be "Genzimnify"
yap(glow"Hello, {name} from {language}")

# Collections and comprehensions
let numbers be [1, 2, 3, 4, 5]
let evens be [n for real n up in numbers sus n % 2 == 0]

# Functions
cook add(a as num, b as num) gives num:
    send it a + b

# Classes
clique Greeter:
    cook new(fam, greeting):
        fam.greeting be greeting

    cook greet(fam, who):
        send it glow"{fam.greeting}, {who}"

let greeter be call up Greeter("yo") yo
yap(call up greeter.greet("chat") yo)
```

Common syntax:

| Genzimnify | Meaning | Python equivalent |
|---|---|---|
| `let x be 1` / `lock x be 1` | Mutable / immutable binding | `x = 1` |
| `nocap`, `cap`, `ghost` | Boolean and empty values | `True`, `False`, `None` |
| `vibecheck` / `or` / `otherwise` | Conditional branches | `if` / `elif` / `else` |
| `for real x up in values` | Iteration | `for x in values` |
| `vibe condition` | Loop while true | `while condition` |
| `cook` / `send it` | Function / return | `def` / `return` |
| `clique` / `fam` / `ancestor` | Class / self / super | `class` / `self` / `super` |
| `pull up` / `outta … pull up` | Import | `import` / `from … import` |
| `f_around` / `find_out` | Exception handling | `try` / `except` |
| `call up function() yo` | Call expression | `function()` |

The language also supports `glow` strings, generators, comprehensions,
pattern matching, context managers, async syntax, global/nonlocal bindings,
and optional type annotations. The
[language guide](https://obliv1onis.github.io/Genzimnify/language-guide.html)
contains the complete reference.

## Command-line interface

| Command | Purpose |
|---|---|
| `gzim app.gzim [args]` | Run a program in the native runtime |
| `gzim run app.gzim [args]` | Explicit form of the run command |
| `gzim check app.gzim` | Parse and semantically check without running |
| `gzim repl` | Start an interactive session |
| `gzim init` | Create `main.gzim` and `gzim.toml` |
| `gzim add <name> <source>` | Add a Git or local dependency |
| `gzim install` | Restore dependencies from `gzim.toml` |
| `gzim packages` | List project dependencies |
| `gzim remove <name>` | Remove a dependency |
| `gzim doctor` | Show runtime and platform information |
| `gzim emit-python app.gzim` | Export Python for interoperability |

See the [CLI reference](https://obliv1onis.github.io/Genzimnify/cli.html) for
exit behavior and command details.

## Ecosystem

### Projects and packages

Dependencies live in `gzim.toml` and can point to Git repositories or local
directories:

```sh
gzim add cool https://github.com/example/cool.git#v1.0.0
gzim add local ../my-local-package
gzim install
```

Packages are installed under `.gzim/packages/`. Git revisions are recorded in
`gzim.lock`, so applications can reproduce the same dependency state. Commit
`gzim.toml` and `gzim.lock`; keep `.gzim/` out of version control.

Read the [package guide](https://obliv1onis.github.io/Genzimnify/packages.html)
for the manifest format and import rules.

### Optional Python interoperability

Python libraries are available only through the explicit `py.` namespace:

```gzim
pull up py.math as pymath
outta py.json pull up dumps

yap(call up pymath.sqrt(81) yo)
yap(call up dumps({"ready": nocap}, sort_keys be nocap) yo)
```

The bridge supports positional and keyword arguments plus JSON-compatible value
conversion. NumPy scalars and arrays are converted through `item()` and
`tolist()`. Each bridge call is isolated; a program that never imports `py.*`
never starts or requires Python.

See [Python interoperability](https://obliv1onis.github.io/Genzimnify/python-interop.html)
for supported conversions and limitations.

### Native standard library

The runtime includes `math`, `system`, `luck`, `clock`, `timing`, `json`,
`path`, and `encoding`, plus relative imports of local `.gzim` modules. The
[standard-library reference](https://obliv1onis.github.io/Genzimnify/stdlib.html)
lists the available functions.

## Tooling

### Language server and Zed

`gzim-lsp` communicates over stdio and provides diagnostics, hover information,
completion, go-to-definition, and document symbols. Release archives include
the server alongside the runtime.

The repository also contains a Zed development extension under
[`zed-genzimnify/`](zed-genzimnify). Build `gzim-lsp`, place it on `PATH`, then
use **Zed: Install Dev Extension** and select that directory.

### Genzimnify Studio

[`studio/`](studio) contains a static, local-first browser IDE with diagnostics,
syntax highlighting, completion, examples, import/export, share links,
formatting, autosave, and a resizable console. It is a separate browser preview
powered by a JavaScript transpiler and Pyodide; the installable `gzim` runtime
remains the authoritative native implementation.

Rebuild the browser transpiler after changing the language core:

```sh
nim js -d:release --out:studio/transpiler.js src/genzimnify/web.nim
```

<details>
<summary><strong>Build from source and explore the architecture</strong></summary>

## Build from source

Requirements: Nim 2.0 or newer and Nimble.

```sh
git clone https://github.com/Obliv1onis/Genzimnify.git
cd Genzimnify
nimble build -d:release
./gzim doctor
```

The main implementation lives in `src/genzimnify/`:

| Component | Responsibility |
|---|---|
| `lexer.nim` | Tokens, indentation, comments, and multi-word syntax |
| `parser.nim` | Recursive-descent statements and Pratt expressions |
| `ast.nim` | Syntax tree node definitions |
| `semantic.nim` | Scope, binding, and control-flow validation |
| `runtime.nim` | Native values, calls, modules, and execution |
| `packages.nim` | Manifests, lockfiles, and dependency installation |
| `emit.nim` | Optional Python export backend |
| `lsp.nim` | Language Server Protocol implementation |
| `cli.nim` | Command-line interface |

The broader design is documented in [`Design_Doc.md`](Design_Doc.md).

</details>

## Tests

```sh
tests/run_tests.sh       # language, runtime, bridge, and package tests
tests/regression_test.sh # negative semantic cases
tests/lsp_test.sh        # end-to-end LSP protocol test
```

<details>
<summary><strong>Current limitations</strong></summary>

<br>

- Same-quote nesting inside `glow` strings is unsupported; use mixed quotes.
- Comparison chains are left-associative; use explicit `both` expressions when
  combining comparisons.
- `timing` is currently cooperative and does not provide a full event loop.
- `emit-python` and `py.*` imports require Python; ordinary native execution
  does not.

</details>

## License

Genzimnify is available under the [MIT License](LICENSE).
