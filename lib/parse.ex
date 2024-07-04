defmodule App.Parse do
    @dialyzer {:nowarn_function, parse_start: 1, agent_updater: 2, parse_case: 2}

    @operations '*/=()'
    @signals '-+'
    @variables Enum.to_list(?A..?Z)
    @numbers Enum.to_list(?0..?9)


    
    @spec parse_start(char_list :: charlist()) :: [charlist()]
    def parse_start(char_list) do 
        char_list = auto_implement(:multiply, char_list, nil)
                    |> variable_implement(nil)

        {:ok, agent} = Agent.start(fn -> [] end)
        agent_updater(char_list, agent)

        agent_equation = Agent.get(agent, fn item -> item end)
                         |> variable_signal()

        Agent.stop(agent)
        agent_equation
    end

    
    @spec agent_updater(char_list :: charlist(), agent :: Agent.agent()) :: nil
    defp agent_updater([], _agent), do: nil
    defp agent_updater(char_list, agent) do
        set_chars = parse_case(char_list, nil)

        Agent.update(agent, fn
            item ->
                item ++ [set_chars]
        end)
        
        agent_updater(
            char_list -- set_chars,
            agent
        )
    end


    @spec parse_case(charlist(), last :: charlist() | char() | nil) :: [charlist()]
    defp parse_case([], _last), do: []
    defp parse_case([char | tail], last) do

        case char do
            float when (char == ?.) and (last in @numbers) ->
                [float | parse_case(tail, char)]

            _float when (char == ?.) -> raise(ArgumentError, "Decimal inválido")


            _number when (char not in @numbers) and (last in @numbers) -> []
            _variable when (char not in @variables) and (last in @variables) -> []

            signal when (char in @numbers or char in @variables) and (last in @signals) -> 
                [signal | parse_case(tail, char)]

            signal when (signal in @signals) and (last in @numbers or @variables) -> []

            signal when (char in @signals) and (last == nil)->
                [signal | parse_case(tail, char)]

            _signal when (char in @signals) -> raise(ArgumentError, "Sinal inválido")

            number when (char in @numbers) -> 
                [number | parse_case(tail, char)]

            variable when (char in @variables) -> 
                [variable | parse_case(tail, char)]

            signal when (char in @signals) ->
                [signal | parse_case(tail, char)]


            operation when (char in @operations) and (last == nil) -> 
                [operation]

            _operation when (char in @operations) -> []
        end

    end


    @spec insert_equation(equation :: [charlist()], to_insert :: [charlist()], parse :: non_neg_integer()) :: [charlist()]
    def insert_equation(equation, [], _parse), do: equation
    def insert_equation(equation, [head | tail]=_to_insert, parse) do
        List.insert_at(equation, parse, head)
        |> insert_equation(tail, parse + 1)
    end


    @spec drop_equation(equation :: [charlist()], start :: integer(), final :: integer()) :: [charlist()]
    def drop_equation(equation, index, repeat) when repeat > 0 do
        List.delete_at(equation, index)
        |> drop_equation(index, repeat - 1)
    end
    def drop_equation(equation, _index, _repeat), do: equation


    # @spec auto_implement(atom(), charlist(), last :: char() | nil) :: charlist()
    def auto_implement(_atom, [], _last), do: []

    def auto_implement(:multiply, [char | tail], last) do
        cond do
            (char == ?() && (last in @numbers || last in @variables) ->
                [?* | [?( | auto_implement(:multiply, tail, char)]]

            (char in @numbers || char in @variables) && ( last == ?) ) ->
                [?* | [char | auto_implement(:multiply, tail, char)]]
            
            true ->
                [char | auto_implement(:multiply, tail, char)]
        end
    end

    def auto_implement(:plus, [char | tail], last) do
        
        cond do
            char == '-' || char == '+' ->
                [next | remaing] = tail

                if List.first(next) == ?- do
                    auto_implement(:plus, tail, char)
                else
                    [
                        char ++ next
                        |
                        auto_implement(:plus, remaing, char)
                    ]
                end

            last == '-' ->
                [?- | exp] = char
                [exp]
            

            true ->
                [char | auto_implement(:plus, tail, char)]
        end
    
    end


    @spec variable_implement(charlist(), last :: char()) :: charlist()
    defp variable_implement([], _last), do: []

    defp variable_implement([char | tail], last) do
        cond do 
            (char in @numbers) && (last in @variables) ->
                [?* | [char | variable_implement(tail, char)]]

            (char in @variables) && (last in @numbers) ->
                [?* | [char | variable_implement(tail, char)]]

            true ->
                [char | variable_implement(tail, char)]
        end
    end


    @spec variable_implement(charlist(), last :: char()) :: charlist()
    defp variable_signal([]), do: []

    defp variable_signal([ [signal, var] | tail]) when var in @variables do
        [[signal, var] | variable_signal(tail)]
    end
    defp variable_signal([ [var] | tail]) when var in @variables do
        [[?+, var] | variable_signal(tail)]
    end
    defp variable_signal([exp | tail]) do
        [exp | variable_signal(tail)]
    end
end
