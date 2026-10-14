///|
test "POS falsifying patterns have sum-clause polarity" {
  // F = A OR NOT B. Only row 01 is false.
  let spec = @fusekite.TruthSpec::new(2, [0, 2, 3], []).unwrap()
  let solution = @fusekite.minimize_pos(spec)
  assert_eq(solution.patterns(), ["01"])
  assert_eq(solution.clause_count, 1)
  assert_eq(solution.literal_count, 2)
  assert_eq(solution.variable_count(), 2)
  assert_eq(solution.essential_clauses().length(), 1)
  let clause = solution.clauses()[0]
  assert_eq(clause.literal_count(), 2)
  for row in 0..<4 {
    assert_eq(clause.evaluate(row), Some(row != 1))
    assert_eq(solution.evaluate(row), Some(row != 1))
  }
  assert_eq(clause.evaluate(-1), None)
  assert_eq(clause.evaluate(4), None)
  assert_eq(solution.evaluate(-1), None)
  assert_eq(solution.evaluate(4), None)
  // The existing SOP interpretation remains a union of products.
  assert_eq(@fusekite.minimize_sop(spec).patterns(), ["-0", "1-"])
}

///|
test "POS combines clauses by AND and omits wildcard literals" {
  let one_input = @fusekite.minimize_pos(
    @fusekite.TruthSpec::new(1, [1], []).unwrap(),
  )
  assert_eq(one_input.patterns(), ["0"])
  assert_eq(one_input.evaluate(0), Some(false))
  assert_eq(one_input.evaluate(1), Some(true))
  let spec = @fusekite.TruthSpec::new(2, [1, 2], []).unwrap()
  let solution = @fusekite.minimize_pos(spec)
  assert_eq(solution.patterns(), ["00", "11"])
  assert_eq(solution.clause_count, 2)
  assert_eq(solution.literal_count, 4)
  for row in 0..<4 {
    assert_eq(solution.evaluate(row), Some(row == 1 || row == 2))
  }
  let odd_rows = @fusekite.TruthSpec::new(3, [1, 3, 5, 7], []).unwrap()
  let literal = @fusekite.minimize_pos(odd_rows)
  assert_eq(literal.patterns(), ["--0"])
  assert_eq(literal.literal_count, 1)
  for row in 0..<8 {
    assert_eq(literal.evaluate(row), Some((row & 1) == 1))
  }
}

///|
test "POS don't-cares expand zero cubes without requiring coverage" {
  let strict = @fusekite.TruthSpec::new(3, [2, 3, 4, 5, 6, 7], []).unwrap()
  assert_eq(@fusekite.minimize_pos(strict).patterns(), ["00-"])
  let relaxed = @fusekite.TruthSpec::new(3, [4, 5, 6, 7], [2, 3]).unwrap()
  let solution = @fusekite.minimize_pos(relaxed)
  assert_eq(solution.patterns(), ["0--"])
  let reordered = @fusekite.TruthSpec::new(3, [7, 6, 5, 4], [3, 2]).unwrap()
  assert_eq(@fusekite.minimize_pos(reordered).patterns(), solution.patterns())
  assert_eq(solution.literal_count, 1)
  for row in 0..<8 {
    assert_eq(solution.evaluate(row), Some(row >= 4))
  }
  // A don't-care-only cube must not add a clause.
  let irrelevant = @fusekite.TruthSpec::new(3, [1, 2, 3, 4, 5, 6], [7]).unwrap()
  assert_eq(@fusekite.minimize_pos(irrelevant).patterns(), ["000"])
  let no_zero = @fusekite.TruthSpec::new(2, [0, 1], [2, 3]).unwrap()
  assert_eq(@fusekite.minimize_pos(no_zero).patterns(), [])
  let no_one = @fusekite.TruthSpec::new(2, [], [2, 3]).unwrap()
  assert_eq(@fusekite.minimize_pos(no_one).patterns(), ["--"])
}

///|
test "POS constants and unconstrained tables across every supported width" {
  for width in 1..<9 {
    let rows : Array[Int] = []
    for row in 0..<(1 << width) {
      rows.push(row)
    }
    let one = @fusekite.minimize_pos(
      @fusekite.TruthSpec::new(width, rows, []).unwrap(),
    )
    let zero = @fusekite.minimize_pos(
      @fusekite.TruthSpec::new(width, [], []).unwrap(),
    )
    let unconstrained = @fusekite.minimize_pos(
      @fusekite.TruthSpec::new(width, [], rows).unwrap(),
    )
    assert_eq(one.clause_count, 0)
    assert_eq(one.literal_count, 0)
    assert_eq(one.patterns(), [])
    assert_eq(zero.clause_count, 1)
    assert_eq(zero.literal_count, 0)
    assert_eq(zero.clauses()[0].literal_count(), 0)
    assert_eq(unconstrained.patterns(), [])
    for row in rows {
      assert_eq(one.evaluate(row), Some(true))
      assert_eq(zero.evaluate(row), Some(false))
      assert_eq(zero.clauses()[0].evaluate(row), Some(false))
      assert_eq(unconstrained.evaluate(row), Some(true))
    }
    assert_eq(one.evaluate(1 << width), None)
    assert_eq(zero.evaluate(-1), None)
  }
}

///|
test "POS eight-input endpoints and MSB preserve row order" {
  let on_set : Array[Int] = []
  for row in 1..<255 {
    on_set.push(row)
  }
  let solution = @fusekite.minimize_pos(
    @fusekite.TruthSpec::new(8, on_set, []).unwrap(),
  )
  assert_eq(solution.patterns(), ["00000000", "11111111"])
  assert_eq(solution.literal_count, 16)
  for row in 0..<256 {
    assert_eq(solution.evaluate(row), Some(row != 0 && row != 255))
  }
  let upper_on : Array[Int] = []
  for row in 0..<254 {
    upper_on.push(row)
  }
  let upper = @fusekite.minimize_pos(
    @fusekite.TruthSpec::new(8, upper_on, [254]).unwrap(),
  )
  assert_eq(upper.patterns(), ["1111111-"])
  for row in 0..<256 {
    assert_eq(upper.evaluate(row), Some(row < 254))
  }
  assert_eq(upper.evaluate(256), None)
  assert_eq(upper.clauses()[0].evaluate(256), None)
  let msb_on : Array[Int] = []
  for row in 128..<256 {
    msb_on.push(row)
  }
  let msb = @fusekite.minimize_pos(
    @fusekite.TruthSpec::new(8, msb_on, []).unwrap(),
  )
  assert_eq(msb.patterns(), ["0-------"])
  for row in 0..<256 {
    assert_eq(msb.evaluate(row), Some(row >= 128))
  }
}

///|
test "POS tie-break and defensive copies are deterministic" {
  // Complement of the existing equal-cost SOP fixture.
  let spec = @fusekite.TruthSpec::new(3, [3, 4], []).unwrap()
  let solution = @fusekite.minimize_pos(spec)
  assert_eq(solution.patterns(), ["-01", "0-0", "11-"])
  assert_eq(solution.clause_count, 3)
  assert_eq(solution.literal_count, 6)
  let reversed = @fusekite.TruthSpec::new(3, [4, 3], []).unwrap()
  assert_eq(@fusekite.minimize_pos(reversed).patterns(), solution.patterns())
  let single = @fusekite.minimize_pos(
    @fusekite.TruthSpec::new(2, [0, 2, 3], []).unwrap(),
  )
  let returned = single.clauses()
  let essentials = single.essential_clauses()
  returned.clear()
  essentials.clear()
  let patterns = single.patterns()
  patterns.clear()
  assert_eq(single.patterns(), ["01"])
  assert_eq(single.essential_clauses().length(), 1)
  assert_eq(single.evaluate(1), Some(false))
}

///|
// Read the exported patterns as OR clauses and AND their values, independently
// of the implementation's cube masks and covers_row operation.
fn evaluate_pos_patterns(patterns : Array[String], row : Int) -> Bool {
  for pattern in patterns {
    let characters = pattern.to_array()
    let mut sum = false
    for position in 0..<characters.length() {
      let input = ((row >> (characters.length() - position - 1)) & 1) == 1
      if (characters[position] == '0' && input) ||
        (characters[position] == '1' && !input) {
        sum = true
      }
    }
    if !sum {
      return false
    }
  }
  true
}

///|
// Independent oracle: enumerate every sum clause directly from literal choices,
// then use dynamic programming over subsets of required zero rows. This does
// not call refine, minimize_sop, Cube::covers_row, or the POS evaluator.
fn pos_cost_oracle(
  width : Int,
  on_set : Array[Int],
  dc : Array[Int],
) -> (Int, Int) {
  let row_count = 1 << width
  let mut required_zero_mask = 0
  for row in 0..<row_count {
    if !on_set.contains(row) && !dc.contains(row) {
      required_zero_mask = required_zero_mask | (1 << row)
    }
  }
  let mut clause_choices = 1
  for _ in 0..<width {
    clause_choices *= 3
  }
  let candidates : Array[(Int, Int)] = []
  for code in 0..<clause_choices {
    let mut digits = code
    let literals : Array[Int] = []
    let mut cost = 0
    for _ in 0..<width {
      let choice = digits % 3
      digits /= 3
      literals.push(choice)
      if choice != 0 {
        cost += 1
      }
    }
    let mut zeros = 0
    let mut valid = true
    for row in 0..<row_count {
      let mut clause_true = false
      for bit in 0..<width {
        let input = ((row >> bit) & 1) == 1
        if (literals[bit] == 1 && input) || (literals[bit] == 2 && !input) {
          clause_true = true
        }
      }
      if !clause_true {
        if on_set.contains(row) {
          valid = false
        }
        if (required_zero_mask & (1 << row)) != 0 {
          zeros = zeros | (1 << row)
        }
      }
    }
    if valid && zeros != 0 {
      candidates.push((zeros, cost))
    }
  }
  let states = 1 << row_count
  let terms = Array::make(states, 1000)
  let costs = Array::make(states, 1000)
  terms[0] = 0
  costs[0] = 0
  for mask in 0..<states {
    if terms[mask] != 1000 {
      for candidate in candidates {
        let (zeros, cost) = candidate
        let next = mask | zeros
        if next != mask &&
          (
            terms[mask] + 1 < terms[next] ||
            (terms[mask] + 1 == terms[next] && costs[mask] + cost < costs[next])
          ) {
          terms[next] = terms[mask] + 1
          costs[next] = costs[mask] + cost
        }
      }
    }
  }
  (terms[required_zero_mask], costs[required_zero_mask])
}

///|
test "POS all three-input functions match literal semantics and exact cost oracle" {
  for truth_bits in 0..<256 {
    let on_set : Array[Int] = []
    for row in 0..<8 {
      if ((truth_bits >> row) & 1) == 1 {
        on_set.push(row)
      }
    }
    let solution = @fusekite.minimize_pos(
      @fusekite.TruthSpec::new(3, on_set, []).unwrap(),
    )
    for row in 0..<8 {
      assert_eq(solution.evaluate(row), Some(on_set.contains(row)))
      assert_eq(
        evaluate_pos_patterns(solution.patterns(), row),
        on_set.contains(row),
      )
    }
    let (clauses, literals) = pos_cost_oracle(3, on_set, [])
    assert_eq(solution.clause_count, clauses)
    assert_eq(solution.literal_count, literals)
  }
}

///|
test "POS all two-input ternary specifications match cared rows and exact costs" {
  for code in 0..<81 {
    let on_set : Array[Int] = []
    let dc : Array[Int] = []
    let mut digits = code
    for row in 0..<4 {
      if digits % 3 == 1 {
        on_set.push(row)
      } else if digits % 3 == 2 {
        dc.push(row)
      }
      digits /= 3
    }
    let solution = @fusekite.minimize_pos(
      @fusekite.TruthSpec::new(2, on_set, dc).unwrap(),
    )
    for row in 0..<4 {
      assert_eq(
        solution.evaluate(row),
        Some(evaluate_pos_patterns(solution.patterns(), row)),
      )
      if !dc.contains(row) {
        assert_eq(solution.evaluate(row), Some(on_set.contains(row)))
      }
    }
    let (clauses, literals) = pos_cost_oracle(2, on_set, dc)
    assert_eq(solution.clause_count, clauses)
    assert_eq(solution.literal_count, literals)
  }
}
