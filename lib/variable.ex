defmodule App.Variable do
    @variables Enum.to_list(?A..?Z)
    @signals '-+'

    @spec assign(left :: [charlist()], right :: [charlist()]) :: any()
    def assign(left, right) do
        variables = find_variable(left, 0)

        if variables do
            {char, count} = variables
            char = invert_signal([char])

            calculate = App.Parse.drop_equation(left, count, 1)
                ++
                [invert_signal(right)]


            if List.first(char) == ?- do
                char = invert_signal([char])
                calculate = [invert_signal(
                    App.Sintax.sintax_resolver(calculate)
                )]

                {char, calculate}
            else
                {char, App.Sintax.sintax_resolver(calculate)}
            end
            
        else
            false
        end

    end


    # @spec find_variable(equation :: [charlist()], count :: pos_integer()) :: false | {charlist(), pos_integer()}
    defp find_variable([], _count), do: false

    defp find_variable([ [exp] | _], count) when exp in @variables do
        {[?+, exp], count}
    end
    defp find_variable([ [signal, exp] | _], count) when (signal in @signals) and (exp in @variables) do
        {[signal, exp], count}
    end
    defp find_variable([_ | tail], count) do
        find_variable(tail, count + 1)
    end


    def invert_signal([char]) do
        signal = List.first(char)

        if signal in @signals do
            
            if signal == ?+ do
                '-' ++ (char -- '+')
            else
                '+' ++ (char -- '-')
            end

        else
            [?- | char]
        end

    end

end
