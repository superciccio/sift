import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import sift
import sift/string as s

pub type Registration {
  Registration(
    username: String,
    email: String,
    age: Int,
    website: Option(String),
    referral_code: Option(String),
  )
}

/// Extract a required string from form pairs.
/// Missing key → FieldError("is required").
fn require(
  form: List(#(String, String)),
  field: String,
  next: fn(String) -> sift.Validated(a, String),
) -> sift.Validated(a, String) {
  case list.key_find(form, field) {
    Ok(value) -> next(value)
    Error(_) -> {
      let #(result, errors) = next("")
      #(result, [sift.FieldError(path: [field], error: "is required"), ..errors])
    }
  }
}

/// Extract an optional string from form pairs.
/// Missing key or empty string → None (no validation).
/// Present non-empty string → Some(value), validated.
fn optional(
  form: List(#(String, String)),
  field: String,
  validator: sift.Validator(String, String),
  next: fn(Option(String)) -> sift.Validated(a, String),
) -> sift.Validated(a, String) {
  case list.key_find(form, field) {
    Error(_) -> next(None)
    Ok("") -> next(None)
    Ok(value) ->
      case validator(value) {
        Ok(v) -> next(Some(v))
        Error(msg) -> {
          let #(result, errors) = next(None)
          #(result, [sift.FieldError(path: [field], error: msg), ..errors])
        }
      }
  }
}

pub fn validate_registration(
  form: List(#(String, String)),
) -> sift.Validated(Registration, String) {
  use username <- require(form, "username")
  use username <- sift.check(
    "username",
    username,
    s.min_length(3, "must be at least 3 characters"),
  )
  use email <- require(form, "email")
  use email <- sift.check("email", email, s.email("invalid email"))
  use age_raw <- require(form, "age")
  use age <- sift.check_parse("age", age_raw, int.parse, 0, "must be a number")
  use age <- sift.check("age", age, fn(v) {
    case v >= 13 {
      True -> Ok(v)
      False -> Error("must be at least 13")
    }
  })
  use website <- optional(form, "website", s.url("invalid url"))
  use referral_code <- optional(
    form,
    "referral_code",
    s.alphanumeric("must be alphanumeric"),
  )
  sift.ok(Registration(username:, email:, age:, website:, referral_code:))
}

pub fn register(
  form: List(#(String, String)),
) -> Result(Registration, List(sift.FieldError(String))) {
  sift.validate(validate_registration(form))
}
