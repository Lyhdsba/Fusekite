///|
/// Consumer-side interpretation of exported SOP patterns, MSB first.
fn evaluate_sop(patterns : Array[String], row : Int32) -> Bool {
  for pattern in patterns {
    let chars = pattern.to_array()
    let mut matches = true
    for index in 0..<chars.length() {
      let high = (row & (1 << (chars.length() - index - 1))) != 0
      match chars[index] {
        '0' => matches = matches && !high
        '1' => matches = matches && high
        '-' => ()
        _ => abort("unexpected SOP pattern character")
      }
    }
    if matches {
      return true
    }
  }
  false
}

///|
/// A project's build/review indicator, using only public dependency APIs.
fn main raise {
  // Inputs: enabled, build_failed, review_requested, muted (MSB first).
  // Show a light iff enabled && (build_failed || review_requested) && !muted.
  // Every input combination is specified; there are no don't-care rows.
  let spec = @fusekite.TruthSpec::new(4, [10, 12, 14], []).unwrap()
  let sop = @fusekite.minimize_sop(spec)
  let pos = @fusekite.minimize_pos(spec)
  let patterns = sop.patterns()
  assert_eq(patterns, ["1-10", "11-0"])
  assert_eq(sop.term_count, 2)
  assert_eq(sop.literal_count, 6)
  assert_eq(pos.patterns(), ["---1", "-00-", "0---"])
  assert_eq(pos.clause_count, 3)
  assert_eq(pos.literal_count, 4)
  // Recompute from the application rule, not from the minimizer or its on-set.
  for row in 0..<16 {
    let enabled = (row & 8) != 0
    let build_failed = (row & 4) != 0
    let review_requested = (row & 2) != 0
    let muted = (row & 1) != 0
    let expected = enabled && (build_failed || review_requested) && !muted
    assert_eq(evaluate_sop(patterns, row), expected)
    assert_eq(pos.evaluate(row), Some(expected))
  }
  let config = @sat.SolverConfig::new(100_000).unwrap()
  assert_true(@fusekite.verify_sop_with_bdd(spec, sop))
  assert_true(@fusekite.verify_pos_with_bdd(spec, pos))
  match @fusekite.verify_sop_with_sat(spec, sop, config) {
    @fusekite.SatEquivalence::Equivalent => ()
    _ => fail("SOP equivalence was not proved")
  }
  match @fusekite.verify_pos_with_sat(spec, pos, config) {
    @fusekite.SatEquivalence::Equivalent => ()
    _ => fail("POS equivalence was not proved")
  }
  // A candidate that forgets review requests must be rejected. Replay the
  // returned witness against both the application rule and the candidate.
  let incomplete = @fusekite.TruthSpec::new(4, [12, 14], []).unwrap()
  let wrong = @fusekite.minimize_sop(incomplete)
  assert_true(!@fusekite.verify_sop_with_bdd(spec, wrong))
  match @fusekite.verify_sop_with_sat(spec, wrong, config) {
    @fusekite.SatEquivalence::Counterexample(inputs) => {
      assert_eq(inputs.length(), 4)
      let mut row = 0
      for high in inputs {
        row = row * 2 + (if high { 1 } else { 0 })
      }
      assert_eq(row, 10)
      assert_true(inputs[0] && (inputs[1] || inputs[2]) && !inputs[3])
      assert_true(!evaluate_sop(wrong.patterns(), row))
    }
    _ => fail("incomplete candidate did not produce a counterexample")
  }
  let cost = @fusekite.estimate_sop_gate_cost(spec, sop)
  let plan = @parts.estimate_74hc_packages(cost)
  assert_eq(cost.inverters, 1)
  assert_eq(cost.and2_gates, 4)
  assert_eq(cost.or2_gates, 1)
  assert_eq(plan.inverters, 1)
  assert_eq(plan.and_packages, 1)
  assert_eq(plan.or_packages, 1)
  println(
    "status indicator: enabled && (build_failed || review_requested) && !muted",
  )
  println("SOP patterns:")
  for pattern in patterns {
    println("  \{pattern}")
  }
  println("POS zero patterns:")
  for pattern in pos.patterns() {
    println("  \{pattern}")
  }
  println("16 rows checked; SOP/POS BDD and SAT equivalent (budget 100000)")
  println("incomplete candidate rejected; SAT witness row 10 replayed")
  println(
    "SOP gates (NOT, AND2, OR2): 1, 4, 1; packages (HC04, HC08, HC32): 1, 1, 1",
  )
}
