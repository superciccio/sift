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

-file("src/sift/option.gleam", 6).
?DOC(" None produces an error, Some(a) unwraps the value\n").
-spec required(binary()) -> fun((gleam@option:option(DVK)) -> {ok, DVK} |
    {error, binary()}).
required(Msg) ->
    fun(Value) -> case Value of
            {some, V} ->
                {ok, V};

            none ->
                {error, Msg}
        end end.

-file("src/sift/option.gleam", 17).
?DOC(
    " None passes through as the default, Some(a) runs the validator\n"
    " Returns Option(a) — None stays None, Some(a) validates a\n"
).
-spec optional(fun((DVO) -> {ok, DVO} | {error, binary()})) -> fun((gleam@option:option(DVO)) -> {ok,
        gleam@option:option(DVO)} |
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
