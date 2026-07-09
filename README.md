# sift

[![Package Version](https://img.shields.io/hexpm/v/sift)](https://hex.pm/packages/sift)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sift/)

Schema validation for Gleam — constraints, error accumulation, and field paths.

All errors are collected in a single pass using the `use` pattern. No short-circuiting, no missing fields.

```sh
gleam add sift
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

pub fn validate(input: UserInput) -> Result(User, List(sift.FieldError(String))) {
  sift.validate({
    use name <- sift.check("name", input.name, s.min_length(1, "required"))
    use email <- sift.check("email", input.email, s.email("invalid email"))
    use age <- sift.check("age", input.age, i.between(0, 150, "out of range"))
    sift.ok(User(name:, email:, age:))
  })
}
```

Invalid input returns **all** errors at once:

```gleam
validate(UserInput(name: "", email: "nope", age: -1))
// -> Error([
//   FieldError(path: ["name"], error: "required"),
//   FieldError(path: ["email"], error: "invalid email"),
//   FieldError(path: ["age"], error: "out of range"),
// ])
```

## Upgrading from 0.1.x

Errors used to always be text. Now you choose what an error is — text, an error
code, an i18n key, whatever your app needs.

If you want to keep using text, there are two edits.

**1. Say `String` in your return type.**

```gleam
// before
pub fn validate(input: UserInput) -> Result(User, List(sift.FieldError))

// after
pub fn validate(input: UserInput) -> Result(User, List(sift.FieldError(String)))
```

**2. Read `.error` instead of `.message`.**

```gleam
// before
errors |> list.map(fn(e) { e.message })

// after
errors |> list.map(fn(e) { e.error })
```

That is the whole migration. Everything else — your `use` chains, `check`,
`check_all`, `nested`, `ok`, `validate` — stays exactly as it was.

### What you get

Errors can now be your own type, and it flows through every validator and every
field path:

```gleam
pub type Problem {
  Required
  TooShort(min: Int)
  NotAnEmail
}

pub fn validate(input: UserInput) -> Result(User, List(sift.FieldError(Problem))) {
  sift.validate({
    use name <- sift.check("name", input.name, s.non_empty(Required))
    use email <- sift.check("email", input.email, s.email(NotAnEmail))
    use age <- sift.check("age", input.age, i.min(13, TooShort(13)))
    sift.ok(User(name:, email:, age:))
  })
}

validate(UserInput(name: "", email: "nope", age: 9))
// -> Error([
//   FieldError(path: ["name"], error: Required),
//   FieldError(path: ["email"], error: NotAnEmail),
//   FieldError(path: ["age"], error: TooShort(13)),
// ])
```

The built-in validators work with any error type — `s.non_empty(Required)` is the
same function as `s.non_empty("required")`.

## Realistic example

For a full walkthrough — nested structs, optional fields, conditional
validation with `when`, multiple validators per field with `check_all`,
and per-item list validation with `each` — see
[`example/contacts/`](example/contacts/src/contacts.gleam).

## Features

- **Error accumulation** — every field is checked, every error is returned
- **Your own error type** — messages, error codes, or i18n keys; the built-in validators work with all of them
- **Field paths** — nested structs and lists produce paths like `["address", "zip"]` or `["tags", "0"]`
- **Multi-validator** — `sift.check_all` runs multiple validators on one field, collects all errors
- **Composable** — `sift.and`, `sift.or`, `sift.not` to combine validators
- **Conditional** — `sift.when` runs a validator only when a condition is true
- **Nested structs** — `sift.nested` with automatic path prefixing
- **List validation** — `sift.each` and `sift.check_each` with indexed paths
- **Cross-field** — `sift.check2` in-chain, `sift.refine` post-assembly
- **Optional fields** — `sift.check_optional`, `sift/option.required`, `sift/option.optional`
- **Form parsing** — `sift.check_parse` bridges raw strings to typed values
- **Built-in validators** — strings, ints, floats, lists, options

## Modules

| Module | Validators |
|--------|-----------|
| `sift` | `check`, `check_all`, `check_optional`, `check_parse`, `check_each`, `check2`, `nested`, `each`, `refine`, `ok`, `validate`, `and`, `or`, `not`, `when`, `equals`, `custom` |
| `sift/string` | `min_length`, `max_length`, `length`, `non_empty`, `matches`, `one_of`, `starts_with`, `ends_with`, `contains`, `email`, `url`, `uuid`, `numeric`, `alpha`, `alphanumeric`, `trimmed` |
| `sift/int` | `min`, `max`, `between`, `positive`, `non_negative`, `negative`, `one_of`, `divisible_by` |
| `sift/float` | `min`, `max`, `between`, `positive`, `non_negative` |
| `sift/list` | `min_length`, `max_length`, `non_empty` |
| `sift/option` | `required`, `optional` |

Further documentation can be found at <https://hexdocs.pm/sift>.
