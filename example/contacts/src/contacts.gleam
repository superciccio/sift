import gleam/option.{type Option}
import sift
import sift/int as i
import sift/list as l
import sift/string as s

// --- Input types (raw, unvalidated) ---

pub type AddressInput {
  AddressInput(street: String, city: String, zip: String, state: String, country: String)
}

pub type ContactInput {
  ContactInput(
    name: String,
    email: String,
    age: Int,
    phone: Option(String),
    website: Option(String),
    tags: List(String),
    address: AddressInput,
  )
}

// --- Validated types ---

pub type Address {
  Address(street: String, city: String, zip: String, state: String, country: String)
}

pub type Contact {
  Contact(
    name: String,
    email: String,
    age: Int,
    phone: Option(String),
    website: Option(String),
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
  use zip <- sift.check_all("zip", input.zip, [
    s.non_empty("required"),
    s.numeric("must be digits"),
    s.length(5, "must be 5 digits"),
  ])
  use state <- sift.check(
    "state",
    input.state,
    sift.when(input.country == "US", s.non_empty("required for US")),
  )
  use country <- sift.check("country", input.country, s.non_empty("required"))
  sift.ok(Address(street:, city:, zip:, state:, country:))
}

pub fn validate_contact(
  input: ContactInput,
) -> sift.Validated(Contact) {
  use name <- sift.check_all("name", input.name, [
    s.non_empty("required"),
    s.trimmed("must not have leading/trailing spaces"),
    s.max_length(100, "too long"),
  ])
  use email <- sift.check_all("email", input.email, [
    s.non_empty("required"),
    s.email("invalid email"),
  ])
  use age <- sift.check(
    "age",
    input.age,
    i.between(0, 150, "must be between 0 and 150"),
  )
  use phone <- sift.check_optional("phone", input.phone, s.min_length(7, "too short"))
  use website <- sift.check_optional("website", input.website, s.url("invalid url"))
  use tags <- sift.check(
    "tags",
    input.tags,
    l.max_length(10, "too many tags"),
  )
  use tags <- sift.each("tags", tags, s.non_empty("empty tag"))
  use address <- sift.nested("address", input.address, validate_address)
  sift.ok(Contact(name:, email:, age:, phone:, website:, tags:, address:))
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
