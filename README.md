# sift

[![Package Version](https://img.shields.io/hexpm/v/sift)](https://hex.pm/packages/sift)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sift/)

Schema validation for Gleam — constraints, error accumulation, and field paths.

All errors are collected in a single pass using the `use` pattern. No short-circuiting, no missing fields.

```sh
gleam add sift@1
```

## Quick example

```gleam
import sift
import sift/string as s
import sift/int as i

pub type UserInput {
  UserInput(name: String, email: String, age: Int)
}

pub type User {
  User(name: String, email: String, age: Int)
}

pub fn validate(input: UserInput) -> Result(User, List(sift.FieldError)) {
  use name <- sift.check("name", input.name, s.min_length(1, "required"))
  use email <- sift.check("email", input.email, s.email("invalid email"))
  use age <- sift.check("age", input.age, i.between(0, 150, "out of range"))
  sift.ok(User(name:, email:, age:))
  |> sift.validate
}
```

Invalid input returns **all** errors at once:

```gleam
validate(UserInput(name: "", email: "nope", age: -1))
// -> Error([
//   FieldError(path: ["name"], message: "required"),
//   FieldError(path: ["email"], message: "invalid email"),
//   FieldError(path: ["age"], message: "out of range"),
// ])
```

## Features

- **Error accumulation** — every field is checked, every error is returned
- **Field paths** — nested structs and lists produce paths like `["address", "zip"]` or `["tags", "0"]`
- **Multi-validator** — `sift.check_all` runs multiple validators on one field, collects all errors
- **Composable** — `sift.and`, `sift.or`, `sift.not` to combine validators
- **Conditional** — `sift.when` runs a validator only when a condition is true
- **Nested structs** — `sift.nested` with automatic path prefixing
- **List validation** — `sift.each` with indexed paths
- **Optional fields** — `sift.check_optional`, `sift/option.required`, `sift/option.optional`
- **Form parsing** — `sift.check_parse` bridges raw strings to typed values
- **Built-in validators** — strings, ints, floats, lists, options

## Modules

| Module | Validators |
|--------|-----------|
| `sift` | `check`, `check_all`, `check_optional`, `check_parse`, `nested`, `each`, `ok`, `validate`, `and`, `or`, `not`, `when`, `equals`, `custom` |
| `sift/string` | `min_length`, `max_length`, `length`, `non_empty`, `matches`, `one_of`, `starts_with`, `ends_with`, `contains`, `email`, `url`, `uuid`, `numeric`, `alpha`, `alphanumeric`, `trimmed` |
| `sift/int` | `min`, `max`, `between`, `positive`, `non_negative`, `negative`, `one_of`, `divisible_by` |
| `sift/float` | `min`, `max`, `between`, `positive`, `non_negative` |
| `sift/list` | `min_length`, `max_length`, `non_empty` |
| `sift/option` | `required`, `optional` |

Further documentation can be found at <https://hexdocs.pm/sift>.
