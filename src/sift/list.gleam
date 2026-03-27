//// List validators — length constraints.

import gleam/list

/// List must have at least n items
pub fn min_length(n: Int, msg: String) -> fn(List(a)) -> Result(List(a), String) {
  fn(value) {
    case list.length(value) >= n {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// List must have at most n items
pub fn max_length(n: Int, msg: String) -> fn(List(a)) -> Result(List(a), String) {
  fn(value) {
    case list.length(value) <= n {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// List must not be empty
pub fn non_empty(msg: String) -> fn(List(a)) -> Result(List(a), String) {
  min_length(1, msg)
}
