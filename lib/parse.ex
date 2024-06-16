defmodule App.Parse do
    @operations '*/'
    @signals '-+'
    @variables Enum.to_list(?A..?Z)
    @numbers Enum.to_list(?0..?9)


    
    @spec parse_start(char_list :: charlist()) :: any
    def parse_start(char_list) do 

        {:ok, agent} = Agent.start(fn -> [] end)
        agent_updater(char_list, agent)

        Agent.get(agent, fn item -> item end)
        |> inspect
        |> IO.puts
        Agent.stop(agent)
    end

    
    @spec agent_updater(char_list :: charlist(), agent :: Agent.agent()) :: any
    defp agent_updater([], _agent), do: nil
    defp agent_updater(char_list, agent) do
        set_chars = parse_case(char_list, nil)

        Agent.update(agent, fn
            item ->

                if List.last(set_chars) == ?* && length(set_chars) > 1 do
                    item ++ [(set_chars -- '*')] ++ ['*']
                else
                    item ++ [set_chars]
                end
        end)

        agent_updater(
            char_list -- set_chars,
            agent
        )
    end


    @spec parse_case(char_list :: charlist(), last :: char() | nil) :: any
    defp parse_case([], _last), do: []
    defp parse_case([char | tail], last) do

        case char do
            _number when (char in @variables) and (last in @numbers) ->
                '*'

            _variable when (char in @numbers) and (last in @variables) ->
                '*'

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

            operation when (char in @operations) and (last == nil) -> [operation]
            _operation when (char in @operations) -> []



            # _operation when (char in @operations) -> :operation
            # _float when (char == ?.) -> :float
            # _equal when (char == ?=) -> :equal

            # _different when (last != nil) and (char != last) -> []
        end

    end
end
