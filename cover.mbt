///|
/// A minimum two-level sum-of-products cover for a validated truth table.
pub struct CoverSolution {
  selected : Array[Cube]
  essential : Array[Cube]
  term_count : Int
  literal_count : Int
  explored_states : Int
}

///|
priv struct CoverSearchState {
  mut best_indices : Array[Int]
  mut best_literal_count : Int
  mut explored_states : Int
}

///|
fn contains_index(indices : Array[Int], target : Int) -> Bool {
  indices.contains(target)
}

///|
fn copy_indices(indices : Array[Int]) -> Array[Int] {
  indices.copy()
}

///|
fn sorted_insert(indices : Array[Int], value : Int) -> Array[Int] {
  let result : Array[Int] = []
  let mut inserted = false
  for index in indices {
    if !inserted && value < index {
      result.push(value)
      inserted = true
    }
    result.push(index)
  }
  if !inserted {
    result.push(value)
  }
  result
}

///|
fn same_indices(left : Array[Int], right : Array[Int]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if left[i] != right[i] {
      return false
    }
  }
  true
}

///|
fn was_visited(visited : Array[Array[Int]], chosen : Array[Int]) -> Bool {
  for state in visited {
    if same_indices(state, chosen) {
      return true
    }
  }
  false
}

///|
fn row_is_covered(
  chart : CoverageChart,
  row_index : Int,
  chosen : Array[Int],
) -> Bool {
  for prime_index in chart.coverers[row_index] {
    if contains_index(chosen, prime_index) {
      return true
    }
  }
  false
}

///|
fn literal_cost(chart : CoverageChart, indices : Array[Int]) -> Int {
  let mut total = 0
  for index in indices {
    total += chart.primes[index].literal_count()
  }
  total
}

///|
fn lexicographically_before(left : Array[Int], right : Array[Int]) -> Bool {
  for i in 0..<left.length() {
    if left[i] < right[i] {
      return true
    }
    if left[i] > right[i] {
      return false
    }
  }
  false
}

///|
fn is_better_cover(
  chart : CoverageChart,
  candidate : Array[Int],
  state : CoverSearchState,
) -> Bool {
  if candidate.length() < state.best_indices.length() {
    return true
  }
  if candidate.length() > state.best_indices.length() {
    return false
  }
  let candidate_literals = literal_cost(chart, candidate)
  if candidate_literals < state.best_literal_count {
    return true
  }
  if candidate_literals > state.best_literal_count {
    return false
  }
  lexicographically_before(candidate, state.best_indices)
}

///|
fn newly_covered_count(
  chart : CoverageChart,
  prime_index : Int,
  chosen : Array[Int],
) -> Int {
  let mut count = 0
  for row_index in 0..<chart.minterms.length() {
    if !row_is_covered(chart, row_index, chosen) &&
      chart.coverers[row_index].contains(prime_index) {
      count += 1
    }
  }
  count
}

///|
fn search_cover(
  chart : CoverageChart,
  chosen : Array[Int],
  state : CoverSearchState,
  visited : Array[Array[Int]],
) -> Unit {
  if was_visited(visited, chosen) {
    return
  }
  visited.push(copy_indices(chosen))
  state.explored_states += 1

  let mut uncovered_count = 0
  let mut smallest_options = 2147483647
  let mut branch_options : Array[Int] = []
  for row_index in 0..<chart.minterms.length() {
    if !row_is_covered(chart, row_index, chosen) {
      uncovered_count += 1
      let options = chart.coverers[row_index].filter(index => {
        !contains_index(chosen, index)
      })
      if options.length() == 0 {
        return
      }
      if options.length() < smallest_options {
        smallest_options = options.length()
        branch_options = options
      }
    }
  }

  if uncovered_count == 0 {
    if is_better_cover(chart, chosen, state) {
      state.best_indices = copy_indices(chosen)
      state.best_literal_count = literal_cost(chart, chosen)
    }
    return
  }
  if chosen.length() >= state.best_indices.length() {
    return
  }

  let mut maximum_gain = 0
  for prime_index in 0..<chart.primes.length() {
    if !contains_index(chosen, prime_index) {
      maximum_gain = Int::max(
        maximum_gain,
        newly_covered_count(chart, prime_index, chosen),
      )
    }
  }
  if maximum_gain == 0 {
    return
  }
  let lower_bound = (uncovered_count + maximum_gain - 1) / maximum_gain
  if chosen.length() + lower_bound > state.best_indices.length() {
    return
  }

  branch_options.sort_by((left, right) => {
    let left_gain = newly_covered_count(chart, left, chosen)
    let right_gain = newly_covered_count(chart, right, chosen)
    if left_gain > right_gain {
      -1
    } else if left_gain < right_gain {
      1
    } else {
      left - right
    }
  })
  for prime_index in branch_options {
    search_cover(chart, sorted_insert(chosen, prime_index), state, visited)
  }
}

///|
/// Select an exact minimum SOP cover for a validated truth table.
///
/// The comparison order is: fewest product terms, fewest total literals, then
/// the lexicographically smallest sorted list of patterns (`- < 0 < 1`).
pub fn minimize_sop(spec : TruthSpec) -> CoverSolution {
  let refinement = refine(spec)
  let chart = make_coverage_chart(spec, refinement)
  let initial_best : Array[Int] = []
  for index in 0..<chart.primes.length() {
    initial_best.push(index)
  }
  let initial_literals = literal_cost(chart, initial_best)
  let essentials = chart.essential_indices()
  let state = CoverSearchState::{
    best_indices: initial_best,
    best_literal_count: initial_literals,
    explored_states: 0,
  }
  let visited : Array[Array[Int]] = []
  search_cover(chart, essentials, state, visited)

  let selected = state.best_indices.map(index => chart.primes[index])
  let essential = essentials.map(index => chart.primes[index])
  {
    selected,
    essential,
    term_count: selected.length(),
    literal_count: literal_cost(chart, state.best_indices),
    explored_states: state.explored_states,
  }
}

///|
pub fn CoverSolution::patterns(self : CoverSolution) -> Array[String] {
  self.selected.map(cube => cube.pattern())
}

///|
test "exact cover returns a minimum implicant set" {
  let spec = match TruthSpec::new(3, [1, 3, 5, 7], []) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }
  let solution = minimize_sop(spec)
  assert_eq(solution.patterns(), ["--1"])
  assert_eq(solution.term_count, 1)
  assert_eq(solution.literal_count, 1)
  assert_eq(solution.essential.length(), 1)
}

///|
test "equal-cost covers use the documented pattern tie-break" {
  let spec = match TruthSpec::new(3, [0, 1, 2, 5, 6, 7], []) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }
  let solution = minimize_sop(spec)
  assert_eq(solution.patterns(), ["-01", "0-0", "11-"])
  assert_eq(solution.term_count, 3)
  assert_eq(solution.literal_count, 6)
}

///|
test "empty on-set produces an empty cover" {
  let spec = match TruthSpec::new(2, [], []) {
    Some(spec) => spec
    None => fail("valid zero function was rejected")
  }
  let solution = minimize_sop(spec)
  assert_eq(solution.patterns(), [])
  assert_eq(solution.term_count, 0)
  assert_eq(solution.literal_count, 0)
}

///|
test "selected cubes cover required rows and avoid required zeroes" {
  let spec = match TruthSpec::new(3, [0, 1, 6, 7], [2]) {
    Some(spec) => spec
    None => fail("valid don't-care table was rejected")
  }
  let solution = minimize_sop(spec)
  assert_eq(solution.patterns(), ["00-", "11-"])
  for row in 0..<8 {
    let mut selected_count = 0
    for cube in solution.selected {
      if cube.covers_row(row) {
        selected_count += 1
      }
    }
    if row == 0 || row == 1 || row == 6 || row == 7 {
      assert_true(selected_count > 0)
    } else if row != 2 {
      assert_eq(selected_count, 0)
    }
  }
}

///|
test "three-input covers match an exhaustive prime-subset oracle" {
  for truth_bits in 0..<256 {
    let on_set : Array[Int] = []
    for row in 0..<8 {
      if ((truth_bits >> row) & 1) == 1 {
        on_set.push(row)
      }
    }
    let spec = match TruthSpec::new(3, on_set, []) {
      Some(spec) => spec
      None => fail("generated truth table was rejected")
    }
    let primes = refine(spec).primes
    let solution = minimize_sop(spec)
    let mut best_terms = 2147483647
    let mut best_literals = 2147483647
    for subset in 0..<(1 << primes.length()) {
      let selected : Array[Cube] = []
      for index in 0..<primes.length() {
        if ((subset >> index) & 1) == 1 {
          selected.push(primes[index])
        }
      }
      let mut equivalent = true
      for row in 0..<8 {
        let mut actual = false
        for cube in selected {
          if cube.covers_row(row) {
            actual = true
          }
        }
        if actual != (((truth_bits >> row) & 1) == 1) {
          equivalent = false
        }
      }
      if equivalent {
        let terms = selected.length()
        let mut actual_literals = 0
        for cube in selected {
          actual_literals += cube.literal_count()
        }
        if terms < best_terms ||
          (terms == best_terms && actual_literals < best_literals) {
          best_terms = terms
          best_literals = actual_literals
        }
      }
    }
    assert_eq(solution.term_count, best_terms)
    assert_eq(solution.literal_count, best_literals)
  }
}
