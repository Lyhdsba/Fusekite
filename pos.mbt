///|
/// A sum clause represented by the cube on which it is false.
/// In its pattern, `0` means a positive literal, `1` a complemented literal,
/// and `-` an omitted variable. The first variable is the most significant bit.
pub struct PosClause {
  priv zero_cube : Cube
}

///|
/// An exact minimum two-level product-of-sums result.
/// Clauses and essential clauses are stored privately; accessors return copies.
pub struct PosSolution {
  priv input_count : Int
  priv selected : Array[PosClause]
  priv essential : Array[PosClause]
  clause_count : Int
  literal_count : Int
  explored_states : Int
}

///|
/// Render the clause's falsifying pattern, not a product-term pattern.
/// For example, `01-` represents `(A OR NOT B)`; `---` is an empty sum (false).
pub fn PosClause::pattern(self : PosClause) -> String {
  self.zero_cube.pattern()
}

///|
pub fn PosClause::literal_count(self : PosClause) -> Int {
  self.zero_cube.literal_count()
}

///|
/// Evaluate a clause; return None for a row outside its truth-table range.
pub fn PosClause::evaluate(self : PosClause, row : Int) -> Bool? {
  if row < 0 || row >= 1 << self.zero_cube.width {
    return None
  }
  Some(!self.zero_cube.covers_row(row))
}

///|
pub fn PosSolution::variable_count(self : PosSolution) -> Int {
  self.input_count
}

///|
pub fn PosSolution::clauses(self : PosSolution) -> Array[PosClause] {
  self.selected.copy()
}

///|
/// Clauses uniquely needed by at least one required zero-row in the prime chart.
pub fn PosSolution::essential_clauses(self : PosSolution) -> Array[PosClause] {
  self.essential.copy()
}

///|
pub fn PosSolution::patterns(self : PosSolution) -> Array[String] {
  self.selected.map(clause => clause.pattern())
}

///|
/// Evaluate the selected product of sums, including its chosen don't-care values.
/// An empty product is true. An empty sum clause makes the product false.
/// Return None for a row outside the validated 1–8 input truth-table range.
pub fn PosSolution::evaluate(self : PosSolution, row : Int) -> Bool? {
  if row < 0 || row >= 1 << self.input_count {
    return None
  }
  for clause in self.selected {
    if clause.zero_cube.covers_row(row) {
      return Some(false)
    }
  }
  Some(true)
}

///|
/// Minimize a validated truth table as a product of sums using De Morgan's law.
/// The complement's required ones are exactly the original required zeroes;
/// don't-care rows remain don't-cares and need no coverage.
/// Rank by clause count, total literals, then the sorted falsifying-pattern list
/// (`- < 0 < 1`). This reuses the exact SOP selector without changing its contract.
/// All-one tables and tables with no cared rows select an empty product (true).
/// All-zero tables select one empty sum clause (false).
pub fn minimize_pos(spec : TruthSpec) -> PosSolution {
  let off_set : Array[Int] = []
  for row in 0..<(1 << spec.input_count) {
    if !contains(spec.on_set, row) && !contains(spec.dont_cares, row) {
      off_set.push(row)
    }
  }
  let complement = TruthSpec::{
    input_count: spec.input_count,
    on_set: off_set,
    dont_cares: spec.dont_cares.copy(),
  }
  let cover = minimize_sop(complement)
  {
    input_count: spec.input_count,
    selected: cover.selected.map(cube => PosClause::{ zero_cube: cube, }),
    essential: cover.essential.map(cube => PosClause::{ zero_cube: cube, }),
    clause_count: cover.term_count,
    literal_count: cover.literal_count,
    explored_states: cover.explored_states,
  }
}
