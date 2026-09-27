## gzim, the native Genzimnify CLI.
## run / check / repl / init / emit-python.

import std/[os, strutils, syncio, tables]
import lexer, parser, semantic, emit, runtime, errors, packages, version

const Version* = GenzimnifyVersion

# ------------------------------------------------------------------ compile

proc compileSource*(src: string, filename: string): tuple[code: string, maps: string] =
  let toks = lex(src)
  let parsed = parseProgram(toks)
  let issues = checkProgram(parsed.program)
  if issues.len > 0:
    var msg = ""
    for iss in issues:
      msg.add filename & ":" & $iss.line & ":" & $iss.col & ": cap: " & iss.msg & "\n"
    raise newGzimError(msg.strip(), issues[0].line, issues[0].col)
  let em = emitProgram(parsed.program, parsed.usedAny)
  result = (em.render(), em.renderMaps())

proc failHard(msg: string): void =
  stderr.writeLine("cap! " & msg)
  quit(1)

proc requireNoArgs(command: string, args: seq[string]) =
  if args.len > 0:
    failHard(command & " doesn't take arguments")

proc compileFile(path: string): tuple[code: string, maps: string] =
  if not fileExists(path):
    failHard("no file called " & path & ", that's ghost")
  let src = readFile(path)
  try:
    result = compileSource(src, path)
  except GzimError as e:
    failHard(e.msg)

# ------------------------------------------------------------------ commands

proc cmdRun(path: string, extraArgs: seq[string]) =
  if not fileExists(path):
    failHard("no file called " & path & ", that's ghost")
  try:
    quit(runSource(readFile(path), path, extraArgs))
  except GzimError as e:
    failHard(e.msg)

proc cmdEmitPython(path: string) =
  let (code, maps) = compileFile(path)
  let outPath = splitFile(path).dir / (splitFile(path).name & ".py")
  writeFile(outPath, code)
  writeFile(outPath & ".gzmap", maps)
  echo "exported " & outPath & " for Python interoperability"

proc cmdCheck(path: string) =
  if not fileExists(path):
    failHard("no file called " & path & ", that's ghost")
  try:
    discard parseChecked(readFile(path), path)
  except GzimError as e:
    failHard(e.msg)
  echo "no cap, " & path & " passes the vibecheck fr"

const InitSample = """
# main.gzim, welcome to the vibe
cook greet(name, greeting be "hey"):
    send it glow"{greeting} {name}!" fr

yap(call up greet("world") yo)
"""

proc cmdInit() =
  if fileExists("main.gzim"):
    echo "main.gzim already exists, it's already vibing"
  else:
    writeFile("main.gzim", InitSample)
    echo "dropped main.gzim, let's get this bread"
  initManifest(getCurrentDir())
  echo "project manifest: gzim.toml"

proc packageFail(action: proc()) =
  try: action()
  except PackageError as error: failHard(error.msg)

proc cmdInstall() =
  packageFail(proc() =
    let count = installDependencies(getCurrentDir())
    echo $count & " packages ready fr")

proc cmdAdd(rest: seq[string]) =
  if rest.len != 2: failHard("add needs a name and source: gzim add <name> <git-url-or-path>")
  packageFail(proc() =
    addDependency(getCurrentDir(), rest[0], rest[1])
    echo "added " & rest[0] & " fr")

proc cmdRemove(rest: seq[string]) =
  if rest.len != 1: failHard("remove needs a package name: gzim remove <name>")
  packageFail(proc() =
    removeDependency(getCurrentDir(), rest[0])
    echo "removed " & rest[0] & " fr")

proc cmdPackages() =
  packageFail(proc() =
    let manifest = loadManifest(getCurrentDir())
    if manifest.dependencies.len == 0: echo "no packages yet"
    for name, source in manifest.dependencies: echo name & "  " & source)

proc cmdRepl() =
  echo "gzim repl " & Version & " native runtime, blank line to run, ctrl-d to dip"
  let session = newReplSession("<repl>")
  var chunk: seq[string] = @[]
  var line: string
  while true:
    stdout.write(if chunk.len > 0: "...> " else: "vibe> ")
    flushFile(stdout)
    if not stdin.readLine(line):
      break
    if line.strip() == "":
      if chunk.len == 0:
        continue
      let src = chunk.join("\n")
      try:
        discard session.runReplChunk(src)
      except GzimError as e:
        echo "cap! " & e.msg
      chunk.setLen(0)
    else:
      chunk.add line

proc showHelp() =
  echo """
gzim, the native Genzimnify runtime. Gen Z syntax, zero Python required.

usage:
  gzim <file.gzim> [args]       run a vibe directly
  gzim run <file.gzim> [args]   same thing, spelled out
  gzim check <file.gzim>        parse + semantic vibecheck only
  gzim repl                     start the native vibe loop
  gzim init                     drop a starter main.gzim
  gzim add <name> <source>      add a Git or local-path dependency
  gzim install                  install dependencies from gzim.toml
  gzim remove <name>            remove a dependency
  gzim packages                 list project dependencies
  gzim doctor                   show runtime and platform information
  gzim emit-python <file.gzim>  optional Python interoperability export
  gzim help                     this menu

a Genzimnify program is called a vibe. running it is vibing.
errors are cap. debugging is checking the vibe.
"""

proc cmdDoctor() =
  echo "gzim " & Version
  echo "runtime: native Nim (Python-free)"
  echo "platform: " & hostOS & "/" & hostCPU
  echo "status: ready to vibe"

proc main*() =
  let params = commandLineParams()
  if params.len == 0:
    showHelp()
    quit(0)

  var cmd: string
  var rest: seq[string]
  if params[0] in ["run", "build", "emit-python", "check", "repl", "init", "add", "install", "remove", "packages", "doctor", "help", "--help", "-h",
                   "--version", "-v"]:
    cmd = params[0]
    rest = params[1 .. ^1]
  elif params[0].endsWith(".gzim"):
    cmd = "run"
    rest = params
  else:
    showHelp()
    quit(1)

  case cmd
  of "run":
    if rest.len == 0:
      failHard("run needs a file, gzim run <file.gzim>")
    cmdRun(rest[0], rest[1 .. ^1])
  of "build", "emit-python":
    if rest.len != 1:
      failHard("emit-python needs a file, gzim emit-python <file.gzim>")
    cmdEmitPython(rest[0])
  of "check":
    if rest.len != 1:
      failHard("check needs a file, gzim check <file.gzim>")
    cmdCheck(rest[0])
  of "repl":
    requireNoArgs("repl", rest)
    cmdRepl()
  of "init":
    requireNoArgs("init", rest)
    cmdInit()
  of "add":
    cmdAdd(rest)
  of "install":
    requireNoArgs("install", rest)
    cmdInstall()
  of "remove":
    cmdRemove(rest)
  of "packages":
    requireNoArgs("packages", rest)
    cmdPackages()
  of "doctor":
    requireNoArgs("doctor", rest)
    cmdDoctor()
  of "--version", "-v":
    requireNoArgs(cmd, rest)
    echo "gzim " & Version
  else:
    requireNoArgs("help", rest)
    showHelp()
    quit(0)
