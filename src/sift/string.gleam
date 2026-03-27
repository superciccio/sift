//// String validators — length, pattern matching, format checks (email, url, uuid).

import gleam/regexp
import gleam/string

/// String must have at least n graphemes
pub fn min_length(n: Int, msg: String) -> fn(String) -> Result(String, String) {
  fn(value) {
    case string.length(value) >= n {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// String must have at most n graphemes
pub fn max_length(n: Int, msg: String) -> fn(String) -> Result(String, String) {
  fn(value) {
    case string.length(value) <= n {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// String must have exactly n graphemes
pub fn length(n: Int, msg: String) -> fn(String) -> Result(String, String) {
  fn(value) {
    case string.length(value) == n {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// String must not be empty (shorthand for min_length(1))
pub fn non_empty(msg: String) -> fn(String) -> Result(String, String) {
  min_length(1, msg)
}

/// String must match the given regex pattern
pub fn matches(
  pattern: String,
  msg: String,
) -> fn(String) -> Result(String, String) {
  fn(value) {
    case regexp.from_string(pattern) {
      Ok(re) ->
        case regexp.check(re, value) {
          True -> Ok(value)
          False -> Error(msg)
        }
      Error(_) -> Error(msg)
    }
  }
}

/// String must be one of the given values
pub fn one_of(
  values: List(String),
  msg: String,
) -> fn(String) -> Result(String, String) {
  fn(value) {
    case list_contains(values, value) {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// String must start with the given prefix
pub fn starts_with(
  prefix: String,
  msg: String,
) -> fn(String) -> Result(String, String) {
  fn(value) {
    case string.starts_with(value, prefix) {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// String must end with the given suffix
pub fn ends_with(
  suffix: String,
  msg: String,
) -> fn(String) -> Result(String, String) {
  fn(value) {
    case string.ends_with(value, suffix) {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// String must contain the given substring
pub fn contains(
  substring: String,
  msg: String,
) -> fn(String) -> Result(String, String) {
  fn(value) {
    case string.contains(value, substring) {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Must look like an email (contains exactly one @, something before and after).
///
/// ```gleam
/// let validator = string.email("invalid email")
/// validator("jo@example.com")  // -> Ok("jo@example.com")
/// validator("nope")            // -> Error("invalid email")
/// ```
pub fn email(msg: String) -> fn(String) -> Result(String, String) {
  matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", msg)
}

/// Must look like a URL (http:// or https://)
pub fn url(msg: String) -> fn(String) -> Result(String, String) {
  matches("^https?://[^\\s]+$", msg)
}

/// Must be a valid UUID v4 format
pub fn uuid(msg: String) -> fn(String) -> Result(String, String) {
  matches(
    "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    msg,
  )
}

fn list_contains(items: List(String), target: String) -> Bool {
  case items {
    [] -> False
    [first, ..rest] ->
      case first == target {
        True -> True
        False -> list_contains(rest, target)
      }
  }
}
