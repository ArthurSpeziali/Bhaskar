defmodule App.Sintax do
    @operators ['/', '*']

    @spec sintax_resolver(equation :: [charlist()]) :: any()
    def sintax_resolver(equation) do

        cond do
            bracket_resolver(:bool, equation) -> 
                sintax_resolver(
                    bracket_resolver(equation)
                )
            
            operator_resolver(:bool, equation) ->
                sintax_resolver(
                    operator_resolver(equation)
                )

            true -> 
                App.Math.resolve(equation)
        end
        
    end

    
    # @spec sintax_verify(atom(), [charlist()], count :: non_neg_integer()) :: false | {integer(), integer()}
    def sintax_verify(:bracket_pair, [], _equation, count), do: count - 2
    def sintax_verify(_atom, [], _equation, _count), do: false

    def sintax_verify(:bracket_begin, [exp | tail], equation, count) do
        if exp == '(' do

            bracket_end = sintax_verify(:bracket_end, tail, equation, count + 1)
            if bracket_end do
                {count, bracket_end}
            else
                false
            end

        else
            sintax_verify(:bracket_begin, tail, equation, count + 1)
        end
    end

    def sintax_verify(:bracket_end, [exp | tail], equation, count) do

        cond do
            exp == ')' -> 
                count - 1

            exp == '(' ->
                sintax_verify(:bracket_pair, tail, equation, count + 1)
                
            true ->
                sintax_verify(:bracket_end, tail, equation, count + 1)
        end

    end

    def sintax_verify(:bracket_pair, [exp | tail], equation, count) do
        index_value = Enum.find_index(
            [exp | tail],
            &(&1 == ')')
        )

        if index_value do
            remaing = App.Parse.drop_equation(
                [exp | tail],
                0,
                index_value + 1
            )
            count = count + index_value

            sintax_verify(:bracket_pair, remaing, equation, count + 1)
        else
            count - 2
        end

    end


    def sintax_verify(:operator, [exp | tail], _equation, count) do
        if exp in @operators do
            count
        else
            sintax_verify(:operator, tail, nil, count + 1)
        end
    end


    @spec bracket_finder(charlist(), count :: integer()) :: nil
    def bracket_finder([], count) do
        if count != 0, do: raise(ArgumentError, "Parenteses inválidos #{count}")
    end

    def bracket_finder([char | tail], count) when count >= 0 do
        
        if char == ?( do 
            bracket_finder(tail, count + 1)
        else
            bracket_finder(tail, count - 1)
        end

    end

    def bracket_finder(_equation, _count), do: raise(ArgumentError, "Parenteses inválidos")


    @spec bracket_resolver(:bool, equation :: [charlist()]) :: false | any()
    def bracket_resolver(:bool, equation) do
        sintax_verify(:bracket_begin, equation, equation, 0)
    end

    @spec bracket_resolver(equation :: [charlist()]) :: [charlist()]
    def bracket_resolver(equation) do
        brackets = sintax_verify(:bracket_begin, equation, equation, 0)
        
        if brackets do
            List.flatten(equation)
            |> Enum.filter(
                &(&1 == ?( or &1 == ?))
            ) |> bracket_finder(0)


            {start, final} = brackets
            result = Enum.slice(
                equation,
                start+1..final
            ) |> App.Sintax.sintax_resolver()

            App.Parse.drop_equation(equation, start, final + 2 - start)
            |> App.Parse.insert_equation(result, start)
        else
            false
        end

    end


    @spec operator_resolver(:bool, equation :: [charlist()]) :: false | any()
    def operator_resolver(:bool, equation) do
        sintax_verify(:operator, equation, equation, 0)
    end
    
    @spec operator_resolver(equation :: [charlist()]) :: [charlist()] | false
    def operator_resolver(equation) do
        operators = sintax_verify(:operator, equation, equation, 0)

        if operators do
            result = App.Math.resolve_multiply(equation, operators)

            App.Parse.drop_equation(equation, operators - 1, 3)
            |> App.Parse.insert_equation(result, operators - 1)
        else
            false
        end

    end
end
