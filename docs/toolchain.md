# Reproducible MoonBit toolchain

The SDK selector in [`.moonbit-version`](../.moonbit-version) is
`0.10.15+943464bfa`. It identifies the compiler release, including its commit
hash. The installed bundle reports:

```text
moon 0.1.20261012 (748b63c 2026-10-12)
moonc v0.10.15+943464bfa (2026-10-12)
moonrun 0.1.20261012 (748b63c 2026-10-12)
```

This is the SDK already validated for the source and the successful
[consumer CI run](https://github.com/Lyhdsba/Fusekite/actions/runs/38748465937).
The formatter, runtime, and core library must come from the same SDK
installation. Do not substitute Moon's `0.1.20261012` build-system version as
the install selector.

## Install from the checkout root

The [official Unix installer](https://cli.moonbitlang.com/install/unix.sh)
accepts the selector as its positional argument. It downloads both
`binaries/<selector>/moonbit-<platform>.tar.gz` and
`cores/core-<selector>.tar.gz`, encoding `+` as `%2B`.
The [official download page](https://www.moonbitlang.com/download/#verifying-binaries)
explains archive checksum verification. The installer script itself is served
from the official installation endpoint; the pinned value selects SDK archives.

Linux/macOS (Bash, with `curl` installed):

```sh
set -euo pipefail
version="$(tr -d '\r\n' < .moonbit-version)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9a-f]+$ ]] || exit 1
curl -fsSL https://cli.moonbitlang.com/install/unix.sh -o /tmp/fusekite-install-moonbit.sh
bash /tmp/fusekite-install-moonbit.sh "$version"
export PATH="${MOON_HOME:-$HOME/.moon}/bin:$PATH"
moon version --all
[[ "$(moonc -v)" == "v$version "* ]] || exit 1
```

Windows (PowerShell):

```powershell
$ErrorActionPreference = 'Stop'
$version = (Get-Content -Raw .moonbit-version).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+\+[0-9a-f]+$') { throw 'Invalid SDK selector' }
$env:MOONBIT_INSTALL_VERSION = $version
$installer = Join-Path $env:TEMP 'fusekite-install-moonbit.ps1'
Invoke-WebRequest https://cli.moonbitlang.com/install/powershell.ps1 -OutFile $installer
& $installer
if ($LASTEXITCODE -ne 0) { throw 'MoonBit installation failed' }
$sdkHome = if ($env:MOON_HOME) { $env:MOON_HOME } else { Join-Path $HOME '.moon' }
$env:Path = "$sdkHome\bin;$env:Path"
moon version --all
if ((moonc -v) -notlike "v$version *") { throw 'Compiler version mismatch' }
Remove-Item Env:MOONBIT_INSTALL_VERSION
```

Both installers default to `.moon` in the user home directory. To keep another
SDK, set `MOON_HOME` to a separate directory **before** running the installer
and keep that directory's `bin` first on `PATH` when checking this project.
Use a fresh installation when reproducing an SDK change. Do not run
`moon upgrade` in the pinned installation.

## Validate and upgrade

Run all commands in [README's build and test section](../README.md#build-and-test),
including the downstream consumer, documentation/package checks, and the
Python 3.12 / pinned-Z3 differential check. CI runs the same checks on Ubuntu
24.04 and verifies the compiler identity before checking the source.

When upgrading, first confirm the candidate's exact compiler version and hash
and that the official binary **and core** archives exist. Install it separately,
run the complete check set from a clean build, inspect formatter/API changes,
then update `.moonbit-version` and the recorded version/results together in one
change. Confirm the resulting remote CI before calling the upgrade validated.
If archives cannot be installed or a platform cannot be tested, record that
limit; do not replace the selector with `latest` or claim that platform passed.

Only the default Wasm target is covered by the checks here. A pinned SDK does
not freeze GitHub's runner contents, installer implementation, Python patch
releases, or unrelated Actions dependencies.
