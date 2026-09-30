///|
/// Boolean operation supported by the ROBDD apply algorithm.
pub enum BddOp {
  And
  Or
  Xor
}

///|
priv struct BddNode {
  variable : Int
  low : Int
  high : Int
}

///|
priv struct BddApplyEntry {
  operation : BddOp
  left : Int
  right : Int
  result : Int
}

///|
priv struct BddNegateEntry {
  node : Int
  result : Int
}

///|
/// A manager for canonical reduced ordered binary decision diagrams.
///
/// Node IDs are local to the manager that created them. IDs 0 and 1 are the
/// false and true terminals. Variables are ordered by their index, from 0 to
/// `variable_count - 1`. A manager accepts 1–32 variables; a Boolean function
/// can still require exponentially many nodes, so callers should treat node
/// growth as input-dependent.
pub struct BddManager {
  priv variable_count : Int
  priv nodes : Array[BddNode]
  priv apply_cache : Array[BddApplyEntry]
  priv negate_cache : Array[BddNegateEntry]
}

///|
/// Create an ROBDD manager with a fixed variable order.
pub fn BddManager::new(variable_count : Int) -> BddManager? {
  if variable_count < 1 || variable_count > 32 {
    return None
  }
  let nodes = [
    BddNode::{ variable: variable_count, low: 0, high: 0, },
    BddNode::{ variable: variable_count, low: 1, high: 1, },
  ]
  Some({ variable_count, nodes, apply_cache: [], negate_cache: [], })
}

///|
/// Return the number of non-terminal nodes currently stored.
pub fn BddManager::node_count(self : BddManager) -> Int {
  self.nodes.length() - 2
}

///|
/// Count non-terminal nodes reachable from a node ID in this manager.
pub fn BddManager::reachable_node_count(self : BddManager, root : Int) -> Int? {
  if !self.valid_node(root) {
    return None
  }
  let visited : Array[Bool] = Array::make(self.nodes.length(), false)
  let pending : Array[Int] = [root]
  let mut count = 0
  while pending.length() > 0 {
    let node_id = pending.pop().unwrap()
    if node_id > 1 && !visited[node_id] {
      visited[node_id] = true
      count += 1
      pending.push(self.nodes[node_id].low)
      pending.push(self.nodes[node_id].high)
    }
  }
  Some(count)
}

///|
fn BddManager::valid_node(self : BddManager, node : Int) -> Bool {
  node >= 0 && node < self.nodes.length()
}

///|
fn same_bdd_op(left : BddOp, right : BddOp) -> Bool {
  match (left, right) {
    (And, And) => true
    (Or, Or) => true
    (Xor, Xor) => true
    _ => false
  }
}

///|
fn BddManager::make_node(
  self : BddManager,
  variable : Int,
  low : Int,
  high : Int,
) -> Int {
  if low == high {
    return low
  }
  for node_id in 2..<self.nodes.length() {
    let node = self.nodes[node_id]
    if node.variable == variable && node.low == low && node.high == high {
      return node_id
    }
  }
  self.nodes.push(BddNode::{ variable, low, high, })
  self.nodes.length() - 1
}

///|
/// Return the canonical node for a variable index, or `None` when out of range.
pub fn BddManager::variable(self : BddManager, index : Int) -> Int? {
  if index < 0 || index >= self.variable_count {
    return None
  }
  Some(self.make_node(index, 0, 1))
}

///|
fn BddManager::terminal_result(
  _self : BddManager,
  operation : BddOp,
  left : Int,
  right : Int,
) -> Int {
  let left_value = left == 1
  let right_value = right == 1
  let result = match operation {
    And => left_value && right_value
    Or => left_value || right_value
    Xor => left_value != right_value
  }
  if result {
    1
  } else {
    0
  }
}

///|
fn BddManager::apply_valid(
  self : BddManager,
  operation : BddOp,
  left : Int,
  right : Int,
) -> Int {
  let (first, second) = if left <= right {
    (left, right)
  } else {
    (right, left)
  }
  match operation {
    And => {
      if first == 0 {
        return 0
      }
      if first == 1 || first == second {
        return second
      }
    }
    Or => {
      if second == 1 {
        return 1
      }
      if first == 0 || first == second {
        return second
      }
    }
    Xor => {
      if first == second {
        return 0
      }
      if first == 0 {
        return second
      }
    }
  }
  if first <= 1 && second <= 1 {
    return self.terminal_result(operation, first, second)
  }
  for entry in self.apply_cache {
    if same_bdd_op(entry.operation, operation) &&
      entry.left == first &&
      entry.right == second {
      return entry.result
    }
  }
  let first_variable = self.nodes[first].variable
  let second_variable = self.nodes[second].variable
  let variable = Int::min(first_variable, second_variable)
  let first_low = if first_variable == variable {
    self.nodes[first].low
  } else {
    first
  }
  let first_high = if first_variable == variable {
    self.nodes[first].high
  } else {
    first
  }
  let second_low = if second_variable == variable {
    self.nodes[second].low
  } else {
    second
  }
  let second_high = if second_variable == variable {
    self.nodes[second].high
  } else {
    second
  }
  let low = self.apply_valid(operation, first_low, second_low)
  let high = self.apply_valid(operation, first_high, second_high)
  let result = self.make_node(variable, low, high)
  self.apply_cache.push({ operation, left: first, right: second, result, })
  result
}

///|
/// Apply a Boolean operation to two node IDs from this manager.
/// Returns `None` if either ID does not belong to this manager.
pub fn BddManager::apply(
  self : BddManager,
  operation : BddOp,
  left : Int,
  right : Int,
) -> Int? {
  if !self.valid_node(left) || !self.valid_node(right) {
    return None
  }
  Some(self.apply_valid(operation, left, right))
}

///|
/// Return the canonical complement of a node, or `None` for an invalid ID.
pub fn BddManager::negate(self : BddManager, node_id : Int) -> Int? {
  if !self.valid_node(node_id) {
    return None
  }
  if node_id == 0 {
    return Some(1)
  }
  if node_id == 1 {
    return Some(0)
  }
  for entry in self.negate_cache {
    if entry.node == node_id {
      return Some(entry.result)
    }
  }
  let node = self.nodes[node_id]
  let low = self.negate(node.low).unwrap()
  let high = self.negate(node.high).unwrap()
  let result = self.make_node(node.variable, low, high)
  self.negate_cache.push({ node: node_id, result, })
  Some(result)
}

///|
/// Evaluate a node using one Boolean value per manager variable.
/// Returns `None` for an invalid node ID or a vector of the wrong length.
pub fn BddManager::evaluate(
  self : BddManager,
  node_id : Int,
  values : Array[Bool],
) -> Bool? {
  if !self.valid_node(node_id) || values.length() != self.variable_count {
    return None
  }
  let mut current = node_id
  while current > 1 {
    let node = self.nodes[current]
    current = if values[node.variable] { node.high } else { node.low }
  }
  Some(current == 1)
}

///|
/// Check equivalence by canonical node identity within this manager.
pub fn BddManager::equivalent(
  self : BddManager,
  left : Int,
  right : Int,
) -> Bool? {
  if !self.valid_node(left) || !self.valid_node(right) {
    return None
  }
  Some(left == right)
}

///|
/// Compare a selected SOP cover with the specified truth table using ROBDDs.
/// Don't-care rows are masked from the comparison. This is a software-level
/// equivalence check independent of the cover-selection search.
pub fn verify_sop_with_bdd(spec : TruthSpec, solution : CoverSolution) -> Bool {
  let manager = match BddManager::new(spec.input_count) {
    Some(manager) => manager
    None => return false
  }
  let mut expected = 0
  let mut care = 0
  let row_count = 1 << spec.input_count
  for row in 0..<row_count {
    if !contains(spec.dont_cares, row) {
      let term = bdd_row_term(manager, row, spec.input_count)
      care = manager.apply_valid(Or, care, term)
      if contains(spec.on_set, row) {
        expected = manager.apply_valid(Or, expected, term)
      }
    }
  }
  let mut actual = 0
  for cube in solution.selected {
    let mut term = 1
    for position in 0..<cube.width {
      let shift = cube.width - position - 1
      if ((cube.wildcard >> shift) & 1) == 0 {
        let variable = manager.variable(position).unwrap()
        let literal = if ((cube.value >> shift) & 1) == 1 {
          variable
        } else {
          manager.negate(variable).unwrap()
        }
        term = manager.apply_valid(And, term, literal)
      }
    }
    actual = manager.apply_valid(Or, actual, term)
  }
  let difference = manager.apply_valid(Xor, expected, actual)
  manager.apply_valid(And, care, difference) == 0
}

///|
fn bdd_row_term(manager : BddManager, row : Int, width : Int) -> Int {
  let mut term = 1
  for index in 0..<width {
    let shift = width - index - 1
    let variable = manager.variable(index).unwrap()
    let literal = if ((row >> shift) & 1) == 1 {
      variable
    } else {
      manager.negate(variable).unwrap()
    }
    term = manager.apply_valid(And, term, literal)
  }
  term
}

///|
test "ROBDD reduces equal branches and shares canonical nodes" {
  let manager = BddManager::new(3).unwrap()
  let a = manager.variable(0).unwrap()
  let b = manager.variable(1).unwrap()
  let same = manager.apply(And, a, a).unwrap()
  let both_orders = manager.apply(And, a, b).unwrap()
  let reverse_orders = manager.apply(And, b, a).unwrap()
  assert_eq(same, a)
  assert_eq(both_orders, reverse_orders)
  assert_eq(manager.node_count(), 3)
}

///|
test "ROBDD evaluates operations and complements" {
  let manager = BddManager::new(2).unwrap()
  let a = manager.variable(0).unwrap()
  let b = manager.variable(1).unwrap()
  let conjunction = manager.apply(And, a, b).unwrap()
  let exclusive_or = manager.apply(Xor, a, b).unwrap()
  let not_a = manager.negate(a).unwrap()
  assert_eq(manager.negate(not_a), Some(a))
  assert_eq(manager.evaluate(conjunction, [true, true]), Some(true))
  assert_eq(manager.evaluate(conjunction, [true, false]), Some(false))
  assert_eq(manager.evaluate(exclusive_or, [true, false]), Some(true))
  assert_eq(manager.evaluate(not_a, [false, true]), Some(true))
  assert_eq(manager.equivalent(not_a, a), Some(false))
}

///|
test "ROBDD validates variables node IDs and assignments" {
  let manager = BddManager::new(2).unwrap()
  assert_true(BddManager::new(0) is None)
  assert_true(BddManager::new(33) is None)
  assert_true(manager.variable(-1) is None)
  assert_true(manager.variable(2) is None)
  assert_true(manager.apply(Or, 2, 99) is None)
  assert_true(manager.evaluate(0, [true]) is None)
}

///|
test "BDD verification masks don't-care rows and catches a wrong cover" {
  let spec = TruthSpec::new(3, [0, 1, 6, 7], [2]).unwrap()
  let solution = minimize_sop(spec)
  assert_true(verify_sop_with_bdd(spec, solution))
  let wrong = CoverSolution::{
    selected: [Cube::{ width: 3, value: 0, wildcard: 1, }],
    essential: [],
    term_count: 1,
    literal_count: 2,
    explored_states: 0,
  }
  assert_true(!verify_sop_with_bdd(spec, wrong))
}

///|
test "ROBDD keeps parity compact beyond truth-table input range" {
  let manager = BddManager::new(16).unwrap()
  let mut parity = 0
  for index in 0..<16 {
    let variable = manager.variable(index).unwrap()
    parity = manager.apply(Xor, parity, variable).unwrap()
  }
  assert_true(manager.reachable_node_count(parity).unwrap() < 40)
  assert_eq(manager.evaluate(parity, Array::make(16, true)), Some(false))
  let odd_values : Array[Bool] = []
  for index in 0..<16 {
    odd_values.push(index == 7)
  }
  assert_eq(manager.evaluate(parity, odd_values), Some(true))
}
