defmodule App.Sintax do
    @operators ['/', '*']

    @spec sintax_resolver(equation :: [charlist()]) :: any()
    def sintax_resolver(equation) do

        cond do
            bracket_resolver(equation) -> 
                sintax_resolver(
                    bracket_resolver(equation)
                )
            
            operator_resolver(equation) ->
                sintax_resolver(
                    operator_resolver(equation)
                )

            true -> 
                App.Math.resolve(equation)
        end
        
    end

    
    # @spec sintax_verify(atom(), [charlist()], count :: non_neg_integer()) :: false | {integer(), integer()}
    defp sintax_verify(_atom, [], _equation, _count), do: false

    defp sintax_verify(:bracket_begin, [exp | tail], equation, count) do
        if exp == '(' do

            bracket_end = sintax_verify(:bracket_end, tail, equation, count)
            if bracket_end do
                {count, bracket_end}
            else
                false
            end

        else
            sintax_verify(:bracket_begin, tail, equation, count + 1)
        end
    end

    defp sintax_verify(:bracket_end, [exp | tail], equation, count) do

        cond do
            exp == ')' -> 
                count

            exp == '(' ->
                close = sintax_verify(:bracket_end, tail, equation, count)
                result = Enum.slice(equation, close..-1)
                sintax_verify(:bracket_end, result, equation, close)
                
            true ->
                sintax_verify(:bracket_end, tail, equation, count + 1)
        end

    end


    defp sintax_verify(:operator, [exp | tail], _equation, count) do
        if exp in @operators do
            count
        else
            sintax_verify(:operator, tail, nil, count + 1)
        end
    end


    @spec bracket_finder(charlist(), count :: integer()) :: nil
    defp bracket_finder(equation, count \\ 0)
    defp bracket_finder([], count) do
        if count != 0, do: raise(ArgumentError, "Parenteses inválidos")
    end

    defp bracket_finder([char | tail], count) when count >= 0 do
        
        if char == ?( do 
            bracket_finder(tail, count + 1)
        else
            bracket_finder(tail, count - 1)
        end

    end

    defp bracket_finder(_equation, _count), do: raise(ArgumentError, "Parenteses inválidos")



    @spec bracket_resolver(equation :: [charlist()]) :: [charlist()]
    defp bracket_resolver(equation) do
        brackets = sintax_verify(:bracket_begin, equation, equation, 0)
        
        if brackets do
            List.flatten(equation)
            |> Enum.filter(
                &(&1 == ?( or &1 == ?))
            ) |> bracket_finder()


            # Aqui o Dialyzer's não ajuda :/
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

    
    @spec operator_resolver(equation :: [charlist()]) :: [charlist()] | false
    defp operator_resolver(equation) do
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
