-module(sift@int).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/sift/int.gleam").
-export([min/2, max/2, between/3, positive/1, non_negative/1, one_of/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" Integer validators — range, positivity, and membership checks.\n").

-file("src/sift/int.gleam", 4).
?DOC(" Value must be >= n\n").
-spec min(integer(), binary()) -> fun((integer()) -> {ok, integer()} |
    {error, binary()}).
min(N, Msg) ->
    fun(Value) -> case Value >= N of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/int.gleam", 14).
?DOC(" Value must be <= n\n").
-spec max(integer(), binary()) -> fun((integer()) -> {ok, integer()} |
    {error, binary()}).
max(N, Msg) ->
    fun(Value) -> case Value =< N of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/int.gleam", 24).
?DOC(" Value must be between lo and hi (inclusive)\n").
-spec between(integer(), integer(), binary()) -> fun((integer()) -> {ok,
        integer()} |
    {error, binary()}).
between(Lo, Hi, Msg) ->
    fun(Value) -> case (Value >= Lo) andalso (Value =< Hi) of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/int.gleam", 34).
?DOC(" Value must be > 0\n").
-spec positive(binary()) -> fun((integer()) -> {ok, integer()} |
    {error, binary()}).
positive(Msg) ->
    fun(Value) -> case Value > 0 of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/int.gleam", 44).
?DOC(" Value must be >= 0\n").
-spec non_negative(binary()) -> fun((integer()) -> {ok, integer()} |
    {error, binary()}).
non_negative(Msg) ->
    fun(Value) -> case Value >= 0 of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/int.gleam", 63).
-spec list_contains(list(integer()), integer()) -> boolean().
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

-file("src/sift/int.gleam", 54).
?DOC(" Value must be one of the given values\n").
-spec one_of(list(integer()), binary()) -> fun((integer()) -> {ok, integer()} |
    {error, binary()}).
one_of(Values, Msg) ->
    fun(Value) -> case list_contains(Values, Value) of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.
