///|
pub struct BitVec {
  priv width : Int
  priv bits : Array[@sat.BoolExpr]
}

///|
pub struct QfBvProblem {
  priv source_variable_count : Int
  priv assertion : @sat.BoolExpr
}

///|
pub enum QfBvOutcome {
  Satisfiable(Array[Bool])
  Unsatisfiable
  Unknown
  InvalidInput
}

///|
/// Bits are ordered least-significant first. Width is restricted to 1..8.
pub fn BitVec::variable(width : Int, first_variable : Int) -> BitVec? {
  if width < 1 ||
    width > 8 ||
    first_variable < 1 ||
    first_variable > 257 - width {
    return None
  }
  let bits : Array[@sat.BoolExpr] = []
  for offset in 0..<width {
    bits.push(@sat.BoolExpr::Variable(first_variable + offset))
  }
  Some({ width, bits, })
}

///|
pub fn BitVec::constant(width : Int, value : Int) -> BitVec? {
  if width < 1 || width > 8 || value < 0 || value >= 1 << width {
    return None
  }
  let bits : Array[@sat.BoolExpr] = []
  for index in 0..<width {
    bits.push(@sat.BoolExpr::Constant((value & (1 << index)) != 0))
  }
  Some({ width, bits, })
}

///|
pub fn BitVec::width(self : BitVec) -> Int {
  self.width
}

///|
/// Evaluate this term using a QfBvProblem source model. The model is indexed
/// from SAT variable 1 at array index 0; out-of-range references return None.
pub fn BitVec::evaluate(self : BitVec, model : Array[Bool]) -> Int? {
  let mut value = 0
  for index in 0..<self.width {
    match evaluate_boolean(self.bits[index], model) {
      Some(true) => value = value | (1 << index)
      Some(false) => ()
      None => return None
    }
  }
  Some(value)
}

///|
fn evaluate_boolean(expression : @sat.BoolExpr, model : Array[Bool]) -> Bool? {
  match expression {
    @sat.BoolExpr::Constant(value) => Some(value)
    @sat.BoolExpr::Variable(index) =>
      if index < 1 || index > model.length() {
        None
      } else {
        Some(model[index - 1])
      }
    @sat.BoolExpr::Not(child) =>
      evaluate_boolean(child, model).map(value => !value)
    @sat.BoolExpr::And(left, right) =>
      match (evaluate_boolean(left, model), evaluate_boolean(right, model)) {
        (Some(left_value), Some(right_value)) => Some(left_value && right_value)
        _ => None
      }
    @sat.BoolExpr::Or(left, right) =>
      match (evaluate_boolean(left, model), evaluate_boolean(right, model)) {
        (Some(left_value), Some(right_value)) => Some(left_value || right_value)
        _ => None
      }
    @sat.BoolExpr::Xor(left, right) =>
      match (evaluate_boolean(left, model), evaluate_boolean(right, model)) {
        (Some(left_value), Some(right_value)) => Some(left_value != right_value)
        _ => None
      }
  }
}

///|
pub fn BitVec::bit_not(self : BitVec) -> BitVec {
  let bits : Array[@sat.BoolExpr] = []
  for bit in self.bits {
    bits.push(@sat.BoolExpr::Not(bit))
  }
  { width: self.width, bits, }
}

///|
pub fn BitVec::bit_and(self : BitVec, other : BitVec) -> BitVec? {
  if self.width != other.width {
    return None
  }
  let bits : Array[@sat.BoolExpr] = []
  for index in 0..<self.width {
    bits.push(@sat.BoolExpr::And(self.bits[index], other.bits[index]))
  }
  Some({ width: self.width, bits, })
}

///|
pub fn BitVec::bit_or(self : BitVec, other : BitVec) -> BitVec? {
  if self.width != other.width {
    return None
  }
  let bits : Array[@sat.BoolExpr] = []
  for index in 0..<self.width {
    bits.push(@sat.BoolExpr::Or(self.bits[index], other.bits[index]))
  }
  Some({ width: self.width, bits, })
}

///|
pub fn BitVec::bit_xor(self : BitVec, other : BitVec) -> BitVec? {
  if self.width != other.width {
    return None
  }
  let bits : Array[@sat.BoolExpr] = []
  for index in 0..<self.width {
    bits.push(@sat.BoolExpr::Xor(self.bits[index], other.bits[index]))
  }
  Some({ width: self.width, bits, })
}

///|
/// Addition wraps modulo 2^width; the final carry is discarded.
pub fn BitVec::add_wrapping(self : BitVec, other : BitVec) -> BitVec? {
  if self.width != other.width {
    return None
  }
  let bits : Array[@sat.BoolExpr] = []
  let mut carry = @sat.BoolExpr::Constant(false)
  for index in 0..<self.width {
    let partial = @sat.BoolExpr::Xor(self.bits[index], other.bits[index])
    bits.push(@sat.BoolExpr::Xor(partial, carry))
    let both = @sat.BoolExpr::And(self.bits[index], other.bits[index])
    let propagated = @sat.BoolExpr::And(partial, carry)
    carry = @sat.BoolExpr::Or(both, propagated)
  }
  Some({ width: self.width, bits, })
}

///|
pub fn BitVec::equal(self : BitVec, other : BitVec) -> @sat.BoolExpr? {
  if self.width != other.width {
    return None
  }
  let mut result = @sat.BoolExpr::Constant(true)
  for index in 0..<self.width {
    let equal_bit = @sat.BoolExpr::Not(
      @sat.BoolExpr::Xor(self.bits[index], other.bits[index]),
    )
    result = @sat.BoolExpr::And(result, equal_bit)
  }
  Some(result)
}

///|
pub fn BitVec::unsigned_less_than(
  self : BitVec,
  other : BitVec,
) -> @sat.BoolExpr? {
  if self.width != other.width {
    return None
  }
  let mut less = @sat.BoolExpr::Constant(false)
  for index in 0..<self.width {
    let left = self.bits[index]
    let right = other.bits[index]
    let bit_less = @sat.BoolExpr::And(@sat.BoolExpr::Not(left), right)
    let equal_bit = @sat.BoolExpr::Not(@sat.BoolExpr::Xor(left, right))
    less = @sat.BoolExpr::Or(bit_less, @sat.BoolExpr::And(equal_bit, less))
  }
  Some(less)
}

///|
pub fn conjunction(assertions : Array[@sat.BoolExpr]) -> @sat.BoolExpr {
  let mut result = @sat.BoolExpr::Constant(true)
  for assertion in assertions {
    result = @sat.BoolExpr::And(result, assertion)
  }
  result
}

///|
/// Source variables are numbered 1 through source_variable_count.
pub fn QfBvProblem::new(
  source_variable_count : Int,
  assertion : @sat.BoolExpr,
) -> QfBvProblem? {
  if source_variable_count < 0 || source_variable_count > 256 {
    return None
  }
  Some({ source_variable_count, assertion, })
}

///|
/// Tseitin-compiles to CNF and solves with bounded DPLL. Returned models omit
/// auxiliary variables introduced by the SAT encoder.
pub fn QfBvProblem::solve(
  self : QfBvProblem,
  config : @sat.SolverConfig,
) -> QfBvOutcome {
  let formula = match
    @sat.CnfFormula::from_expression(self.source_variable_count, self.assertion) {
    Some(formula) => formula
    None => return InvalidInput
  }
  let report = formula.solve(config)
  match report.outcome {
    @sat.SatOutcome::Satisfiable(model) => {
      if model.length() < self.source_variable_count {
        return InvalidInput
      }
      let source_model : Array[Bool] = []
      for index in 0..<self.source_variable_count {
        source_model.push(model[index])
      }
      Satisfiable(source_model)
    }
    @sat.SatOutcome::Unsatisfiable => Unsatisfiable
    @sat.SatOutcome::Unknown => Unknown
  }
}

///|
test "bit-vector constructors enforce widths and unsigned ranges" {
  assert_true(BitVec::variable(0, 1) is None)
  assert_true(BitVec::variable(9, 1) is None)
  assert_true(BitVec::variable(8, 250) is None)
  assert_true(BitVec::constant(4, -1) is None)
  assert_true(BitVec::constant(4, 16) is None)
  assert_eq(BitVec::constant(4, 15).unwrap().width(), 4)
  assert_true(QfBvProblem::new(257, @sat.BoolExpr::Constant(true)) is None)
}

///|
test "wrapping addition equality finds the only four-bit wraparound model" {
  let x = BitVec::variable(4, 1).unwrap()
  let three = BitVec::constant(4, 3).unwrap()
  let two = BitVec::constant(4, 2).unwrap()
  let assertion = x.add_wrapping(three).unwrap().equal(two).unwrap()
  let problem = QfBvProblem::new(4, assertion).unwrap()
  match problem.solve(@sat.SolverConfig::new(10_000).unwrap()) {
    Satisfiable(model) => {
      assert_eq(model, [true, true, true, true])
      assert_eq(x.evaluate(model), Some(15))
    }
    _ => fail("15 + 3 modulo 16 should equal 2")
  }
}

///|
test "bit-vector arithmetic can prove x plus one is never x" {
  let x = BitVec::variable(4, 1).unwrap()
  let one = BitVec::constant(4, 1).unwrap()
  let next = x.add_wrapping(one).unwrap()
  let assertion = next.equal(x).unwrap()
  let problem = QfBvProblem::new(4, assertion).unwrap()
  assert_true(
    problem.solve(@sat.SolverConfig::new(10_000).unwrap()) is Unsatisfiable,
  )
}

///|
test "bitwise and unsigned comparison produce a satisfying model" {
  let x = BitVec::variable(4, 1).unwrap()
  let mask = BitVec::constant(4, 10).unwrap()
  let target = BitVec::constant(4, 8).unwrap()
  let bound = BitVec::constant(4, 12).unwrap()
  let masked = x.bit_and(mask).unwrap()
  let assertions = [
    masked.equal(target).unwrap(),
    x.unsigned_less_than(bound).unwrap(),
  ]
  let problem = QfBvProblem::new(4, conjunction(assertions)).unwrap()
  match problem.solve(@sat.SolverConfig::new(10_000).unwrap()) {
    Satisfiable(model) => {
      assert_eq(masked.evaluate(model), Some(8))
      assert_true(x.evaluate(model).unwrap() < 12)
    }
    _ => fail("x AND 10 = 8 and x < 12 should be satisfiable")
  }
}

///|
test "bit-vector operations reject width mismatches" {
  let narrow = BitVec::variable(2, 1).unwrap()
  let wide = BitVec::variable(3, 3).unwrap()
  assert_true(narrow.add_wrapping(wide) is None)
  assert_true(narrow.bit_and(wide) is None)
  assert_true(narrow.equal(wide) is None)
  assert_true(narrow.unsigned_less_than(wide) is None)
  assert_true(narrow.evaluate([true]) is None)
}

///|
test "QF_BV exposes budget exhaustion and invalid encodings" {
  let x = @sat.BoolExpr::Variable(1)
  let y = @sat.BoolExpr::Variable(2)
  let impossible = QfBvProblem::new(
    2,
    conjunction([
      @sat.BoolExpr::Or(x, y),
      @sat.BoolExpr::Or(@sat.BoolExpr::Not(x), y),
      @sat.BoolExpr::Or(x, @sat.BoolExpr::Not(y)),
      @sat.BoolExpr::Or(@sat.BoolExpr::Not(x), @sat.BoolExpr::Not(y)),
    ]),
  ).unwrap()
  assert_true(impossible.solve(@sat.SolverConfig::new(1).unwrap()) is Unknown)
  let invalid_reference = QfBvProblem::new(1, @sat.BoolExpr::Variable(2)).unwrap()
  assert_true(
    invalid_reference.solve(@sat.SolverConfig::new(100).unwrap())
    is InvalidInput,
  )
}

///|
fn constant_assertion_is_sat(assertion : @sat.BoolExpr) -> Bool {
  let problem = QfBvProblem::new(0, assertion).unwrap()
  problem.solve(@sat.SolverConfig::new(1000).unwrap()) is Satisfiable(_)
}

///|
test "two-bit bit-vector operators match exhaustive unsigned arithmetic" {
  for left_value in 0..<4 {
    for right_value in 0..<4 {
      let left = BitVec::constant(2, left_value).unwrap()
      let right = BitVec::constant(2, right_value).unwrap()
      let add_expected = BitVec::constant(2, (left_value + right_value) % 4).unwrap()
      let and_expected = BitVec::constant(2, left_value & right_value).unwrap()
      let or_expected = BitVec::constant(2, left_value | right_value).unwrap()
      let xor_expected = BitVec::constant(2, left_value ^ right_value).unwrap()
      let not_expected = BitVec::constant(2, 3 ^ left_value).unwrap()
      assert_true(
        constant_assertion_is_sat(left.bit_not().equal(not_expected).unwrap()),
      )
      assert_true(
        constant_assertion_is_sat(
          left.add_wrapping(right).unwrap().equal(add_expected).unwrap(),
        ),
      )
      assert_true(
        constant_assertion_is_sat(
          left.bit_and(right).unwrap().equal(and_expected).unwrap(),
        ),
      )
      assert_true(
        constant_assertion_is_sat(
          left.bit_or(right).unwrap().equal(or_expected).unwrap(),
        ),
      )
      assert_true(
        constant_assertion_is_sat(
          left.bit_xor(right).unwrap().equal(xor_expected).unwrap(),
        ),
      )
      assert_eq(
        constant_assertion_is_sat(left.equal(right).unwrap()),
        left_value == right_value,
      )
      assert_eq(
        constant_assertion_is_sat(left.unsigned_less_than(right).unwrap()),
        left_value < right_value,
      )
    }
  }
}
