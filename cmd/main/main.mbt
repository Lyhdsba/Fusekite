///|
/// Print a worked logic plan and its direct 74HC package estimate.
fn show_example(example : @circuits.CircuitExample) -> Unit {
  let solution = @fusekite.minimize_sop(example.spec)
  let cost = @fusekite.estimate_sop_gate_cost(example.spec, solution)
  let packages = @parts.estimate_74hc_packages(cost)
  println("\n\{example.name}")
  let mut labels = ""
  for index in 0..<example.input_labels.length() {
    if index > 0 {
      labels += ", "
    }
    labels += example.input_labels[index]
  }
  println("inputs: \{labels}")
  println("minimum SOP patterns:")
  for pattern in solution.patterns() {
    println("  \{pattern}")
  }
  println("terms: \{solution.term_count}, literals: \{solution.literal_count}")
  println(
    "gate counts (NOT, AND2, OR2): \{cost.inverters}, \{cost.and2_gates}, \{cost.or2_gates}",
  )
  println(
    "SN74HC packages (HC04, HC08, HC32): \{packages.inverters}, \{packages.and_packages}, \{packages.or_packages}",
  )
}

///|
/// Show the DIMACS parser and bounded SAT outcomes on tiny formulas.
fn show_sat_examples() -> Unit raise {
  let config = @sat.SolverConfig::new(10_000).unwrap()
  let satisfiable = match
    @sat.CnfFormula::parse_dimacs(
      (
        #| c x1 or x2; x3 follows if either x1 or x2 is false
        #| p cnf 3 3
        #| 1 2 0
        #| -1 3 0
        #| -2 3 0
      ),
    ) {
    Ok(formula) => formula
    Err(_) => fail("SAT demonstration DIMACS input is invalid")
  }
  let contradiction = match
    @sat.CnfFormula::parse_dimacs(
      (
        #| p cnf 1 2
        #| 1 0
        #| -1 0
      ),
    ) {
    Ok(formula) => formula
    Err(_) => fail("UNSAT demonstration DIMACS input is invalid")
  }
  println("\nCNF / DPLL demonstrations")
  match satisfiable.solve(config).outcome {
    @sat.SatOutcome::Satisfiable(model) => {
      let x1 = if model[0] { "1" } else { "0" }
      let x2 = if model[1] { "1" } else { "0" }
      let x3 = if model[2] { "1" } else { "0" }
      println("SAT model (x1, x2, x3): " + x1 + ", " + x2 + ", " + x3)
    }
    @sat.SatOutcome::Unsatisfiable => println("unexpected UNSAT result")
    @sat.SatOutcome::Unknown => println("search budget exhausted")
  }
  match contradiction.solve(config).outcome {
    @sat.SatOutcome::Satisfiable(_) => println("unexpected SAT result")
    @sat.SatOutcome::Unsatisfiable => println("contradictory units: UNSAT")
    @sat.SatOutcome::Unknown => println("search budget exhausted")
  }
}

///|
/// Solve one four-bit unsigned wraparound constraint through the QF_BV layer.
fn show_qfbv_example() -> Unit {
  let x = @smt.BitVec::variable(4, 1).unwrap()
  let three = @smt.BitVec::constant(4, 3).unwrap()
  let two = @smt.BitVec::constant(4, 2).unwrap()
  let assertion = x.add_wrapping(three).unwrap().equal(two).unwrap()
  let problem = @smt.QfBvProblem::new(4, assertion).unwrap()
  println("\nBounded QF_BV demonstration")
  match problem.solve(@sat.SolverConfig::new(10_000).unwrap()) {
    @smt.QfBvOutcome::Satisfiable(model) => {
      let mut value = 0
      for index in 0..<4 {
        if model[index] {
          value = value | (1 << index)
        }
      }
      println("four-bit x + 3 = 2 modulo 16; model x = \{value}")
    }
    @smt.QfBvOutcome::Unsatisfiable => println("unexpected QF_BV UNSAT result")
    @smt.QfBvOutcome::Unknown => println("QF_BV search budget exhausted")
    @smt.QfBvOutcome::InvalidInput => println("invalid QF_BV assertion")
  }
}

///|
/// Demonstrate three electronics examples and their structural package plans.
fn main raise {
  show_example(@circuits.sensor_interlock())
  show_example(@circuits.bcd_segment_a())
  show_example(@circuits.majority_alarm())
  show_sat_examples()
  show_qfbv_example()
}
