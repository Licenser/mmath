-module(mmath_aggr_eqc).

-include_lib("eqc/include/eqc.hrl").
-include_lib("eunit/include/eunit.hrl").
-include("../include/mmath.hrl").
-compile(export_all).

-import(mmath_helper, [int_array/0, float_array/0, pos_int/0, non_neg_int/0,
                       i_or_f_list/0, i_or_f_array/0,
                       non_empty_i_or_f_list/0, out/1, defined_int_array/0,
                       defined_float_array/0, defined_i_or_f_array/0]).


prop_n_length_chunks() ->
    ?FORALL({L, N}, {list(int()), pos_int()},
            ceiling(length(L) / N) =:= length(n_length_chunks(L, N))).

prop_avg_all() ->
    ?FORALL(L, non_empty_i_or_f_list(),
            [lists:sum(L)/length(L)] == ?B2L(mmath_aggr:avg(?L2B(L), length(L)))).

prop_avg_len() ->
    ?FORALL({L, N}, {non_empty_i_or_f_list(), pos_int()},
            ceiling(length(L)/N) == length(?B2L(mmath_aggr:avg(?L2B(L), N)))).

prop_avg_impl() ->
    ?FORALL({{_, L, B}, N}, {defined_i_or_f_array(), pos_int()},
            avg(L, N) == mmath_bin:to_list(mmath_aggr:avg(B, N))).

prop_avg_len_undefined() ->
    ?FORALL({L, N}, {non_neg_int(), pos_int()},
            ceiling(L/N) == mmath_bin:length(mmath_aggr:avg(mmath_bin:empty(L), N))).

prop_sum() ->
    ?FORALL({{_, L, B}, N}, {defined_i_or_f_array(), pos_int()},
            sum(L, N) == mmath_bin:to_list(mmath_aggr:sum(B, N))).

prop_sum_len_undefined() ->
    ?FORALL({L, N}, {non_neg_int(), pos_int()},
            ceiling(L/N) == mmath_bin:length(mmath_aggr:sum(mmath_bin:empty(L), N))).

%% We need to know about unset values for min!
prop_min() ->
    ?FORALL({{L, _, B}, N}, {defined_i_or_f_array(), pos_int()},
            min_list(L, N) == mmath_bin:to_list(mmath_aggr:min(B, N))).

prop_min_len_undefined() ->
    ?FORALL({L, N}, {non_neg_int(), pos_int()},
            ceiling(L/N) == mmath_bin:length(mmath_aggr:min(mmath_bin:empty(L), N))).

%% We need to know about unset values for min!
prop_max() ->
    ?FORALL({{L, _, B}, N}, {defined_i_or_f_array(), pos_int()},
            max_list(L, N) == mmath_bin:to_list(mmath_aggr:max(B, N))).

prop_max_len_undefined() ->
    ?FORALL({L, N}, {non_neg_int(), pos_int()},
            ceiling(L/N) == mmath_bin:length(mmath_aggr:max(mmath_bin:empty(L), N))).

prop_der() ->
    ?FORALL({_, L, B}, defined_i_or_f_array(),
            derivate(L) == mmath_bin:to_list(mmath_aggr:derivate(B))).

prop_der_len_undefined() ->
    ?FORALL(L, non_neg_int(),
            erlang:max(0, L - 1) == mmath_bin:length(mmath_aggr:derivate(mmath_bin:empty(L)))).

prop_scale_int() ->
    ?FORALL({{_, L, B}, S}, {defined_int_array(), real()},
            scale_i(L, S) == mmath_bin:to_list(mmath_aggr:scale(B,S))).

prop_scale_flaot() ->
    ?FORALL({{_, L, B}, S}, {defined_float_array(), real()},
            scale_f(L, S) == mmath_bin:to_list(mmath_aggr:scale(B, S))).

prop_scale_len_undefined() ->
    ?FORALL(L, non_neg_int(),
            L == mmath_bin:length(mmath_aggr:scale(mmath_bin:empty(L), 1))).

prop_combine_sum_identity() ->
    ?FORALL({_, _, A}, defined_int_array(),
            mmath_comb:sum([A]) == A).

prop_combine_sum_N() ->
    ?FORALL({{_, _, A}, N}, {defined_int_array(), pos_int()},
            mmath_comb:sum([A || _ <- lists:seq(1, N+1)]) == mmath_aggr:scale(A, N+1)).

prop_combine_avg_N() ->
    ?FORALL({{_, _, A}, N}, {defined_int_array(), pos_int()},
            mmath_comb:avg([A || _ <- lists:seq(1, N+1)]) == mmath_aggr:scale(A, 1.0)).

scale_i(L, S) ->
    [round(N*S) || N <- L].

scale_f(L, S) ->
    [N*S || N <- L].

avg(L, N) ->
    apply_n(L, N, fun avg_/2).

sum(L, N) ->
    apply_n(L, N, fun sum_/2).

min_list(L, N) ->
    apply_n(L, N, fun min_/2).

max_list(L, N) ->
    apply_n(L, N, fun max_/2).

apply_n(L, N, F) ->
    fix_list([F(SL, N) || SL <- n_length_chunks(L, N)], 0, []).

avg_(L, N) ->
    lists:sum(L) / N.

sum_(L, _N) ->
    lists:sum(L).

min_(L, _N) ->
    case lists:sort([V || {true, V} <- L]) of
        [] ->
            undefined;
        [S | _ ] ->
            S
    end.

max_(L, _N) ->
    case lists:sort([V || {true, V} <- L]) of
        [] ->
            undefined;
        L1 ->
            lists:last(L1)
    end.

fix_list([undefined | T], Last, Acc) ->
    fix_list(T, Last, [Last | Acc]);
fix_list([V | T], _, Acc) ->
    fix_list(T, V, [V | Acc]);
fix_list([],_,Acc) ->
    lists:reverse(Acc).

derivate([]) ->
    [];
derivate([H | T]) ->
    derivate(H, T, []).
derivate(H, [H1 | T], Acc) ->
    derivate(H1, T, [H1 - H | Acc]);
derivate(_, [], Acc) ->
    lists:reverse(Acc).

prop_ceiling() ->
    ?FORALL(F, real(),
            F =< ceiling(F)).

%% Taken from: http://schemecookbook.org/Erlang/NumberRounding
ceiling(X) ->
    T = erlang:trunc(X),
    case (X - T) of
        Neg when Neg < 0 -> T;
        Pos when Pos > 0 -> T + 1;
        _ -> T
    end.
%% taken from http://stackoverflow.com/questions/12534898/splitting-a-list-in-equal-sized-chunks-in-erlang
n_length_chunks([],_) -> [];
n_length_chunks(List,Len) when Len > length(List) ->
    [List];
n_length_chunks(List,Len) ->
    {Head,Tail} = lists:split(Len,List),
    [Head | n_length_chunks(Tail,Len)].

-include("eqc_helper.hrl").
