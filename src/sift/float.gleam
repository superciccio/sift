//// Float validators — range and positivity checks.

import gleam/float
import gleam/order

/// Value must be >= n
pub fn min(n: Float, msg: e) -> fn(Float) -> Result(Float, e) {
  fn(value) {
    case float.compare(value, n) {
      order.Lt -> Error(msg)
      _ -> Ok(value)
    }
  }
}

/// Value must be <= n
pub fn max(n: Float, msg: e) -> fn(Float) -> Result(Float, e) {
  fn(value) {
    case float.compare(value, n) {
      order.Gt -> Error(msg)
      _ -> Ok(value)
    }
  }
}

/// Value must be between lo and hi (inclusive)
pub fn between(lo: Float, hi: Float, msg: e) -> fn(Float) -> Result(Float, e) {
  fn(value) {
    case float.compare(value, lo), float.compare(value, hi) {
      order.Lt, _ -> Error(msg)
      _, order.Gt -> Error(msg)
      _, _ -> Ok(value)
    }
  }
}

/// Value must be > 0.0
pub fn positive(msg: e) -> fn(Float) -> Result(Float, e) {
  fn(value) {
    case float.compare(value, 0.0) {
      order.Gt -> Ok(value)
      _ -> Error(msg)
    }
  }
}

/// Value must be >= 0.0.
///
/// ```gleam
/// let validator = float.non_negative("must be >= 0")
/// validator(0.0)   // -> Ok(0.0)
/// validator(-0.1)  // -> Error("must be >= 0")
/// ```
pub fn non_negative(msg: e) -> fn(Float) -> Result(Float, e) {
  fn(value) {
    case float.compare(value, 0.0) {
      order.Lt -> Error(msg)
      _ -> Ok(value)
    }
  }
}
