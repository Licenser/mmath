%%%-------------------------------------------------------------------
%%% @author Heinz Nikolaus Gies <heinz@licenser.net>
%%% @copyright (C) 2014, Heinz Nikolaus Gies
%%% @doc
%%%
%%% @end
%%% Created :  8 Jun 2014 by Heinz Nikolaus Gies <heinz@licenser.net>
%%%-------------------------------------------------------------------
-module(mmath_aggr).

-export([empty/2, sum/2, avg/2, min/2, max/2, scale/2, derivate/1]).
-include("mmath.hrl").


empty(Data, Count) ->
    empty(Data, 0, Count, Count, <<>>).

empty(R, Empty, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?INT, Empty:?BITS/signed-integer>>,
    empty(R, 0, Count, Count, Acc1);

empty(<<?NONE, 0:?BITS/float, R/binary>>, Sum, N, Count, Acc) ->
    empty(R, Sum + 1, N-1, Count, Acc);


empty(<<_, _I:?BITS/signed-integer, R/binary>>, Sum, N, Count, Acc) ->
    empty(R, Sum, N - 1, Count, Acc);

empty(<<>>, 0, _Count, _Count, Acc) ->
    Acc;

empty(<<>>, Sum, Missing, _Count, Acc) ->
    Empty = Sum + Missing,
    <<Acc/binary, ?INT, Empty:?BITS/signed-integer>>.

avg(Data, Count) ->
    avg(Data, 0, 0, Count, Count, <<>>).

avg(R, Last, Sum, 0, Count, Acc) ->
    Avg = Sum/Count,
    Acc1 = <<Acc/binary, ?FLOAT, Avg:?BITS/float>>,
    avg(R, Last, 0, Count, Count, Acc1);
avg(<<?INT, I:?BITS/signed-integer, R/binary>>, _Last, Sum, N, Count, Acc) ->
    avg(R, I, Sum + I, N - 1, Count, Acc);

avg(<<?FLOAT, I:?BITS/float, R/binary>>, _Last, Sum, N, Count, Acc) ->
    avg(R, I, Sum + I, N - 1, Count, Acc);

avg(<<?NONE, 0:?BITS/float, R/binary>>, Last, Sum, N, Count, Acc) ->
    avg(R, Last, Sum + Last, N-1, Count, Acc);

avg(<<>>, _, 0, _Count, _Count, Acc) ->
    Acc;

avg(<<>>, _, Sum, _Missing, Count, Acc) ->
    Avg = Sum/Count,
    <<Acc/binary, ?FLOAT, Avg:?BITS/float>>.

sum(<<>>, _Count) ->
    <<>>;

sum(Data, Count) ->
    case mmath_bin:find_type(Data) of
        integer ->
            sum_int(Data, 0, 0, Count, Count, <<>>);
        float ->
            sum_float(Data, 0.0, 0.0, Count, Count, <<>>);
        undefined ->
            mmath_bin:empty(ceiling(mmath_bin:length(Data)/Count))
    end.

sum_float(R, Last, Sum, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?FLOAT, Sum:?BITS/float>>,
    sum_float(R, Last, 0.0, Count, Count, Acc1);
sum_float(<<?FLOAT, I:?BITS/float, R/binary>>, _Last, Sum, N, Count, Acc) ->
    sum_float(R, I, Sum+I, N-1, Count, Acc);
sum_float(<<?NONE, 0:?BITS/float, R/binary>>, Last, Sum, N, Count, Acc) ->
    sum_float(R, Last, Sum + Last, N-1, Count, Acc);
sum_float(<<>>, _, 0.0, _Count, _Count, Acc) ->
    Acc;
sum_float(<<>>, _, Sum, _, _, Acc) ->
    <<Acc/binary, ?FLOAT, Sum:?BITS/float>>.

sum_int(R, Last, Sum, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?INT, Sum:?BITS/signed-integer>>,
    sum_int(R, Last, 0, Count, Count, Acc1);
sum_int(<<?INT, I:?BITS/signed-integer, R/binary>>, _, Sum, N, Count, Acc) ->
    sum_int(R, I, Sum+I, N-1, Count, Acc);
sum_int(<<?NONE, 0:?BITS/signed-integer, R/binary>>, Last, Sum, N, Count, Acc) ->
    sum_int(R, Last, Sum+Last, N-1, Count, Acc);
sum_int(<<>>, _, 0, _Count, _Count, Acc) ->
    Acc;
sum_int(<<>>, _, Sum, _, _, Acc) ->
    <<Acc/binary, ?INT, Sum:?BITS/signed-integer>>.

min(<<>>, _) ->
    <<>>;
min(Data, Count) ->
    case mmath_bin:find_type(Data) of
        integer ->
            min_int(Data, undefined, Count, Count, <<>>);
        float ->
            min_float(Data, undefined, Count, Count, <<>>);
        undefined ->
            mmath_bin:empty(ceiling(mmath_bin:length(Data)/Count))
    end.

min_int(R, undefined, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?NONE, 0:?BITS/signed-integer>>,
    min_int(R, undefined, Count, Count, Acc1);
min_int(R, V, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?INT, V:?BITS/signed-integer>>,
    min_int(R, undefined, Count, Count, Acc1);
min_int(<<?INT, V:?BITS/signed-integer, R/binary>>, undefined, N, Count, Acc) ->
    min_int(R, V, N-1, Count, Acc);
min_int(<<?INT, V:?BITS/signed-integer, R/binary>>, Min, N, Count, Acc)
  when V <  Min->
    min_int(R, V, N-1, Count, Acc);
min_int(<<_, _:?BITS/signed-integer, R/binary>>, Min, N, Count, Acc) ->
    min_int(R, Min, N-1, Count, Acc);
min_int(<<>>, _, _Count, _Count, Acc) ->
    Acc;
min_int(<<>>, undefined, _, _, Acc) ->
    <<Acc/binary, ?NONE, 0:?BITS/signed-integer>>;
min_int(<<>>, Min, _, _, Acc) ->
    <<Acc/binary, ?INT, Min:?BITS/signed-integer>>.

min_float(R, undefined, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?NONE, 0:?BITS/float>>,
    min_float(R, undefined, Count, Count, Acc1);
min_float(R, V, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?FLOAT, V:?BITS/float>>,
    min_float(R, undefined, Count, Count, Acc1);
min_float(<<?FLOAT, V:?BITS/float, R/binary>>, undefined, N, Count, Acc) ->
    min_float(R, V, N-1, Count, Acc);
min_float(<<?FLOAT, V:?BITS/float, R/binary>>, Min, N, Count, Acc)
  when V <  Min->
    min_float(R, V, N-1, Count, Acc);
min_float(<<_, _:?BITS/float, R/binary>>, Min, N, Count, Acc) ->
    min_float(R, Min, N-1, Count, Acc);
min_float(<<>>, _, _Count, _Count, Acc) ->
    Acc;
min_float(<<>>, undefined, _, _, Acc) ->
    <<Acc/binary, ?NONE, 0:?BITS/float>>;
min_float(<<>>, Min, _, _, Acc) ->
    <<Acc/binary, ?FLOAT, Min:?BITS/float>>.

max(<<>>, _) ->
    <<>>;
max(Data, Count) ->
    case mmath_bin:find_type(Data) of
        integer ->
            max_int(Data, undefined, Count, Count, <<>>);
        float ->
            max_float(Data, undefined, Count, Count, <<>>);
        undefined ->
            mmath_bin:empty(ceiling(mmath_bin:length(Data)/Count))
    end.

max_int(R, undefined, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?NONE, 0:?BITS/signed-integer>>,
    max_int(R, undefined, Count, Count, Acc1);
max_int(R, V, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?INT, V:?BITS/signed-integer>>,
    max_int(R, undefined, Count, Count, Acc1);
max_int(<<?INT, V:?BITS/signed-integer, R/binary>>, undefined, N, Count, Acc) ->
    max_int(R, V, N-1, Count, Acc);
max_int(<<?INT, V:?BITS/signed-integer, R/binary>>, Max, N, Count, Acc)
  when V >  Max->
    max_int(R, V, N-1, Count, Acc);
max_int(<<_, _:?BITS/signed-integer, R/binary>>, Max, N, Count, Acc) ->
    max_int(R, Max, N-1, Count, Acc);
max_int(<<>>, _, _Count, _Count, Acc) ->
    Acc;
max_int(<<>>, undefined, _, _, Acc) ->
    <<Acc/binary, ?NONE, 0:?BITS/signed-integer>>;
max_int(<<>>, Max, _, _, Acc) ->
    <<Acc/binary, ?INT, Max:?BITS/signed-integer>>.

max_float(R, undefined, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?NONE, 0:?BITS/float>>,
    max_float(R, undefined, Count, Count, Acc1);
max_float(R, V, 0, Count, Acc) ->
    Acc1 = <<Acc/binary, ?FLOAT, V:?BITS/float>>,
    max_float(R, undefined, Count, Count, Acc1);
max_float(<<?FLOAT, V:?BITS/float, R/binary>>, undefined, N, Count, Acc) ->
    max_float(R, V, N-1, Count, Acc);
max_float(<<?FLOAT, V:?BITS/float, R/binary>>, Max, N, Count, Acc)
  when V >  Max->
    max_float(R, V, N-1, Count, Acc);
max_float(<<_, _:?BITS/float, R/binary>>, Max, N, Count, Acc) ->
    max_float(R, Max, N-1, Count, Acc);
max_float(<<>>, _, _Count, _Count, Acc) ->
    Acc;
max_float(<<>>, undefined, _, _, Acc) ->
    <<Acc/binary, ?NONE, 0:?BITS/float>>;
max_float(<<>>, Max, _, _, Acc) ->
    <<Acc/binary, ?FLOAT, Max:?BITS/float>>.

scale(<<>>, _) ->
    <<>>;
scale(Bin, Scale) ->
    case mmath_bin:find_type(Bin) of
        integer ->
            scale_int(Bin, 0, Scale, <<>>);
        float ->
            scale_float(Bin, 0, Scale, <<>>);
        undefined ->
            mmath_bin:empty(mmath_bin:length(Bin))
    end.

scale_int(<<?INT, I:?BITS/signed-integer, Rest/binary>>, _, S, Acc) ->
    scale_int(Rest, I, S, <<Acc/binary, ?INT, (round(I*S)):?BITS/signed-integer>>);
scale_int(<<?NONE, _:?BITS/integer, Rest/binary>>, I, S, Acc) ->
    scale_int(Rest, I, S, <<Acc/binary, ?INT, (round(I*S)):?BITS/signed-integer>>);
scale_int(<<>>, _, _, Acc) ->
    Acc.

scale_float(<<?FLOAT, I:?BITS/float, Rest/binary>>, _, S, Acc) ->
    scale_float(Rest, I, S, <<Acc/binary, ?FLOAT, (I*S):?BITS/float>>);
scale_float(<<?NONE, _:?BITS/integer, Rest/binary>>, I, S, Acc) ->
    scale_float(Rest, I, S, <<Acc/binary, ?FLOAT, (I*S):?BITS/float>>);
scale_float(<<>>, _, _, Acc) ->
    Acc.

derivate(<<>>) ->
    <<>>;

derivate(<<?INT, I:?BITS/signed-integer, Rest/binary>>) ->
    der_int(Rest, I, <<>>);

derivate(<<?FLOAT, I:?BITS/float, Rest/binary>>) ->
    der_float(Rest, I, <<>>);

derivate(<<?NONE, 0:?BITS/signed-integer, Rest/binary>>) ->
    case mmath_bin:find_type(Rest) of
        integer ->
            der_int(Rest, 0, <<>>);
        float ->
            der_float(Rest, 0.0, <<>>);
        undefined ->
            mmath_bin:empty(erlang:max(mmath_bin:length(Rest),0))
    end.

der_int(<<?INT, I:?BITS/signed-integer, Rest/binary>>, Last, Acc) ->
    der_int(Rest, I, <<Acc/binary, ?INT, (I - Last):?BITS/signed-integer>>);
der_int(<<?NONE, 0:?BITS/signed-integer, Rest/binary>>, Last, Acc) ->
    der_int(Rest, Last, <<Acc/binary, ?INT, 0:?BITS/signed-integer>>);
der_int(<<>>, _, Acc) ->
    Acc.

der_float(<<?FLOAT, I:?BITS/float, Rest/binary>>, Last, Acc) ->
    der_float(Rest, I, <<Acc/binary, ?FLOAT, (I - Last):?BITS/float>>);
der_float(<<?NONE, 0:?BITS/float, Rest/binary>>, Last, Acc) ->
    der_float(Rest, Last, <<Acc/binary, ?FLOAT, 0:?BITS/float>>);
der_float(<<>>, _, Acc) ->
    Acc.

ceiling(X) ->
    T = erlang:trunc(X),
    case (X - T) of
        Neg when Neg < 0 -> T;
        Pos when Pos > 0 -> T + 1;
        _ -> T
    end.
