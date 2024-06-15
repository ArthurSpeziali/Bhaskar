defmodule App.Parse do
    @operations '+-*/'
    @variables Enum.to_list(?A..?Z)
    @numbers Enum.to_list(?0..?9)
    @floats ?.
    @equals ?=


    
    @spec parse_start(char_list :: charlist()) :: any
    def parse_start(char_list), do: parse(char_list, nil)

    @spec parse(char_list :: charlist(), last :: char() | nil) :: any
    defp parse([], _last), do: []
    defp parse([char | tail], last) do

        case char do
            number when (char in @numbers) -> 
                [number | parse(tail, char)]

            _number when (char not in @numbers) and (last in @numbers) -> []


            # _variable when (char <= ?Z and char >= ?A) -> :variable
            # _operation when (char in @operations) -> :operation
            # _float when (char == ?.) -> :float
            # _equal when (char == ?=) -> :equal
        end

    end
end
