//// Core validation functions — check fields, accumulate errors, compose validators.

import gleam/int
import gleam/list

/// A validation error with path to the field and a human-readable message.
///
/// ```gleam
/// FieldError(path: ["email"], message: "required")
/// FieldError(path: ["address", "zip"], message: "must be 5 digits")
/// ```
pub type FieldError {
  FieldError(path: List(String), message: String)
}

/// Accumulated validation result — value + errors collected so far
/// Using a tuple (not Result) enables the `use` pattern to run ALL validators
pub type Validated(a) =
  #(a, List(FieldError))

/// A single constraint: takes a value, returns Ok(value) or Error(message)
pub type Validator(a) =
  fn(a) -> Result(a, String)

/// Run a validator on a field value, accumulate errors, feeds into `use`.
///
/// ```gleam
/// use name <- sift.check("name", input.name, s.min_length(1, "required"))
/// use email <- sift.check("email", input.email, s.email("invalid"))
/// sift.ok(User(name:, email:))
/// ```
pub fn check(
  field: String,
  value: a,
  validator: Validator(a),
  next: fn(a) -> Validated(b),
) -> Validated(b) {
  case validator(value) {
    Ok(v) -> next(v)
    Error(msg) -> {
      let #(result, errors) = next(value)
      #(result, [FieldError(path: [field], message: msg), ..errors])
    }
  }
}

/// Run a sub-validator function, prefixing error paths with the field name.
///
/// ```gleam
/// use address <- sift.nested("address", input.address, validate_address)
/// // errors get paths like ["address", "zip"]
/// ```
pub fn nested(
  field: String,
  value: a,
  validator_fn: fn(a) -> Validated(b),
  next: fn(b) -> Validated(c),
) -> Validated(c) {
  let #(inner_value, inner_errors) = validator_fn(value)
  let prefixed_errors =
    list.map(inner_errors, fn(e) {
      FieldError(path: [field, ..e.path], message: e.message)
    })
  let #(result, outer_errors) = next(inner_value)
  #(result, list.append(prefixed_errors, outer_errors))
}

/// Wrap a final value into a Validated tuple with no errors
pub fn ok(value: a) -> Validated(a) {
  #(value, [])
}

/// Convert a Validated(a) to Result(a, List(FieldError)).
///
/// ```gleam
/// sift.ok(User(name: "Jo", email: "jo@example.com"))
/// |> sift.validate
/// // -> Ok(User(name: "Jo", email: "jo@example.com"))
/// ```
pub fn validate(validated: Validated(a)) -> Result(a, List(FieldError)) {
  case validated {
    #(value, []) -> Ok(value)
    #(_, errors) -> Error(errors)
  }
}

/// Compose two validators — run both, accumulate errors from both.
///
/// ```gleam
/// let validator = s.min_length(1, "required") |> sift.and(s.email("invalid"))
/// ```
pub fn and(
  v1: Validator(a),
  v2: Validator(a),
) -> Validator(a) {
  fn(value) {
    case v1(value), v2(value) {
      Ok(a), Ok(_) -> Ok(a)
      Ok(_), Error(msg) -> Error(msg)
      Error(msg), Ok(_) -> Error(msg)
      // When both fail, return the first error (second is lost in this simple compose)
      Error(msg), _ -> Error(msg)
    }
  }
}

/// Validate every item in a list, accumulating indexed error paths.
/// Produces paths like `["tags", "0"]`, `["tags", "1"]`, etc.
///
/// ```gleam
/// use tags <- sift.each("tags", input.tags, s.non_empty("empty tag"))
/// // invalid items get paths like ["tags", "2"]
/// ```
pub fn each(
  field: String,
  items: List(a),
  validator: Validator(a),
  next: fn(List(a)) -> Validated(b),
) -> Validated(b) {
  let item_errors =
    items
    |> list.index_map(fn(item, idx) {
      case validator(item) {
        Ok(_) -> []
        Error(msg) -> [
          FieldError(
            path: [field, int.to_string(idx)],
            message: msg,
          ),
        ]
      }
    })
    |> list.flatten
  let #(result, outer_errors) = next(items)
  #(result, list.append(item_errors, outer_errors))
}

/// Pass if either validator succeeds (try v1 first, then v2).
///
/// ```gleam
/// let validator = s.email("invalid") |> sift.or(s.url("invalid"))
/// ```
pub fn or(
  v1: Validator(a),
  v2: Validator(a),
) -> Validator(a) {
  fn(value) {
    case v1(value) {
      Ok(v) -> Ok(v)
      Error(_) -> v2(value)
    }
  }
}

/// Invert a validator — fail if it passes, pass if it fails.
///
/// ```gleam
/// let not_admin = sift.not(s.one_of(["admin"], ""), "cannot be admin")
/// ```
pub fn not(
  validator: Validator(a),
  msg: String,
) -> Validator(a) {
  fn(value) {
    case validator(value) {
      Ok(_) -> Error(msg)
      Error(_) -> Ok(value)
    }
  }
}

/// Value must equal the expected value
pub fn equals(expected: a, msg: String) -> Validator(a) {
  fn(value) {
    case value == expected {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Escape hatch for user-defined checks
pub fn custom(f: fn(a) -> Result(a, String)) -> Validator(a) {
  f
}
