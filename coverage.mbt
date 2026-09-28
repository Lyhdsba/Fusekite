///|
/// A prime-implicant chart. Each entry in `coverers` corresponds to the
/// minterm at the same index and contains indexes into `primes`.
pub struct CoverageChart {
  minterms : Array[Int]
  primes : Array[Cube]
  coverers : Array[Array[Int]]
}

///|
fn compare_cubes(left : Cube, right : Cube) -> Int {
  for bit in 0..<left.width {
    let shift = left.width - bit - 1
    let left_rank = if ((left.wildcard >> shift) & 1) == 1 {
      0
    } else if ((left.value >> shift) & 1) == 0 {
      1
    } else {
      2
    }
    let right_rank = if ((right.wildcard >> shift) & 1) == 1 {
      0
    } else if ((right.value >> shift) & 1) == 0 {
      1
    } else {
      2
    }
    if left_rank < right_rank {
      return -1
    }
    if left_rank > right_rank {
      return 1
    }
  }
  0
}

///|
/// Build a row-to-prime coverage chart from a validated table and its
/// refinement result.
pub fn make_coverage_chart(
  spec : TruthSpec,
  refinement : Refinement,
) -> CoverageChart {
  let primes = refinement.primes.copy()
  primes.sort_by(compare_cubes)
  let coverers : Array[Array[Int]] = []
  for row in spec.on_set {
    let row_coverers : Array[Int] = []
    for i in 0..<primes.length() {
      if primes[i].covers_row(row) {
        row_coverers.push(i)
      }
    }
    coverers.push(row_coverers)
  }
  { minterms: spec.on_set.copy(), primes, coverers, }
}

///|
test "coverage chart maps each required row to its prime implicants" {
  let spec = match TruthSpec::new(3, [7, 1, 5, 3], []) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }
  let chart = make_coverage_chart(spec, refine(spec))
  assert_eq(chart.minterms, [7, 1, 5, 3])
  assert_eq(chart.primes.length(), 1)
  assert_eq(chart.primes[0].pattern(), "--1")
  assert_eq(chart.coverers, [[0], [0], [0], [0]])
}

///|
test "coverage chart omits don't-care-only rows" {
  let spec = match TruthSpec::new(3, [1], [3]) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }
  let chart = make_coverage_chart(spec, refine(spec))
  assert_eq(chart.minterms, [1])
  assert_eq(chart.coverers, [[0]])
}
