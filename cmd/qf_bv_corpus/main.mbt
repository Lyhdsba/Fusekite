///|
fn emit_case(
  operation : String,
  width : Int,
  target : Int,
  config : @sat.SolverConfig,
) -> Unit raise {
  let x = @smt.BitVec::variable(width, 1).unwrap()
  let y = @smt.BitVec::variable(width, width + 1).unwrap()
  let expected = @smt.BitVec::constant(width, target).unwrap()
  let value = match operation {
    "add" => x.add_wrapping(y).unwrap()
    "sub" => x.subtract_wrapping(y).unwrap()
    "mul" => x.multiply_low(y).unwrap()
    "and" => x.bit_and(y).unwrap()
    "or" => x.bit_or(y).unwrap()
    "xor" => x.bit_xor(y).unwrap()
    "not" => x.bit_not()
    "slt" => x
    _ => fail("unknown QF_BV oracle operation")
  }
  let assertion = if operation == "slt" {
    if target == 1 {
      x.signed_less_than(y).unwrap()
    } else {
      @sat.BoolExpr::Not(x.signed_less_than(y).unwrap())
    }
  } else {
    @sat.BoolExpr::And(
      value.equal(expected).unwrap(),
      x.unsigned_less_than(y).unwrap(),
    )
  }
  let problem = @smt.QfBvProblem::new(width * 2, assertion).unwrap()
  match problem.solve(config) {
    @smt.QfBvOutcome::Satisfiable(model) => {
      let x_value = x.evaluate(model).unwrap()
      let y_value = y.evaluate(model).unwrap()
      println("QFBV|\{operation}|\{width}|\{target}|SAT|\{x_value}|\{y_value}")
    }
    @smt.QfBvOutcome::Unsatisfiable =>
      println("QFBV|\{operation}|\{width}|\{target}|UNSAT|-|-")
    @smt.QfBvOutcome::Unknown =>
      println("QFBV|\{operation}|\{width}|\{target}|UNKNOWN|-|-")
    @smt.QfBvOutcome::InvalidInput =>
      println("QFBV|\{operation}|\{width}|\{target}|INVALID|-|-")
  }
}

///|
fn main raise {
  let config = @sat.SolverConfig::new(100_000).unwrap()
  let operations = ["add", "sub", "mul", "and", "or", "xor", "not"]
  for width in 1..<9 {
    for operation in operations {
      for target in 0..<(1 << width) {
        emit_case(operation, width, target, config)
      }
    }
    for target in 0..<2 {
      emit_case("slt", width, target, config)
    }
  }
}
