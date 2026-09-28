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
  assert_true(@fusekite.TruthSpec::new(2, [4], []) is None)
  assert_true(@fusekite.TruthSpec::new(2, [1, 1], []) is None)
  assert_true(@fusekite.TruthSpec::new(2, [1], [1]) is None)
  assert_true(@fusekite.TruthSpec::new(2, [], [2, 2]) is None)
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
