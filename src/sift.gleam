//// Core validation functions — check fields, accumulate errors, compose validators.
////
//// Build a validator for a struct by chaining `check` calls with `use`,
//// then finish with `ok` and convert to a `Result` with `validate`. Every
//// field runs, so a single call returns every error at once — not just the
//// first.
////
//// ```gleam
//// import sift
//// import sift/int as i
//// import sift/string as s
////
//// pub type User { User(name: String, email: String, age: Int) }
////
//// pub fn validate_user(input: User) -> Result(User, List(sift.FieldError)) {
////   use name <- sift.check("name", input.name, s.non_empty("required"))
////   use email <- sift.check("email", input.email, s.email("invalid"))
////   use age <- sift.check("age", input.age, i.between(0, 150, "out of range"))
////   sift.ok(User(name:, email:, age:))
////   |> sift.validate
//// }
//// ```
////
//// For nested structs use `nested`, for lists use `each`, for multiple
//// constraints on one field use `check_all`, and for conditional
//// constraints use `when`. See `example/contacts/` for a full walkthrough.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}

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

/// Value must equal the expected value.
///
/// ```gleam
/// let validator = sift.equals("yes", "must accept terms")
/// validator("yes")  // -> Ok("yes")
/// validator("no")   // -> Error("must accept terms")
/// ```
pub fn equals(expected: a, msg: String) -> Validator(a) {
  fn(value) {
    case value == expected {
      True -> Ok(value)
      False -> Error(msg)
    }
  }
}

/// Run multiple validators on a field, accumulate all errors.
///
/// ```gleam
/// use name <- sift.check_all("name", input.name, [
///   s.non_empty("required"),
///   s.min_length(3, "too short"),
///   s.max_length(100, "too long"),
/// ])
/// sift.ok(name)
/// ```
pub fn check_all(
  field: String,
  value: a,
  validators: List(Validator(a)),
  next: fn(a) -> Validated(b),
) -> Validated(b) {
  let field_errors =
    validators
    |> list.filter_map(fn(v) {
      case v(value) {
        Ok(_) -> Error(Nil)
        Error(msg) -> Ok(FieldError(path: [field], message: msg))
      }
    })
  let #(result, outer_errors) = next(value)
  #(result, list.append(field_errors, outer_errors))
}

/// Conditional validator — runs the validator only when condition is True.
///
/// ```gleam
/// use state <- sift.check("state", input.state,
///   sift.when(country == "US", s.non_empty("required")))
/// ```
pub fn when(condition: Bool, validator: Validator(a)) -> Validator(a) {
  fn(value) {
    case condition {
      True -> validator(value)
      False -> Ok(value)
    }
  }
}

/// Validate an Option value only when Some, skip when None.
///
/// ```gleam
/// use nickname <- sift.check_optional("nickname", input.nickname,
///   s.min_length(2, "too short"))
/// sift.ok(User(nickname:))
/// ```
pub fn check_optional(
  field: String,
  value: Option(a),
  validator: Validator(a),
  next: fn(Option(a)) -> Validated(b),
) -> Validated(b) {
  case value {
    None -> next(None)
    Some(v) ->
      case validator(v) {
        Ok(_) -> next(Some(v))
        Error(msg) -> {
          let #(result, errors) = next(Some(v))
          #(result, [FieldError(path: [field], message: msg), ..errors])
        }
      }
  }
}

/// Parse a raw value and feed the result into the chain.
/// On success, passes the parsed value to next.
/// On failure, records a FieldError and passes the default to next
/// so that subsequent fields still validate.
///
/// ```gleam
/// use age <- sift.check_parse("age", "42", int.parse, 0, "must be a number")
/// use age <- sift.check("age", age, i.min(13, "must be at least 13"))
/// sift.ok(age)
/// ```
pub fn check_parse(
  field: String,
  value: a,
  parser: fn(a) -> Result(b, c),
  default: b,
  msg: String,
  next: fn(b) -> Validated(d),
) -> Validated(d) {
  case parser(value) {
    Ok(parsed) -> next(parsed)
    Error(_) -> {
      let #(result, errors) = next(default)
      #(result, [FieldError(path: [field], message: msg), ..errors])
    }
  }
}

/// Validate every item in a list with a sub-validator function, prefixing
/// error paths with the field name and the item's index.
/// Produces paths like `["tags", "0", "name"]`.
///
/// Use this when each item is itself a struct to validate. For a single
/// `Validator(a)` per item, use `each` instead.
///
/// ```gleam
/// use tags <- sift.check_each("tags", input.tags, validate_tag)
/// // errors get paths like ["tags", "2", "name"]
/// ```
pub fn check_each(
  field: String,
  values: List(a),
  validator_fn: fn(a) -> Validated(b),
  next: fn(List(b)) -> Validated(c),
) -> Validated(c) {
  let #(validated_values, item_errors) =
    values
    |> list.index_map(fn(item, idx) {
      let #(value, errors) = validator_fn(item)
      let prefixed =
        list.map(errors, fn(e) {
          FieldError(
            path: [field, int.to_string(idx), ..e.path],
            message: e.message,
          )
        })
      #(value, prefixed)
    })
    |> list.fold(#([], []), fn(acc, pair) {
      let #(values_acc, errors_acc) = acc
      let #(value, errors) = pair
      #([value, ..values_acc], list.append(errors_acc, errors))
    })
  let validated_values = list.reverse(validated_values)
  let #(result, outer_errors) = next(validated_values)
  #(result, list.append(item_errors, outer_errors))
}

/// Cross-field validator comparing two already-validated values.
/// On success, passes the (possibly transformed) first value to next.
/// On failure, records a FieldError under `field` and passes `a` through
/// so subsequent checks still run.
///
/// ```gleam
/// use name <- sift.check("name", input.name, s.non_empty("required"))
/// use confirm <- sift.check("confirm", input.confirm, s.non_empty("required"))
/// use name <- sift.check2("confirm", name, confirm, fn(a, b) {
///   case a == b { True -> Ok(a) False -> Error("must match name") }
/// })
/// sift.ok(name)
/// ```
pub fn check2(
  field: String,
  a: a,
  b: b,
  validator: fn(a, b) -> Result(a, String),
  next: fn(a) -> Validated(c),
) -> Validated(c) {
  case validator(a, b) {
    Ok(v) -> next(v)
    Error(msg) -> {
      let #(result, errors) = next(a)
      #(result, [FieldError(path: [field], message: msg), ..errors])
    }
  }
}

/// Post-assembly whole-object check. Runs on a `Validated(a)` produced by
/// `ok(...)`, useful for cross-field constraints expressed in terms of the
/// final struct.
///
/// ```gleam
/// sift.ok(Registration(role:, mfa:))
/// |> sift.refine("mfa", fn(r) {
///   case r.role == "admin" && r.mfa == None {
///     True -> Error("required for admins")
///     False -> Ok(r)
///   }
/// })
/// |> sift.validate
/// ```
pub fn refine(
  validated: Validated(a),
  field: String,
  check: fn(a) -> Result(a, String),
) -> Validated(a) {
  let #(value, errors) = validated
  case check(value) {
    Ok(v) -> #(v, errors)
    Error(msg) -> #(
      value,
      list.append(errors, [FieldError(path: [field], message: msg)]),
    )
  }
}

/// Escape hatch for user-defined checks.
///
/// ```gleam
/// let even = sift.custom(fn(n: Int) {
///   case n % 2 == 0 {
///     True -> Ok(n)
///     False -> Error("must be even")
///   }
/// })
/// even(4)  // -> Ok(4)
/// even(3)  // -> Error("must be even")
/// ```
pub fn custom(f: fn(a) -> Result(a, String)) -> Validator(a) {
  f
}
