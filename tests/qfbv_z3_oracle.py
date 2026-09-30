from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from z3 import BitVec, BitVecVal, Solver, ULT, sat, unsat


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_CASES = 5 * sum(1 << width for width in range(1, 9))


def operation_value(operation: str, width: int, left: int, right: int) -> int:
    mask = (1 << width) - 1
    if operation == "add":
        return (left + right) & mask
    if operation == "and":
        return left & right
    if operation == "or":
        return left | right
    if operation == "xor":
        return left ^ right
    if operation == "not":
        return (~left) & mask
    raise ValueError(f"unknown operation: {operation}")


def main() -> int:
    command = ["moon", "run", "cmd/qf_bv_corpus"]
    generated = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if generated.returncode != 0:
        sys.stderr.write(generated.stdout)
        sys.stderr.write(generated.stderr)
        return generated.returncode

    cases = [line for line in generated.stdout.splitlines() if line.startswith("QFBV|")]
    if len(cases) != EXPECTED_CASES:
        raise RuntimeError(
            f"expected {EXPECTED_CASES} QF_BV rows, received {len(cases)}"
        )

    for line in cases:
        _, operation, width_text, target_text, outcome, left_text, right_text = (
            line.split("|")
        )
        width = int(width_text)
        target = int(target_text)
        left = BitVec("x", width)
        right = BitVec("y", width)
        expression = {
            "add": left + right,
            "and": left & right,
            "or": left | right,
            "xor": left ^ right,
            "not": ~left,
        }[operation]
        reference = Solver()
        reference.add(expression == BitVecVal(target, width))
        reference.add(ULT(left, right))
        expected = reference.check()

        if outcome == "UNKNOWN" or outcome == "INVALID":
            raise AssertionError(f"MoonBit backend did not decide {line}")
        if (outcome == "SAT") != (expected == sat):
            raise AssertionError(f"SAT status differs from Z3: {line}; Z3={expected}")
        if expected == unsat:
            continue

        model_left = int(left_text)
        model_right = int(right_text)
        concrete = operation_value(operation, width, model_left, model_right)
        if concrete != target or not model_left < model_right:
            raise AssertionError(f"MoonBit returned an invalid model: {line}")
        reference.push()
        reference.add(left == BitVecVal(model_left, width))
        reference.add(right == BitVecVal(model_right, width))
        if reference.check() != sat:
            raise AssertionError(f"Z3 rejects the MoonBit model: {line}")
        reference.pop()

    print(f"Z3 differential check passed for {len(cases)} QF_BV cases.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
