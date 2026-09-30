///|
/// A worked, single-output combinational circuit with an independent expected
/// output vector. A value of -1 marks a don't-care row.
pub struct CircuitExample {
  name : String
  input_labels : Array[String]
  spec : @fusekite.TruthSpec
  priv expected_outputs : Array[Int]
  assumptions : String
}

///|
fn make_example(
  name : String,
  input_labels : Array[String],
  on_set : Array[Int],
  dont_cares : Array[Int],
  expected_outputs : Array[Int],
  assumptions : String,
) -> CircuitExample? {
  if expected_outputs.length() != 1 << input_labels.length() {
    return None
  }
  for row in 0..<expected_outputs.length() {
    let expected = expected_outputs[row]
    if (expected == 1 && !on_set.contains(row)) ||
      (expected == 0 && (on_set.contains(row) || dont_cares.contains(row))) ||
      (expected == -1 && !dont_cares.contains(row)) ||
      expected < -1 ||
      expected > 1 {
      return None
    }
  }
  let spec = match
    @fusekite.TruthSpec::new(input_labels.length(), on_set, dont_cares) {
    Some(spec) => spec
    None => return None
  }
  Some({
    name,
    input_labels,
    spec,
    expected_outputs: expected_outputs.copy(),
    assumptions,
  })
}

///|
/// Return a copy of the independently authored expected output vector.
pub fn CircuitExample::expected_outputs(self : CircuitExample) -> Array[Int] {
  self.expected_outputs.copy()
}

///|
/// Door interlock: enable only when both the door is closed and the sensor is
/// clear. Row bit 1 is `door_closed`; bit 0 is `sensor_clear`.
pub fn sensor_interlock() -> CircuitExample raise {
  match
    make_example(
      "Two-condition sensor interlock",
      ["door_closed", "sensor_clear"],
      [3],
      [],
      [0, 0, 0, 1],
      "Both inputs are active-high and the output is an active-high enable.",
    ) {
    Some(example) => example
    None => fail("sensor interlock truth table is invalid")
  }
}

///|
/// BCD-to-seven-segment output for segment `a`. Invalid BCD values 10–15 are
/// left as don't-cares. Input bit 3 is the most significant BCD bit.
pub fn bcd_segment_a() -> CircuitExample raise {
  match
    make_example(
      "BCD seven-segment output a",
      ["D8", "D4", "D2", "D1"],
      [0, 2, 3, 5, 6, 7, 8, 9],
      [10, 11, 12, 13, 14, 15],
      [1, 0, 1, 1, 0, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1],
      "The display is common-cathode (active-high segment); inputs 10–15 never occur as valid BCD.",
    ) {
    Some(example) => example
    None => fail("BCD segment truth table is invalid")
  }
}

///|
/// Three-sensor threshold alarm: assert when at least two active-high sensor
/// inputs are true.
pub fn majority_alarm() -> CircuitExample raise {
  match
    make_example(
      "Two-of-three sensor alarm",
      ["sensor_A", "sensor_B", "sensor_C"],
      [3, 5, 6, 7],
      [],
      [0, 0, 0, 1, 0, 1, 1, 1],
      "All sensors are active-high and equally authoritative; alarm is active-high.",
    ) {
    Some(example) => example
    None => fail("majority alarm truth table is invalid")
  }
}

///|
/// Check a candidate cover against the example's independently listed output
/// vector, skipping only rows explicitly marked as don't-care.
pub fn CircuitExample::verify_cover(
  self : CircuitExample,
  solution : @fusekite.CoverSolution,
) -> Bool {
  for row in 0..<self.expected_outputs.length() {
    let expected = self.expected_outputs[row]
    if expected >= 0 {
      let mut actual = false
      for cube in solution.selected {
        if cube.covers_row(row) {
          actual = true
        }
      }
      if actual != (expected == 1) {
        return false
      }
    }
  }
  true
}

///|
/// Evaluate the two-level SOP as input literals, product terms, and an OR
/// stage. This models Boolean behavior only, not propagation delay or device
/// electrical characteristics.
pub fn CircuitExample::simulate_cover(
  self : CircuitExample,
  solution : @fusekite.CoverSolution,
  inputs : Array[Bool],
) -> Bool? {
  if inputs.length() != self.input_labels.length() {
    return None
  }
  for cube in solution.selected {
    if cube.width != inputs.length() {
      return None
    }
  }
  let mut output = false
  for cube in solution.selected {
    let mut term = true
    for index in 0..<inputs.length() {
      let mask = 1 << (cube.width - index - 1)
      if (cube.wildcard & mask) == 0 {
        let literal_value = (cube.value & mask) != 0
        if inputs[index] != literal_value {
          term = false
        }
      }
    }
    output = output || term
  }
  Some(output)
}

///|
test "interlock cover matches all independently listed rows" {
  let example = sensor_interlock()
  assert_eq(example.expected_outputs(), [0, 0, 0, 1])
  let solution = @fusekite.minimize_sop(example.spec)
  assert_eq(solution.patterns(), ["11"])
  assert_true(example.verify_cover(solution))
  assert_true(@fusekite.verify_sop_with_bdd(example.spec, solution))
  assert_true(
    @fusekite.verify_sop_with_sat(
      example.spec,
      solution,
      @sat.SolverConfig::new(100_000).unwrap(),
    )
    is @fusekite.SatEquivalence::Equivalent,
  )
  let cost = @fusekite.estimate_sop_gate_cost(example.spec, solution)
  let packages = @parts.estimate_74hc_packages(cost)
  assert_eq(packages.and_packages, 1)
  assert_eq(packages.or_packages, 0)
  assert_eq(packages.inverters, 0)
}

///|
test "worked examples reject inconsistent independently listed output vectors" {
  assert_true(make_example("bad", ["A"], [1], [], [0, 0], "test") is None)
  assert_true(make_example("bad", ["A"], [1], [], [1, -1], "test") is None)
  let expected = [0, 1]
  let example = make_example("copy", ["A"], [1], [], expected, "test").unwrap()
  expected[0] = 1
  assert_eq(example.expected_outputs(), [0, 1])
}

///|
test "BCD segment cover matches all valid digits and skips invalid BCD" {
  let example = bcd_segment_a()
  assert_eq(example.expected_outputs(), [
    1, 0, 1, 1, 0, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1,
  ])
  let solution = @fusekite.minimize_sop(example.spec)
  assert_eq(solution.patterns(), ["--1-", "-0-0", "-1-1", "1---"])
  assert_true(example.verify_cover(solution))
  assert_true(@fusekite.verify_sop_with_bdd(example.spec, solution))
  assert_true(
    @fusekite.verify_sop_with_sat(
      example.spec,
      solution,
      @sat.SolverConfig::new(100_000).unwrap(),
    )
    is @fusekite.SatEquivalence::Equivalent,
  )
  let cost = @fusekite.estimate_sop_gate_cost(example.spec, solution)
  let packages = @parts.estimate_74hc_packages(cost)
  assert_eq(packages.and_packages, 1)
  assert_eq(packages.or_packages, 1)
  assert_eq(packages.inverters, 1)
  assert_eq(
    example.verify_cover(@fusekite.minimize_sop(sensor_interlock().spec)),
    false,
  )
}

///|
test "two-of-three alarm cover matches all eight sensor combinations" {
  let example = majority_alarm()
  assert_eq(example.expected_outputs(), [0, 0, 0, 1, 0, 1, 1, 1])
  let solution = @fusekite.minimize_sop(example.spec)
  assert_eq(solution.patterns(), ["-11", "1-1", "11-"])
  assert_true(example.verify_cover(solution))
  assert_true(@fusekite.verify_sop_with_bdd(example.spec, solution))
  assert_true(
    @fusekite.verify_sop_with_sat(
      example.spec,
      solution,
      @sat.SolverConfig::new(100_000).unwrap(),
    )
    is @fusekite.SatEquivalence::Equivalent,
  )
  let cost = @fusekite.estimate_sop_gate_cost(example.spec, solution)
  let packages = @parts.estimate_74hc_packages(cost)
  assert_eq(packages.and_packages, 1)
  assert_eq(packages.or_packages, 1)
  assert_eq(packages.inverters, 0)
}

///|
test "SOP gate-level simulation matches every specified example row" {
  let examples = [sensor_interlock(), bcd_segment_a(), majority_alarm()]
  for example in examples {
    let solution = @fusekite.minimize_sop(example.spec)
    let expected_outputs = example.expected_outputs()
    for row in 0..<(1 << example.input_labels.length()) {
      let inputs : Array[Bool] = []
      for index in 0..<example.input_labels.length() {
        let mask = 1 << (example.input_labels.length() - index - 1)
        inputs.push((row & mask) != 0)
      }
      let simulated = example.simulate_cover(solution, inputs).unwrap()
      let expected = expected_outputs[row]
      if expected >= 0 {
        assert_eq(simulated, expected == 1)
      }
    }
    assert_true(example.simulate_cover(solution, []) is None)
  }
}
