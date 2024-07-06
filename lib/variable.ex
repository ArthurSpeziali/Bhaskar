defmodule App.Variable do
    @dialyzer {:nowarn_function, assign: 2, invert_signal: 1, swap_variable: 3, get_variable: 2, variable_plus: 3}

    @type equation_type :: [charlist()]
    @variables Enum.to_list(?A..?Z)
    @numbers Enum.to_list(?0..?9)
    @signals '-+'
    @operators ['/', '*']


    @spec variable_multiply(equation :: equation_type) :: equation_type
    def variable_multiply(equation) do
        disable_operator = fn operator ->
            if operator == '/' do
                'd'
            else
                'm'
            end
        end

        operations = App.Sintax.operator_resolver(:bool, equation)
        if operations do

            previous = Enum.at(equation, operations - 1)
            next = Enum.at(equation, operations + 1)
            operator = Enum.at(equation, operations)

            remaing = App.Parse.drop_equation(equation, operations - 1, 3)
            if (List.last(previous) not in @variables) && (List.last(next) not in @variables) do
                charset = [previous | [operator | [next]]]
                result = App.Sintax.operator_resolver(charset)
                
                variable_multiply(
                    App.Parse.insert_equation(
                        remaing,
                        result,
                        operations - 1
                    )
                )
                
            else
                charset = [previous | [disable_operator.(operator) | [next]]]
                variable_multiply(
                    App.Parse.insert_equation(
                        remaing,
                        charset,
                        operations - 1
                    )
                )

            end

        else

            Enum.map(equation, fn exp ->
                case exp do
                    'd' -> '/'
                    'm' -> '*'
                    _ -> exp
                end
            end)

        end

    end


    @spec variable_plus(equation_type, right :: equation_type, left :: equation_type) :: equation_type
    def variable_plus([], right, left), do: {right, left}
    def variable_plus([exp | tail], right, left) do
        next =
            if tail != [] do
                [next | _] = tail
                next
            else
                []
            end
       

        if (List.last(exp) in @numbers) and (next not in @operators) do
           variable_plus(
               tail,
               App.Sintax.sintax_resolver(
                   right
                   ++
                   [invert_signal(exp)]
               ),
               left
           )

        else
            variable_plus(tail, right, left ++ [exp])
        end

    end


    @spec variable_operator(equation_type, right :: equation_type) :: equation_type
    def variable_operator([], right), do: right
    def variable_operator([exp | tail], right) do
        [next, remaing] =
            if tail != [] do
                [next | remaing] = tail
                [next, remaing]
            else
                [[], []]
            end


        cond do
            List.last(exp) in @numbers ->
                variable_operator(
                    remaing,
                    [exp, next] ++ right
                )

            
            List.last(exp) in @variables ->
                variable_operator(tail, right)


            exp in @operators ->
                variable_operator(
                    remaing,
                    [next, exp] ++ right
                )

        end

    end
    


    @spec assign(left :: equation_type, right :: charlist()) :: false | equation_type
    def assign(left, right) do
        variables = find_variable(left, 0)
        {char, count} = variables
        operators = App.Sintax.operator_resolver(:bool, left)
        brackets = App.Sintax.bracket_resolver(:bool, left)

        cond do
             brackets ->
                {start, final} = brackets
                operation = Enum.slice(left, start+1..final)

                for item <- operation do
                    if List.last(item) in @variables, do: raise(ArgumentError, "Não é permitido váriaveis sem valor dentro de parênteses")
                end

                
                result = App.Sintax.bracket_resolver(left)
                assign(
                    App.Parse.auto_implement(:plus, result, nil),
                    right
                )


            operators ->
                left = variable_multiply(left)
                {right, left} = variable_plus(left, [right], [])

                [operation] = variable_operator(left, right)
                              |> App.Sintax.sintax_resolver()
    

                if List.first(char) == ?- do
                    [invert_signal(operation)]
                else
                    [operation]
                end


            variables ->
                char = invert_signal(char)

                calculate = App.Parse.drop_equation(left, count, 1)
                    ++
                    [invert_signal(right)]


                if List.first(char) == ?- do
                    calculate = invert_signal(
                       App.Sintax.sintax_resolver(calculate)
                       |> List.first()
                    )

                    [calculate]
                else
                    App.Sintax.sintax_resolver(calculate)
                end


            true ->
                false
        end

    end


    @spec find_variable(equation :: equation_type, count :: pos_integer()) :: false | {charlist(), pos_integer()}
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



    @spec get_variable(equation :: equation_type, agent :: Agent.agent()) :: equation_type
    def get_variable(equation, agent) do
        variables = App.Sintax.variable_resolver(:bool, equation, agent)

        if variables do
            {char, _count} = variables

            char = if List.first(char) == ?- do
                invert_signal(char)
            else
                char
            end 

            content = Agent.get(agent, &(&1))
            value = content[char]

            if value do
                [value] = value
                [?+ | char] = char
                equation = swap_variable(equation, char, value)

                get_variable(equation, agent)
            else
                equation
            end

        else
            equation
        end
    end


    @spec swap_variable(equation_type, var :: charlist(), value :: charlist()) :: equation_type
    defp swap_variable([], _char, _value), do: []

    defp swap_variable([ [exp_signal, exp_abs] | tail], [var], value) do
        value = invert_signal(value)
                |> invert_signal()

        exp = [exp_signal, exp_abs]
        value_signal = List.first(value)
        value_abs = value -- [value_signal]

        if exp_abs == var do

            if exp_signal == value_signal do
                [[?+ | value_abs] | swap_variable(tail, [var], value)]
            else
                [[?- | value_abs] | swap_variable(tail, [var], value)]
            end

        else
            [exp | swap_variable(tail, var, value)]
        end

    end
    defp swap_variable([exp | tail], var, value) do
        [exp | swap_variable(tail, var, value)]
    end
end
