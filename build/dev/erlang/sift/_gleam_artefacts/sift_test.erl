-module(sift_test).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "test/sift_test.gleam").
-export([main/0, check_valid_test/0, check_invalid_test/0, nested_prefixes_paths_test/0, and_both_pass_test/0, and_first_fails_test/0, and_second_fails_test/0, custom_validator_test/0, string_min_length_test/0, string_max_length_test/0, string_length_test/0, string_non_empty_test/0, string_matches_test/0, string_one_of_test/0, string_starts_with_test/0, string_ends_with_test/0, string_contains_test/0, int_min_test/0, int_max_test/0, int_between_test/0, int_positive_test/0, int_non_negative_test/0, int_one_of_test/0, float_min_test/0, float_max_test/0, float_between_test/0, float_positive_test/0, list_min_length_test/0, list_max_length_test/0, list_non_empty_test/0, each_valid_test/0, option_required_some_test/0, option_required_none_test/0, option_optional_none_test/0, option_optional_some_valid_test/0, option_optional_some_invalid_test/0, or_first_passes_test/0, or_second_passes_test/0, or_both_fail_test/0, not_passes_test/0, not_fails_test/0, equals_passes_test/0, equals_fails_test/0, email_valid_test/0, email_invalid_test/0, url_valid_test/0, url_invalid_test/0, uuid_valid_test/0, uuid_invalid_test/0, full_valid_user_test/0, multiple_errors_accumulate_test/0, each_invalid_indexed_paths_test/0, full_invalid_user_test/0]).
-export_type([user_input/0, user/0]).

-type user_input() :: {user_input,
        binary(),
        integer(),
        gleam@option:option(binary())}.

-type user() :: {user, binary(), integer(), gleam@option:option(binary())}.

-file("test/sift_test.gleam", 10).
-spec main() -> nil.
main() ->
    gleeunit:main().

-file("test/sift_test.gleam", 16).
-spec check_valid_test() -> {ok, binary()} | {error, list(sift:field_error())}.
check_valid_test() ->
    Result = begin
        sift:check(
            <<"name"/utf8>>,
            <<"Alice"/utf8>>,
            sift@string:non_empty(<<"required"/utf8>>),
            fun(Name) -> sift:ok(Name) end
        )
    end,
    _assert_subject = {<<"Alice"/utf8>>, []},
    case Result =:= _assert_subject of
        true -> nil;
        false -> erlang:error(#{gleam_error => assert,
                message => <<"Assertion failed."/utf8>>,
                file => <<?FILEPATH/utf8>>,
                module => <<"sift_test"/utf8>>,
                function => <<"check_valid_test"/utf8>>,
                line => 21,
                kind => binary_operator,
                operator => '==',
                left => #{kind => expression,
                    value => Result,
                    start => 395,
                    'end' => 401
                    },
                right => #{kind => literal,
                    value => _assert_subject,
                    start => 405,
                    'end' => 419
                    },
                start => 388,
                'end' => 419,
                expression_start => 395})
    end,
    _assert_subject@1 = sift:validate(Result),
    case _assert_subject@1 of
        {ok, <<"Alice"/utf8>>} -> _assert_subject@1;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"check_valid_test"/utf8>>,
                        line => 22,
                        value => _assert_fail,
                        start => 422,
                        'end' => 468,
                        pattern_start => 433,
                        pattern_end => 444})
    end.

-file("test/sift_test.gleam", 25).
-spec check_invalid_test() -> {ok, binary()} | {error, list(sift:field_error())}.
check_invalid_test() ->
    Result = begin
        sift:check(
            <<"name"/utf8>>,
            <<""/utf8>>,
            sift@string:non_empty(<<"required"/utf8>>),
            fun(Name) -> sift:ok(Name) end
        )
    end,
    _assert_subject = sift:validate(Result),
    case _assert_subject of
        {error, [{field_error, [<<"name"/utf8>>], <<"required"/utf8>>}]} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"check_invalid_test"/utf8>>,
                        line => 30,
                        value => _assert_fail,
                        start => 607,
                        'end' => 707,
                        pattern_start => 618,
                        pattern_end => 679})
    end.

-file("test/sift_test.gleam", 44).
-spec nested_prefixes_paths_test() -> {ok, binary()} |
    {error, list(sift:field_error())}.
nested_prefixes_paths_test() ->
    Validate_inner = fun(Value) ->
        sift:check(
            <<"zip"/utf8>>,
            Value,
            sift@string:length(5, <<"must be 5 chars"/utf8>>),
            fun(V) -> sift:ok(V) end
        )
    end,
    Result = begin
        sift:nested(
            <<"address"/utf8>>,
            <<"abc"/utf8>>,
            Validate_inner,
            fun(Zip) -> sift:ok(Zip) end
        )
    end,
    _assert_subject = sift:validate(Result),
    case _assert_subject of
        {error,
            [{field_error,
                    [<<"address"/utf8>>, <<"zip"/utf8>>],
                    <<"must be 5 chars"/utf8>>}]} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"nested_prefixes_paths_test"/utf8>>,
                        line => 53,
                        value => _assert_fail,
                        start => 1296,
                        'end' => 1418,
                        pattern_start => 1307,
                        pattern_end => 1394})
    end.

-file("test/sift_test.gleam", 58).
-spec and_both_pass_test() -> {ok, binary()} | {error, binary()}.
and_both_pass_test() ->
    V = begin
        _pipe = sift@string:min_length(1, <<"too short"/utf8>>),
        sift:'and'(_pipe, sift@string:max_length(5, <<"too long"/utf8>>))
    end,
    _assert_subject = V(<<"hey"/utf8>>),
    case _assert_subject of
        {ok, <<"hey"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"and_both_pass_test"/utf8>>,
                        line => 60,
                        value => _assert_fail,
                        start => 1534,
                        'end' => 1565,
                        pattern_start => 1545,
                        pattern_end => 1554})
    end.

-file("test/sift_test.gleam", 63).
-spec and_first_fails_test() -> {ok, binary()} | {error, binary()}.
and_first_fails_test() ->
    V = begin
        _pipe = sift@string:min_length(3, <<"too short"/utf8>>),
        sift:'and'(_pipe, sift@string:max_length(5, <<"too long"/utf8>>))
    end,
    _assert_subject = V(<<"hi"/utf8>>),
    case _assert_subject of
        {error, <<"too short"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"and_first_fails_test"/utf8>>,
                        line => 65,
                        value => _assert_fail,
                        start => 1683,
                        'end' => 1722,
                        pattern_start => 1694,
                        pattern_end => 1712})
    end.

-file("test/sift_test.gleam", 68).
-spec and_second_fails_test() -> {ok, binary()} | {error, binary()}.
and_second_fails_test() ->
    V = begin
        _pipe = sift@string:min_length(1, <<"too short"/utf8>>),
        sift:'and'(_pipe, sift@string:max_length(3, <<"too long"/utf8>>))
    end,
    _assert_subject = V(<<"hello"/utf8>>),
    case _assert_subject of
        {error, <<"too long"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"and_second_fails_test"/utf8>>,
                        line => 70,
                        value => _assert_fail,
                        start => 1841,
                        'end' => 1882,
                        pattern_start => 1852,
                        pattern_end => 1869})
    end.

-file("test/sift_test.gleam", 73).
-spec custom_validator_test() -> {ok, integer()} | {error, binary()}.
custom_validator_test() ->
    Even = sift:custom(fun(N) -> case (N rem 2) =:= 0 of
                true ->
                    {ok, N};

                false ->
                    {error, <<"must be even"/utf8>>}
            end end),
    case Even(4) of
        {ok, 4} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"custom_validator_test"/utf8>>,
                        line => 80,
                        value => _assert_fail,
                        start => 2049,
                        'end' => 2075,
                        pattern_start => 2060,
                        pattern_end => 2065})
    end,
    _assert_subject = Even(3),
    case _assert_subject of
        {error, <<"must be even"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"custom_validator_test"/utf8>>,
                        line => 81,
                        value => _assert_fail@1,
                        start => 2078,
                        'end' => 2120,
                        pattern_start => 2089,
                        pattern_end => 2110})
    end.

-file("test/sift_test.gleam", 86).
-spec string_min_length_test() -> {ok, binary()} | {error, binary()}.
string_min_length_test() ->
    case (sift@string:min_length(3, <<"too short"/utf8>>))(<<"abc"/utf8>>) of
        {ok, <<"abc"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_min_length_test"/utf8>>,
                        line => 87,
                        value => _assert_fail,
                        start => 2179,
                        'end' => 2237,
                        pattern_start => 2190,
                        pattern_end => 2199})
    end,
    _assert_subject = (sift@string:min_length(3, <<"too short"/utf8>>))(
        <<"ab"/utf8>>
    ),
    case _assert_subject of
        {error, <<"too short"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_min_length_test"/utf8>>,
                        line => 88,
                        value => _assert_fail@1,
                        start => 2240,
                        'end' => 2306,
                        pattern_start => 2251,
                        pattern_end => 2269})
    end.

-file("test/sift_test.gleam", 91).
-spec string_max_length_test() -> {ok, binary()} | {error, binary()}.
string_max_length_test() ->
    case (sift@string:max_length(3, <<"too long"/utf8>>))(<<"ab"/utf8>>) of
        {ok, <<"ab"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_max_length_test"/utf8>>,
                        line => 92,
                        value => _assert_fail,
                        start => 2346,
                        'end' => 2401,
                        pattern_start => 2357,
                        pattern_end => 2365})
    end,
    _assert_subject = (sift@string:max_length(3, <<"too long"/utf8>>))(
        <<"abcd"/utf8>>
    ),
    case _assert_subject of
        {error, <<"too long"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_max_length_test"/utf8>>,
                        line => 93,
                        value => _assert_fail@1,
                        start => 2404,
                        'end' => 2470,
                        pattern_start => 2415,
                        pattern_end => 2432})
    end.

-file("test/sift_test.gleam", 96).
-spec string_length_test() -> {ok, binary()} | {error, binary()}.
string_length_test() ->
    case (sift@string:length(3, <<"wrong"/utf8>>))(<<"abc"/utf8>>) of
        {ok, <<"abc"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_length_test"/utf8>>,
                        line => 97,
                        value => _assert_fail,
                        start => 2506,
                        'end' => 2556,
                        pattern_start => 2517,
                        pattern_end => 2526})
    end,
    _assert_subject = (sift@string:length(3, <<"wrong"/utf8>>))(<<"ab"/utf8>>),
    case _assert_subject of
        {error, <<"wrong"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_length_test"/utf8>>,
                        line => 98,
                        value => _assert_fail@1,
                        start => 2559,
                        'end' => 2613,
                        pattern_start => 2570,
                        pattern_end => 2584})
    end.

-file("test/sift_test.gleam", 101).
-spec string_non_empty_test() -> {ok, binary()} | {error, binary()}.
string_non_empty_test() ->
    case (sift@string:non_empty(<<"required"/utf8>>))(<<"a"/utf8>>) of
        {ok, <<"a"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_non_empty_test"/utf8>>,
                        line => 102,
                        value => _assert_fail,
                        start => 2652,
                        'end' => 2701,
                        pattern_start => 2663,
                        pattern_end => 2670})
    end,
    _assert_subject = (sift@string:non_empty(<<"required"/utf8>>))(<<""/utf8>>),
    case _assert_subject of
        {error, <<"required"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_non_empty_test"/utf8>>,
                        line => 103,
                        value => _assert_fail@1,
                        start => 2704,
                        'end' => 2762,
                        pattern_start => 2715,
                        pattern_end => 2732})
    end.

-file("test/sift_test.gleam", 106).
-spec string_matches_test() -> {ok, binary()} | {error, binary()}.
string_matches_test() ->
    case (sift@string:matches(<<"^\\d+$"/utf8>>, <<"digits only"/utf8>>))(
        <<"123"/utf8>>
    ) of
        {ok, <<"123"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_matches_test"/utf8>>,
                        line => 107,
                        value => _assert_fail,
                        start => 2799,
                        'end' => 2863,
                        pattern_start => 2810,
                        pattern_end => 2819})
    end,
    _assert_subject = (sift@string:matches(
        <<"^\\d+$"/utf8>>,
        <<"digits only"/utf8>>
    ))(<<"abc"/utf8>>),
    case _assert_subject of
        {error, <<"digits only"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_matches_test"/utf8>>,
                        line => 108,
                        value => _assert_fail@1,
                        start => 2866,
                        'end' => 2941,
                        pattern_start => 2877,
                        pattern_end => 2897})
    end.

-file("test/sift_test.gleam", 111).
-spec string_one_of_test() -> {ok, binary()} | {error, binary()}.
string_one_of_test() ->
    case (sift@string:one_of(
        [<<"a"/utf8>>, <<"b"/utf8>>, <<"c"/utf8>>],
        <<"invalid"/utf8>>
    ))(<<"a"/utf8>>) of
        {ok, <<"a"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_one_of_test"/utf8>>,
                        line => 112,
                        value => _assert_fail,
                        start => 2977,
                        'end' => 3039,
                        pattern_start => 2988,
                        pattern_end => 2995})
    end,
    _assert_subject = (sift@string:one_of(
        [<<"a"/utf8>>, <<"b"/utf8>>, <<"c"/utf8>>],
        <<"invalid"/utf8>>
    ))(<<"d"/utf8>>),
    case _assert_subject of
        {error, <<"invalid"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_one_of_test"/utf8>>,
                        line => 113,
                        value => _assert_fail@1,
                        start => 3042,
                        'end' => 3113,
                        pattern_start => 3053,
                        pattern_end => 3069})
    end.

-file("test/sift_test.gleam", 116).
-spec string_starts_with_test() -> {ok, binary()} | {error, binary()}.
string_starts_with_test() ->
    case (sift@string:starts_with(
        <<"hello"/utf8>>,
        <<"must start with hello"/utf8>>
    ))(<<"hello world"/utf8>>) of
        {ok, <<"hello world"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_starts_with_test"/utf8>>,
                        line => 117,
                        value => _assert_fail,
                        start => 3154,
                        'end' => 3251,
                        pattern_start => 3165,
                        pattern_end => 3182})
    end,
    _assert_subject = (sift@string:starts_with(
        <<"hello"/utf8>>,
        <<"must start with hello"/utf8>>
    ))(<<"world"/utf8>>),
    case _assert_subject of
        {error, <<"must start with hello"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_starts_with_test"/utf8>>,
                        line => 119,
                        value => _assert_fail@1,
                        start => 3254,
                        'end' => 3358,
                        pattern_start => 3265,
                        pattern_end => 3295})
    end.

-file("test/sift_test.gleam", 123).
-spec string_ends_with_test() -> {ok, binary()} | {error, binary()}.
string_ends_with_test() ->
    case (sift@string:ends_with(
        <<"world"/utf8>>,
        <<"must end with world"/utf8>>
    ))(<<"hello world"/utf8>>) of
        {ok, <<"hello world"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_ends_with_test"/utf8>>,
                        line => 124,
                        value => _assert_fail,
                        start => 3397,
                        'end' => 3490,
                        pattern_start => 3408,
                        pattern_end => 3425})
    end,
    _assert_subject = (sift@string:ends_with(
        <<"world"/utf8>>,
        <<"must end with world"/utf8>>
    ))(<<"hello"/utf8>>),
    case _assert_subject of
        {error, <<"must end with world"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_ends_with_test"/utf8>>,
                        line => 126,
                        value => _assert_fail@1,
                        start => 3493,
                        'end' => 3591,
                        pattern_start => 3504,
                        pattern_end => 3532})
    end.

-file("test/sift_test.gleam", 130).
-spec string_contains_test() -> {ok, binary()} | {error, binary()}.
string_contains_test() ->
    case (sift@string:contains(<<"lo wo"/utf8>>, <<"must contain lo wo"/utf8>>))(
        <<"hello world"/utf8>>
    ) of
        {ok, <<"hello world"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_contains_test"/utf8>>,
                        line => 131,
                        value => _assert_fail,
                        start => 3629,
                        'end' => 3720,
                        pattern_start => 3640,
                        pattern_end => 3657})
    end,
    _assert_subject = (sift@string:contains(
        <<"lo wo"/utf8>>,
        <<"must contain lo wo"/utf8>>
    ))(<<"goodbye"/utf8>>),
    case _assert_subject of
        {error, <<"must contain lo wo"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"string_contains_test"/utf8>>,
                        line => 133,
                        value => _assert_fail@1,
                        start => 3723,
                        'end' => 3820,
                        pattern_start => 3734,
                        pattern_end => 3761})
    end.

-file("test/sift_test.gleam", 139).
-spec int_min_test() -> {ok, integer()} | {error, binary()}.
int_min_test() ->
    case (sift@int:min(3, <<"too small"/utf8>>))(5) of
        {ok, 5} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_min_test"/utf8>>,
                        line => 140,
                        value => _assert_fail,
                        start => 3866,
                        'end' => 3909,
                        pattern_start => 3877,
                        pattern_end => 3882})
    end,
    _assert_subject = (sift@int:min(3, <<"too small"/utf8>>))(2),
    case _assert_subject of
        {error, <<"too small"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_min_test"/utf8>>,
                        line => 141,
                        value => _assert_fail@1,
                        start => 3912,
                        'end' => 3968,
                        pattern_start => 3923,
                        pattern_end => 3941})
    end.

-file("test/sift_test.gleam", 144).
-spec int_max_test() -> {ok, integer()} | {error, binary()}.
int_max_test() ->
    case (sift@int:max(5, <<"too big"/utf8>>))(3) of
        {ok, 3} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_max_test"/utf8>>,
                        line => 145,
                        value => _assert_fail,
                        start => 3998,
                        'end' => 4039,
                        pattern_start => 4009,
                        pattern_end => 4014})
    end,
    _assert_subject = (sift@int:max(5, <<"too big"/utf8>>))(6),
    case _assert_subject of
        {error, <<"too big"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_max_test"/utf8>>,
                        line => 146,
                        value => _assert_fail@1,
                        start => 4042,
                        'end' => 4094,
                        pattern_start => 4053,
                        pattern_end => 4069})
    end.

-file("test/sift_test.gleam", 149).
-spec int_between_test() -> {ok, integer()} | {error, binary()}.
int_between_test() ->
    case (sift@int:between(1, 10, <<"out of range"/utf8>>))(5) of
        {ok, 5} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_between_test"/utf8>>,
                        line => 150,
                        value => _assert_fail,
                        start => 4128,
                        'end' => 4182,
                        pattern_start => 4139,
                        pattern_end => 4144})
    end,
    case (sift@int:between(1, 10, <<"out of range"/utf8>>))(0) of
        {error, <<"out of range"/utf8>>} -> nil;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_between_test"/utf8>>,
                        line => 151,
                        value => _assert_fail@1,
                        start => 4185,
                        'end' => 4255,
                        pattern_start => 4196,
                        pattern_end => 4217})
    end,
    _assert_subject = (sift@int:between(1, 10, <<"out of range"/utf8>>))(11),
    case _assert_subject of
        {error, <<"out of range"/utf8>>} -> _assert_subject;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_between_test"/utf8>>,
                        line => 152,
                        value => _assert_fail@2,
                        start => 4258,
                        'end' => 4329,
                        pattern_start => 4269,
                        pattern_end => 4290})
    end.

-file("test/sift_test.gleam", 155).
-spec int_positive_test() -> {ok, integer()} | {error, binary()}.
int_positive_test() ->
    case (sift@int:positive(<<"must be positive"/utf8>>))(1) of
        {ok, 1} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_positive_test"/utf8>>,
                        line => 156,
                        value => _assert_fail,
                        start => 4364,
                        'end' => 4416,
                        pattern_start => 4375,
                        pattern_end => 4380})
    end,
    case (sift@int:positive(<<"must be positive"/utf8>>))(0) of
        {error, <<"must be positive"/utf8>>} -> nil;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_positive_test"/utf8>>,
                        line => 157,
                        value => _assert_fail@1,
                        start => 4419,
                        'end' => 4491,
                        pattern_start => 4430,
                        pattern_end => 4455})
    end,
    _assert_subject = (sift@int:positive(<<"must be positive"/utf8>>))(-1),
    case _assert_subject of
        {error, <<"must be positive"/utf8>>} -> _assert_subject;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_positive_test"/utf8>>,
                        line => 158,
                        value => _assert_fail@2,
                        start => 4494,
                        'end' => 4567,
                        pattern_start => 4505,
                        pattern_end => 4530})
    end.

-file("test/sift_test.gleam", 161).
-spec int_non_negative_test() -> {ok, integer()} | {error, binary()}.
int_non_negative_test() ->
    case (sift@int:non_negative(<<"must be >= 0"/utf8>>))(0) of
        {ok, 0} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_non_negative_test"/utf8>>,
                        line => 162,
                        value => _assert_fail,
                        start => 4606,
                        'end' => 4658,
                        pattern_start => 4617,
                        pattern_end => 4622})
    end,
    case (sift@int:non_negative(<<"must be >= 0"/utf8>>))(1) of
        {ok, 1} -> nil;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_non_negative_test"/utf8>>,
                        line => 163,
                        value => _assert_fail@1,
                        start => 4661,
                        'end' => 4713,
                        pattern_start => 4672,
                        pattern_end => 4677})
    end,
    _assert_subject = (sift@int:non_negative(<<"must be >= 0"/utf8>>))(-1),
    case _assert_subject of
        {error, <<"must be >= 0"/utf8>>} -> _assert_subject;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_non_negative_test"/utf8>>,
                        line => 164,
                        value => _assert_fail@2,
                        start => 4716,
                        'end' => 4785,
                        pattern_start => 4727,
                        pattern_end => 4748})
    end.

-file("test/sift_test.gleam", 167).
-spec int_one_of_test() -> {ok, integer()} | {error, binary()}.
int_one_of_test() ->
    case (sift@int:one_of([1, 2, 3], <<"invalid"/utf8>>))(1) of
        {ok, 1} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_one_of_test"/utf8>>,
                        line => 168,
                        value => _assert_fail,
                        start => 4818,
                        'end' => 4870,
                        pattern_start => 4829,
                        pattern_end => 4834})
    end,
    _assert_subject = (sift@int:one_of([1, 2, 3], <<"invalid"/utf8>>))(4),
    case _assert_subject of
        {error, <<"invalid"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"int_one_of_test"/utf8>>,
                        line => 169,
                        value => _assert_fail@1,
                        start => 4873,
                        'end' => 4936,
                        pattern_start => 4884,
                        pattern_end => 4900})
    end.

-file("test/sift_test.gleam", 174).
-spec float_min_test() -> {ok, float()} | {error, binary()}.
float_min_test() ->
    case (sift@float:min(3.0, <<"too small"/utf8>>))(5.0) of
        {ok, 5.0} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_min_test"/utf8>>,
                        line => 175,
                        value => _assert_fail,
                        start => 4986,
                        'end' => 5035,
                        pattern_start => 4997,
                        pattern_end => 5004})
    end,
    _assert_subject = (sift@float:min(3.0, <<"too small"/utf8>>))(2.0),
    case _assert_subject of
        {error, <<"too small"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_min_test"/utf8>>,
                        line => 176,
                        value => _assert_fail@1,
                        start => 5038,
                        'end' => 5098,
                        pattern_start => 5049,
                        pattern_end => 5067})
    end.

-file("test/sift_test.gleam", 179).
-spec float_max_test() -> {ok, float()} | {error, binary()}.
float_max_test() ->
    case (sift@float:max(5.0, <<"too big"/utf8>>))(3.0) of
        {ok, 3.0} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_max_test"/utf8>>,
                        line => 180,
                        value => _assert_fail,
                        start => 5130,
                        'end' => 5177,
                        pattern_start => 5141,
                        pattern_end => 5148})
    end,
    _assert_subject = (sift@float:max(5.0, <<"too big"/utf8>>))(6.0),
    case _assert_subject of
        {error, <<"too big"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_max_test"/utf8>>,
                        line => 181,
                        value => _assert_fail@1,
                        start => 5180,
                        'end' => 5236,
                        pattern_start => 5191,
                        pattern_end => 5207})
    end.

-file("test/sift_test.gleam", 184).
-spec float_between_test() -> {ok, float()} | {error, binary()}.
float_between_test() ->
    case (sift@float:between(1.0, 10.0, <<"out of range"/utf8>>))(5.0) of
        {ok, 5.0} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_between_test"/utf8>>,
                        line => 185,
                        value => _assert_fail,
                        start => 5272,
                        'end' => 5334,
                        pattern_start => 5283,
                        pattern_end => 5290})
    end,
    _assert_subject = (sift@float:between(1.0, 10.0, <<"out of range"/utf8>>))(
        0.5
    ),
    case _assert_subject of
        {error, <<"out of range"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_between_test"/utf8>>,
                        line => 186,
                        value => _assert_fail@1,
                        start => 5337,
                        'end' => 5413,
                        pattern_start => 5348,
                        pattern_end => 5369})
    end.

-file("test/sift_test.gleam", 189).
-spec float_positive_test() -> {ok, float()} | {error, binary()}.
float_positive_test() ->
    case (sift@float:positive(<<"must be positive"/utf8>>))(0.1) of
        {ok, 0.1} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_positive_test"/utf8>>,
                        line => 190,
                        value => _assert_fail,
                        start => 5450,
                        'end' => 5506,
                        pattern_start => 5461,
                        pattern_end => 5468})
    end,
    case (sift@float:positive(<<"must be positive"/utf8>>))(+0.0) of
        {error, <<"must be positive"/utf8>>} -> nil;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_positive_test"/utf8>>,
                        line => 191,
                        value => _assert_fail@1,
                        start => 5509,
                        'end' => 5583,
                        pattern_start => 5520,
                        pattern_end => 5545})
    end,
    _assert_subject = (sift@float:positive(<<"must be positive"/utf8>>))(-1.0),
    case _assert_subject of
        {error, <<"must be positive"/utf8>>} -> _assert_subject;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"float_positive_test"/utf8>>,
                        line => 192,
                        value => _assert_fail@2,
                        start => 5586,
                        'end' => 5661,
                        pattern_start => 5597,
                        pattern_end => 5622})
    end.

-file("test/sift_test.gleam", 197).
-spec list_min_length_test() -> {ok, list(integer())} | {error, binary()}.
list_min_length_test() ->
    case (sift@list:min_length(2, <<"too few"/utf8>>))([1, 2, 3]) of
        {ok, [1, 2, 3]} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"list_min_length_test"/utf8>>,
                        line => 198,
                        value => _assert_fail,
                        start => 5716,
                        'end' => 5780,
                        pattern_start => 5727,
                        pattern_end => 5740})
    end,
    _assert_subject = (sift@list:min_length(2, <<"too few"/utf8>>))([1]),
    case _assert_subject of
        {error, <<"too few"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"list_min_length_test"/utf8>>,
                        line => 199,
                        value => _assert_fail@1,
                        start => 5783,
                        'end' => 5844,
                        pattern_start => 5794,
                        pattern_end => 5810})
    end.

-file("test/sift_test.gleam", 202).
-spec list_max_length_test() -> {ok, list(integer())} | {error, binary()}.
list_max_length_test() ->
    case (sift@list:max_length(2, <<"too many"/utf8>>))([1]) of
        {ok, [1]} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"list_max_length_test"/utf8>>,
                        line => 203,
                        value => _assert_fail,
                        start => 5882,
                        'end' => 5935,
                        pattern_start => 5893,
                        pattern_end => 5900})
    end,
    _assert_subject = (sift@list:max_length(2, <<"too many"/utf8>>))([1, 2, 3]),
    case _assert_subject of
        {error, <<"too many"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"list_max_length_test"/utf8>>,
                        line => 204,
                        value => _assert_fail@1,
                        start => 5938,
                        'end' => 6007,
                        pattern_start => 5949,
                        pattern_end => 5966})
    end.

-file("test/sift_test.gleam", 207).
-spec list_non_empty_test() -> {ok, list(any())} | {error, binary()}.
list_non_empty_test() ->
    case (sift@list:non_empty(<<"empty"/utf8>>))([1]) of
        {ok, [1]} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"list_non_empty_test"/utf8>>,
                        line => 208,
                        value => _assert_fail,
                        start => 6044,
                        'end' => 6090,
                        pattern_start => 6055,
                        pattern_end => 6062})
    end,
    _assert_subject = (sift@list:non_empty(<<"empty"/utf8>>))([]),
    case _assert_subject of
        {error, <<"empty"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"list_non_empty_test"/utf8>>,
                        line => 209,
                        value => _assert_fail@1,
                        start => 6093,
                        'end' => 6145,
                        pattern_start => 6104,
                        pattern_end => 6118})
    end.

-file("test/sift_test.gleam", 212).
-spec each_valid_test() -> {ok, list(binary())} |
    {error, list(sift:field_error())}.
each_valid_test() ->
    Result = begin
        sift:each(
            <<"tags"/utf8>>,
            [<<"a"/utf8>>, <<"b"/utf8>>],
            sift@string:non_empty(<<"empty"/utf8>>),
            fun(Tags) -> sift:ok(Tags) end
        )
    end,
    _assert_subject = sift:validate(Result),
    case _assert_subject of
        {ok, [<<"a"/utf8>>, <<"b"/utf8>>]} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"each_valid_test"/utf8>>,
                        line => 217,
                        value => _assert_fail,
                        start => 6285,
                        'end' => 6334,
                        pattern_start => 6296,
                        pattern_end => 6310})
    end.

-file("test/sift_test.gleam", 232).
-spec assert_has_path(list(sift:field_error()), list(binary())) -> nil.
assert_has_path(Errors, Path) ->
    case Errors of
        [] ->
            erlang:error(#{gleam_error => panic,
                    message => <<"expected error with given path"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"sift_test"/utf8>>,
                    function => <<"assert_has_path"/utf8>>,
                    line => 234});

        [First | Rest] ->
            case erlang:element(2, First) =:= Path of
                true ->
                    nil;

                false ->
                    assert_has_path(Rest, Path)
            end
    end.

-file("test/sift_test.gleam", 245).
-spec option_required_some_test() -> {ok, binary()} | {error, binary()}.
option_required_some_test() ->
    _assert_subject = (sift@option:required(<<"required"/utf8>>))(
        {some, <<"hello"/utf8>>}
    ),
    case _assert_subject of
        {ok, <<"hello"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"option_required_some_test"/utf8>>,
                        line => 246,
                        value => _assert_fail,
                        start => 7029,
                        'end' => 7091,
                        pattern_start => 7040,
                        pattern_end => 7051})
    end.

-file("test/sift_test.gleam", 249).
-spec option_required_none_test() -> {ok, any()} | {error, binary()}.
option_required_none_test() ->
    _assert_subject = (sift@option:required(<<"required"/utf8>>))(none),
    case _assert_subject of
        {error, <<"required"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"option_required_none_test"/utf8>>,
                        line => 250,
                        value => _assert_fail,
                        start => 7134,
                        'end' => 7193,
                        pattern_start => 7145,
                        pattern_end => 7162})
    end.

-file("test/sift_test.gleam", 253).
-spec option_optional_none_test() -> {ok, gleam@option:option(binary())} |
    {error, binary()}.
option_optional_none_test() ->
    _assert_subject = (sift@option:optional(
        sift@string:non_empty(<<"required"/utf8>>)
    ))(none),
    case _assert_subject of
        {ok, none} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"option_optional_none_test"/utf8>>,
                        line => 254,
                        value => _assert_fail,
                        start => 7236,
                        'end' => 7299,
                        pattern_start => 7247,
                        pattern_end => 7255})
    end.

-file("test/sift_test.gleam", 257).
-spec option_optional_some_valid_test() -> {ok, gleam@option:option(binary())} |
    {error, binary()}.
option_optional_some_valid_test() ->
    _assert_subject = (sift@option:optional(
        sift@string:non_empty(<<"required"/utf8>>)
    ))({some, <<"hi"/utf8>>}),
    case _assert_subject of
        {ok, {some, <<"hi"/utf8>>}} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"option_optional_some_valid_test"/utf8>>,
                        line => 258,
                        value => _assert_fail,
                        start => 7348,
                        'end' => 7423,
                        pattern_start => 7359,
                        pattern_end => 7373})
    end.

-file("test/sift_test.gleam", 261).
-spec option_optional_some_invalid_test() -> {ok, gleam@option:option(binary())} |
    {error, binary()}.
option_optional_some_invalid_test() ->
    _assert_subject = (sift@option:optional(
        sift@string:non_empty(<<"required"/utf8>>)
    ))({some, <<""/utf8>>}),
    case _assert_subject of
        {error, <<"required"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"option_optional_some_invalid_test"/utf8>>,
                        line => 262,
                        value => _assert_fail,
                        start => 7474,
                        'end' => 7550,
                        pattern_start => 7485,
                        pattern_end => 7502})
    end.

-file("test/sift_test.gleam", 267).
-spec or_first_passes_test() -> {ok, binary()} | {error, binary()}.
or_first_passes_test() ->
    V = begin
        _pipe = sift@string:matches(<<"^\\d+$"/utf8>>, <<"digits"/utf8>>),
        sift:'or'(
            _pipe,
            sift@string:matches(<<"^[a-z]+$"/utf8>>, <<"letters"/utf8>>)
        )
    end,
    _assert_subject = V(<<"123"/utf8>>),
    case _assert_subject of
        {ok, <<"123"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"or_first_passes_test"/utf8>>,
                        line => 270,
                        value => _assert_fail,
                        start => 7707,
                        'end' => 7738,
                        pattern_start => 7718,
                        pattern_end => 7727})
    end.

-file("test/sift_test.gleam", 273).
-spec or_second_passes_test() -> {ok, binary()} | {error, binary()}.
or_second_passes_test() ->
    V = begin
        _pipe = sift@string:matches(<<"^\\d+$"/utf8>>, <<"digits"/utf8>>),
        sift:'or'(
            _pipe,
            sift@string:matches(<<"^[a-z]+$"/utf8>>, <<"letters"/utf8>>)
        )
    end,
    _assert_subject = V(<<"abc"/utf8>>),
    case _assert_subject of
        {ok, <<"abc"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"or_second_passes_test"/utf8>>,
                        line => 276,
                        value => _assert_fail,
                        start => 7866,
                        'end' => 7897,
                        pattern_start => 7877,
                        pattern_end => 7886})
    end.

-file("test/sift_test.gleam", 279).
-spec or_both_fail_test() -> {ok, binary()} | {error, binary()}.
or_both_fail_test() ->
    V = begin
        _pipe = sift@string:matches(<<"^\\d+$"/utf8>>, <<"digits"/utf8>>),
        sift:'or'(
            _pipe,
            sift@string:matches(<<"^[a-z]+$"/utf8>>, <<"letters"/utf8>>)
        )
    end,
    _assert_subject = V(<<"ABC!"/utf8>>),
    case _assert_subject of
        {error, <<"letters"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"or_both_fail_test"/utf8>>,
                        line => 282,
                        value => _assert_fail,
                        start => 8021,
                        'end' => 8060,
                        pattern_start => 8032,
                        pattern_end => 8048})
    end.

-file("test/sift_test.gleam", 285).
-spec not_passes_test() -> {ok, binary()} | {error, binary()}.
not_passes_test() ->
    V = sift:'not'(
        sift@string:contains(<<"@"/utf8>>, <<""/utf8>>),
        <<"must not contain @"/utf8>>
    ),
    _assert_subject = V(<<"hello"/utf8>>),
    case _assert_subject of
        {ok, <<"hello"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"not_passes_test"/utf8>>,
                        line => 287,
                        value => _assert_fail,
                        start => 8155,
                        'end' => 8190,
                        pattern_start => 8166,
                        pattern_end => 8177})
    end.

-file("test/sift_test.gleam", 290).
-spec not_fails_test() -> {ok, binary()} | {error, binary()}.
not_fails_test() ->
    V = sift:'not'(
        sift@string:contains(<<"@"/utf8>>, <<""/utf8>>),
        <<"must not contain @"/utf8>>
    ),
    _assert_subject = V(<<"a@b"/utf8>>),
    case _assert_subject of
        {error, <<"must not contain @"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"not_fails_test"/utf8>>,
                        line => 292,
                        value => _assert_fail,
                        start => 8284,
                        'end' => 8333,
                        pattern_start => 8295,
                        pattern_end => 8322})
    end.

-file("test/sift_test.gleam", 295).
-spec equals_passes_test() -> {ok, binary()} | {error, binary()}.
equals_passes_test() ->
    _assert_subject = (sift:equals(<<"yes"/utf8>>, <<"must be yes"/utf8>>))(
        <<"yes"/utf8>>
    ),
    case _assert_subject of
        {ok, <<"yes"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"equals_passes_test"/utf8>>,
                        line => 296,
                        value => _assert_fail,
                        start => 8369,
                        'end' => 8432,
                        pattern_start => 8380,
                        pattern_end => 8389})
    end.

-file("test/sift_test.gleam", 299).
-spec equals_fails_test() -> {ok, binary()} | {error, binary()}.
equals_fails_test() ->
    _assert_subject = (sift:equals(<<"yes"/utf8>>, <<"must be yes"/utf8>>))(
        <<"no"/utf8>>
    ),
    case _assert_subject of
        {error, <<"must be yes"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"equals_fails_test"/utf8>>,
                        line => 300,
                        value => _assert_fail,
                        start => 8467,
                        'end' => 8540,
                        pattern_start => 8478,
                        pattern_end => 8498})
    end.

-file("test/sift_test.gleam", 305).
-spec email_valid_test() -> {ok, binary()} | {error, binary()}.
email_valid_test() ->
    _assert_subject = (sift@string:email(<<"invalid email"/utf8>>))(
        <<"alice@example.com"/utf8>>
    ),
    case _assert_subject of
        {ok, <<"alice@example.com"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"email_valid_test"/utf8>>,
                        line => 306,
                        value => _assert_fail,
                        start => 8601,
                        'end' => 8683,
                        pattern_start => 8612,
                        pattern_end => 8635})
    end.

-file("test/sift_test.gleam", 309).
-spec email_invalid_test() -> {ok, binary()} | {error, binary()}.
email_invalid_test() ->
    case (sift@string:email(<<"invalid email"/utf8>>))(<<"not-an-email"/utf8>>) of
        {error, <<"invalid email"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"email_invalid_test"/utf8>>,
                        line => 310,
                        value => _assert_fail,
                        start => 8719,
                        'end' => 8795,
                        pattern_start => 8730,
                        pattern_end => 8752})
    end,
    case (sift@string:email(<<"invalid email"/utf8>>))(<<"@missing.user"/utf8>>) of
        {error, <<"invalid email"/utf8>>} -> nil;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"email_invalid_test"/utf8>>,
                        line => 311,
                        value => _assert_fail@1,
                        start => 8798,
                        'end' => 8875,
                        pattern_start => 8809,
                        pattern_end => 8831})
    end,
    _assert_subject = (sift@string:email(<<"invalid email"/utf8>>))(
        <<"no-domain@"/utf8>>
    ),
    case _assert_subject of
        {error, <<"invalid email"/utf8>>} -> _assert_subject;
        _assert_fail@2 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"email_invalid_test"/utf8>>,
                        line => 312,
                        value => _assert_fail@2,
                        start => 8878,
                        'end' => 8952,
                        pattern_start => 8889,
                        pattern_end => 8911})
    end.

-file("test/sift_test.gleam", 315).
-spec url_valid_test() -> {ok, binary()} | {error, binary()}.
url_valid_test() ->
    case (sift@string:url(<<"invalid url"/utf8>>))(
        <<"https://example.com"/utf8>>
    ) of
        {ok, <<"https://example.com"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"url_valid_test"/utf8>>,
                        line => 316,
                        value => _assert_fail,
                        start => 8984,
                        'end' => 9066,
                        pattern_start => 8995,
                        pattern_end => 9020})
    end,
    _assert_subject = (sift@string:url(<<"invalid url"/utf8>>))(
        <<"http://localhost:3000/path"/utf8>>
    ),
    case _assert_subject of
        {ok, <<"http://localhost:3000/path"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"url_valid_test"/utf8>>,
                        line => 317,
                        value => _assert_fail@1,
                        start => 9069,
                        'end' => 9169,
                        pattern_start => 9080,
                        pattern_end => 9112})
    end.

-file("test/sift_test.gleam", 321).
-spec url_invalid_test() -> {ok, binary()} | {error, binary()}.
url_invalid_test() ->
    case (sift@string:url(<<"invalid url"/utf8>>))(<<"not a url"/utf8>>) of
        {error, <<"invalid url"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"url_invalid_test"/utf8>>,
                        line => 322,
                        value => _assert_fail,
                        start => 9203,
                        'end' => 9270,
                        pattern_start => 9214,
                        pattern_end => 9234})
    end,
    _assert_subject = (sift@string:url(<<"invalid url"/utf8>>))(
        <<"ftp://other.com"/utf8>>
    ),
    case _assert_subject of
        {error, <<"invalid url"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"url_invalid_test"/utf8>>,
                        line => 323,
                        value => _assert_fail@1,
                        start => 9273,
                        'end' => 9346,
                        pattern_start => 9284,
                        pattern_end => 9304})
    end.

-file("test/sift_test.gleam", 326).
-spec uuid_valid_test() -> {ok, binary()} | {error, binary()}.
uuid_valid_test() ->
    _assert_subject = (sift@string:uuid(<<"invalid uuid"/utf8>>))(
        <<"550e8400-e29b-41d4-a716-446655440000"/utf8>>
    ),
    case _assert_subject of
        {ok, <<"550e8400-e29b-41d4-a716-446655440000"/utf8>>} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"uuid_valid_test"/utf8>>,
                        line => 327,
                        value => _assert_fail,
                        start => 9379,
                        'end' => 9501,
                        pattern_start => 9390,
                        pattern_end => 9432})
    end.

-file("test/sift_test.gleam", 331).
-spec uuid_invalid_test() -> {ok, binary()} | {error, binary()}.
uuid_invalid_test() ->
    case (sift@string:uuid(<<"invalid uuid"/utf8>>))(<<"not-a-uuid"/utf8>>) of
        {error, <<"invalid uuid"/utf8>>} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"uuid_invalid_test"/utf8>>,
                        line => 332,
                        value => _assert_fail,
                        start => 9536,
                        'end' => 9607,
                        pattern_start => 9547,
                        pattern_end => 9568})
    end,
    _assert_subject = (sift@string:uuid(<<"invalid uuid"/utf8>>))(
        <<"550e8400-e29b-51d4-a716-446655440000"/utf8>>
    ),
    case _assert_subject of
        {error, <<"invalid uuid"/utf8>>} -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"uuid_invalid_test"/utf8>>,
                        line => 333,
                        value => _assert_fail@1,
                        start => 9610,
                        'end' => 9707,
                        pattern_start => 9621,
                        pattern_end => 9642})
    end.

-file("test/sift_test.gleam", 346).
-spec full_valid_user_test() -> {ok, user()} | {error, list(sift:field_error())}.
full_valid_user_test() ->
    Input = {user_input,
        <<"Alice"/utf8>>,
        30,
        {some, <<"alice@test.com"/utf8>>}},
    Result = begin
        sift:check(
            <<"name"/utf8>>,
            erlang:element(2, Input),
            begin
                _pipe = sift@string:min_length(1, <<"required"/utf8>>),
                sift:'and'(
                    _pipe,
                    sift@string:max_length(50, <<"too long"/utf8>>)
                )
            end,
            fun(Name) ->
                sift:check(
                    <<"age"/utf8>>,
                    erlang:element(3, Input),
                    sift@int:min(0, <<"must be non-negative"/utf8>>),
                    fun(Age) ->
                        sift:check(
                            <<"email"/utf8>>,
                            erlang:element(4, Input),
                            sift@option:optional(
                                sift@string:non_empty(<<"empty email"/utf8>>)
                            ),
                            fun(Email) -> sift:ok({user, Name, Age, Email}) end
                        )
                    end
                )
            end
        )
    end,
    _assert_subject = sift:validate(Result),
    case _assert_subject of
        {ok, {user, <<"Alice"/utf8>>, 30, {some, <<"alice@test.com"/utf8>>}}} -> _assert_subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"full_valid_user_test"/utf8>>,
                        line => 362,
                        value => _assert_fail,
                        start => 10408,
                        'end' => 10492,
                        pattern_start => 10419,
                        pattern_end => 10464})
    end.

-file("test/sift_test.gleam", 386).
-spec length(list(any())) -> integer().
length(Items) ->
    case Items of
        [] ->
            0;

        [_ | Rest] ->
            1 + length(Rest)
    end.

-file("test/sift_test.gleam", 34).
-spec multiple_errors_accumulate_test() -> integer().
multiple_errors_accumulate_test() ->
    Result = begin
        sift:check(
            <<"name"/utf8>>,
            <<""/utf8>>,
            sift@string:non_empty(<<"name required"/utf8>>),
            fun(Name) ->
                sift:check(
                    <<"age"/utf8>>,
                    -1,
                    sift@int:positive(<<"must be positive"/utf8>>),
                    fun(Age) -> sift:ok({Name, Age}) end
                )
            end
        )
    end,
    Errors@1 = case sift:validate(Result) of
        {error, Errors} -> Errors;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"multiple_errors_accumulate_test"/utf8>>,
                        line => 40,
                        value => _assert_fail,
                        start => 941,
                        'end' => 989,
                        pattern_start => 952,
                        pattern_end => 965})
    end,
    _assert_subject = length(Errors@1),
    case _assert_subject of
        2 -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"multiple_errors_accumulate_test"/utf8>>,
                        line => 41,
                        value => _assert_fail@1,
                        start => 992,
                        'end' => 1021,
                        pattern_start => 1003,
                        pattern_end => 1004})
    end.

-file("test/sift_test.gleam", 220).
-spec each_invalid_indexed_paths_test() -> nil.
each_invalid_indexed_paths_test() ->
    Result = begin
        sift:each(
            <<"tags"/utf8>>,
            [<<"a"/utf8>>, <<""/utf8>>, <<"b"/utf8>>, <<""/utf8>>],
            sift@string:non_empty(<<"empty"/utf8>>),
            fun(Tags) -> sift:ok(Tags) end
        )
    end,
    Errors@1 = case sift:validate(Result) of
        {error, Errors} -> Errors;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"each_invalid_indexed_paths_test"/utf8>>,
                        line => 225,
                        value => _assert_fail,
                        start => 6498,
                        'end' => 6546,
                        pattern_start => 6509,
                        pattern_end => 6522})
    end,
    case length(Errors@1) of
        2 -> nil;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"each_invalid_indexed_paths_test"/utf8>>,
                        line => 226,
                        value => _assert_fail@1,
                        start => 6549,
                        'end' => 6578,
                        pattern_start => 6560,
                        pattern_end => 6561})
    end,
    assert_has_path(Errors@1, [<<"tags"/utf8>>, <<"1"/utf8>>]),
    assert_has_path(Errors@1, [<<"tags"/utf8>>, <<"3"/utf8>>]).

-file("test/sift_test.gleam", 366).
-spec full_invalid_user_test() -> integer().
full_invalid_user_test() ->
    Input = {user_input, <<""/utf8>>, -1, {some, <<""/utf8>>}},
    Result = begin
        sift:check(
            <<"name"/utf8>>,
            erlang:element(2, Input),
            begin
                _pipe = sift@string:min_length(1, <<"required"/utf8>>),
                sift:'and'(
                    _pipe,
                    sift@string:max_length(50, <<"too long"/utf8>>)
                )
            end,
            fun(Name) ->
                sift:check(
                    <<"age"/utf8>>,
                    erlang:element(3, Input),
                    sift@int:min(0, <<"must be non-negative"/utf8>>),
                    fun(Age) ->
                        sift:check(
                            <<"email"/utf8>>,
                            erlang:element(4, Input),
                            sift@option:optional(
                                sift@string:non_empty(<<"empty email"/utf8>>)
                            ),
                            fun(Email) -> sift:ok({user, Name, Age, Email}) end
                        )
                    end
                )
            end
        )
    end,
    Errors@1 = case sift:validate(Result) of
        {error, Errors} -> Errors;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"full_invalid_user_test"/utf8>>,
                        line => 382,
                        value => _assert_fail,
                        start => 10970,
                        'end' => 11018,
                        pattern_start => 10981,
                        pattern_end => 10994})
    end,
    _assert_subject = length(Errors@1),
    case _assert_subject of
        3 -> _assert_subject;
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"sift_test"/utf8>>,
                        function => <<"full_invalid_user_test"/utf8>>,
                        line => 383,
                        value => _assert_fail@1,
                        start => 11021,
                        'end' => 11050,
                        pattern_start => 11032,
                        pattern_end => 11033})
    end.
