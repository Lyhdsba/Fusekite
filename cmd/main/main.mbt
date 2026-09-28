///|
/// Demonstrate exact SOP cover selection on a simple logic function.
fn main raise {
  let spec = match @fusekite.TruthSpec::new(3, [1, 3, 5, 7], []) {
    Some(spec) => spec
    None => fail("example truth table is invalid")
  }
  let solution = @fusekite.minimize_sop(spec)
  println("F(A, B, C) = Σm(1, 3, 5, 7)")
  println("minimum SOP patterns:")
  for pattern in solution.patterns() {
    println("  \{pattern}")
  }
  println("terms: \{solution.term_count}, literals: \{solution.literal_count}")
}
