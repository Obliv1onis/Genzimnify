## Lightweight project manifest and Git/path package manager for gzim.

import std/[algorithm, json, os, osproc, streams, strutils, syncio, tables]

const ManifestName* = "gzim.toml"

type
  PackageError* = object of CatchableError
  Manifest* = object
    name*: string
    version*: string
    dependencies*: OrderedTable[string, string]

proc cleanQuoted(value: string): string =
  result = value.strip()
  if result.len >= 2 and result[0] == '"' and result[^1] == '"':
    result = result[1 .. ^2]

proc loadManifest*(root: string): Manifest =
  result.name = lastPathPart(root)
  result.version = "0.1.0"
  result.dependencies = initOrderedTable[string, string]()
  let path = root / ManifestName
  if not fileExists(path):
    raise newException(PackageError, "no gzim.toml here; run 'gzim init' first")
  var section = ""
  for rawLine in lines(path):
    let line = rawLine.strip()
    if line == "" or line.startsWith("#"): continue
    if line.startsWith("[") and line.endsWith("]"):
      section = line[1 .. ^2]
      continue
    let separator = line.find('=')
    if separator < 1: continue
    let key = line[0 ..< separator].strip()
    let value = cleanQuoted(line[separator + 1 .. ^1])
    case section
    of "project":
      if key == "name": result.name = value
      elif key == "version": result.version = value
    of "dependencies": result.dependencies[key] = value
    else: discard

proc saveManifest*(manifest: Manifest, root: string) =
  var names: seq[string]
  for name in manifest.dependencies.keys: names.add name
  names.sort()
  var output = "[project]\nname = \"" & manifest.name & "\"\nversion = \"" & manifest.version & "\"\n\n[dependencies]\n"
  for name in names:
    output.add name & " = \"" & manifest.dependencies[name] & "\"\n"
  writeFile(root / ManifestName, output)

proc initManifest*(root: string) =
  if fileExists(root / ManifestName): return
  var manifest = Manifest(name: lastPathPart(absolutePath(root)), version: "0.1.0",
    dependencies: initOrderedTable[string, string]())
  manifest.saveManifest(root)

proc validPackageName(name: string): bool =
  if name == "": return false
  for ch in name:
    if not (ch.isAlphaNumeric or ch in {'-', '_'}): return false
  true

proc runGit(args: seq[string], root: string): string =
  let git = findExe("git")
  if git == "": raise newException(PackageError, "git is required to install Git dependencies")
  let process = startProcess(git, workingDir = root, args = args,
    options = {poUsePath, poStdErrToStdOut})
  let output = process.outputStream.readAll()
  let code = process.waitForExit()
  process.close()
  if code != 0: raise newException(PackageError, output.strip())
  output.strip()

proc packageRoot*(root: string): string = root / ".gzim" / "packages"

proc loadLock(root: string): Table[string, tuple[source, revision: string]] =
  result = initTable[string, tuple[source, revision: string]]()
  let path = root / "gzim.lock"
  if not fileExists(path): return
  try:
    let document = parseFile(path)
    if document.hasKey("packages"):
      for name, item in document["packages"]:
        result[name] = (item{"source"}.getStr(""), item{"revision"}.getStr(""))
  except CatchableError:
    raise newException(PackageError, "gzim.lock is invalid; delete it and run 'gzim install'")

proc saveLock(root: string, entries: Table[string, tuple[source, revision: string]]) =
  var packages = newJObject()
  var names: seq[string]
  for name in entries.keys: names.add name
  names.sort()
  for name in names:
    packages[name] = %*{"source": entries[name].source, "revision": entries[name].revision}
  writeFile(root / "gzim.lock", pretty(%*{"version": 1, "packages": packages}) & "\n")

proc fetchPackage(root, destination, source: string, lockedRevision = ""): string =
  var localSource = source
  if localSource.startsWith("path:"): localSource = localSource[5 .. ^1]
  if localSource == "": raise newException(PackageError, "package source cannot be empty")
  let resolvedLocal = if localSource.isAbsolute: localSource else: root / localSource
  if dirExists(resolvedLocal):
    copyDir(normalizedPath(absolutePath(resolvedLocal)), destination)
    return "path"

  var url = source
  var reference = ""
  let hashAt = source.rfind('#')
  if hashAt > source.find("://") + 2:
    url = source[0 ..< hashAt]
    reference = source[hashAt + 1 .. ^1]
  if reference == "": reference = lockedRevision
  if reference == "":
    discard runGit(@["clone", "--depth", "1", url, destination], root)
  else:
    createDir(destination)
    discard runGit(@["-C", destination, "init"], root)
    discard runGit(@["-C", destination, "remote", "add", "origin", url], root)
    discard runGit(@["-C", destination, "fetch", "--depth", "1", "origin", reference], root)
    discard runGit(@["-C", destination, "checkout", "--detach", "FETCH_HEAD"], root)
  runGit(@["-C", destination, "rev-parse", "HEAD"], root)

proc installOne(root, name, source: string, lockedRevision = ""): string =
  if not validPackageName(name):
    raise newException(PackageError, "invalid package name '" & name & "'")
  let packages = packageRoot(root)
  createDir(packages)
  let destination = packages / name
  let staging = packages / ("." & name & ".tmp-" & $getCurrentProcessId())
  let backup = packages / ("." & name & ".old-" & $getCurrentProcessId())
  var localSource = source
  if localSource.startsWith("path:"): localSource = localSource[5 .. ^1]
  if localSource == "": raise newException(PackageError, "package source cannot be empty")
  let resolvedLocal = if localSource.isAbsolute: localSource else: root / localSource
  if dirExists(resolvedLocal):
    let canonicalSource = normalizedPath(absolutePath(resolvedLocal))
    let canonicalRoot = normalizedPath(absolutePath(root))
    let canonicalPackages = normalizedPath(absolutePath(packages))
    if canonicalSource == canonicalRoot or canonicalSource.startsWith(canonicalPackages & $DirSep):
      raise newException(PackageError, "package path must be outside the project package cache")

  if dirExists(staging): removeDir(staging)
  if dirExists(backup): removeDir(backup)
  try:
    result = fetchPackage(root, staging, source, lockedRevision)
    if dirExists(destination): moveDir(destination, backup)
    try:
      moveDir(staging, destination)
    except CatchableError:
      if dirExists(backup): moveDir(backup, destination)
      raise
    if dirExists(backup): removeDir(backup)
  except CatchableError:
    if dirExists(staging): removeDir(staging)
    if dirExists(backup) and not dirExists(destination): moveDir(backup, destination)
    raise

proc installDependencies*(root: string): int =
  let manifest = loadManifest(root)
  let oldLock = loadLock(root)
  var newLock = initTable[string, tuple[source, revision: string]]()
  for name, source in manifest.dependencies:
    stdout.writeLine("pulling up " & name & "...")
    let pin = if oldLock.hasKey(name) and oldLock[name].source == source: oldLock[name].revision else: ""
    let revision = installOne(root, name, source, if pin == "path": "" else: pin)
    newLock[name] = (source, revision)
    inc result
  saveLock(root, newLock)

proc addDependency*(root, name, source: string) =
  if not validPackageName(name):
    raise newException(PackageError, "invalid package name '" & name & "'")
  var manifest = loadManifest(root)
  let oldManifest = manifest
  manifest.dependencies[name] = source
  manifest.saveManifest(root)
  try:
    discard installDependencies(root)
  except CatchableError:
    oldManifest.saveManifest(root)
    raise

proc removeDependency*(root, name: string) =
  if not validPackageName(name):
    raise newException(PackageError, "invalid package name '" & name & "'")
  var manifest = loadManifest(root)
  if not manifest.dependencies.hasKey(name):
    raise newException(PackageError, "package '" & name & "' is not in gzim.toml")
  manifest.dependencies.del(name)
  manifest.saveManifest(root)
  let destination = packageRoot(root) / name
  if dirExists(destination): removeDir(destination)
  discard installDependencies(root)

proc findProjectRoot*(start: string): string =
  var current = absolutePath(start)
  if fileExists(current): current = parentDir(current)
  while true:
    if fileExists(current / ManifestName): return current
    let parent = parentDir(current)
    if parent == current: return ""
    current = parent
