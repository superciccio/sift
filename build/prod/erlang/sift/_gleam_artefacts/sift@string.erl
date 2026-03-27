-module(sift@string).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/sift/string.gleam").
-export([min_length/2, max_length/2, length/2, non_empty/1, matches/2, starts_with/2, ends_with/2, contains/2, email/1, url/1, uuid/1, one_of/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" String validators — length, pattern matching, format checks (email, url, uuid).\n").

-file("src/sift/string.gleam", 7).
?DOC(" String must have at least n graphemes\n").
-spec min_length(integer(), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
min_length(N, Msg) ->
    fun(Value) -> case string:length(Value) >= N of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/string.gleam", 17).
?DOC(" String must have at most n graphemes\n").
-spec max_length(integer(), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
max_length(N, Msg) ->
    fun(Value) -> case string:length(Value) =< N of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/string.gleam", 27).
?DOC(" String must have exactly n graphemes\n").
-spec length(integer(), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
length(N, Msg) ->
    fun(Value) -> case string:length(Value) =:= N of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/string.gleam", 37).
?DOC(" String must not be empty (shorthand for min_length(1))\n").
-spec non_empty(binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
non_empty(Msg) ->
    min_length(1, Msg).

-file("src/sift/string.gleam", 42).
?DOC(" String must match the given regex pattern\n").
-spec matches(binary(), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
matches(Pattern, Msg) ->
    fun(Value) -> case gleam@regexp:from_string(Pattern) of
            {ok, Re} ->
                case gleam@regexp:check(Re, Value) of
                    true ->
                        {ok, Value};

                    false ->
                        {error, Msg}
                end;

            {error, _} ->
                {error, Msg}
        end end.

-file("src/sift/string.gleam", 72).
?DOC(" String must start with the given prefix\n").
-spec starts_with(binary(), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
starts_with(Prefix, Msg) ->
    fun(Value) -> case gleam_stdlib:string_starts_with(Value, Prefix) of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/string.gleam", 85).
?DOC(" String must end with the given suffix\n").
-spec ends_with(binary(), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
ends_with(Suffix, Msg) ->
    fun(Value) -> case gleam_stdlib:string_ends_with(Value, Suffix) of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/string.gleam", 98).
?DOC(" String must contain the given substring\n").
-spec contains(binary(), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
contains(Substring, Msg) ->
    fun(Value) -> case gleam_stdlib:contains_string(Value, Substring) of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/string.gleam", 111).
?DOC(" Must look like an email (contains exactly one @, something before and after)\n").
-spec email(binary()) -> fun((binary()) -> {ok, binary()} | {error, binary()}).
email(Msg) ->
    matches(<<"^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"/utf8>>, Msg).

-file("src/sift/string.gleam", 116).
?DOC(" Must look like a URL (http:// or https://)\n").
-spec url(binary()) -> fun((binary()) -> {ok, binary()} | {error, binary()}).
url(Msg) ->
    matches(<<"^https?://[^\\s]+$"/utf8>>, Msg).

-file("src/sift/string.gleam", 121).
?DOC(" Must be a valid UUID v4 format\n").
-spec uuid(binary()) -> fun((binary()) -> {ok, binary()} | {error, binary()}).
uuid(Msg) ->
    matches(
        <<"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"/utf8>>,
        Msg
    ).

-file("src/sift/string.gleam", 128).
-spec list_contains(list(binary()), binary()) -> boolean().
list_contains(Items, Target) ->
    case Items of
        [] ->
            false;

        [First | Rest] ->
            case First =:= Target of
                true ->
                    true;

                false ->
                    list_contains(Rest, Target)
            end
    end.

-file("src/sift/string.gleam", 59).
?DOC(" String must be one of the given values\n").
-spec one_of(list(binary()), binary()) -> fun((binary()) -> {ok, binary()} |
    {error, binary()}).
one_of(Values, Msg) ->
    fun(Value) -> case list_contains(Values, Value) of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.
