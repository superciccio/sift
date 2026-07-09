//// Integer validators — range, positivity, and membership checks.

/// Value must be >= n
pub fn min(n: Int, msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case value >= n {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Value must be <= n
pub fn max(n: Int, msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case value <= n {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Value must be between lo and hi (inclusive).
///
/// ```gleam
/// let validator = int.between(1, 100, "out of range")
/// validator(50)   // -> Ok(50)
/// validator(200)  // -> Error("out of range")
/// ```
pub fn between(lo: Int, hi: Int, msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case value >= lo && value <= hi {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Value must be > 0
pub fn positive(msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case value > 0 {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Value must be >= 0
pub fn non_negative(msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case value >= 0 {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Value must be one of the given values
pub fn one_of(values: List(Int), msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case list_contains(values, value) {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Value must be < 0.
///
/// ```gleam
/// let validator = int.negative("must be negative")
/// validator(-1)  // -> Ok(-1)
/// validator(0)   // -> Error("must be negative")
/// ```
pub fn negative(msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case value < 0 {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Value must be divisible by n.
///
/// ```gleam
/// let validator = int.divisible_by(3, "must be divisible by 3")
/// validator(9)  // -> Ok(9)
/// validator(7)  // -> Error("must be divisible by 3")
/// ```
pub fn divisible_by(n: Int, msg: e) -> fn(Int) -> Result(Int, e) {
  fn(value) {
    case value % n == 0 {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

fn list_contains(items: List(Int), target: Int) -> Bool {
  case items {
    [] -> False
    [first, ..rest] ->
      case first == target {
        True -> True
        False -> list_contains(rest, target)
      }
  }
}
