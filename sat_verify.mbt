///|
/// Result of asking the SAT backend for a counterexample to an SOP result.
pub enum SatEquivalence {
  Equivalent
  Counterexample(Array[Bool])
  Unknown(@sat.SolverStats)
  InvalidInput
}

///|
fn row_expression(row : Int, width : Int) -> @sat.BoolExpr {
  let mut expression = @sat.BoolExpr::Constant(true)
  for index in 0..<width {
    let shift = width - index - 1
    let variable = @sat.BoolExpr::Variable(index + 1)
    let literal = if ((row >> shift) & 1) == 1 {
      variable
    } else {
      @sat.BoolExpr::Not(variable)
    }
    expression = @sat.BoolExpr::And(expression, literal)
  }
  expression
}

///|
fn row_set_expression(rows : Array[Int], width : Int) -> @sat.BoolExpr {
  let mut expression = @sat.BoolExpr::Constant(false)
  for row in rows {
    expression = @sat.BoolExpr::Or(expression, row_expression(row, width))
  }
  expression
}

///|
fn cube_expression(cube : Cube) -> @sat.BoolExpr {
  let mut expression = @sat.BoolExpr::Constant(true)
  for index in 0..<cube.width {
    let shift = cube.width - index - 1
    if ((cube.wildcard >> shift) & 1) == 0 {
      let variable = @sat.BoolExpr::Variable(index + 1)
      let literal = if ((cube.value >> shift) & 1) == 1 {
        variable
      } else {
        @sat.BoolExpr::Not(variable)
      }
      expression = @sat.BoolExpr::And(expression, literal)
    }
  }
  expression
}

///|
fn valid_solution_for_spec(spec : TruthSpec, solution : CoverSolution) -> Bool {
  for cube in solution.selected {
    if cube.width != spec.input_count ||
      cube.value < 0 ||
      cube.wildcard < 0 ||
      (cube.value & cube.wildcard) != 0 ||
      (cube.value | cube.wildcard) >= 1 << spec.input_count {
      return false
    }
  }
  true
}

///|
/// Ask the DPLL backend to find an assignment where a selected SOP cover
/// differs from the truth-table specification.
///
/// The expected function is encoded from its required one-rows. Don't-care
/// rows are excluded by conjoining the negation of their minterm set. An
/// `Unsatisfiable` proof becomes `Equivalent`; a satisfying model is returned
/// as a concrete counterexample. Search exhaustion remains `Unknown` and is
/// never treated as proof. The node budget uses `SolverConfig`'s upper bound.
pub fn verify_sop_with_sat(
  spec : TruthSpec,
  solution : CoverSolution,
  config : @sat.SolverConfig,
) -> SatEquivalence {
  if !valid_solution_for_spec(spec, solution) {
    return InvalidInput
  }
  let expected = row_set_expression(spec.on_set, spec.input_count)
  let mut actual = @sat.BoolExpr::Constant(false)
  for cube in solution.selected {
    actual = @sat.BoolExpr::Or(actual, cube_expression(cube))
  }
  let dont_cares = if spec.dont_cares.length() == 0 {
    @sat.BoolExpr::Constant(false)
  } else {
    row_set_expression(spec.dont_cares, spec.input_count)
  }
  let mismatch = @sat.BoolExpr::And(
    @sat.BoolExpr::Xor(expected, actual),
    @sat.BoolExpr::Not(dont_cares),
  )
  let formula = match
    @sat.CnfFormula::from_expression(spec.input_count, mismatch) {
    Some(formula) => formula
    None => return InvalidInput
  }
  let report = formula.solve(config)
  match report.outcome {
    @sat.SatOutcome::Satisfiable(model) => {
      let inputs : Array[Bool] = []
      for index in 0..<spec.input_count {
        inputs.push(model[index])
      }
      Counterexample(inputs)
    }
    @sat.SatOutcome::Unsatisfiable => Equivalent
    @sat.SatOutcome::Unknown => Unknown(report.stats)
  }
}

///|
test "SAT verifier proves all worked examples and returns a concrete mismatch" {
  let config = @sat.SolverConfig::new(100_000).unwrap()
  let spec = TruthSpec::new(3, [1, 3, 5, 7], []).unwrap()
  let solution = minimize_sop(spec)
  assert_true(verify_sop_with_bdd(spec, solution))
  assert_true(verify_sop_with_sat(spec, solution, config) is Equivalent)

  let spec = TruthSpec::new(2, [1, 2], []).unwrap()
  let wrong = CoverSolution::{
    selected: [Cube::{ width: 2, value: 0, wildcard: 1, }],
    essential: [],
    term_count: 1,
    literal_count: 1,
    explored_states: 0,
  }
  match verify_sop_with_sat(spec, wrong, config) {
    Counterexample(inputs) => {
      assert_eq(inputs.length(), 2)
      let row = (if inputs[0] { 2 } else { 0 }) +
        (if inputs[1] { 1 } else { 0 })
      let expected = row == 1 || row == 2
      assert_true(expected != wrong.selected[0].covers_row(row))
    }
    _ => fail("wrong cover should have a SAT counterexample")
  }
}

///|
test "SAT verifier rejects a cover with the wrong input width" {
  let config = @sat.SolverConfig::new(1000).unwrap()
  let spec = TruthSpec::new(1, [1], []).unwrap()
  let solution = minimize_sop(spec)
  assert_true(verify_sop_with_sat(spec, solution, config) is Equivalent)
  let invalid = CoverSolution::{
    selected: [Cube::{ width: 2, value: 0, wildcard: 0, }],
    essential: [],
    term_count: 1,
    literal_count: 2,
    explored_states: 0,
  }
  assert_true(verify_sop_with_sat(spec, invalid, config) is InvalidInput)
  assert_true(!verify_sop_with_bdd(spec, invalid))
  assert_true(
    verify_sop_with_sat(spec, solution, @sat.SolverConfig::new(1).unwrap())
    is Unknown(_),
  )
}
