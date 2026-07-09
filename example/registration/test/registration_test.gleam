import gleam/option.{None, Some}
import gleeunit
import registration.{Registration}
import sift

pub fn main() -> Nil {
  gleeunit.main()
}

// --- Happy path ---

pub fn valid_registration_test() {
  let form = [
    #("username", "alice"),
    #("email", "alice@example.com"),
    #("age", "25"),
    #("website", "https://alice.dev"),
    #("referral_code", "ABC123"),
  ]
  let assert Ok(Registration(
    username: "alice",
    email: "alice@example.com",
    age: 25,
    website: Some("https://alice.dev"),
    referral_code: Some("ABC123"),
  )) = registration.register(form)
}

pub fn valid_minimal_registration_test() {
  let form = [
    #("username", "bob"),
    #("email", "bob@test.com"),
    #("age", "30"),
  ]
  let assert Ok(Registration(
    username: "bob",
    email: "bob@test.com",
    age: 30,
    website: None,
    referral_code: None,
  )) = registration.register(form)
}

// --- Missing fields ---

pub fn missing_username_test() {
  let form = [#("email", "a@b.com"), #("age", "20")]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["username"], "is required")
}

pub fn missing_email_test() {
  let form = [#("username", "alice"), #("age", "20")]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["email"], "is required")
}

pub fn missing_age_test() {
  let form = [#("username", "alice"), #("email", "a@b.com")]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["age"], "is required")
}

// --- Parse errors ---

pub fn age_not_a_number_test() {
  let form = [
    #("username", "alice"),
    #("email", "a@b.com"),
    #("age", "twenty"),
  ]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["age"], "must be a number")
}

// --- Validation errors after parse ---

pub fn age_too_young_test() {
  let form = [
    #("username", "alice"),
    #("email", "a@b.com"),
    #("age", "12"),
  ]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["age"], "must be at least 13")
}

pub fn username_too_short_test() {
  let form = [#("username", "ab"), #("email", "a@b.com"), #("age", "20")]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["username"], "must be at least 3 characters")
}

pub fn invalid_email_test() {
  let form = [#("username", "alice"), #("email", "not-email"), #("age", "20")]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["email"], "invalid email")
}

pub fn invalid_website_test() {
  let form = [
    #("username", "alice"),
    #("email", "a@b.com"),
    #("age", "20"),
    #("website", "not-a-url"),
  ]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["website"], "invalid url")
}

// --- Error accumulation across parse + validate ---

pub fn multiple_errors_accumulate_test() {
  let form = [
    #("username", ""),
    #("email", "bad"),
    #("age", "xyz"),
    #("website", "nope"),
  ]
  let assert Error(errors) = registration.register(form)
  // username empty, email invalid, age parse fail, website invalid
  assert list_length(errors) >= 4
}

pub fn all_missing_test() {
  let form = []
  let assert Error(errors) = registration.register(form)
  // username, email, age all required
  assert list_length(errors) >= 3
}

// --- Optional fields ---

pub fn empty_website_treated_as_none_test() {
  let form = [
    #("username", "alice"),
    #("email", "a@b.com"),
    #("age", "20"),
    #("website", ""),
  ]
  let assert Ok(Registration(website: None, ..)) = registration.register(form)
}

pub fn empty_referral_treated_as_none_test() {
  let form = [
    #("username", "alice"),
    #("email", "a@b.com"),
    #("age", "20"),
    #("referral_code", ""),
  ]
  let assert Ok(Registration(referral_code: None, ..)) =
    registration.register(form)
}

pub fn referral_code_alphanumeric_test() {
  let form = [
    #("username", "alice"),
    #("email", "a@b.com"),
    #("age", "20"),
    #("referral_code", "not valid!"),
  ]
  let assert Error(errors) = registration.register(form)
  assert_has_error(errors, ["referral_code"], "must be alphanumeric")
}

// --- Helpers ---

fn assert_has_error(
  errors: List(sift.FieldError(String)),
  path: List(String),
  message: String,
) -> Nil {
  let found = list_any(errors, fn(e) { e.path == path && e.error == message })
  case found {
    True -> Nil
    False -> {
      panic as { "Expected error at path with message: " <> message }
    }
  }
}

fn list_any(items: List(a), predicate: fn(a) -> Bool) -> Bool {
  case items {
    [] -> False
    [first, ..rest] ->
      case predicate(first) {
        True -> True
        False -> list_any(rest, predicate)
      }
  }
}

fn list_length(items: List(a)) -> Int {
  case items {
    [] -> 0
    [_, ..rest] -> 1 + list_length(rest)
  }
}
