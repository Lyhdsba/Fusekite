///|
/// A validated single-output truth-table specification.
///
/// Rows are numbered in binary order: the first variable is the most
/// significant bit. The all-zero row is row 0.
pub struct TruthSpec {
  input_count : Int
  on_set : Array[Int]
  dont_cares : Array[Int]
}

///|
/// A product term encoded with `0`, `1`, and `-` characters.
/// A dash means that input does not affect the output.
pub struct Cube {
  width : Int
  value : Int
  wildcard : Int
}

///|
/// Intermediate Quine–McCluskey rounds and the prime implicants found so far.
pub struct Refinement {
  rounds : Array[Array[Cube]]
  primes : Array[Cube]
}

///|
fn contains(values : Array[Int], target : Int) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn has_duplicate_after(values : Array[Int], start : Int, target : Int) -> Bool {
  for i in start..<values.length() {
    if values[i] == target {
      return true
    }
  }
  false
}

///|
fn same_shape(left : Cube, right : Cube) -> Bool {
  left.width == right.width &&
  left.value == right.value &&
  left.wildcard == right.wildcard
}

///|
fn append_unique(cubes : Array[Cube], candidate : Cube) -> Unit {
  let mut found = false
  for cube in cubes {
    if same_shape(cube, candidate) {
      found = true
    }
  }
  if !found {
    cubes.push(candidate)
  }
}

///|
fn Cube::from_row(row : Int, width : Int) -> Cube {
  { width, value: row, wildcard: 0, }
}

///|
fn Cube::merge(self : Cube, other : Cube) -> Cube? {
  if self.width != other.width || self.wildcard != other.wildcard {
    return None
  }
  let difference = self.value ^ other.value
  if difference == 0 ||
    (difference & (difference - 1)) != 0 ||
    (difference & self.wildcard) != 0 {
    return None
  }
  Some({
    width: self.width,
    value: self.value & (((1 << self.width) - 1) ^ difference),
    wildcard: self.wildcard | difference,
  })
}

///|
fn Cube::covers_row(self : Cube, row : Int) -> Bool {
  (row & (((1 << self.width) - 1) ^ self.wildcard)) == self.value
}

///|
fn has_on_set_coverage(cube : Cube, on_set : Array[Int]) -> Bool {
  for row in on_set {
    if cube.covers_row(row) {
      return true
    }
  }
  false
}

///|
fn merge_round(current : Array[Cube]) -> (Array[Cube], Array[Bool]) {
  let used : Array[Bool] = []
  for _ in 0..<current.length() {
    used.push(false)
  }
  let next : Array[Cube] = []
  for i in 0..<current.length() {
    for j in (i + 1)..<current.length() {
      match current[i].merge(current[j]) {
        Some(cube) => {
          used[i] = true
          used[j] = true
          append_unique(next, cube)
        }
        None => ()
      }
    }
  }
  (next, used)
}

///|
/// Validate a single-output truth table.
///
/// `input_count` is limited to eight so a complete truth table stays bounded.
/// Minterms and don't-care rows must be unique, in range, and disjoint.
pub fn TruthSpec::new(
  input_count : Int,
  on_set : Array[Int],
  dont_cares : Array[Int],
) -> TruthSpec? {
  if input_count < 1 || input_count > 8 {
    return None
  }
  let row_count = 1 << input_count
  for i in 0..<on_set.length() {
    let row = on_set[i]
    if row < 0 ||
      row >= row_count ||
      has_duplicate_after(on_set, i + 1, row) ||
      contains(dont_cares, row) {
      return None
    }
  }
  for i in 0..<dont_cares.length() {
    let row = dont_cares[i]
    if row < 0 ||
      row >= row_count ||
      has_duplicate_after(dont_cares, i + 1, row) {
      return None
    }
  }
  Some({ input_count, on_set, dont_cares, })
}

///|
/// Number of input variables in the table.
pub fn TruthSpec::variable_count(self : TruthSpec) -> Int {
  self.input_count
}

///|
/// Number of rows whose output is one.
pub fn TruthSpec::minterm_count(self : TruthSpec) -> Int {
  self.on_set.length()
}

///|
/// Render the implicant as a fixed-width binary pattern.
pub fn Cube::pattern(self : Cube) -> String {
  let mut result = ""
  for position in 0..<self.width {
    let bit = self.width - position - 1
    if ((self.wildcard >> bit) & 1) == 1 {
      result = result + "-"
    } else if ((self.value >> bit) & 1) == 1 {
      result = result + "1"
    } else {
      result = result + "0"
    }
  }
  result
}

///|
/// Count the literals left in this product term.
pub fn Cube::literal_count(self : Cube) -> Int {
  let mut wildcards = 0
  for bit in 0..<self.width {
    if ((self.wildcard >> bit) & 1) == 1 {
      wildcards += 1
    }
  }
  self.width - wildcards
}

///|
/// Produce every prime implicant using deterministic pairwise merge rounds.
/// Don't-care rows participate in merging but are omitted from the final prime
/// list when they cover no required minterm.
pub fn refine(spec : TruthSpec) -> Refinement {
  let row_count = 1 << spec.input_count
  let mut current : Array[Cube] = []
  for row in 0..<row_count {
    if contains(spec.on_set, row) || contains(spec.dont_cares, row) {
      current.push(Cube::from_row(row, spec.input_count))
    }
  }

  let rounds : Array[Array[Cube]] = []
  let primes : Array[Cube] = []
  while current.length() > 0 {
    rounds.push(current)
    let (next, used) = merge_round(current)
    for i in 0..<current.length() {
      if !used[i] && has_on_set_coverage(current[i], spec.on_set) {
        append_unique(primes, current[i])
      }
    }
    current = next
  }
  { rounds, primes, }
}
