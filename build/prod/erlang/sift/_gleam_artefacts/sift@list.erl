-module(sift@list).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/sift/list.gleam").
-export([min_length/2, max_length/2, non_empty/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" List validators — length constraints.\n").

-file("src/sift/list.gleam", 6).
?DOC(" List must have at least n items\n").
-spec min_length(integer(), binary()) -> fun((list(DUF)) -> {ok, list(DUF)} |
    {error, binary()}).
min_length(N, Msg) ->
    fun(Value) -> case erlang:length(Value) >= N of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/list.gleam", 16).
?DOC(" List must have at most n items\n").
-spec max_length(integer(), binary()) -> fun((list(DUK)) -> {ok, list(DUK)} |
    {error, binary()}).
max_length(N, Msg) ->
    fun(Value) -> case erlang:length(Value) =< N of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift/list.gleam", 26).
?DOC(" List must not be empty\n").
-spec non_empty(binary()) -> fun((list(DUP)) -> {ok, list(DUP)} |
    {error, binary()}).
non_empty(Msg) ->
    min_length(1, Msg).
