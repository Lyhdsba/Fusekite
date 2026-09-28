///|
/// Logic family represented by one catalog entry.
pub struct LogicPart {
  part_number : String
  function : String
  gates_per_package : Int
  inputs_per_gate : Int
  source_url : String
}

///|
/// Package counts for a direct mapping of the SOP gate estimate.
pub struct PackagePlan {
  inverters : Int
  and_packages : Int
  or_packages : Int
}

///|
/// Return the small, explicitly sourced Texas Instruments 74HC catalog.
///
/// Channel counts refer to the cited SN74HC family descriptions. They do not
/// specify an orderable package suffix or guarantee interchangeable behavior
/// across vendors.
pub fn standard_74hc_catalog() -> Array[LogicPart] {
  [
    {
      part_number: "SN74HC00",
      function: "NAND2",
      gates_per_package: 4,
      inputs_per_gate: 2,
      source_url: "https://www.ti.com/lit/ds/symlink/sn74hc00.pdf",
    },
    {
      part_number: "SN74HC08",
      function: "AND2",
      gates_per_package: 4,
      inputs_per_gate: 2,
      source_url: "https://www.ti.com/lit/ds/symlink/sn74hc08.pdf",
    },
    {
      part_number: "SN74HC32",
      function: "OR2",
      gates_per_package: 4,
      inputs_per_gate: 2,
      source_url: "https://www.ti.com/lit/ds/symlink/sn74hc32.pdf",
    },
    {
      part_number: "SN74HC04",
      function: "NOT",
      gates_per_package: 6,
      inputs_per_gate: 1,
      source_url: "https://www.ti.com/lit/ds/symlink/sn74hc04.pdf",
    },
  ]
}

///|
/// Return whole packages needed for a nonnegative number of gates.
pub fn LogicPart::packages_required(self : LogicPart, gate_count : Int) -> Int? {
  @fusekite.GateCost::packages_for(gate_count, self.gates_per_package)
}

///|
/// Estimate package counts for the direct two-level SOP mapping.
///
/// NAND2 is cataloged for manual alternatives, but this mapping uses AND2,
/// OR2 and NOT parts. Counts are rounded independently by package family.
pub fn estimate_74hc_packages(cost : @fusekite.GateCost) -> PackagePlan {
  {
    inverters: match @fusekite.GateCost::packages_for(cost.inverters, 6) {
      Some(count) => count
      None => 0
    },
    and_packages: match @fusekite.GateCost::packages_for(cost.and2_gates, 4) {
      Some(count) => count
      None => 0
    },
    or_packages: match @fusekite.GateCost::packages_for(cost.or2_gates, 4) {
      Some(count) => count
      None => 0
    },
  }
}

///|
test "catalog channels match the documented device families" {
  let catalog = standard_74hc_catalog()
  assert_eq(catalog.length(), 4)
  assert_eq(catalog[0].part_number, "SN74HC00")
  assert_eq(catalog[0].function, "NAND2")
  assert_eq(catalog[0].gates_per_package, 4)
  assert_eq(catalog[1].function, "AND2")
  assert_eq(catalog[1].gates_per_package, 4)
  assert_eq(catalog[2].function, "OR2")
  assert_eq(catalog[2].gates_per_package, 4)
  assert_eq(catalog[3].function, "NOT")
  assert_eq(catalog[3].gates_per_package, 6)
  for part in catalog {
    assert_true(part.source_url.has_prefix("https://www.ti.com/lit/ds/"))
  }
}

///|
test "package estimate rounds each part family independently" {
  let cost = match @fusekite.GateCost::new(7, 5, 4) {
    Some(cost) => cost
    None => fail("valid gate cost was rejected")
  }
  let plan = estimate_74hc_packages(cost)
  assert_eq(plan.inverters, 2)
  assert_eq(plan.and_packages, 2)
  assert_eq(plan.or_packages, 1)
  assert_eq(standard_74hc_catalog()[0].packages_required(5), Some(2))
  assert_eq(standard_74hc_catalog()[3].packages_required(7), Some(2))
}
