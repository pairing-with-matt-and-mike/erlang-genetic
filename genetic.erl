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
    By_fitness = generation_by_fitness(Training, Vars, Generation),
    lists:sublist(By_fitness, 5).

generation_by_fitness(Training, Vars, Generation) ->
    Results = map(fun(G) -> {G, calculate_fitness(Training, Vars, G)} end, Generation),
    lists:sort(fun ({_, A}, {_, B}) -> A > B end, Results).


generate_average_function() ->
    Training = generate_averages(),
    generate_best_function(Training, [a, b]).


mutate_function({number, _}, Vars) -> generate_node(Vars);
mutate_function({var, _}, Vars) -> generate_node(Vars);
mutate_function({Operator, Left, Right}, Vars) ->
    New_node = generate_node(Vars),
    case uniform(5) of
         1 -> {Operator, New_node, Right};
         2 -> {Operator, Left, New_node};
         3 -> Left;
         4 -> Right;
         _ -> New_node
    end.

generate_average_function_mutation(GenerateGeneration) ->
    Training = generate_averages(),
    Vars = [a, b],
    Initial = generate_node(Vars),
    lists:foldl(
        fun(_, Parent) ->
           Generation = GenerateGeneration(Parent, Vars),
           [{Winner, _}|_] = generation_by_fitness(Training, Vars, Generation),
           Winner
        end,
        Initial,
        lists:seq(1, 1000)
    ).


generate_mutant_generation(Depth, Parent, Vars) ->
    lists:foldl(
        fun(_, Ancestors) ->
            [mutate_function(hd(Ancestors), Vars)|Ancestors]
        end,
        [Parent],
        lists:seq(1, Depth)
    ).

go(Depth) ->
    generate_average_function_mutation(fun(Parent, Vars) ->
        generate_mutant_generation(Depth, Parent, Vars)
    end).
