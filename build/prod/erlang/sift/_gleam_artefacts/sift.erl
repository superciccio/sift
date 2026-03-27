-module(sift).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/sift.gleam").
-export([check/4, nested/4, ok/1, validate/1, 'and'/2, each/4, 'or'/2, 'not'/2, equals/2, custom/1]).
-export_type([field_error/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(" Core validation functions — check fields, accumulate errors, compose validators.\n").

-type field_error() :: {field_error, list(binary()), binary()}.

-file("src/sift.gleam", 21).
?DOC(" Run a validator on a field value, accumulate errors, feeds into `use`\n").
-spec check(
    binary(),
    DMA,
    fun((DMA) -> {ok, DMA} | {error, binary()}),
    fun((DMA) -> {DMC, list(field_error())})
) -> {DMC, list(field_error())}.
check(Field, Value, Validator, Next) ->
    case Validator(Value) of
        {ok, V} ->
            Next(V);

        {error, Msg} ->
            {Result, Errors} = Next(Value),
            {Result, [{field_error, [Field], Msg} | Errors]}
    end.

-file("src/sift.gleam", 37).
?DOC(" Run a sub-validator function, prefixing error paths with the field name\n").
-spec nested(
    binary(),
    DMF,
    fun((DMF) -> {DMG, list(field_error())}),
    fun((DMG) -> {DMI, list(field_error())})
) -> {DMI, list(field_error())}.
nested(Field, Value, Validator_fn, Next) ->
    {Inner_value, Inner_errors} = Validator_fn(Value),
    Prefixed_errors = gleam@list:map(
        Inner_errors,
        fun(E) ->
            {field_error, [Field | erlang:element(2, E)], erlang:element(3, E)}
        end
    ),
    {Result, Outer_errors} = Next(Inner_value),
    {Result, lists:append(Prefixed_errors, Outer_errors)}.

-file("src/sift.gleam", 53).
?DOC(" Wrap a final value into a Validated tuple with no errors\n").
-spec ok(DML) -> {DML, list(field_error())}.
ok(Value) ->
    {Value, []}.

-file("src/sift.gleam", 58).
?DOC(" Convert a Validated(a) to Result(a, List(FieldError))\n").
-spec validate({DMN, list(field_error())}) -> {ok, DMN} |
    {error, list(field_error())}.
validate(Validated) ->
    case Validated of
        {Value, []} ->
            {ok, Value};

        {_, Errors} ->
            {error, Errors}
    end.

-file("src/sift.gleam", 66).
?DOC(" Compose two validators — run both, accumulate errors from both\n").
-spec 'and'(
    fun((DMS) -> {ok, DMS} | {error, binary()}),
    fun((DMS) -> {ok, DMS} | {error, binary()})
) -> fun((DMS) -> {ok, DMS} | {error, binary()}).
'and'(V1, V2) ->
    fun(Value) -> case {V1(Value), V2(Value)} of
            {{ok, A}, {ok, _}} ->
                {ok, A};

            {{ok, _}, {error, Msg}} ->
                {error, Msg};

            {{error, Msg@1}, {ok, _}} ->
                {error, Msg@1};

            {{error, Msg@2}, _} ->
                {error, Msg@2}
        end end.

-file("src/sift.gleam", 84).
?DOC(
    " Validate every item in a list, accumulating indexed error paths.\n"
    " Works like `nested` — takes a field name and feeds into `use`.\n"
    " Produces paths like [\"tags\", \"0\"], [\"tags\", \"1\"], etc.\n"
).
-spec each(
    binary(),
    list(DMW),
    fun((DMW) -> {ok, DMW} | {error, binary()}),
    fun((list(DMW)) -> {DNA, list(field_error())})
) -> {DNA, list(field_error())}.
each(Field, Items, Validator, Next) ->
    Item_errors = begin
        _pipe = Items,
        _pipe@1 = gleam@list:index_map(
            _pipe,
            fun(Item, Idx) -> case Validator(Item) of
                    {ok, _} ->
                        [];

                    {error, Msg} ->
                        [{field_error,
                                [Field, erlang:integer_to_binary(Idx)],
                                Msg}]
                end end
        ),
        lists:append(_pipe@1)
    end,
    {Result, Outer_errors} = Next(Items),
    {Result, lists:append(Item_errors, Outer_errors)}.

-file("src/sift.gleam", 109).
?DOC(" Pass if either validator succeeds (try v1 first, then v2)\n").
-spec 'or'(
    fun((DND) -> {ok, DND} | {error, binary()}),
    fun((DND) -> {ok, DND} | {error, binary()})
) -> fun((DND) -> {ok, DND} | {error, binary()}).
'or'(V1, V2) ->
    fun(Value) -> case V1(Value) of
            {ok, V} ->
                {ok, V};

            {error, _} ->
                V2(Value)
        end end.

-file("src/sift.gleam", 122).
?DOC(" Invert a validator — fail if it passes, pass if it fails\n").
-spec 'not'(fun((DNH) -> {ok, DNH} | {error, binary()}), binary()) -> fun((DNH) -> {ok,
        DNH} |
    {error, binary()}).
'not'(Validator, Msg) ->
    fun(Value) -> case Validator(Value) of
            {ok, _} ->
                {error, Msg};

            {error, _} ->
                {ok, Value}
        end end.

-file("src/sift.gleam", 135).
?DOC(" Value must equal the expected value\n").
-spec equals(DNK, binary()) -> fun((DNK) -> {ok, DNK} | {error, binary()}).
equals(Expected, Msg) ->
    fun(Value) -> case Value =:= Expected of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift.gleam", 145).
?DOC(" Escape hatch for user-defined checks\n").
-spec custom(fun((DNM) -> {ok, DNM} | {error, binary()})) -> fun((DNM) -> {ok,
        DNM} |
    {error, binary()}).
custom(F) ->
    F.
