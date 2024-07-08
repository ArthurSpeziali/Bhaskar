defmodule App.Sintax do
    @dialyzer {:nowarn_function, variable_resolver: 2, variable_resolver: 3, sintax_verify: 4, sintax_main: 2, sintax_resolver: 1, bracket_finder: 2, bracket_resolver: 2, operator_resolver: 2, bracket_resolver: 1, operator_resolver: 1, equal_resolver: 2, equal_resolver: 1}

    @operators ['/', '*']
    @exroot ['^']
    @type equation_type :: [charlist()]

    
    @spec sintax_main(list_equation :: [equation_type], :agent | Agent.agent()) :: [equation_type]
    def sintax_main(list_equation, :agent) do
        {:ok, agent} = Agent.start(fn -> %{} end)
        sintax_main(list_equation, agent)
    end
    
    def sintax_main(list_equation, agent) do
        result = 
            for item <- list_equation do
                item = App.Variable.get_variable(item, agent)

                item = 
                    if variable_resolver(:bool, item, agent) do
                        variable_resolver(item, agent)
                    else
                        item
                    end

                sintax_resolver(item)
            end

        {agent, result}
    end


    @spec sintax_resolver(equation :: equation_type) :: equation_type
    def sintax_resolver(equation) do
        cond do
            variable_resolver(:bool, equation, nil) ->
                raise(ArgumentError, "Valor de váriaveis não especificadas")

            equal_resolver(:bool, equation) ->
                equal_resolver(equation)

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

    
    @spec sintax_verify(atom(), equation_type, equation :: equation_type, count :: non_neg_integer()) :: any()
    defp sintax_verify(:bracket_pair, [], _equation, count), do: count - 2
    defp sintax_verify(_atom, [], _equation, _count), do: false

    defp sintax_verify(:bracket_begin, [exp | tail], equation, count) do
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

    defp sintax_verify(:bracket_end, [exp | tail], equation, count) do

        cond do
            exp == ')' -> 
                count - 1

            exp == '(' ->
                sintax_verify(:bracket_pair, tail, equation, count + 1)
                
            true ->
                sintax_verify(:bracket_end, tail, equation, count + 1)
        end

    end

    defp sintax_verify(:bracket_pair, [exp | tail], equation, count) do
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


    defp sintax_verify(:operator, [exp | tail], _equation, count) do
        if exp in @operators do
            count
        else
            sintax_verify(:operator, tail, nil, count + 1)
        end
    end

    defp sintax_verify(:equal, [exp | tail], _equation, _count) do
        index_value = Enum.find_index(
            [exp | tail],
            &(&1 == '=')
        )

        if index_value do
            frequencies = Enum.frequencies([exp | tail])
            if frequencies['='] > 1, do: raise(ArgumentError, "Mais de um sinal de igual")


            left = Enum.slice(
                [exp | tail],
                0..index_value - 1
            )
            right = Enum.slice(
                [exp | tail],
                index_value + 1..-1
            )

            {left, right}
        else
            false
        end
    end

    defp sintax_verify(:exroot, [exp | tail], equation, count) do
        if exp in @exroot do
            count
        else
            sintax_verify(:exroot, tail, equation, count + 1)
        end
    end
    


    @spec bracket_finder(charlist(), count :: integer()) :: nil
    defp bracket_finder([], count) do
        if count != 0, do: raise(ArgumentError, "Parenteses inválidos #{count}")
    end

    defp bracket_finder([char | tail], count) when count >= 0 do
        
        if char == ?( do 
            bracket_finder(tail, count + 1)
        else
            bracket_finder(tail, count - 1)
        end

    end

    defp bracket_finder(_equation, _count), do: raise(ArgumentError, "Parenteses inválidos")


    @spec bracket_resolver(:bool, equation :: equation_type) :: false | any()
    def bracket_resolver(:bool, equation) do
        sintax_verify(:bracket_begin, equation, equation, 0)
    end

    @spec bracket_resolver(equation :: equation_type) :: equation_type
    def bracket_resolver(equation) do
        brackets = sintax_verify(:bracket_begin, equation, equation, 0)
        
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
    end


    @spec operator_resolver(:bool, equation :: equation_type) :: false | any()
    def operator_resolver(:bool, equation) do
        sintax_verify(:operator, equation, equation, 0)
    end
    
    @spec operator_resolver(equation :: equation_type) :: equation_type | false
    def operator_resolver(equation) do
        operators = sintax_verify(:operator, equation, equation, 0)

        result = App.Math.resolve_multiply(equation, operators)

        App.Parse.drop_equation(equation, operators - 1, 3)
        |> App.Parse.insert_equation(result, operators - 1)
    end


    @spec equal_resolver(:bool, equation :: equation_type) :: false | any()
    defp equal_resolver(:bool, equation) do
        sintax_verify(:equal, equation, equation, 0)
    end

    @spec equal_resolver(equation :: equation_type) :: any()
    defp equal_resolver(equation) do
        equals = sintax_verify(:equal, equation, equation, 0)
        
        {left, right} = equals

        left_resolve = App.Sintax.sintax_resolver(left)
        right_resolve = App.Sintax.sintax_resolver(right)

        if left_resolve != right_resolve, do: raise(ArgumentError, "Igualdade não equivalente dos dois lados")

        left_resolve
    end


    @spec variable_resolver(:bool, equation :: equation_type, agent :: Agent.agent()) :: false | any()
    def variable_resolver(:bool, equation, _agent) do
        App.Variable.find_variable(equation, 0)
    end

    @spec variable_resolver(equation :: equation_type, agent :: Agent.agent()) :: equation_type
    def variable_resolver(equation, agent) do
        variables = App.Variable.find_variable(equation, 0)

        {char, _count} = variables
        equals = equal_resolver(:bool, equation)

        if !equals, do: raise(ArgumentError, "Valor de #{char} não foi encontrado")
        {left, right} = equals

        {operation, value} = cond do
            char in left ->
                {left, right}

            char in right ->
                {right, left}

            (char in left) && (char in right) ->
                raise(ArgumentError, "Valor de #{char} não foi encontrado")
        end

        [value] = App.Sintax.sintax_resolver(value)
        variable_value = App.Variable.assign(operation, value)
        char = List.replace_at(char, 0, ?+)
        
        Agent.update(
            agent,
            fn item ->
                Map.put(
                    item,
                    char,
                    variable_value)
            end)

        [value]
    end


    def exroot_resolver(:bool, equation) do
        sintax_verify(:exroot, equation, equation, 0)
    end

    def exroot_resolver(equation) do
        exroots = sintax_verify(:exroot, equation, equation, 0)

        if Enum.at(equation, exroots) == '^' do

        else
            # root_finder
        end

    end
end
