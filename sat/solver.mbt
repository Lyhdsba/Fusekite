///|
/// A validated CNF formula over variables numbered from 1 through
/// `variable_count`. A positive literal denotes a variable; a negative literal
/// denotes its complement. Empty clauses are allowed and make the formula
/// unsatisfiable. Tautological clauses are removed during construction.
pub struct CnfFormula {
  priv variable_count : Int
  priv clauses : Array[Array[Int]]
}

///|
/// A Boolean expression that can be compiled to equisatisfiable CNF with
/// Tseitin variables.
pub(all) enum BoolExpr {
  Constant(Bool)
  Variable(Int)
  Not(BoolExpr)
  And(BoolExpr, BoolExpr)
  Or(BoolExpr, BoolExpr)
  Xor(BoolExpr, BoolExpr)
}

///|
/// Error returned while reading a DIMACS CNF document.
pub enum DimacsError {
  MissingHeader
  InvalidHeader
  InvalidInteger
  InvalidLiteral
  ClauseCountMismatch
  TrailingClauseData
}

///|
/// Search bound for the deterministic DPLL solver.
pub struct SolverConfig {
  priv max_search_nodes : Int
}

///|
/// Result of a bounded SAT search. `Unknown` means the configured search-node
/// budget was reached before satisfiability or unsatisfiability was proved.
pub enum SatOutcome {
  Satisfiable(Array[Bool])
  Unsatisfiable
  Unknown
}

///|
/// Counters collected while solving one formula.
pub struct SolverStats {
  search_nodes : Int
  decisions : Int
  propagations : Int
  conflicts : Int
}

///|
/// SAT outcome and reproducible search counters.
pub struct SatReport {
  outcome : SatOutcome
  stats : SolverStats
}

///|
priv struct SearchState {
  clauses : Array[Array[Int]]
  watch_lists : Array[Array[Int]]
  watch0 : Array[Int]
  watch1 : Array[Int]
  mut search_nodes : Int
  mut decisions : Int
  mut propagations : Int
  mut conflicts : Int
}

///|
priv struct CnfEncoder {
  mut variable_count : Int
  clauses : Array[Array[Int]]
  source_variable_count : Int
  mut expression_nodes : Int
  expression_cache : Array[CnfCacheEntry]
}

///|
priv struct CnfCacheEntry {
  expression : BoolExpr
  literal : Int
}

///|
priv enum SearchResult {
  Found(Array[Bool])
  ProvedUnsat
  BudgetExhausted
}

///|
fn same_clause(left : Array[Int], right : Array[Int]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for index in 0..<left.length() {
    if left[index] != right[index] {
      return false
    }
  }
  true
}

///|
/// Validate and normalize a CNF formula.
///
/// `variable_count` is limited to 4,096. Clause inputs are copied, duplicate
/// literals are removed, literals are sorted, duplicate clauses are removed,
/// and tautological clauses are omitted. A clause containing no literals is
/// preserved as an immediate contradiction.
pub fn CnfFormula::new(
  variable_count : Int,
  clauses : Array[Array[Int]],
) -> CnfFormula? {
  if variable_count < 0 || variable_count > 4096 {
    return None
  }
  let normalized_clauses : Array[Array[Int]] = []
  for clause in clauses {
    let normalized : Array[Int] = []
    let mut tautology = false
    for literal in clause {
      if literal == 0 || literal > variable_count || literal < -variable_count {
        return None
      }
      if normalized.contains(-literal) {
        tautology = true
      } else if !normalized.contains(literal) {
        normalized.push(literal)
      }
    }
    if !tautology {
      normalized.sort_by((left, right) => left - right)
      let mut duplicate = false
      for existing in normalized_clauses {
        if same_clause(existing, normalized) {
          duplicate = true
        }
      }
      if !duplicate {
        normalized_clauses.push(normalized)
      }
    }
  }
  Some({ variable_count, clauses: normalized_clauses, })
}

///|
/// Create a positive search budget. Values above one million are rejected to
/// make accidental unbounded searches harder to trigger.
pub fn SolverConfig::new(max_search_nodes : Int) -> SolverConfig? {
  if max_search_nodes < 1 || max_search_nodes > 1_000_000 {
    return None
  }
  Some({ max_search_nodes, })
}

///|
fn CnfEncoder::fresh_literal(self : CnfEncoder) -> Int? {
  if self.variable_count >= 4096 {
    return None
  }
  self.variable_count += 1
  Some(self.variable_count)
}

///|
fn same_bool_expr(left : BoolExpr, right : BoolExpr) -> Bool {
  match (left, right) {
    (Constant(left_value), Constant(right_value)) => left_value == right_value
    (Variable(left_index), Variable(right_index)) => left_index == right_index
    (Not(left_child), Not(right_child)) =>
      same_bool_expr(left_child, right_child)
    (And(left_first, left_second), And(right_first, right_second)) =>
      same_bool_expr(left_first, right_first) &&
      same_bool_expr(left_second, right_second)
    (Or(left_first, left_second), Or(right_first, right_second)) =>
      same_bool_expr(left_first, right_first) &&
      same_bool_expr(left_second, right_second)
    (Xor(left_first, left_second), Xor(right_first, right_second)) =>
      same_bool_expr(left_first, right_first) &&
      same_bool_expr(left_second, right_second)
    _ => false
  }
}

///|
fn CnfEncoder::encode(
  self : CnfEncoder,
  expression : BoolExpr,
  depth : Int,
) -> Int? {
  for index in 0..<self.expression_cache.length() {
    let entry = self.expression_cache[index]
    if same_bool_expr(entry.expression, expression) {
      return Some(entry.literal)
    }
  }
  if depth > 1024 {
    return None
  }
  self.expression_nodes += 1
  if self.expression_nodes > 100_000 {
    return None
  }
  let result = match expression {
    Constant(value) => {
      let literal = match self.fresh_literal() {
        Some(literal) => literal
        None => return None
      }
      self.clauses.push(if value { [literal] } else { [-literal] })
      Some(literal)
    }
    Variable(index) =>
      if index < 1 || index > self.source_variable_count {
        None
      } else {
        Some(index)
      }
    Not(child) => self.encode(child, depth + 1).map(literal => -literal)
    And(left, right) => {
      let left_literal = match self.encode(left, depth + 1) {
        Some(literal) => literal
        None => return None
      }
      let right_literal = match self.encode(right, depth + 1) {
        Some(literal) => literal
        None => return None
      }
      let result = match self.fresh_literal() {
        Some(literal) => literal
        None => return None
      }
      self.clauses.push([-result, left_literal])
      self.clauses.push([-result, right_literal])
      self.clauses.push([result, -left_literal, -right_literal])
      Some(result)
    }
    Or(left, right) => {
      let left_literal = match self.encode(left, depth + 1) {
        Some(literal) => literal
        None => return None
      }
      let right_literal = match self.encode(right, depth + 1) {
        Some(literal) => literal
        None => return None
      }
      let result = match self.fresh_literal() {
        Some(literal) => literal
        None => return None
      }
      self.clauses.push([result, -left_literal])
      self.clauses.push([result, -right_literal])
      self.clauses.push([-result, left_literal, right_literal])
      Some(result)
    }
    Xor(left, right) => {
      let left_literal = match self.encode(left, depth + 1) {
        Some(literal) => literal
        None => return None
      }
      let right_literal = match self.encode(right, depth + 1) {
        Some(literal) => literal
        None => return None
      }
      let result = match self.fresh_literal() {
        Some(literal) => literal
        None => return None
      }
      self.clauses.push([left_literal, right_literal, -result])
      self.clauses.push([-left_literal, -right_literal, -result])
      self.clauses.push([left_literal, -right_literal, result])
      self.clauses.push([-left_literal, right_literal, result])
      Some(result)
    }
  }
  match result {
    Some(literal) => {
      self.expression_cache.push({ expression, literal, })
      Some(literal)
    }
    None => None
  }
}

///|
/// Compile an expression and assert that it is true.
///
/// Variables in the expression are numbered 1 through `variable_count`.
/// The encoder uses Tseitin definitions and structurally shares repeated
/// subexpressions rather than distributing into potentially exponential
/// DNF/CNF. Generated clauses and variables are validated by the same limits
/// as directly constructed formulas. Distinct expression nodes are capped at
/// 100,000 and nesting at 1,024 levels.
pub fn CnfFormula::from_expression(
  variable_count : Int,
  expression : BoolExpr,
) -> CnfFormula? {
  if variable_count < 0 || variable_count > 256 {
    return None
  }
  let encoder = CnfEncoder::{
    variable_count,
    clauses: [],
    source_variable_count: variable_count,
    expression_nodes: 0,
    expression_cache: [],
  }
  let output = match encoder.encode(expression, 0) {
    Some(literal) => literal
    None => return None
  }
  encoder.clauses.push([output])
  CnfFormula::new(encoder.variable_count, encoder.clauses)
}

///|
fn dimacs_tokens(line : StringView) -> Array[String] {
  let tokens : Array[String] = []
  let token : Array[Char] = []
  for character in line.iter() {
    if character == ' ' || character == '\t' || character == '\r' {
      if token.length() > 0 {
        tokens.push(String::from_array(token))
        token.clear()
      }
    } else {
      token.push(character)
    }
  }
  if token.length() > 0 {
    tokens.push(String::from_array(token))
  }
  tokens
}

///|
fn parse_dimacs_integer(token : String, max_magnitude : Int) -> Int? {
  let characters = token.to_array()
  if characters.length() == 0 {
    return None
  }
  let mut index = 0
  let mut negative = false
  if characters[0] == '-' {
    negative = true
    index = 1
  } else if characters[0] == '+' {
    index = 1
  }
  if index >= characters.length() {
    return None
  }
  let mut value = 0
  while index < characters.length() {
    let digit = characters[index].to_int() - '0'.to_int()
    if digit < 0 ||
      digit > 9 ||
      digit > max_magnitude ||
      value > (max_magnitude - digit) / 10 {
      return None
    }
    value = value * 10 + digit
    index += 1
  }
  if negative {
    Some(-value)
  } else {
    Some(value)
  }
}

///|
/// Parse a DIMACS CNF text document.
///
/// The parser accepts standard `c` comment lines, one `p cnf V C` header,
/// clauses spanning lines, and zero-terminated clauses. It checks the declared
/// variable and clause counts and applies the normal CNF validation rules.
pub fn CnfFormula::parse_dimacs(
  text : String,
) -> Result[CnfFormula, DimacsError] {
  let mut header_seen = false
  let mut variable_count = 0
  let mut declared_clause_count = 0
  let clauses : Array[Array[Int]] = []
  let current_clause : Array[Int] = []
  for line in text.split("\n") {
    let tokens = dimacs_tokens(line)
    if tokens.length() == 0 || tokens[0] == "c" {
      continue
    }
    if !header_seen {
      if tokens.length() != 4 || tokens[0] != "p" || tokens[1] != "cnf" {
        return Err(InvalidHeader)
      }
      variable_count = match parse_dimacs_integer(tokens[2], 4096) {
        Some(value) => value
        None => return Err(InvalidInteger)
      }
      declared_clause_count = match parse_dimacs_integer(tokens[3], 1_000_000) {
        Some(value) => value
        None => return Err(InvalidInteger)
      }
      if variable_count < 0 || declared_clause_count < 0 {
        return Err(InvalidHeader)
      }
      header_seen = true
      continue
    }
    for token in tokens {
      let literal = match parse_dimacs_integer(token, 4096) {
        Some(value) => value
        None => return Err(InvalidInteger)
      }
      if literal == 0 {
        clauses.push(current_clause.copy())
        current_clause.clear()
        if clauses.length() > declared_clause_count {
          return Err(TrailingClauseData)
        }
      } else {
        if literal > variable_count || literal < -variable_count {
          return Err(InvalidLiteral)
        }
        current_clause.push(literal)
      }
    }
  }
  if !header_seen {
    return Err(MissingHeader)
  }
  if current_clause.length() > 0 || clauses.length() != declared_clause_count {
    return Err(ClauseCountMismatch)
  }
  match CnfFormula::new(variable_count, clauses) {
    Some(formula) => Ok(formula)
    None => Err(InvalidLiteral)
  }
}

///|
/// Return the declared number of variables.
pub fn CnfFormula::variable_count(self : CnfFormula) -> Int {
  self.variable_count
}

///|
/// Return defensive copies of the normalized clauses.
pub fn CnfFormula::clauses(self : CnfFormula) -> Array[Array[Int]] {
  self.clauses.map(clause => clause.copy())
}

///|
fn literal_is_satisfied(literal : Int, assignment : Array[Int]) -> Bool {
  let value = assignment[Int::abs(literal) - 1]
  if literal > 0 {
    value == 1
  } else {
    value == 0
  }
}

///|
fn watch_index(literal : Int) -> Int {
  let base = (Int::abs(literal) - 1) * 2
  if literal > 0 {
    base
  } else {
    base + 1
  }
}

///|
fn enqueue_literal(
  literal : Int,
  assignment : Array[Int],
  trail : Array[Int],
) -> Bool {
  let variable = Int::abs(literal) - 1
  let required_value = if literal > 0 { 1 } else { 0 }
  if assignment[variable] == -1 {
    assignment[variable] = required_value
    trail.push(literal)
    true
  } else {
    assignment[variable] == required_value
  }
}

///|
fn initialize_watches(
  state : SearchState,
  assignment : Array[Int],
  trail : Array[Int],
) -> Bool {
  for clause_index in 0..<state.clauses.length() {
    let clause = state.clauses[clause_index]
    if clause.length() == 0 {
      state.conflicts += 1
      return false
    }
    state.watch0.push(0)
    state.watch1.push(if clause.length() == 1 { 0 } else { 1 })
    state.watch_lists[watch_index(clause[0])].push(clause_index)
    if clause.length() > 1 {
      state.watch_lists[watch_index(clause[1])].push(clause_index)
    } else if !enqueue_literal(clause[0], assignment, trail) {
      state.conflicts += 1
      return false
    } else {
      state.propagations += 1
    }
  }
  true
}

///|
fn propagate_watched(
  state : SearchState,
  assignment : Array[Int],
  trail : Array[Int],
  qhead : Int,
) -> (Bool, Int) {
  let mut queue_head = qhead
  while queue_head < trail.length() {
    let false_literal = -trail[queue_head]
    let false_watch_index = watch_index(false_literal)
    let current_watchers = state.watch_lists[false_watch_index].copy()
    let remaining_watchers : Array[Int] = []
    let mut conflict = false
    for clause_index in current_watchers {
      let clause = state.clauses[clause_index]
      let old_watch0 = state.watch0[clause_index]
      let old_watch1 = state.watch1[clause_index]
      let false_slot = if clause[old_watch0] == false_literal {
        Some(0)
      } else if clause[old_watch1] == false_literal {
        Some(1)
      } else {
        None
      }
      match false_slot {
        None => ()
        Some(slot) => {
          let false_position = if slot == 0 { old_watch0 } else { old_watch1 }
          let other_position = if slot == 0 { old_watch1 } else { old_watch0 }
          let other_literal = clause[other_position]
          if literal_is_satisfied(other_literal, assignment) {
            remaining_watchers.push(clause_index)
          } else {
            let mut replacement : Int? = None
            for position in 0..<clause.length() {
              if position != false_position && position != other_position {
                let candidate = clause[position]
                let value = assignment[Int::abs(candidate) - 1]
                if value == -1 || literal_is_satisfied(candidate, assignment) {
                  if replacement is None {
                    replacement = Some(position)
                  }
                }
              }
            }
            match replacement {
              Some(position) => {
                if slot == 0 {
                  state.watch0[clause_index] = position
                } else {
                  state.watch1[clause_index] = position
                }
                let replacement_literal = clause[position]
                state.watch_lists[watch_index(replacement_literal)].push(
                  clause_index,
                )
              }
              None => {
                remaining_watchers.push(clause_index)
                let other_value = assignment[Int::abs(other_literal) - 1]
                if other_value == -1 {
                  if enqueue_literal(other_literal, assignment, trail) {
                    state.propagations += 1
                  } else {
                    conflict = true
                  }
                } else if !literal_is_satisfied(other_literal, assignment) {
                  conflict = true
                }
              }
            }
          }
        }
      }
    }
    state.watch_lists[false_watch_index] = remaining_watchers
    queue_head += 1
    if conflict {
      state.conflicts += 1
      return (false, queue_head)
    }
  }
  (true, queue_head)
}

///|
fn first_open_literal(
  clauses : Array[Array[Int]],
  assignment : Array[Int],
) -> Int? {
  for clause in clauses {
    let mut satisfied = false
    for literal in clause {
      if literal_is_satisfied(literal, assignment) {
        satisfied = true
      }
    }
    if !satisfied {
      for literal in clause {
        if assignment[Int::abs(literal) - 1] == -1 {
          return Some(literal)
        }
      }
    }
  }
  None
}

///|
fn complete_model(assignment : Array[Int]) -> Array[Bool] {
  assignment.map(value => value == 1)
}

///|
fn search(
  state : SearchState,
  assignment : Array[Int],
  trail : Array[Int],
  qhead : Int,
  max_search_nodes : Int,
) -> SearchResult {
  if state.search_nodes >= max_search_nodes {
    return BudgetExhausted
  }
  state.search_nodes += 1
  let (consistent, next_qhead) = propagate_watched(
    state, assignment, trail, qhead,
  )
  if !consistent {
    return ProvedUnsat
  }
  let branch_literal = match first_open_literal(state.clauses, assignment) {
    Some(literal) => literal
    None => return Found(complete_model(assignment))
  }
  let variable = Int::abs(branch_literal) - 1
  state.decisions += 1

  let first_assignment = assignment.copy()
  let first_trail = trail.copy()
  first_assignment[variable] = if branch_literal > 0 { 1 } else { 0 }
  first_trail.push(branch_literal)
  let first_result = search(
    state, first_assignment, first_trail, next_qhead, max_search_nodes,
  )
  match first_result {
    Found(model) => return Found(model)
    ProvedUnsat => ()
    BudgetExhausted => {
      let second_assignment = assignment.copy()
      let second_trail = trail.copy()
      second_assignment[variable] = if branch_literal > 0 { 0 } else { 1 }
      second_trail.push(-branch_literal)
      return match
        search(
          state, second_assignment, second_trail, next_qhead, max_search_nodes,
        ) {
        Found(model) => Found(model)
        ProvedUnsat => BudgetExhausted
        BudgetExhausted => BudgetExhausted
      }
    }
  }

  let second_assignment = assignment.copy()
  let second_trail = trail.copy()
  second_assignment[variable] = if branch_literal > 0 { 0 } else { 1 }
  second_trail.push(-branch_literal)
  search(state, second_assignment, second_trail, next_qhead, max_search_nodes)
}

///|
/// Solve a CNF formula using deterministic DPLL with two-watched-literal
/// propagation.
///
/// Branching uses the first unassigned literal in the first unresolved clause.
/// The solver returns a complete Boolean model on SAT and `Unknown` if the
/// configured search-node budget is exhausted before a proof is found.
pub fn CnfFormula::solve(self : CnfFormula, config : SolverConfig) -> SatReport {
  let assignment : Array[Int] = Array::make(self.variable_count, -1)
  let trail : Array[Int] = []
  let watch_lists : Array[Array[Int]] = []
  for _ in 0..<(self.variable_count * 2) {
    watch_lists.push([])
  }
  let state = SearchState::{
    clauses: self.clauses,
    watch_lists,
    watch0: [],
    watch1: [],
    search_nodes: 0,
    decisions: 0,
    propagations: 0,
    conflicts: 0,
  }
  let search_result = if initialize_watches(state, assignment, trail) {
    search(state, assignment, trail, 0, config.max_search_nodes)
  } else {
    ProvedUnsat
  }
  let outcome = match search_result {
    Found(model) => Satisfiable(model)
    ProvedUnsat => Unsatisfiable
    BudgetExhausted => Unknown
  }
  {
    outcome,
    stats: {
      search_nodes: state.search_nodes,
      decisions: state.decisions,
      propagations: state.propagations,
      conflicts: state.conflicts,
    },
  }
}

///|
/// Check a reported model against the formula's normalized clauses.
pub fn CnfFormula::accepts(self : CnfFormula, model : Array[Bool]) -> Bool {
  if model.length() != self.variable_count {
    return false
  }
  for clause in self.clauses {
    let mut satisfied = false
    for literal in clause {
      let value = model[Int::abs(literal) - 1]
      if (literal > 0 && value) || (literal < 0 && !value) {
        satisfied = true
      }
    }
    if !satisfied {
      return false
    }
  }
  true
}

///|
test "CNF validates bounds and owns normalized clause data" {
  assert_true(CnfFormula::new(-1, []) is None)
  assert_true(CnfFormula::new(4097, []) is None)
  assert_true(CnfFormula::new(2, [[0]]) is None)
  assert_true(CnfFormula::new(2, [[3]]) is None)
  assert_true(SolverConfig::new(0) is None)
  let input : Array[Array[Int]] = [[2, 1, 2], [1, -1], [-2, -2], [1, 2]]
  let formula = CnfFormula::new(2, input).unwrap()
  input[0].push(-2)
  assert_eq(formula.clauses(), [[1, 2], [-2]])
}

///|
test "DIMACS parser accepts comments multiline clauses and checks its header" {
  let text =
    #| c sample formula
    #| p cnf 3 3
    #| 1 -2
    #| 0 3 0
    #| -1 2 0
  let formula = match CnfFormula::parse_dimacs(text) {
    Ok(formula) => formula
    Err(_) => fail("valid DIMACS input was rejected")
  }
  assert_eq(formula.variable_count(), 3)
  assert_eq(formula.clauses(), [[-2, 1], [3], [-1, 2]])
  let report = formula.solve(SolverConfig::new(100).unwrap())
  match report.outcome {
    Satisfiable(model) => assert_true(formula.accepts(model))
    _ => fail("DIMACS example should be satisfiable")
  }
}

///|
test "DIMACS parser rejects malformed headers literals and clause counts" {
  assert_true(CnfFormula::parse_dimacs("c no formula here") is Err(_))
  assert_true(CnfFormula::parse_dimacs("p cnf x 1\n1 0\n") is Err(_))
  assert_true(CnfFormula::parse_dimacs("p cnf 1 1\n2 0\n") is Err(_))
  assert_true(CnfFormula::parse_dimacs("p cnf 1 2\n1 0\n") is Err(_))
  assert_true(CnfFormula::parse_dimacs("p cnf 1 1\n1\n") is Err(_))
  assert_true(CnfFormula::parse_dimacs("p cnf 1 1\nabc 0\n") is Err(_))
  assert_true(CnfFormula::parse_dimacs("p cnf 1 1\n1 0 0\n") is Err(_))
}

///|
test "DPLL handles empty formulas contradictions and unit chains" {
  let config = SolverConfig::new(100).unwrap()
  let empty = CnfFormula::new(3, []).unwrap()
  let empty_result = empty.solve(config)
  match empty_result.outcome {
    Satisfiable(model) => {
      assert_eq(model, [false, false, false])
      assert_true(empty.accepts(model))
    }
    _ => fail("empty CNF should be satisfiable")
  }
  let contradiction = CnfFormula::new(1, [[]]).unwrap()
  assert_true(contradiction.solve(config).outcome is Unsatisfiable)
  assert_true(
    CnfFormula::new(0, []).unwrap().solve(config).outcome is Satisfiable(_),
  )
  assert_true(
    CnfFormula::new(0, [[]]).unwrap().solve(config).outcome is Unsatisfiable,
  )
  let chain = CnfFormula::new(3, [[1], [-1, 2], [-2, 3]]).unwrap()
  let result = chain.solve(config)
  match result.outcome {
    Satisfiable(model) => assert_eq(model, [true, true, true])
    _ => fail("unit chain should be satisfiable")
  }
  assert_eq(result.stats.propagations, 3)
}

///|
test "two-watched literals move across falsified positions before unit propagation" {
  let formula = CnfFormula::new(4, [[1, 2, 3, 4], [-1], [-2], [-3]]).unwrap()
  let report = formula.solve(SolverConfig::new(100).unwrap())
  match report.outcome {
    Satisfiable(model) => {
      assert_eq(model, [false, false, false, true])
      assert_true(formula.accepts(model))
    }
    _ => fail("the final watched literal should be propagated")
  }
  assert_eq(report.stats.decisions, 0)
  assert_eq(report.stats.propagations, 4)
}

///|
test "DPLL backtracks and returns a model that satisfies every clause" {
  let formula = CnfFormula::new(3, [[1, 2], [-1, 2], [1, -2, 3]]).unwrap()
  let report = formula.solve(SolverConfig::new(100).unwrap())
  match report.outcome {
    Satisfiable(model) => assert_true(formula.accepts(model))
    _ => fail("formula should be satisfiable")
  }
  let unsat = CnfFormula::new(2, [[1, 2], [-1, 2], [1, -2], [-1, -2]]).unwrap()
  let unsat_report = unsat.solve(SolverConfig::new(100).unwrap())
  assert_true(unsat_report.outcome is Unsatisfiable)
  assert_true(unsat_report.stats.decisions > 0)
  assert_true(unsat_report.stats.conflicts > 0)
}

///|
fn oracle_satisfiable(
  variable_count : Int,
  clauses : Array[Array[Int]],
) -> Bool {
  for bits in 0..<(1 << variable_count) {
    let model : Array[Bool] = []
    for variable in 0..<variable_count {
      model.push(((bits >> variable) & 1) == 1)
    }
    let mut all_clauses_satisfied = true
    for clause in clauses {
      let mut satisfied = false
      for literal in clause {
        let value = model[Int::abs(literal) - 1]
        if (literal > 0 && value) || (literal < 0 && !value) {
          satisfied = true
        }
      }
      if !satisfied {
        all_clauses_satisfied = false
      }
    }
    if all_clauses_satisfied {
      return true
    }
  }
  false
}

///|
test "two-variable CNFs agree with exhaustive truth-assignment oracle" {
  let clause_universe : Array[Array[Int]] = []
  for code in 1..<9 {
    let mut encoded = code
    let clause : Array[Int] = []
    for variable in 1..<=2 {
      let state = encoded % 3
      encoded /= 3
      if state == 1 {
        clause.push(variable)
      } else if state == 2 {
        clause.push(-variable)
      }
    }
    clause_universe.push(clause)
  }
  let config = SolverConfig::new(100).unwrap()
  for formula_bits in 0..<256 {
    let clauses : Array[Array[Int]] = []
    for index in 0..<clause_universe.length() {
      if ((formula_bits >> index) & 1) == 1 {
        clauses.push(clause_universe[index])
      }
    }
    let formula = CnfFormula::new(2, clauses).unwrap()
    let expected = oracle_satisfiable(2, clauses)
    match formula.solve(config).outcome {
      Satisfiable(model) => {
        assert_true(expected)
        assert_true(formula.accepts(model))
      }
      Unsatisfiable => assert_true(!expected)
      Unknown => fail("small exhaustive case unexpectedly exhausted budget")
    }
  }
}

///|
test "sampled three-variable CNFs agree with exhaustive truth assignments" {
  let clause_universe : Array[Array[Int]] = []
  for code in 1..<27 {
    let mut encoded = code
    let clause : Array[Int] = []
    for variable in 1..<=3 {
      let state = encoded % 3
      encoded /= 3
      if state == 1 {
        clause.push(variable)
      } else if state == 2 {
        clause.push(-variable)
      }
    }
    clause_universe.push(clause)
  }
  let config = SolverConfig::new(1000).unwrap()
  for seed in 0..<1024 {
    let clauses : Array[Array[Int]] = []
    for index in 0..<clause_universe.length() {
      let selector = (seed * 97 + index * 193 + seed / 3) % 13
      if selector < 6 {
        clauses.push(clause_universe[index])
      }
    }
    let formula = CnfFormula::new(3, clauses).unwrap()
    let expected = oracle_satisfiable(3, clauses)
    match formula.solve(config).outcome {
      Satisfiable(model) => {
        assert_true(expected)
        assert_true(formula.accepts(model))
      }
      Unsatisfiable => assert_true(!expected)
      Unknown => fail("three-variable sample unexpectedly exhausted budget")
    }
  }
}

///|
test "DPLL reports unknown rather than guessing when the budget expires" {
  let formula = CnfFormula::new(2, [[1, 2], [-1, 2], [1, -2], [-1, -2]]).unwrap()
  let report = formula.solve(SolverConfig::new(1).unwrap())
  assert_true(report.outcome is Unknown)
  assert_eq(report.stats.search_nodes, 1)
}

///|
fn eval_expr(expression : BoolExpr, assignment : Array[Bool]) -> Bool {
  match expression {
    Constant(value) => value
    Variable(index) => assignment[index - 1]
    Not(child) => !eval_expr(child, assignment)
    And(left, right) =>
      eval_expr(left, assignment) && eval_expr(right, assignment)
    Or(left, right) =>
      eval_expr(left, assignment) || eval_expr(right, assignment)
    Xor(left, right) =>
      eval_expr(left, assignment) != eval_expr(right, assignment)
  }
}

///|
test "Tseitin encoding preserves Boolean expression truth tables" {
  let expressions = [
    Variable(1),
    Not(Variable(2)),
    And(Variable(1), Variable(2)),
    Or(Variable(1), Variable(2)),
    Xor(Variable(1), Variable(2)),
    Xor(And(Variable(1), Variable(2)), Not(Variable(1))),
    Or(Constant(false), And(Variable(1), Not(Variable(2)))),
  ]
  let config = SolverConfig::new(1000).unwrap()
  for expression in expressions {
    for bits in 0..<4 {
      let assignment = [(bits & 1) == 1, ((bits >> 1) & 1) == 1]
      let fixed_a = if assignment[0] { Variable(1) } else { Not(Variable(1)) }
      let fixed_b = if assignment[1] { Variable(2) } else { Not(Variable(2)) }
      let constrained = And(And(expression, fixed_a), fixed_b)
      let formula = CnfFormula::from_expression(2, constrained).unwrap()
      let expected = eval_expr(expression, assignment)
      match formula.solve(config).outcome {
        Satisfiable(model) => {
          assert_true(expected)
          assert_eq(model[0], assignment[0])
          assert_eq(model[1], assignment[1])
          assert_true(formula.accepts(model))
        }
        Unsatisfiable => assert_true(!expected)
        Unknown => fail("small Tseitin test exhausted its budget")
      }
    }
  }
  assert_true(CnfFormula::from_expression(2, Variable(3)) is None)
}

///|
test "Tseitin encoding shares repeated structural subexpressions" {
  let mut expression = BoolExpr::Variable(1)
  for _ in 0..<24 {
    expression = BoolExpr::And(expression, expression)
  }
  let formula = CnfFormula::from_expression(1, expression).unwrap()
  assert_eq(formula.variable_count(), 25)
  match formula.solve(SolverConfig::new(100).unwrap()).outcome {
    Satisfiable(model) => assert_true(model[0])
    _ =>
      fail("a repeated conjunction of one true variable should be satisfiable")
  }
}
