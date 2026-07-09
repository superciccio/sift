//// Option validators — required/optional field handling.

import gleam/option.{type Option, None, Some}

/// None produces an error, Some(a) unwraps the value.
///
/// ```gleam
/// let validator = option.required("field is required")
/// validator(Some("hello"))  // -> Ok("hello")
/// validator(None)           // -> Error("field is required")
/// ```
pub fn required(msg: e) -> fn(Option(a)) -> Result(a, e) {
  fn(value) {
    case value {
      Some(v) -> Ok(v)
      None -> Error(msg)
    }
  }
}

/// None passes through as the default, Some(a) runs the validator.
/// Returns Option(a) — None stays None, Some(a) validates a.
///
/// ```gleam
/// let validator = option.optional(string.min_length(3, "too short"))
/// validator(None)           // -> Ok(None)
/// validator(Some("hello"))  // -> Ok(Some("hello"))
/// validator(Some("hi"))     // -> Error("too short")
/// ```
pub fn optional(
  validator: fn(a) -> Result(a, e),
) -> fn(Option(a)) -> Result(Option(a), e) {
  fn(value) {
    case value {
      None -> Ok(None)
      Some(v) ->
        case validator(v) {
          Ok(validated) -> Ok(Some(validated))
          Error(msg) -> Error(msg)
        }
    }
  }
}
