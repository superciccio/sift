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

-file("src/sift.gleam", 32).
?DOC(
    " Run a validator on a field value, accumulate errors, feeds into `use`.\n"
    "\n"
    " ```gleam\n"
    " use name <- sift.check(\"name\", input.name, s.min_length(1, \"required\"))\n"
    " use email <- sift.check(\"email\", input.email, s.email(\"invalid\"))\n"
    " sift.ok(User(name:, email:))\n"
    " ```\n"
).
-spec check(
    binary(),
    SJ,
    fun((SJ) -> {ok, SJ} | {error, binary()}),
    fun((SJ) -> {SL, list(field_error())})
) -> {SL, list(field_error())}.
check(Field, Value, Validator, Next) ->
    case Validator(Value) of
        {ok, V} ->
            Next(V);

        {error, Msg} ->
            {Result, Errors} = Next(Value),
            {Result, [{field_error, [Field], Msg} | Errors]}
    end.

-file("src/sift.gleam", 53).
?DOC(
    " Run a sub-validator function, prefixing error paths with the field name.\n"
    "\n"
    " ```gleam\n"
    " use address <- sift.nested(\"address\", input.address, validate_address)\n"
    " // errors get paths like [\"address\", \"zip\"]\n"
    " ```\n"
).
-spec nested(
    binary(),
    SO,
    fun((SO) -> {SP, list(field_error())}),
    fun((SP) -> {SR, list(field_error())})
) -> {SR, list(field_error())}.
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

-file("src/sift.gleam", 69).
?DOC(" Wrap a final value into a Validated tuple with no errors\n").
-spec ok(SU) -> {SU, list(field_error())}.
ok(Value) ->
    {Value, []}.

-file("src/sift.gleam", 80).
?DOC(
    " Convert a Validated(a) to Result(a, List(FieldError)).\n"
    "\n"
    " ```gleam\n"
    " sift.ok(User(name: \"Jo\", email: \"jo@example.com\"))\n"
    " |> sift.validate\n"
    " // -> Ok(User(name: \"Jo\", email: \"jo@example.com\"))\n"
    " ```\n"
).
-spec validate({SW, list(field_error())}) -> {ok, SW} |
    {error, list(field_error())}.
validate(Validated) ->
    case Validated of
        {Value, []} ->
            {ok, Value};

        {_, Errors} ->
            {error, Errors}
    end.

-file("src/sift.gleam", 92).
?DOC(
    " Compose two validators — run both, accumulate errors from both.\n"
    "\n"
    " ```gleam\n"
    " let validator = s.min_length(1, \"required\") |> sift.and(s.email(\"invalid\"))\n"
    " ```\n"
).
-spec 'and'(
    fun((TB) -> {ok, TB} | {error, binary()}),
    fun((TB) -> {ok, TB} | {error, binary()})
) -> fun((TB) -> {ok, TB} | {error, binary()}).
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

-file("src/sift.gleam", 114).
?DOC(
    " Validate every item in a list, accumulating indexed error paths.\n"
    " Produces paths like `[\"tags\", \"0\"]`, `[\"tags\", \"1\"]`, etc.\n"
    "\n"
    " ```gleam\n"
    " use tags <- sift.each(\"tags\", input.tags, s.non_empty(\"empty tag\"))\n"
    " // invalid items get paths like [\"tags\", \"2\"]\n"
    " ```\n"
).
-spec each(
    binary(),
    list(TF),
    fun((TF) -> {ok, TF} | {error, binary()}),
    fun((list(TF)) -> {TJ, list(field_error())})
) -> {TJ, list(field_error())}.
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

-file("src/sift.gleam", 143).
?DOC(
    " Pass if either validator succeeds (try v1 first, then v2).\n"
    "\n"
    " ```gleam\n"
    " let validator = s.email(\"invalid\") |> sift.or(s.url(\"invalid\"))\n"
    " ```\n"
).
-spec 'or'(
    fun((TM) -> {ok, TM} | {error, binary()}),
    fun((TM) -> {ok, TM} | {error, binary()})
) -> fun((TM) -> {ok, TM} | {error, binary()}).
'or'(V1, V2) ->
    fun(Value) -> case V1(Value) of
            {ok, V} ->
                {ok, V};

            {error, _} ->
                V2(Value)
        end end.

-file("src/sift.gleam", 160).
?DOC(
    " Invert a validator — fail if it passes, pass if it fails.\n"
    "\n"
    " ```gleam\n"
    " let not_admin = sift.not(s.one_of([\"admin\"], \"\"), \"cannot be admin\")\n"
    " ```\n"
).
-spec 'not'(fun((TQ) -> {ok, TQ} | {error, binary()}), binary()) -> fun((TQ) -> {ok,
        TQ} |
    {error, binary()}).
'not'(Validator, Msg) ->
    fun(Value) -> case Validator(Value) of
            {ok, _} ->
                {error, Msg};

            {error, _} ->
                {ok, Value}
        end end.

-file("src/sift.gleam", 173).
?DOC(" Value must equal the expected value\n").
-spec equals(TT, binary()) -> fun((TT) -> {ok, TT} | {error, binary()}).
equals(Expected, Msg) ->
    fun(Value) -> case Value =:= Expected of
            true ->
                {ok, Value};

            false ->
                {error, Msg}
        end end.

-file("src/sift.gleam", 183).
?DOC(" Escape hatch for user-defined checks\n").
-spec custom(fun((TV) -> {ok, TV} | {error, binary()})) -> fun((TV) -> {ok, TV} |
    {error, binary()}).
custom(F) ->
    F.
