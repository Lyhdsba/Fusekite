"""Failure-injection checks for the evidence gate, independent of MoonBit output."""

import subprocess
import unittest
from unittest.mock import patch

import qfbv_z3_oracle as oracle


def corpus() -> list[str]:
    # These UNSAT placeholders test the transport contract only, not semantics.
    rows = []
    for width in range(1, 9):
        for operation in ("add", "sub", "mul", "and", "or", "xor", "not"):
            rows.extend(
                f"QFBV|{operation}|{width}|{target}|UNSAT|-|-"
                for target in range(1 << width)
            )
        rows.extend(f"QFBV|slt|{width}|{target}|UNSAT|-|-" for target in (0, 1))
    return rows


class CorpusContractTests(unittest.TestCase):
    def test_complete_matrix_is_order_independent(self):
        cases = oracle.parse_corpus("compiler diagnostic\n" + "\n".join(reversed(corpus())))
        self.assertEqual(len(cases), 3586)
        self.assertEqual(len({case[:3] for case in cases}), 3586)

    def test_duplicate_cannot_replace_a_missing_case(self):
        rows = corpus()
        rows[-1] = rows[0]
        with self.assertRaisesRegex(ValueError, "duplicate"):
            oracle.parse_corpus("\n".join(rows))

    def test_truncated_or_empty_output_fails(self):
        for rows in ([], corpus()[:-1]):
            with self.subTest(count=len(rows)):
                with self.assertRaisesRegex(ValueError, "missing"):
                    oracle.parse_corpus("\n".join(rows))

    def test_unexpected_keys_fail(self):
        for row in (
            "QFBV|div|1|0|UNSAT|-|-",
            "QFBV|add|0|0|UNSAT|-|-",
            "QFBV|add|9|0|UNSAT|-|-",
            "QFBV|add|1|2|UNSAT|-|-",
            "QFBV|slt|8|2|UNSAT|-|-",
        ):
            with self.subTest(row=row):
                with self.assertRaisesRegex(ValueError, "unexpected QF_BV case"):
                    oracle.parse_corpus("\n".join([row, *corpus()[1:]]))

    def test_unknown_invalid_or_misspelled_outcomes_fail(self):
        for outcome in ("UNKNOWN", "INVALID", "UNSATT", ""):
            with self.subTest(outcome=outcome):
                with self.assertRaisesRegex(ValueError, "outcome"):
                    oracle.parse_corpus(f"QFBV|add|1|0|{outcome}|-|-")

    def test_malformed_fields_and_models_fail(self):
        for row in (
            "QFBV|add|1|0|SAT|0",
            "QFBV|add|one|0|UNSAT|-|-",
            "QFBV|add|1|0|SAT|-|0",
            "QFBV|add|1|0|UNSAT|0|0",
        ):
            with self.subTest(row=row):
                with self.assertRaises(ValueError):
                    oracle.parse_corpus(row)

    def test_models_must_fit_unsigned_width(self):
        # In the old gate Z3's BitVecVal silently wrapped these integers.
        for left, right in ((-1, 0), (0, -1), (2, 0), (0, 2)):
            with self.subTest(left=left, right=right):
                with self.assertRaisesRegex(ValueError, "out-of-range"):
                    oracle.parse_corpus(f"QFBV|slt|1|1|SAT|{left}|{right}")

    def test_valid_sat_model_is_retained(self):
        rows = corpus()
        rows[1] = "QFBV|add|1|1|SAT|0|1"
        case = oracle.parse_corpus("\n".join(rows))[1]
        self.assertEqual(case, oracle.Case("add", 1, 1, "SAT", 0, 1))

    def test_failed_generator_propagates_exit_and_diagnostics(self):
        generated = subprocess.CompletedProcess([], 7, "partial output", "compiler failure")
        with patch.object(oracle.subprocess, "run", return_value=generated):
            with patch.object(oracle.sys.stderr, "write") as write:
                self.assertEqual(oracle.main(), 7)
        self.assertEqual([call.args[0] for call in write.call_args_list],
                         ["partial output", "compiler failure"])

    def test_main_rejects_duplicate_before_solver_comparison(self):
        rows = corpus()
        rows[-1] = rows[0]
        generated = subprocess.CompletedProcess([], 0, "\n".join(rows), "")
        with patch.object(oracle.subprocess, "run", return_value=generated):
            with self.assertRaisesRegex(ValueError, "duplicate"):
                oracle.main()


if __name__ == "__main__":
    unittest.main()
