///|
/// Print a worked logic plan and its direct 74HC package estimate.
fn show_example(example : @circuits.CircuitExample) -> Unit {
  let solution = @fusekite.minimize_sop(example.spec)
  let cost = @fusekite.estimate_sop_gate_cost(example.spec, solution)
  let packages = @parts.estimate_74hc_packages(cost)
  println("\n\{example.name}")
  let mut labels = ""
  for index in 0..<example.input_labels.length() {
    if index > 0 {
      labels += ", "
    }
    labels += example.input_labels[index]
  }
  println("inputs: \{labels}")
  println("minimum SOP patterns:")
  for pattern in solution.patterns() {
    println("  \{pattern}")
  }
  println("terms: \{solution.term_count}, literals: \{solution.literal_count}")
  println(
    "gate counts (NOT, AND2, OR2): \{cost.inverters}, \{cost.and2_gates}, \{cost.or2_gates}",
  )
  println(
    "SN74HC packages (HC04, HC08, HC32): \{packages.inverters}, \{packages.and_packages}, \{packages.or_packages}",
  )
}

///|
/// Demonstrate three electronics examples and their structural package plans.
fn main raise {
  show_example(@circuits.sensor_interlock())
  show_example(@circuits.bcd_segment_a())
  show_example(@circuits.majority_alarm())
}
