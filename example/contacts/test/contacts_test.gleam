import contacts.{Address, AddressInput, Contact, ContactInput}
import gleam/option.{None, Some}
import gleeunit
import sift

pub fn main() -> Nil {
  gleeunit.main()
}

fn valid_address() {
  AddressInput(street: "123 Main St", city: "Springfield", zip: "62704", state: "IL", country: "US")
}

fn valid_input() {
  ContactInput(
    name: "Alice Smith",
    email: "alice@example.com",
    age: 30,
    phone: Some("555-1234"),
    website: None,
    tags: ["friend", "work"],
    address: valid_address(),
  )
}

// --- Happy path ---

pub fn create_valid_contact_test() {
  let assert Ok(Contact(
    name: "Alice Smith",
    email: "alice@example.com",
    age: 30,
    phone: Some("555-1234"),
    website: None,
    tags: ["friend", "work"],
    address: Address(street: "123 Main St", city: "Springfield", zip: "62704", state: "IL", country: "US"),
  )) = contacts.create(valid_input())
}

pub fn create_with_no_phone_test() {
  let input = ContactInput(..valid_input(), phone: None)
  let assert Ok(Contact(phone: None, ..)) = contacts.create(input)
}

pub fn create_with_no_tags_test() {
  let input = ContactInput(..valid_input(), tags: [])
  let assert Ok(Contact(tags: [], ..)) = contacts.create(input)
}

// --- Single field errors ---

pub fn empty_name_test() {
  let input = ContactInput(..valid_input(), name: "")
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["name"], "required")
}

pub fn name_too_long_test() {
  let long = string_of_length(101)
  let input = ContactInput(..valid_input(), name: long)
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["name"], "too long")
}

// check_all: name with leading space gets trimmed error
pub fn name_untrimmed_test() {
  let input = ContactInput(..valid_input(), name: " Alice")
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["name"], "must not have leading/trailing spaces")
}

// check_all: empty name hits both required AND trimmed won't fire (empty is trimmed)
// but it does hit required
pub fn name_check_all_accumulates_test() {
  let long = " " <> string_of_length(101)
  let input = ContactInput(..valid_input(), name: long)
  let assert Error(errors) = contacts.create(input)
  // Both trimmed and too long should fire
  assert_has_error(errors, ["name"], "must not have leading/trailing spaces")
  assert_has_error(errors, ["name"], "too long")
}

pub fn empty_email_test() {
  let input = ContactInput(..valid_input(), email: "")
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["email"], "required")
}

pub fn email_invalid_test() {
  let input = ContactInput(..valid_input(), email: "alice.example.com")
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["email"], "invalid email")
}

pub fn age_negative_test() {
  let input = ContactInput(..valid_input(), age: -1)
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["age"], "must be between 0 and 150")
}

pub fn age_too_high_test() {
  let input = ContactInput(..valid_input(), age: 200)
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["age"], "must be between 0 and 150")
}

pub fn phone_too_short_test() {
  let input = ContactInput(..valid_input(), phone: Some("123"))
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["phone"], "too short")
}

pub fn too_many_tags_test() {
  let input =
    ContactInput(
      ..valid_input(),
      tags: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"],
    )
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["tags"], "too many tags")
}

pub fn empty_tag_test() {
  let input = ContactInput(..valid_input(), tags: ["ok", ""])
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["tags", "1"], "empty tag")
}

// --- check_optional (phone & website) ---

pub fn phone_none_skips_validation_test() {
  let input = ContactInput(..valid_input(), phone: None)
  let assert Ok(Contact(phone: None, ..)) = contacts.create(input)
}

pub fn website_valid_test() {
  let input = ContactInput(..valid_input(), website: Some("https://example.com"))
  let assert Ok(Contact(website: Some("https://example.com"), ..)) = contacts.create(input)
}

pub fn website_none_skips_test() {
  let input = ContactInput(..valid_input(), website: None)
  let assert Ok(Contact(website: None, ..)) = contacts.create(input)
}

pub fn website_invalid_test() {
  let input = ContactInput(..valid_input(), website: Some("not-a-url"))
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["website"], "invalid url")
}

// --- Conditional validation (when) ---

pub fn us_address_requires_state_test() {
  let input =
    ContactInput(
      ..valid_input(),
      address: AddressInput(..valid_address(), country: "US", state: ""),
    )
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["address", "state"], "required for US")
}

pub fn non_us_address_skips_state_test() {
  let input =
    ContactInput(
      ..valid_input(),
      address: AddressInput(..valid_address(), country: "IT", state: ""),
    )
  let assert Ok(Contact(address: Address(state: "", country: "IT", ..), ..)) =
    contacts.create(input)
}

// --- Nested address errors ---

pub fn address_empty_street_test() {
  let input =
    ContactInput(
      ..valid_input(),
      address: AddressInput(..valid_address(), street: ""),
    )
  let assert Error(errors) = contacts.create(input)
  assert_has_error(errors, ["address", "street"], "required")
}

pub fn address_bad_zip_test() {
  let input =
    ContactInput(
      ..valid_input(),
      address: AddressInput(..valid_address(), zip: "abc"),
    )
  let assert Error(errors) = contacts.create(input)
  // check_all catches both: not numeric AND not 5 digits
  assert_has_error(errors, ["address", "zip"], "must be digits")
  assert_has_error(errors, ["address", "zip"], "must be 5 digits")
}

pub fn address_empty_zip_check_all_test() {
  let input =
    ContactInput(
      ..valid_input(),
      address: AddressInput(..valid_address(), zip: ""),
    )
  let assert Error(errors) = contacts.create(input)
  // All three zip validators fire
  assert_has_error(errors, ["address", "zip"], "required")
  assert_has_error(errors, ["address", "zip"], "must be digits")
  assert_has_error(errors, ["address", "zip"], "must be 5 digits")
}

// --- Error accumulation ---

pub fn multiple_errors_accumulate_test() {
  let input =
    ContactInput(
      name: "",
      email: "bad",
      age: -1,
      phone: Some("x"),
      website: Some("nope"),
      tags: [""],
      address: AddressInput(street: "", city: "", zip: "bad", state: "", country: "US"),
    )
  let assert Error(errors) = contacts.create(input)
  // name, email(invalid), age, phone, website, tags[0], address.street, address.city,
  // address.zip(x2), address.state, address.country — lots of errors
  assert list_length(errors) >= 10
}

pub fn update_also_validates_test() {
  let input = ContactInput(..valid_input(), name: "")
  let assert Error(errors) = contacts.update(input)
  assert_has_error(errors, ["name"], "required")
}

// --- Helpers ---

fn assert_has_error(
  errors: List(sift.FieldError),
  path: List(String),
  message: String,
) -> Nil {
  let found =
    list_any(errors, fn(e) { e.path == path && e.message == message })
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

fn string_of_length(n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> "a" <> string_of_length(n - 1)
  }
}
