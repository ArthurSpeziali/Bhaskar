defmodule App.Variable do
    @dialyzer {:nowarn_function, assign: 2, invert_signal: 1}

    @variables Enum.to_list(?A..?Z)
    @signals '-+'

    @spec assign(left :: [charlist()], right :: charlist()) :: false | [charlist()]
    def assign(left, right) do
        variables = find_variable(left, 0)

        if variables do
            {char, count} = variables
            char = invert_signal(char)

            calculate = App.Parse.drop_equation(left, count, 1)
                ++
                [invert_signal(right)]



            if List.first(char) == ?- do
                calculate = invert_signal(
                   App.Sintax.sintax_resolver(calculate)
                   |> List.first()
                )

                calculate
            else
                App.Sintax.sintax_resolver(calculate)
            end
            
        else
            false
        end

    end


    @spec find_variable(equation :: [charlist()], count :: pos_integer()) :: false | {charlist(), pos_integer()}
    def find_variable([], _count), do: false

    def find_variable([ [exp] | _], count) when exp in @variables do
        {[?+, exp], count}
    end
    def find_variable([ [signal, exp] | _], count) when (signal in @signals) and (exp in @variables) do
        {[signal, exp], count}
    end
    def find_variable([_ | tail], count) do
        find_variable(tail, count + 1)
    end


    @spec invert_signal(exp :: charlist()) :: charlist()
    defp invert_signal(exp) do
        signal = List.first(exp)

        if signal == ?- do
            '+' ++ (exp -- '-')
        else
            '-' ++ (exp -- '+')
        end
    end

end
