from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import NamedTuple

from z3 import BitVec, BitVecVal, Solver, ULT, sat, unsat


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_KEYS = frozenset(
    (operation, width, target)
    for width in range(1, 9)
    for operation in ("add", "sub", "mul", "and", "or", "xor", "not", "slt")
    for target in range(2 if operation == "slt" else 1 << width)
)


class Case(NamedTuple):
    operation: str
    width: int
    target: int
    outcome: str
    left: int | None
    right: int | None


def parse_corpus(output: str) -> list[Case]:
    """Require each expected case once, before trusting any solver evidence."""
    cases = []
    seen = set()
    for line in output.splitlines():
        if not line.startswith("QFBV|"):
            continue
        fields = line.split("|")
        if len(fields) != 7:
            raise ValueError(f"malformed QF_BV row: {line}")
        _, operation, width_text, target_text, outcome, left_text, right_text = fields
        width, target = int(width_text), int(target_text)
        key = (operation, width, target)
        if key not in EXPECTED_KEYS:
            raise ValueError(f"unexpected QF_BV case: {key}")
        if key in seen:
            raise ValueError(f"duplicate QF_BV case: {key}")
        seen.add(key)
        if outcome == "SAT":
            left, right = int(left_text), int(right_text)
            if not (0 <= left < 1 << width and 0 <= right < 1 << width):
                raise ValueError(f"out-of-range QF_BV model: {line}")
        elif outcome == "UNSAT":
            if (left_text, right_text) != ("-", "-"):
                raise ValueError(f"unexpected UNSAT model: {line}")
            left, right = None, None
        else:
            raise ValueError(f"undecided or unknown QF_BV outcome: {line}")
        cases.append(Case(operation, width, target, outcome, left, right))
    missing = EXPECTED_KEYS - seen
    if missing:
        raise ValueError(f"missing {len(missing)} QF_BV cases; first: {min(missing)}")
    return cases


def operation_value(operation: str, width: int, left: int, right: int) -> int:
    mask = (1 << width) - 1
    if operation == "add":
        return (left + right) & mask
    if operation == "sub":
        return (left - right) & mask
    if operation == "mul":
        return (left * right) & mask
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

    cases = parse_corpus(generated.stdout)

    for case in cases:
        operation, width, target, outcome, model_left, model_right = case
        left = BitVec("x", width)
        right = BitVec("y", width)
        reference = Solver()
        if operation == "slt":
            reference.add((left < right) == (target == 1))
        else:
            expression = {
                "add": left + right,
                "sub": left - right,
                "mul": left * right,
                "and": left & right,
                "or": left | right,
                "xor": left ^ right,
                "not": ~left,
            }[operation]
            reference.add(expression == BitVecVal(target, width))
        if operation != "slt":
            reference.add(ULT(left, right))
        expected = reference.check()

        if expected not in (sat, unsat):
            raise AssertionError(f"Z3 did not decide {case}: {expected}")
        if (outcome == "SAT") != (expected == sat):
            raise AssertionError(f"SAT status differs from Z3: {case}; Z3={expected}")
        if expected == unsat:
            continue

        assert model_left is not None and model_right is not None
        if operation == "slt":
            sign_bit = 1 << (width - 1)
            signed_left = model_left - (1 << width) if model_left & sign_bit else model_left
            signed_right = model_right - (1 << width) if model_right & sign_bit else model_right
            valid_model = (signed_left < signed_right) == (target == 1)
        else:
            concrete = operation_value(operation, width, model_left, model_right)
            valid_model = concrete == target and model_left < model_right
        if not valid_model:
            raise AssertionError(f"MoonBit returned an invalid model: {case}")
        reference.push()
        reference.add(left == BitVecVal(model_left, width))
        reference.add(right == BitVecVal(model_right, width))
        if reference.check() != sat:
            raise AssertionError(f"Z3 rejects the MoonBit model: {case}")
        reference.pop()

    print(f"Z3 differential check passed for {len(cases)} QF_BV cases.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
