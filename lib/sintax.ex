defmodule App.Sintax do
    @dialyzer {:nowarn_function, variable_resolver: 2, variable_resolver: 3, sintax_verify: 4, sintax_main: 2, sintax_resolver: 1, bracket_finder: 2, bracket_resolver: 2, operator_resolver: 2, bracket_resolver: 1, operator_resolver: 1, equal_resolver: 2, equal_resolver: 1, powroot_resolver: 1, powroot_resolver: 2, log_resolver: 1, log_resolver: 2, variable_index: 1}

    @operators [~c"/", ~c"*"]
    @type equation_type() :: [charlist()]

    
    @spec sintax_main(list_equation :: [equation_type()], :agent | Agent.agent()) :: [equation_type()]
    def sintax_main(list_equation, :agent) do
        {:ok, agent} = Agent.start(fn -> %{} end)
        sintax_main(list_equation, agent)
    end
    
    def sintax_main(list_equation, agent) do
        result = 
            for item <- list_equation do
                item = App.Variable.get_variable(item, agent)

                item = 
                    if variable_resolver(:bool, item, agent) || variable_index(item) do
                        variable_resolver(item, agent)
                    else 
                        item
                    end
                sintax_resolver(item)
            end

        {agent, result}
    end


    @spec sintax_resolver(equation :: equation_type()) :: equation_type()
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

            log_resolver(:bool, equation) ->
                sintax_resolver(
                    log_resolver(equation)
                )

            powroot_resolver(:bool, equation) ->
                sintax_resolver(
                    powroot_resolver(equation)
                )

            operator_resolver(:bool, equation) ->
                sintax_resolver(
                    operator_resolver(equation)
                )

            true -> 
                App.Math.resolve(equation)
        end
        
    end

    
    @spec sintax_verify(atom(), equation_type(), equation :: equation_type(), count :: non_neg_integer()) :: any()
    defp sintax_verify(:bracket_pair, [], _equation, count), do: count - 2
    defp sintax_verify(_atom, [], _equation, _count), do: false

    defp sintax_verify(:bracket_begin, [exp | tail], equation, count) do
        if exp == ~c"(" do

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
            exp == ~c")" -> 
                count - 1

            exp == ~c"(" ->
                sintax_verify(:bracket_pair, tail, equation, count + 1)
                
            true ->
                sintax_verify(:bracket_end, tail, equation, count + 1)
        end

    end

    defp sintax_verify(:bracket_pair, [exp | tail], equation, count) do
        index_value = Enum.find_index(
            [exp | tail],
            &(&1 == ~c")")
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
        equal_value = Enum.find_index(
            [exp | tail],
            &(&1 == ~c"=")
        )

        if equal_value do
            frequencies = Enum.frequencies([exp | tail])
            if frequencies[~c"="] > 1, do: raise(ArgumentError, "Mais de um sinal de igual")


            left = Enum.slice(
                [exp | tail],
                0..equal_value - 1//1
            )
            right = Enum.slice(
                [exp | tail],
                equal_value + 1..-1//1
            )

            {left, right}
        else
            false
        end
    end

    defp sintax_verify(:powroot, equation, _equation, _count) do
        pow = Enum.find_index(equation, fn item ->
            item == ~c"^"
        end)

        index = App.Parse.index_find(equation, 0)

        {root, value} = 
            if index do
                {func, value} = App.Parse.extract_index(
                    Enum.at(equation, index)
                )    

                if func == ?{ do
                    {index, value}
                else
                    {nil, nil}
                end

        else
            {nil, nil}
        end


        case {pow, root} do
            {nil, nil} -> false
            {_, nil} -> {:pow, pow, value}
            {nil, _} -> {:root, root, value}

            {_, _} ->
                if pow < root do
                    {:pow, pow, value}
                else
                    {:root, root, value}
                end
        end

    end
    
    
    defp sintax_verify(:log, equation, _equation, _count) do
        index = Enum.find_index(equation, fn item ->
            Enum.slice(
                item,
                -2..-1//1
            ) == ~c">\\"

        end)


        if index do
            {logarithm, base} = App.Parse.extract_index(
                Enum.at(equation, index)
            )

            if logarithm == ?\\ do
                final = Enum.find_index(equation, fn item -> 
                    item == ~c"\\"
                end)


                {index, base, final}
            else
                false
            end

        else
            false
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


    @spec bracket_resolver(:bool, equation :: equation_type()) :: false | any()
    def bracket_resolver(:bool, equation) do
        sintax_verify(:bracket_begin, equation, equation, 0)
    end

    @spec bracket_resolver(equation :: equation_type()) :: equation_type()
    def bracket_resolver(equation) do
        brackets = sintax_verify(:bracket_begin, equation, equation, 0)
        
        List.flatten(equation)
        |> Enum.filter(
            &(&1 == ?( or &1 == ?))
        ) |> bracket_finder(0)


        {start, final} = brackets
        result = Enum.slice(
            equation,
            start+1..final//1
        ) |> App.Sintax.sintax_resolver()

        App.Parse.drop_equation(equation, start, final + 2 - start)
        |> App.Parse.insert_equation(start, result)
    end


    @spec operator_resolver(:bool, equation :: equation_type()) :: false | any()
    def operator_resolver(:bool, equation) do
        sintax_verify(:operator, equation, equation, 0)
    end
    
    @spec operator_resolver(equation :: equation_type()) :: equation_type() | false
    def operator_resolver(equation) do
        operators = sintax_verify(:operator, equation, equation, 0)

        result = App.Math.resolve_multiply(equation, operators)

        App.Parse.drop_equation(equation, operators - 1, 3)
        |> App.Parse.insert_equation(operators - 1, result)
    end


    @spec equal_resolver(:bool, equation :: equation_type()) :: false | any()
    defp equal_resolver(:bool, equation) do
        sintax_verify(:equal, equation, equation, 0)
    end

    @spec equal_resolver(equation :: equation_type()) :: any()
    defp equal_resolver(equation) do
        equals = sintax_verify(:equal, equation, equation, 0)
        
        {left, right} = equals

        left_resolve = App.Sintax.sintax_resolver(left)
                       |> List.first()
                       |> App.Math.to_number()

        right_resolve = App.Sintax.sintax_resolver(right)
                        |> List.first()
                        |> App.Math.to_number()

        if left_resolve / 1 != right_resolve / 1, do: App.Errors.invalid_equality(equation)

        [App.Math.to_charlist(left_resolve)]
    end


    @spec variable_resolver(:bool, equation :: equation_type(), agent :: Agent.agent()) :: false | any()
    def variable_resolver(:bool, equation, _agent) do
        App.Variable.find_variable(equation, 0)
    end

    @spec variable_resolver(equation :: equation_type(), agent :: Agent.agent()) :: equation_type()
    def variable_resolver(equation, agent) do
        variables = App.Variable.find_variable(equation, 0)
        variables = if !variables do

            count = variable_index(equation)
            {_, char} = App.Parse.extract_index(
                Enum.at(equation, count)
            )

            {char, count}
        else
            variables
        end

        {char, _count} = variables
        equals = equal_resolver(:bool, equation)

        if !equals, do: raise(ArgumentError, "Valor de #{char} não foi encontrado")
        {left, right} = equals

        {operation, value} = cond do
            (char in left) && (char in right) ->
                raise(ArgumentError, "Valor de #{char} não foi encontrado")

            char in left ->
                {left, right}

            char in right ->
                {right, left}


            variable_index(left) && variable_index(right) ->
                raise(ArgumentError, "Valor de #{char} não foi encontrado")

            variable_index(left) ->
                {left, right}

            variable_index(right) ->
                {right, left}

        end

        [value] = App.Sintax.sintax_resolver(value)
        variable_value = App.Variable.assign(operation, value)
                         |> List.first()
                         |> App.Math.to_number()
        variable_value = variable_value / 1
                         |> App.Math.to_charlist()
                         |> App.Variable.invert_signal()
                         |> App.Variable.invert_signal()


        char = List.replace_at(char, 0, ?+)
        
        Agent.update(
            agent,
            fn item ->
                Map.put(
                    item,
                    char,
                    [variable_value]
                )
            end)

        [value]
    end


    @spec powroot_resolver(:bool, powroot_resolver :: equation_type()) :: equation_type()
    def powroot_resolver(:bool, equation) do
        sintax_verify(:powroot, equation, equation, 0)
    end

    @spec powroot_resolver(equation :: equation_type()) :: equation_type()
    def powroot_resolver(equation) do
        {powroots, count, value} = sintax_verify(:powroot, equation, equation, 0)
        
        if powroots == :pow do
            previous = App.Math.to_number(
                Enum.at(equation, count - 1)
            )


            number? = List.to_string(
                Enum.at(equation, count + 1)
            ) |> Float.parse()

            case number? do
                {_float, ""} -> false
                {_float, _string} -> App.Errors.invalid_operator(equation, count)
                :error -> App.Errors.invalid_operator(equation, count)
            end


            next = App.Math.to_number(
                Enum.at(equation, count + 1)
            )
            result = [App.Math.to_charlist(previous ** next)]

            App.Parse.drop_equation(equation, count - 1, 3)
            |> App.Parse.insert_equation(count - 1, result)


        else
            final = Enum.find_index(equation, fn item ->
                item == ~c"}"
            end)
            if final == nil, do: raise(ArgumentError, "Fim da raiz não encontrada")

            [operation] = Enum.slice(equation, count + 1..final - 1//1)
                     |> sintax_resolver()

            result = App.Math.to_number(operation)
                     |> App.Math.root(
                            App.Math.to_number(value)
                     ) |> App.Math.to_charlist()

            App.Parse.drop_equation(
                equation,
                count,
                final - (count - 1)
            ) |> App.Parse.insert_equation(count, [result]) 

        end
    end


    @spec log_resolver(:bool, equation :: equation_type()) :: false | tuple()
    def log_resolver(:bool, equation) do
        sintax_verify(:log, equation, equation, 0)
    end

    @spec log_resolver(equation :: equation_type()) :: equation_type()
    def log_resolver(equation) do
        {index, base, final} = sintax_verify(:log, equation, equation, 0)

        [value] = sintax_resolver(
            Enum.slice(equation, index + 1..final - 1)
        )

        value = App.Math.to_number(value)
        base = App.Math.to_number(base)
        
        result = App.Math.log(value, base)
                 |> App.Math.to_charlist()

        App.Parse.drop_equation(equation, index, final - (index - 1))
        |> App.Parse.insert_equation(index, [result])
    end


    @spec variable_index(equation :: equation_type()) :: false | integer()
    def variable_index(equation) do
        {:ok, agent} = Agent.start(fn -> %{} end)
        index = App.Parse.index_find(equation, 0)

        if index do
            {_func, value} = Enum.at(equation, index)
                          |> App.Parse.extract_index()

            if variable_resolver(:bool, [value], agent) do
                index
            else
                false
            end

        else
            false
        end

    end

end
