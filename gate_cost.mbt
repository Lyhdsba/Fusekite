///|
/// A count of primitive positive-logic gates used by a two-level SOP or POS mapping.
///
/// This is a structural estimate, not a timing, power, area, or price model.
pub struct GateCost {
  inverters : Int32
  and2_gates : Int32
  or2_gates : Int32
}

///|
/// Create a gate-count value, rejecting negative counts.
pub fn GateCost::new(
  inverters : Int32,
  and2_gates : Int32,
  or2_gates : Int32,
) -> GateCost? {
  if inverters < 0 || and2_gates < 0 || or2_gates < 0 {
    return None
  }
  let max_int = 2147483647
  if and2_gates > max_int - inverters ||
    or2_gates > max_int - inverters - and2_gates {
    return None
  }
  Some({ inverters, and2_gates, or2_gates, })
}

///|
/// A simple gate-count estimate for implementing a selected SOP cover.
///
/// Each product of `n` literals uses `n - 1` two-input AND gates. Products are
/// joined using a two-input OR tree. Inverted input literals are shared by
/// variable, so each input that appears negated contributes one inverter.
pub fn estimate_sop_gate_cost(
  spec : TruthSpec,
  solution : CoverSolution,
) -> GateCost {
  let mut and2_gates = 0
  let inverted_inputs : Array[Bool] = []
  for _ in 0..<spec.input_count {
    inverted_inputs.push(false)
  }
  for cube in solution.selected {
    let literals = cube.literal_count()
    and2_gates += Int32::max(0, literals - 1)
    for bit in 0..<spec.input_count {
      if ((cube.wildcard >> bit) & 1) == 0 && ((cube.value >> bit) & 1) == 0 {
        inverted_inputs[bit] = true
      }
    }
  }
  let mut inverters = 0
  for inverted in inverted_inputs {
    if inverted {
      inverters += 1
    }
  }
  let or2_gates = Int32::max(0, solution.selected.length() - 1)
  { inverters, and2_gates, or2_gates, }
}

///|
/// Estimate a direct two-level AND-of-OR implementation of a POS result.
///
/// Each sum clause with `n` literals uses `n - 1` two-input OR gates; the
/// clauses use a two-input AND tree. Complemented input literals are shared
/// by variable. This is a structural estimate and does not choose NAND/NOR
/// mappings or account for electrical constraints.
pub fn estimate_pos_gate_cost(
  spec : TruthSpec,
  solution : PosSolution,
) -> GateCost? {
  if !valid_pos_for_spec(spec, solution) {
    return None
  }
  let clauses = solution.clauses()
  let mut or2_gates = 0
  let inverted_inputs : Array[Bool] = []
  for _ in 0..<spec.input_count {
    inverted_inputs.push(false)
  }
  for clause in clauses {
    let pattern = clause.pattern().to_array()
    let mut literals = 0
    for bit in 0..<pattern.length() {
      if pattern[bit] != '-' {
        literals += 1
        if pattern[bit] == '1' {
          inverted_inputs[bit] = true
        }
      }
    }
    or2_gates += Int32::max(0, literals - 1)
  }
  let mut inverters = 0
  for inverted in inverted_inputs {
    if inverted {
      inverters += 1
    }
  }
  let and2_gates = Int32::max(0, clauses.length() - 1)
  Some({ inverters, and2_gates, or2_gates, })
}

///|
/// Return the total number of primitive gates in this estimate.
pub fn GateCost::total(self : GateCost) -> Int32 {
  self.inverters + self.and2_gates + self.or2_gates
}

///|
/// Round a nonnegative gate count up to whole packages of `channels` gates.
/// Return `None` for invalid counts or a package without usable channels.
pub fn GateCost::packages_for(gates : Int32, channels : Int32) -> Int32? {
  if gates < 0 || channels <= 0 {
    return None
  }
  let whole_packages = gates / channels
  if gates % channels == 0 {
    Some(whole_packages)
  } else {
    Some(whole_packages + 1)
  }
}

///|
test "SOP gate estimate shares complemented input literals" {
  let spec = match TruthSpec::new(2, [0, 1], []) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }
  let cost = estimate_sop_gate_cost(spec, minimize_sop(spec))
  assert_eq(cost.inverters, 1)
  assert_eq(cost.and2_gates, 0)
  assert_eq(cost.or2_gates, 0)
}

///|
test "SOP gate estimate counts product and sum trees" {
  let spec = match TruthSpec::new(3, [0, 7], []) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }
  let cost = estimate_sop_gate_cost(spec, minimize_sop(spec))
  assert_eq(cost.inverters, 3)
  assert_eq(cost.and2_gates, 4)
  assert_eq(cost.or2_gates, 1)
  assert_eq(cost.total(), 8)
}

///|
test "package counts round up and reject invalid dimensions" {
  assert_eq(GateCost::packages_for(0, 4), Some(0))
  assert_eq(GateCost::packages_for(4, 4), Some(1))
  assert_eq(GateCost::packages_for(5, 4), Some(2))
  assert_true(GateCost::packages_for(-1, 4) is None)
  assert_true(GateCost::packages_for(1, 0) is None)
  assert_eq(GateCost::packages_for(2147483647, 1), Some(2147483647))
  assert_eq(GateCost::packages_for(2147483647, 4), Some(536870912))
  assert_true(GateCost::new(2147483647, 1, 0) is None)
}

///|
test "POS gate estimate counts OR clauses and the AND tree" {
  let interlock = TruthSpec::new(2, [3], []).unwrap()
  let interlock_cost = estimate_pos_gate_cost(
    interlock,
    minimize_pos(interlock),
  ).unwrap()
  assert_eq(interlock_cost.inverters, 0)
  assert_eq(interlock_cost.and2_gates, 1)
  assert_eq(interlock_cost.or2_gates, 0)

  let bcd = TruthSpec::new(4, [0, 2, 3, 5, 6, 7, 8, 9], [10, 11, 12, 13, 14, 15]).unwrap()
  let bcd_cost = estimate_pos_gate_cost(bcd, minimize_pos(bcd)).unwrap()
  assert_eq(bcd_cost.inverters, 2)
  assert_eq(bcd_cost.and2_gates, 1)
  assert_eq(bcd_cost.or2_gates, 5)

  let majority = TruthSpec::new(3, [3, 5, 6, 7], []).unwrap()
  let majority_cost = estimate_pos_gate_cost(majority, minimize_pos(majority)).unwrap()
  assert_eq(majority_cost.inverters, 0)
  assert_eq(majority_cost.and2_gates, 2)
  assert_eq(majority_cost.or2_gates, 3)

  assert_true(estimate_pos_gate_cost(interlock, minimize_pos(bcd)) is None)

  let always_true = TruthSpec::new(2, [0, 1, 2, 3], []).unwrap()
  let true_cost = estimate_pos_gate_cost(always_true, minimize_pos(always_true)).unwrap()
  assert_eq(true_cost.total(), 0)
  let always_false = TruthSpec::new(2, [], []).unwrap()
  let false_cost = estimate_pos_gate_cost(
    always_false,
    minimize_pos(always_false),
  ).unwrap()
  assert_eq(false_cost.total(), 0)
}
