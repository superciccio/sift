import gleam/option.{type Option}
import sift
import sift/int as i
import sift/list as l
import sift/option as o
import sift/string as s

// --- Input types (raw, unvalidated) ---

pub type AddressInput {
  AddressInput(street: String, city: String, zip: String)
}

pub type ContactInput {
  ContactInput(
    name: String,
    email: String,
    age: Int,
    phone: Option(String),
    tags: List(String),
    address: AddressInput,
  )
}

// --- Validated types ---

pub type Address {
  Address(street: String, city: String, zip: String)
}

pub type Contact {
  Contact(
    name: String,
    email: String,
    age: Int,
    phone: Option(String),
    tags: List(String),
    address: Address,
  )
}

// --- Validation ---

pub fn validate_address(
  input: AddressInput,
) -> sift.Validated(Address) {
  use street <- sift.check("street", input.street, s.non_empty("required"))
  use city <- sift.check("city", input.city, s.non_empty("required"))
  use zip <- sift.check(
    "zip",
    input.zip,
    s.non_empty("required")
      |> sift.and(s.matches("^\\d{5}$", "must be 5 digits")),
  )
  sift.ok(Address(street:, city:, zip:))
}

pub fn validate_contact(
  input: ContactInput,
) -> sift.Validated(Contact) {
  use name <- sift.check(
    "name",
    input.name,
    s.min_length(1, "required")
      |> sift.and(s.max_length(100, "too long")),
  )
  use email <- sift.check(
    "email",
    input.email,
    s.non_empty("required")
      |> sift.and(s.contains("@", "must contain @")),
  )
  use age <- sift.check(
    "age",
    input.age,
    i.between(0, 150, "must be between 0 and 150"),
  )
  use phone <- sift.check(
    "phone",
    input.phone,
    o.optional(s.min_length(7, "too short")),
  )
  use tags <- sift.check(
    "tags",
    input.tags,
    l.max_length(10, "too many tags"),
  )
  use tags <- sift.each("tags", tags, s.non_empty("empty tag"))
  use address <- sift.nested("address", input.address, validate_address)
  sift.ok(Contact(name:, email:, age:, phone:, tags:, address:))
}

// --- CRUD boundary ---

pub fn create(
  input: ContactInput,
) -> Result(Contact, List(sift.FieldError)) {
  sift.validate(validate_contact(input))
}

pub fn update(
  input: ContactInput,
) -> Result(Contact, List(sift.FieldError)) {
  sift.validate(validate_contact(input))
}
