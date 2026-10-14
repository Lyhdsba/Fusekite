///|
fn valid_pos_for_spec(spec : TruthSpec, solution : PosSolution) -> Bool {
  if solution.input_count != spec.input_count {
    return false
  }
  for clause in solution.selected {
    let cube = clause.zero_cube
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
/// Compare a POS result with the cared truth-table rows using canonical BDDs.
/// Build literal OR clauses and their AND directly, without complement SOP
/// selection or row evaluation. A result with a different width returns false.
pub fn verify_pos_with_bdd(spec : TruthSpec, solution : PosSolution) -> Bool {
  if !valid_pos_for_spec(spec, solution) {
    return false
  }
  let manager = BddManager::new(spec.input_count).unwrap()
  let mut expected = 0
  let mut care = 0
  for row in 0..<(1 << spec.input_count) {
    if !contains(spec.dont_cares, row) {
      let term = bdd_row_term(manager, row, spec.input_count)
      care = manager.apply(Or, care, term).unwrap()
      if contains(spec.on_set, row) {
        expected = manager.apply(Or, expected, term).unwrap()
      }
    }
  }
  let mut actual = 1
  for clause in solution.selected {
    let pattern = clause.pattern().to_array()
    let mut sum = 0
    for position in 0..<pattern.length() {
      if pattern[position] != '-' {
        let variable = manager.variable(position).unwrap()
        let literal = if pattern[position] == '0' {
          variable
        } else {
          manager.negate(variable).unwrap()
        }
        sum = manager.apply(Or, sum, literal).unwrap()
      }
    }
    actual = manager.apply(And, actual, sum).unwrap()
  }
  let difference = manager.apply(Xor, expected, actual).unwrap()
  manager.apply(And, care, difference).unwrap() == 0
}

///|
/// Find a cared-row mismatch between a POS result and its specification.
/// Encode an AND of literal OR clauses directly into the existing SAT backend.
/// Counterexamples use MSB-first input order; budget exhaustion stays Unknown.
/// A result with a different width returns InvalidInput, even if constant.
pub fn verify_pos_with_sat(
  spec : TruthSpec,
  solution : PosSolution,
  config : @sat.SolverConfig,
) -> SatEquivalence {
  if !valid_pos_for_spec(spec, solution) {
    return InvalidInput
  }
  let mut actual = @sat.BoolExpr::Constant(true)
  for clause in solution.selected {
    let pattern = clause.pattern().to_array()
    let mut sum = @sat.BoolExpr::Constant(false)
    for position in 0..<pattern.length() {
      if pattern[position] != '-' {
        let variable = @sat.BoolExpr::Variable(position + 1)
        let literal = if pattern[position] == '0' {
          variable
        } else {
          @sat.BoolExpr::Not(variable)
        }
        sum = @sat.BoolExpr::Or(sum, literal)
      }
    }
    actual = @sat.BoolExpr::And(actual, sum)
  }
  let expected = row_set_expression(spec.on_set, spec.input_count)
  let dont_cares = row_set_expression(spec.dont_cares, spec.input_count)
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
