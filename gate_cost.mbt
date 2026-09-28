///|
/// A count of primitive positive-logic gates used by a two-level SOP mapping.
///
/// This is a structural estimate, not a timing, power, area, or price model.
pub struct GateCost {
  inverters : Int
  and2_gates : Int
  or2_gates : Int
}

///|
/// Create a gate-count value, rejecting negative counts.
pub fn GateCost::new(
  inverters : Int,
  and2_gates : Int,
  or2_gates : Int,
) -> GateCost? {
  if inverters < 0 || and2_gates < 0 || or2_gates < 0 {
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
    and2_gates += Int::max(0, literals - 1)
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
  let or2_gates = Int::max(0, solution.selected.length() - 1)
  { inverters, and2_gates, or2_gates, }
}

///|
/// Return the total number of primitive gates in this estimate.
pub fn GateCost::total(self : GateCost) -> Int {
  self.inverters + self.and2_gates + self.or2_gates
}

///|
/// Round a nonnegative gate count up to whole packages of `channels` gates.
/// Return `None` for invalid counts or a package without usable channels.
pub fn GateCost::packages_for(gates : Int, channels : Int) -> Int? {
  if gates < 0 || channels <= 0 {
    return None
  }
  Some((gates + channels - 1) / channels)
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
}
