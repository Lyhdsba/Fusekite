///|
test "odd three-bit rows collapse to one implicant" {
  let spec = match @fusekite.TruthSpec::new(3, [1, 3, 5, 7], []) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }
  let report = @fusekite.refine(spec)
  assert_eq(report.rounds.length(), 3)
  assert_eq(report.primes.length(), 1)
  assert_eq(report.primes[0].pattern(), "--1")
  assert_eq(report.primes[0].literal_count(), 1)
}

///|
test "don't-care rows can participate in a merge" {
  let spec = match @fusekite.TruthSpec::new(3, [1], [3]) {
    Some(spec) => spec
    None => fail("valid don't-care table was rejected")
  }
  let report = @fusekite.refine(spec)
  assert_eq(report.primes.length(), 1)
  assert_eq(report.primes[0].pattern(), "0-1")
}

///|
test "truth table rejects invalid dimensions and row sets" {
  assert_true(@fusekite.TruthSpec::new(0, [], []) is None)
  assert_true(@fusekite.TruthSpec::new(9, [], []) is None)
  assert_true(@fusekite.TruthSpec::new(1, [1], []) is Some(_))
  assert_true(@fusekite.TruthSpec::new(8, [255], []) is Some(_))
  assert_true(@fusekite.TruthSpec::new(2, [4], []) is None)
  assert_true(@fusekite.TruthSpec::new(2, [1, 1], []) is None)
  assert_true(@fusekite.TruthSpec::new(2, [1], [1]) is None)
  assert_true(@fusekite.TruthSpec::new(2, [], [2, 2]) is None)
}

///|
test "truth spec protects its validated rows from caller mutation" {
  let on_set = [1]
  let dont_cares = [3]
  let spec = match @fusekite.TruthSpec::new(2, on_set, dont_cares) {
    Some(spec) => spec
    None => fail("valid truth table was rejected")
  }

  on_set.push(2)
  dont_cares.push(0)
  let returned_minterms = spec.minterms()
  let returned_dont_cares = spec.dont_care_rows()
  returned_minterms.push(2)
  returned_dont_cares.push(0)

  assert_eq(spec.minterm_count(), 1)
  assert_eq(spec.minterms(), [1])
  assert_eq(spec.dont_care_rows(), [3])
  assert_eq(@fusekite.minimize_sop(spec).patterns(), ["-1"])
}

///|
test "eight-input upper boundary preserves the most significant bit" {
  let spec = match @fusekite.TruthSpec::new(8, [255], [254]) {
    Some(spec) => spec
    None => fail("valid upper-bound truth table was rejected")
  }
  let solution = @fusekite.minimize_sop(spec)
  assert_eq(solution.patterns(), ["1111111-"])
  assert_true(solution.selected[0].covers_row(255))
  assert_true(solution.selected[0].covers_row(254))
  assert_true(!solution.selected[0].covers_row(253))
}

///|
test "eight-input separated endpoints remain a valid exact cover" {
  let spec = match @fusekite.TruthSpec::new(8, [0, 255], []) {
    Some(spec) => spec
    None => fail("valid endpoint truth table was rejected")
  }
  let solution = @fusekite.minimize_sop(spec)
  assert_eq(solution.patterns(), ["00000000", "11111111"])
  assert_eq(solution.term_count, 2)
  assert_eq(solution.literal_count, 16)
}

///|
test "all-one and all-zero tables have unsurprising prime sets" {
  let all_one = match @fusekite.TruthSpec::new(2, [0, 1, 2, 3], []) {
    Some(spec) => spec
    None => fail("all-one table was rejected")
  }
  assert_eq(@fusekite.refine(all_one).primes[0].pattern(), "--")

  let all_zero = match @fusekite.TruthSpec::new(2, [], []) {
    Some(spec) => spec
    None => fail("all-zero table was rejected")
  }
  assert_eq(@fusekite.refine(all_zero).primes.length(), 0)
}
