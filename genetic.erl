-module(genetic).
-compile(export_all).
-import(random, [uniform/0, uniform/1]).
-import(lists, [nth/2, map/2, zip/2]).

select(A) -> nth(uniform(length(A)), A).

generate_node(Vars) ->
    case uniform(3) of
         1 -> {number, uniform()};
         2 -> {var, select(Vars)};
         _ -> {select([add,subtract,multiply,divide]),
               generate_node(Vars), generate_node(Vars)}
    end.

generate_averages() ->
    map(fun(_) -> generate_average() end, lists:seq(1, 1000)).

generate_average() ->
    First = uniform(100),
    Second = uniform(100),
    Average = (First + Second) / 2,
    {[First, Second], Average}.

calculate_fitness(Training, Vars, Function) ->
    lists:sum(map(fun(T) -> calculate_accuracy(Vars, T, Function) end, Training)).

calculate_accuracy(Vars, {Inputs, A}, Function) ->
    Result = evaluate(Function, dict:from_list(zip(Vars, Inputs))),
    case Result of
        nan -> -100000000;
        _ -> -abs(A - Result)
    end.

evaluate_operator(_, nan, _) -> nan;
evaluate_operator(_, _, nan) -> nan;
evaluate_operator(add, First, Second) -> First + Second;
evaluate_operator(subtract, First, Second) -> First - Second;
evaluate_operator(multiply, First, Second) -> First * Second;
evaluate_operator(divide, _, 0.0) -> nan;
evaluate_operator(divide, _, 0) -> nan;
evaluate_operator(divide, First, Second) -> First / Second.

evaluate({number, Value}, _) -> Value;
evaluate({var, InputName}, BoundInputs) -> dict:fetch(InputName, BoundInputs);
evaluate({Operator, First, Second}, BoundInputs) ->
    evaluate_operator(Operator, evaluate(First, BoundInputs), evaluate(Second, BoundInputs)).


generate_best_function(Training, Vars) ->
    Generation = map(fun(_) -> generate_node(Vars) end, lists:seq(1, 5000)),
    Results = map(fun(G) -> {G, calculate_fitness(Training, Vars, G)} end, Generation),
    lists:sublist(lists:sort(fun ({_, A}, {_, B}) -> A > B end, Results), 5).

generate_average_function() ->
    Training = generate_averages(),
    generate_best_function(Training, [a, b]).
