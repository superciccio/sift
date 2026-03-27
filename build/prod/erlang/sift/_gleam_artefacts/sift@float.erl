-module(sift@float).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/sift/float.gleam").
-export([min/2, max/2, between/3, positive/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" Float validators — range and positivity checks.\n").

-file("src/sift/float.gleam", 7).
?DOC(" Value must be >= n\n").
-spec min(float(), binary()) -> fun((float()) -> {ok, float()} |
    {error, binary()}).
min(N, Msg) ->
    fun(Value) -> case gleam@float:compare(Value, N) of
            lt ->
                {error, Msg};

            _ ->
                {ok, Value}
        end end.

-file("src/sift/float.gleam", 17).
?DOC(" Value must be <= n\n").
-spec max(float(), binary()) -> fun((float()) -> {ok, float()} |
    {error, binary()}).
max(N, Msg) ->
    fun(Value) -> case gleam@float:compare(Value, N) of
            gt ->
                {error, Msg};

            _ ->
                {ok, Value}
        end end.

-file("src/sift/float.gleam", 27).
?DOC(" Value must be between lo and hi (inclusive)\n").
-spec between(float(), float(), binary()) -> fun((float()) -> {ok, float()} |
    {error, binary()}).
between(Lo, Hi, Msg) ->
    fun(Value) ->
        case {gleam@float:compare(Value, Lo), gleam@float:compare(Value, Hi)} of
            {lt, _} ->
                {error, Msg};

            {_, gt} ->
                {error, Msg};

            {_, _} ->
                {ok, Value}
        end
    end.

-file("src/sift/float.gleam", 42).
?DOC(" Value must be > 0.0\n").
-spec positive(binary()) -> fun((float()) -> {ok, float()} | {error, binary()}).
positive(Msg) ->
    fun(Value) -> case gleam@float:compare(Value, +0.0) of
            gt ->
                {ok, Value};

            _ ->
                {error, Msg}
        end end.
