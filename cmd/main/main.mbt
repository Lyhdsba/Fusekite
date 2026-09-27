///|
/// Demonstrate the first refinement increment on a simple logic function.
fn main raise {
  let spec = match @fusekite.TruthSpec::new(3, [1, 3, 5, 7], []) {
    Some(spec) => spec
    None => fail("example truth table is invalid")
  }
  let report = @fusekite.refine(spec)
  println("F(A, B, C) = Σm(1, 3, 5, 7)")
  println("prime implicants:")
  for cube in report.primes {
    println("  \{cube.pattern()}")
  }
}
