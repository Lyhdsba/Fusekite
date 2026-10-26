"""Run the public API consumer against a real Mooncakes release, never the checkout."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE = "Lyhdsba/fusekite"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", default="0.2.0", help="Published release to verify")
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error("--version must be a stable MAJOR.MINOR.PATCH release")
    moon = shutil.which("moon")
    moonc = shutil.which("moonc")
    if not moon or not moonc:
        parser.error("Put the SDK selected by .moonbit-version on PATH")
    expected_sdk = (ROOT / ".moonbit-version").read_text().strip()
    compiler = subprocess.check_output([moonc, "-v"], text=True).strip()
    if not compiler.startswith(f"v{expected_sdk} "):
        raise RuntimeError(f"Expected moonc v{expected_sdk}, got {compiler}")

    # Copy only the consumer's application code and package imports. In
    # particular, do not copy examples/moon.work, library sources, or caches.
    with tempfile.TemporaryDirectory(prefix="fusekite-registry-consumer-") as temp:
        consumer = Path(temp).resolve()
        if consumer.is_relative_to(ROOT):
            raise RuntimeError("The temporary consumer must be outside the checkout")
        for parent in (consumer, *consumer.parents):
            for filename in ("moon.work", "moon.work.json"):
                if (parent / filename).exists():
                    raise RuntimeError(f"Refusing enclosing workspace: {parent / filename}")
        print(f"Independent registry consumer: {consumer}", flush=True)
        (consumer / "moon.mod").write_text(
            'name = "acceptance/fusekite-registry-consumer"\n\n'
            'version = "0.1.0"\n\npreferred_target = "wasm"\n',
            encoding="utf-8",
        )
        for filename in ("main.mbt", "moon.pkg"):
            shutil.copyfile(ROOT / "examples/status-indicator" / filename, consumer / filename)

        def run(*arguments: str) -> None:
            print("+ moon " + " ".join(arguments), flush=True)
            subprocess.run([moon, *arguments], cwd=consumer, check=True)

        run("version", "--all")
        # moon add refreshes the registry index; unavailable releases fail here.
        run("add", f"{MODULE}@{args.version}")
        print((consumer / "moon.mod").read_text(encoding="utf-8"), flush=True)
        installed = consumer / ".mooncakes/Lyhdsba/fusekite/moon.mod"
        metadata = installed.read_text(encoding="utf-8")
        for field, value in (("name", MODULE), ("version", args.version)):
            if not re.search(rf'(?m)^{field}\s*=\s*"{re.escape(value)}"\s*$', metadata):
                raise RuntimeError(f"Downloaded manifest does not contain {field}={value}")
        print(f"Downloaded registry manifest: {installed}", flush=True)
        run("tree")
        run("fmt", "--check")
        run("check", "--deny-warn")
        run("run", ".")
        print(f"Registry consumer passed: {MODULE}@{args.version}", flush=True)


if __name__ == "__main__":
    main()
