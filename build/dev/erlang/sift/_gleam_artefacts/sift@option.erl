-module(sift@option).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/sift/option.gleam").
-export([required/1, optional/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" Option validators — required/optional field handling.\n").

-file("src/sift/option.gleam", 12).
?DOC(
    " None produces an error, Some(a) unwraps the value.\n"
    "\n"
    " ```gleam\n"
    " let validator = option.required(\"field is required\")\n"
    " validator(Some(\"hello\"))  // -> Ok(\"hello\")\n"
    " validator(None)           // -> Error(\"field is required\")\n"
    " ```\n"
).
-spec required(binary()) -> fun((gleam@option:option(AAF)) -> {ok, AAF} |
    {error, binary()}).
required(Msg) ->
    fun(Value) -> case Value of
            {some, V} ->
                {ok, V};

            none ->
                {error, Msg}
        end end.

-file("src/sift/option.gleam", 30).
?DOC(
    " None passes through as the default, Some(a) runs the validator.\n"
    " Returns Option(a) — None stays None, Some(a) validates a.\n"
    "\n"
    " ```gleam\n"
    " let validator = option.optional(string.min_length(3, \"too short\"))\n"
    " validator(None)           // -> Ok(None)\n"
    " validator(Some(\"hello\"))  // -> Ok(Some(\"hello\"))\n"
    " validator(Some(\"hi\"))     // -> Error(\"too short\")\n"
    " ```\n"
).
-spec optional(fun((AAJ) -> {ok, AAJ} | {error, binary()})) -> fun((gleam@option:option(AAJ)) -> {ok,
        gleam@option:option(AAJ)} |
    {error, binary()}).
optional(Validator) ->
    fun(Value) -> case Value of
            none ->
                {ok, none};

            {some, V} ->
                case Validator(V) of
                    {ok, Validated} ->
                        {ok, {some, Validated}};

                    {error, Msg} ->
                        {error, Msg}
                end
        end end.
