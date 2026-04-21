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

/// String must match the given regex pattern.
///
/// ```gleam
/// let validator = string.matches("^[A-Z]{3}$", "must be 3 uppercase letters")
/// validator("ABC")   // -> Ok("ABC")
/// validator("abc")   // -> Error("must be 3 uppercase letters")
/// ```
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

/// String must be one of the given values.
///
/// ```gleam
/// let validator = string.one_of(["admin", "user", "guest"], "invalid role")
/// validator("admin")   // -> Ok("admin")
/// validator("root")    // -> Error("invalid role")
/// ```
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

/// Must look like a URL (http:// or https://).
///
/// ```gleam
/// let validator = string.url("invalid url")
/// validator("https://example.com")  // -> Ok("https://example.com")
/// validator("example.com")          // -> Error("invalid url")
/// ```
pub fn url(msg: String) -> fn(String) -> Result(String, String) {
  matches("^https?://[^\\s]+$", msg)
}

/// Must be a valid UUID v4 format.
///
/// ```gleam
/// let validator = string.uuid("invalid uuid")
/// validator("550e8400-e29b-41d4-a716-446655440000")  // -> Ok(..)
/// validator("not-a-uuid")                            // -> Error("invalid uuid")
/// ```
pub fn uuid(msg: String) -> fn(String) -> Result(String, String) {
  matches(
    "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    msg,
  )
}

/// All characters must be digits (0-9).
///
/// ```gleam
/// let validator = string.numeric("digits only")
/// validator("123")   // -> Ok("123")
/// validator("12a")   // -> Error("digits only")
/// ```
pub fn numeric(msg: String) -> fn(String) -> Result(String, String) {
  matches("^[0-9]+$", msg)
}

/// All characters must be letters (a-zA-Z).
///
/// ```gleam
/// let validator = string.alpha("letters only")
/// validator("abc")   // -> Ok("abc")
/// validator("abc1")  // -> Error("letters only")
/// ```
pub fn alpha(msg: String) -> fn(String) -> Result(String, String) {
  matches("^[a-zA-Z]+$", msg)
}

/// All characters must be letters or digits.
///
/// ```gleam
/// let validator = string.alphanumeric("alphanumeric only")
/// validator("abc123")  // -> Ok("abc123")
/// validator("abc 123") // -> Error("alphanumeric only")
/// ```
pub fn alphanumeric(msg: String) -> fn(String) -> Result(String, String) {
  matches("^[a-zA-Z0-9]+$", msg)
}

/// String must have no leading or trailing whitespace.
///
/// ```gleam
/// let validator = string.trimmed("no surrounding spaces")
/// validator("hello")   // -> Ok("hello")
/// validator(" hello")  // -> Error("no surrounding spaces")
/// ```
pub fn trimmed(msg: String) -> fn(String) -> Result(String, String) {
  fn(value) {
    case string.trim(value) == value {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
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
