import gleam/int
import gleam/option.{type Option, None, Some}
import gleeunit
import sift
import sift/float as f
import sift/int as i
import sift/list as l
import sift/option as o
import sift/string as s

pub fn main() -> Nil {
  gleeunit.main()
}

// --- Core ---

pub fn check_valid_test() {
  let result = {
    use name <- sift.check("name", "Alice", s.non_empty("required"))
    sift.ok(name)
  }
  assert result == #("Alice", [])
  let assert Ok("Alice") = sift.validate(result)
}

pub fn check_invalid_test() {
  let result = {
    use name <- sift.check("name", "", s.non_empty("required"))
    sift.ok(name)
  }
  let assert Error([sift.FieldError(path: ["name"], error: "required")]) =
    sift.validate(result)
}

pub fn multiple_errors_accumulate_test() {
  let result = {
    use name <- sift.check("name", "", s.non_empty("name required"))
    use age <- sift.check("age", -1, i.positive("must be positive"))
    sift.ok(#(name, age))
  }
  let assert Error(errors) = sift.validate(result)
  let assert 2 = length(errors)
}

pub fn nested_prefixes_paths_test() {
  let validate_inner = fn(value: String) {
    use v <- sift.check("zip", value, s.length(5, "must be 5 chars"))
    sift.ok(v)
  }
  let result = {
    use zip <- sift.nested("address", "abc", validate_inner)
    sift.ok(zip)
  }
  let assert Error([
    sift.FieldError(path: ["address", "zip"], error: "must be 5 chars"),
  ]) = sift.validate(result)
}

pub fn and_both_pass_test() {
  let v = s.min_length(1, "too short") |> sift.and(s.max_length(5, "too long"))
  let assert Ok("hey") = v("hey")
}

pub fn and_first_fails_test() {
  let v = s.min_length(3, "too short") |> sift.and(s.max_length(5, "too long"))
  let assert Error("too short") = v("hi")
}

pub fn and_second_fails_test() {
  let v = s.min_length(1, "too short") |> sift.and(s.max_length(3, "too long"))
  let assert Error("too long") = v("hello")
}

pub fn custom_validator_test() {
  let even =
    sift.custom(fn(n: Int) {
      case n % 2 == 0 {
        True -> Ok(n)
        False -> Error("must be even")
      }
    })
  let assert Ok(4) = even(4)
  let assert Error("must be even") = even(3)
}

// --- check_all ---

pub fn check_all_all_pass_test() {
  let result = {
    use name <- sift.check_all("name", "Alice", [
      s.non_empty("required"),
      s.min_length(3, "too short"),
      s.max_length(50, "too long"),
    ])
    sift.ok(name)
  }
  let assert Ok("Alice") = sift.validate(result)
}

pub fn check_all_multiple_fail_test() {
  let result = {
    use name <- sift.check_all("name", "", [
      s.non_empty("required"),
      s.min_length(3, "too short"),
    ])
    sift.ok(name)
  }
  let assert Error(errors) = sift.validate(result)
  let assert 2 = length(errors)
}

pub fn check_all_partial_fail_test() {
  let result = {
    use name <- sift.check_all("name", "ab", [
      s.non_empty("required"),
      s.min_length(3, "too short"),
      s.max_length(50, "too long"),
    ])
    sift.ok(name)
  }
  let assert Error([sift.FieldError(path: ["name"], error: "too short")]) =
    sift.validate(result)
}

// --- when ---

pub fn when_true_passes_test() {
  let v = sift.when(True, s.non_empty("required"))
  let assert Ok("hello") = v("hello")
}

pub fn when_true_fails_test() {
  let v = sift.when(True, s.non_empty("required"))
  let assert Error("required") = v("")
}

pub fn when_false_skips_test() {
  let v = sift.when(False, s.non_empty("required"))
  let assert Ok("") = v("")
}

pub fn when_in_check_test() {
  let result = {
    use state <- sift.check(
      "state",
      "",
      sift.when(True, s.non_empty("required")),
    )
    sift.ok(state)
  }
  let assert Error([sift.FieldError(path: ["state"], error: "required")]) =
    sift.validate(result)
}

pub fn when_false_in_check_test() {
  let result = {
    use state <- sift.check(
      "state",
      "",
      sift.when(False, s.non_empty("required")),
    )
    sift.ok(state)
  }
  let assert Ok("") = sift.validate(result)
}

// --- check_optional ---

pub fn check_optional_none_skips_test() {
  let result = {
    use nickname <- sift.check_optional(
      "nickname",
      None,
      s.min_length(2, "too short"),
    )
    sift.ok(nickname)
  }
  let assert Ok(None) = sift.validate(result)
}

pub fn check_optional_some_valid_test() {
  let result = {
    use nickname <- sift.check_optional(
      "nickname",
      Some("Al"),
      s.min_length(2, "too short"),
    )
    sift.ok(nickname)
  }
  let assert Ok(Some("Al")) = sift.validate(result)
}

pub fn check_optional_some_invalid_test() {
  let result = {
    use nickname <- sift.check_optional(
      "nickname",
      Some("A"),
      s.min_length(2, "too short"),
    )
    sift.ok(nickname)
  }
  let assert Error([sift.FieldError(path: ["nickname"], error: "too short")]) =
    sift.validate(result)
}

// --- check_parse ---

pub fn check_parse_valid_test() {
  let result = {
    use age <- sift.check_parse("age", "42", int.parse, 0, "must be a number")
    sift.ok(age)
  }
  let assert Ok(42) = sift.validate(result)
}

pub fn check_parse_invalid_test() {
  let result = {
    use age <- sift.check_parse("age", "abc", int.parse, 0, "must be a number")
    sift.ok(age)
  }
  let assert Error([sift.FieldError(path: ["age"], error: "must be a number")]) =
    sift.validate(result)
}

pub fn check_parse_then_validate_test() {
  // Parse string to int, then validate the int
  let result = {
    use age <- sift.check_parse("age", "42", int.parse, 0, "must be a number")
    use age <- sift.check("age", age, i.positive("must be positive"))
    sift.ok(age)
  }
  let assert Ok(42) = sift.validate(result)
}

pub fn check_parse_fail_then_validate_still_runs_test() {
  // Parse fails, but subsequent checks on other fields still accumulate
  let result = {
    use age <- sift.check_parse("age", "abc", int.parse, 0, "must be a number")
    use name <- sift.check("name", "", s.non_empty("required"))
    sift.ok(#(age, name))
  }
  let assert Error(errors) = sift.validate(result)
  let assert 2 = length(errors)
}

pub fn check_parse_in_form_scenario_test() {
  // Simulating a form: all fields come as strings
  let form_name = "Alice"
  let form_age = "30"
  let form_score = "not_a_number"

  let result = {
    use name <- sift.check("name", form_name, s.non_empty("required"))
    use age <- sift.check_parse(
      "age",
      form_age,
      int.parse,
      0,
      "must be a number",
    )
    use age <- sift.check("age", age, i.between(0, 150, "out of range"))
    use score <- sift.check_parse(
      "score",
      form_score,
      int.parse,
      0,
      "must be a number",
    )
    sift.ok(#(name, age, score))
  }
  let assert Error(errors) = sift.validate(result)
  // Only score fails to parse
  let assert 1 = length(errors)
}

// --- String ---

pub fn string_min_length_test() {
  let assert Ok("abc") = s.min_length(3, "too short")("abc")
  let assert Error("too short") = s.min_length(3, "too short")("ab")
}

pub fn string_max_length_test() {
  let assert Ok("ab") = s.max_length(3, "too long")("ab")
  let assert Error("too long") = s.max_length(3, "too long")("abcd")
}

pub fn string_length_test() {
  let assert Ok("abc") = s.length(3, "wrong")("abc")
  let assert Error("wrong") = s.length(3, "wrong")("ab")
}

pub fn string_non_empty_test() {
  let assert Ok("a") = s.non_empty("required")("a")
  let assert Error("required") = s.non_empty("required")("")
}

pub fn string_matches_test() {
  let assert Ok("123") = s.matches("^\\d+$", "digits only")("123")
  let assert Error("digits only") = s.matches("^\\d+$", "digits only")("abc")
}

pub fn string_one_of_test() {
  let assert Ok("a") = s.one_of(["a", "b", "c"], "invalid")("a")
  let assert Error("invalid") = s.one_of(["a", "b", "c"], "invalid")("d")
}

pub fn string_starts_with_test() {
  let assert Ok("hello world") =
    s.starts_with("hello", "must start with hello")("hello world")
  let assert Error("must start with hello") =
    s.starts_with("hello", "must start with hello")("world")
}

pub fn string_ends_with_test() {
  let assert Ok("hello world") =
    s.ends_with("world", "must end with world")("hello world")
  let assert Error("must end with world") =
    s.ends_with("world", "must end with world")("hello")
}

pub fn string_contains_test() {
  let assert Ok("hello world") =
    s.contains("lo wo", "must contain lo wo")("hello world")
  let assert Error("must contain lo wo") =
    s.contains("lo wo", "must contain lo wo")("goodbye")
}

pub fn string_numeric_test() {
  let assert Ok("123") = s.numeric("digits only")("123")
  let assert Error("digits only") = s.numeric("digits only")("12a")
  let assert Error("digits only") = s.numeric("digits only")("")
}

pub fn string_alpha_test() {
  let assert Ok("abc") = s.alpha("letters only")("abc")
  let assert Ok("ABC") = s.alpha("letters only")("ABC")
  let assert Error("letters only") = s.alpha("letters only")("abc1")
  let assert Error("letters only") = s.alpha("letters only")("")
}

pub fn string_alphanumeric_test() {
  let assert Ok("abc123") = s.alphanumeric("alphanumeric only")("abc123")
  let assert Error("alphanumeric only") =
    s.alphanumeric("alphanumeric only")("abc 123")
  let assert Error("alphanumeric only") =
    s.alphanumeric("alphanumeric only")("")
}

pub fn string_trimmed_test() {
  let assert Ok("hello") = s.trimmed("no whitespace")("hello")
  let assert Ok("hello world") = s.trimmed("no whitespace")("hello world")
  let assert Error("no whitespace") = s.trimmed("no whitespace")(" hello")
  let assert Error("no whitespace") = s.trimmed("no whitespace")("hello ")
  let assert Error("no whitespace") = s.trimmed("no whitespace")(" hello ")
}

// --- Int ---

pub fn int_min_test() {
  let assert Ok(5) = i.min(3, "too small")(5)
  let assert Error("too small") = i.min(3, "too small")(2)
}

pub fn int_max_test() {
  let assert Ok(3) = i.max(5, "too big")(3)
  let assert Error("too big") = i.max(5, "too big")(6)
}

pub fn int_between_test() {
  let assert Ok(5) = i.between(1, 10, "out of range")(5)
  let assert Error("out of range") = i.between(1, 10, "out of range")(0)
  let assert Error("out of range") = i.between(1, 10, "out of range")(11)
}

pub fn int_positive_test() {
  let assert Ok(1) = i.positive("must be positive")(1)
  let assert Error("must be positive") = i.positive("must be positive")(0)
  let assert Error("must be positive") = i.positive("must be positive")(-1)
}

pub fn int_non_negative_test() {
  let assert Ok(0) = i.non_negative("must be >= 0")(0)
  let assert Ok(1) = i.non_negative("must be >= 0")(1)
  let assert Error("must be >= 0") = i.non_negative("must be >= 0")(-1)
}

pub fn int_one_of_test() {
  let assert Ok(1) = i.one_of([1, 2, 3], "invalid")(1)
  let assert Error("invalid") = i.one_of([1, 2, 3], "invalid")(4)
}

pub fn int_negative_test() {
  let assert Ok(-1) = i.negative("must be negative")(-1)
  let assert Error("must be negative") = i.negative("must be negative")(0)
  let assert Error("must be negative") = i.negative("must be negative")(1)
}

pub fn int_divisible_by_test() {
  let assert Ok(9) = i.divisible_by(3, "must be divisible by 3")(9)
  let assert Ok(0) = i.divisible_by(3, "must be divisible by 3")(0)
  let assert Error("must be divisible by 3") =
    i.divisible_by(3, "must be divisible by 3")(7)
}

// --- Float ---

pub fn float_min_test() {
  let assert Ok(5.0) = f.min(3.0, "too small")(5.0)
  let assert Error("too small") = f.min(3.0, "too small")(2.0)
}

pub fn float_max_test() {
  let assert Ok(3.0) = f.max(5.0, "too big")(3.0)
  let assert Error("too big") = f.max(5.0, "too big")(6.0)
}

pub fn float_between_test() {
  let assert Ok(5.0) = f.between(1.0, 10.0, "out of range")(5.0)
  let assert Error("out of range") = f.between(1.0, 10.0, "out of range")(0.5)
}

pub fn float_positive_test() {
  let assert Ok(0.1) = f.positive("must be positive")(0.1)
  let assert Error("must be positive") = f.positive("must be positive")(0.0)
  let assert Error("must be positive") = f.positive("must be positive")(-1.0)
}

pub fn float_non_negative_test() {
  let assert Ok(0.0) = f.non_negative("must be >= 0")(0.0)
  let assert Ok(1.5) = f.non_negative("must be >= 0")(1.5)
  let assert Error("must be >= 0") = f.non_negative("must be >= 0")(-0.1)
}

// --- List ---

pub fn list_min_length_test() {
  let assert Ok([1, 2, 3]) = l.min_length(2, "too few")([1, 2, 3])
  let assert Error("too few") = l.min_length(2, "too few")([1])
}

pub fn list_max_length_test() {
  let assert Ok([1]) = l.max_length(2, "too many")([1])
  let assert Error("too many") = l.max_length(2, "too many")([1, 2, 3])
}

pub fn list_non_empty_test() {
  let assert Ok([1]) = l.non_empty("empty")([1])
  let assert Error("empty") = l.non_empty("empty")([])
}

pub fn each_valid_test() {
  let result = {
    use tags <- sift.each("tags", ["a", "b"], s.non_empty("empty"))
    sift.ok(tags)
  }
  let assert Ok(["a", "b"]) = sift.validate(result)
}

pub fn each_invalid_indexed_paths_test() {
  let result = {
    use tags <- sift.each("tags", ["a", "", "b", ""], s.non_empty("empty"))
    sift.ok(tags)
  }
  let assert Error(errors) = sift.validate(result)
  let assert 2 = length(errors)
  // Check indexed paths
  assert_has_path(errors, ["tags", "1"])
  assert_has_path(errors, ["tags", "3"])
}

// --- check_each ---

pub fn check_each_valid_test() {
  let validate_tag = fn(t: String) {
    use name <- sift.check("name", t, s.non_empty("required"))
    sift.ok(name)
  }
  let result = {
    use tags <- sift.check_each("tags", ["a", "b"], validate_tag)
    sift.ok(tags)
  }
  let assert Ok(["a", "b"]) = sift.validate(result)
}

pub fn check_each_indexed_nested_paths_test() {
  let validate_tag = fn(t: String) {
    use name <- sift.check("name", t, s.non_empty("required"))
    sift.ok(name)
  }
  let result = {
    use tags <- sift.check_each("tags", ["a", "", "b", ""], validate_tag)
    sift.ok(tags)
  }
  let assert Error(errors) = sift.validate(result)
  let assert 2 = length(errors)
  assert_has_path(errors, ["tags", "1", "name"])
  assert_has_path(errors, ["tags", "3", "name"])
}

pub fn check_each_preserves_value_on_failure_test() {
  // When an item fails, the default (original) value should flow through
  let validate_tag = fn(t: String) {
    use name <- sift.check("name", t, s.non_empty("required"))
    sift.ok(name)
  }
  let result = {
    use tags <- sift.check_each("tags", ["a", "", "c"], validate_tag)
    sift.ok(tags)
  }
  let #(value, _errors) = result
  assert value == ["a", "", "c"]
}

// --- check2 ---

pub fn check2_pass_test() {
  let result = {
    use name <- sift.check("name", "jo", s.non_empty("required"))
    use confirm <- sift.check("confirm", "jo", s.non_empty("required"))
    use name <- sift.check2("confirm", name, confirm, fn(a, b) {
      case a == b {
        True -> Ok(a)
        False -> Error("must match")
      }
    })
    sift.ok(name)
  }
  let assert Ok("jo") = sift.validate(result)
}

pub fn check2_fail_test() {
  let result = {
    use name <- sift.check("name", "jo", s.non_empty("required"))
    use confirm <- sift.check("confirm", "no", s.non_empty("required"))
    use name <- sift.check2("confirm", name, confirm, fn(a, b) {
      case a == b {
        True -> Ok(a)
        False -> Error("must match")
      }
    })
    sift.ok(name)
  }
  let assert Error([sift.FieldError(path: ["confirm"], error: "must match")]) =
    sift.validate(result)
}

// --- refine ---

pub fn refine_pass_test() {
  let result =
    sift.ok(#("admin", Some("mfa-token")))
    |> sift.refine("mfa", fn(r) {
      let #(role, mfa) = r
      case role == "admin" && mfa == None {
        True -> Error("required for admins")
        False -> Ok(r)
      }
    })
  let assert Ok(#("admin", Some("mfa-token"))) = sift.validate(result)
}

pub fn refine_fail_test() {
  let result =
    sift.ok(#("admin", None))
    |> sift.refine("mfa", fn(r) {
      let #(role, mfa) = r
      case role == "admin" && mfa == None {
        True -> Error("required for admins")
        False -> Ok(r)
      }
    })
  let assert Error([
    sift.FieldError(path: ["mfa"], error: "required for admins"),
  ]) = sift.validate(result)
}

pub fn refine_appends_after_field_errors_test() {
  // refine errors should come after field errors
  let result =
    {
      use name <- sift.check("name", "", s.non_empty("required"))
      sift.ok(name)
    }
    |> sift.refine("whole", fn(_) { Error("whole-object fail") })
  let assert Error([
    sift.FieldError(path: ["name"], error: "required"),
    sift.FieldError(path: ["whole"], error: "whole-object fail"),
  ]) = sift.validate(result)
}

fn assert_has_path(
  errors: List(sift.FieldError(String)),
  path: List(String),
) -> Nil {
  case errors {
    [] -> panic as "expected error with given path"
    [first, ..rest] ->
      case first.path == path {
        True -> Nil
        False -> assert_has_path(rest, path)
      }
  }
}

// --- Option ---

pub fn option_required_some_test() {
  let assert Ok("hello") = o.required("required")(Some("hello"))
}

pub fn option_required_none_test() {
  let assert Error("required") = o.required("required")(None)
}

pub fn option_optional_none_test() {
  let assert Ok(None) = o.optional(s.non_empty("required"))(None)
}

pub fn option_optional_some_valid_test() {
  let assert Ok(Some("hi")) = o.optional(s.non_empty("required"))(Some("hi"))
}

pub fn option_optional_some_invalid_test() {
  let assert Error("required") = o.optional(s.non_empty("required"))(Some(""))
}

// --- or / not / equals ---

pub fn or_first_passes_test() {
  let v =
    s.matches("^\\d+$", "digits") |> sift.or(s.matches("^[a-z]+$", "letters"))
  let assert Ok("123") = v("123")
}

pub fn or_second_passes_test() {
  let v =
    s.matches("^\\d+$", "digits") |> sift.or(s.matches("^[a-z]+$", "letters"))
  let assert Ok("abc") = v("abc")
}

pub fn or_both_fail_test() {
  let v =
    s.matches("^\\d+$", "digits") |> sift.or(s.matches("^[a-z]+$", "letters"))
  let assert Error("letters") = v("ABC!")
}

pub fn not_passes_test() {
  let v = sift.not(s.contains("@", ""), "must not contain @")
  let assert Ok("hello") = v("hello")
}

pub fn not_fails_test() {
  let v = sift.not(s.contains("@", ""), "must not contain @")
  let assert Error("must not contain @") = v("a@b")
}

pub fn equals_passes_test() {
  let assert Ok("yes") = sift.equals("yes", "must be yes")("yes")
}

pub fn equals_fails_test() {
  let assert Error("must be yes") = sift.equals("yes", "must be yes")("no")
}

// --- String presets ---

pub fn email_valid_test() {
  let assert Ok("alice@example.com") =
    s.email("invalid email")("alice@example.com")
}

pub fn email_invalid_test() {
  let assert Error("invalid email") = s.email("invalid email")("not-an-email")
  let assert Error("invalid email") = s.email("invalid email")("@missing.user")
  let assert Error("invalid email") = s.email("invalid email")("no-domain@")
}

pub fn url_valid_test() {
  let assert Ok("https://example.com") =
    s.url("invalid url")("https://example.com")
  let assert Ok("http://localhost:3000/path") =
    s.url("invalid url")("http://localhost:3000/path")
}

pub fn url_invalid_test() {
  let assert Error("invalid url") = s.url("invalid url")("not a url")
  let assert Error("invalid url") = s.url("invalid url")("ftp://other.com")
}

pub fn uuid_valid_test() {
  let assert Ok("550e8400-e29b-41d4-a716-446655440000") =
    s.uuid("invalid uuid")("550e8400-e29b-41d4-a716-446655440000")
}

pub fn uuid_invalid_test() {
  let assert Error("invalid uuid") = s.uuid("invalid uuid")("not-a-uuid")
  let assert Error("invalid uuid") =
    s.uuid("invalid uuid")("550e8400-e29b-51d4-a716-446655440000")
}

// --- Integration: full validation scenario ---

pub type UserInput {
  UserInput(name: String, age: Int, email: Option(String))
}

pub type User {
  User(name: String, age: Int, email: Option(String))
}

pub fn full_valid_user_test() {
  let input = UserInput("Alice", 30, Some("alice@test.com"))
  let result = {
    use name <- sift.check(
      "name",
      input.name,
      s.min_length(1, "required") |> sift.and(s.max_length(50, "too long")),
    )
    use age <- sift.check("age", input.age, i.min(0, "must be non-negative"))
    use email <- sift.check(
      "email",
      input.email,
      o.optional(s.non_empty("empty email")),
    )
    sift.ok(User(name:, age:, email:))
  }
  let assert Ok(User("Alice", 30, Some("alice@test.com"))) =
    sift.validate(result)
}

pub fn full_invalid_user_test() {
  let input = UserInput("", -1, Some(""))
  let result = {
    use name <- sift.check(
      "name",
      input.name,
      s.min_length(1, "required") |> sift.and(s.max_length(50, "too long")),
    )
    use age <- sift.check("age", input.age, i.min(0, "must be non-negative"))
    use email <- sift.check(
      "email",
      input.email,
      o.optional(s.non_empty("empty email")),
    )
    sift.ok(User(name:, age:, email:))
  }
  let assert Error(errors) = sift.validate(result)
  let assert 3 = length(errors)
}

fn length(items: List(a)) -> Int {
  case items {
    [] -> 0
    [_, ..rest] -> 1 + length(rest)
  }
}
