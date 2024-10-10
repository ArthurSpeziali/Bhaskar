defmodule App.Math do
    @dialyzer {:nowarn_function, resolve_multiply: 2}

    @houses 8
    @type equation_type() :: [charlist()]

    @spec resolve(equation_type()) :: equation_type
    def resolve(equation) do
        result = App.Parse.auto_implement(:plus, equation, nil)
                 |> resolve_plus() 

        if is_float(result) do
            [
                Float.round(result, @houses)
                |> Float.to_charlist()
            ]
        else
            [
                Integer.to_charlist(result)
            ]
        end
    end

    defp resolve_plus([]), do: 0
    defp resolve_plus([exp | tail]) do
        frequencies = Enum.frequencies(exp)

        equation_find = fn 
            item ->
                item == ~c"." || item == ?.
        end


        if frequencies[?.] > 1 && frequencies[?.] != nil do
            IO.inspect(frequencies)
            pos = Enum.find_index(
                List.delete_at(
                    exp,

                    Enum.find_index(
                        exp,
                        equation_find
                    )
                ),
                equation_find
            ) 
            App.Errors.invalid_float([exp | tail], pos + 1)
        end


        if ?. in exp do
            List.to_float(exp) + resolve_plus(tail)
        else
            List.to_integer(exp) + resolve_plus(tail)
        end
    end


    @spec resolve_multiply(equation :: equation_type(), char :: non_neg_integer()) :: equation_type
    def resolve_multiply(equation, char) do
        operator = Enum.at(equation, char)

        previous = Enum.at(equation, char - 1)
        previous = to_number(previous)

        next = Enum.at(equation, char + 1)
        if !next, do: App.Errors.missing_char(equation)

        number? = List.to_string(next)
                  |> Integer.parse()

        case number? do
            {_integer, ""} -> false
            {_integer, _string} -> App.Errors.invalid_operator(equation, char)
            :error -> App.Errors.invalid_operator(equation, char)
        end
        {next, _string} = number?


        result = case operator do
            ~c"*" ->
                if is_float(previous * next) do
                    Float.round(
                        previous * next, 
                        @houses
                    )
                else
                    previous * next
                end

            ~c"/" -> 
                Float.round(
                    previous / next,
                    @houses
                )
        end

        if is_float(result) do
            [
                Float.to_charlist(result)
            ]
        else
            [
                Integer.to_charlist(result)
            ]
        end

    end

    
    @spec to_number(exp :: charlist()) :: integer() | float()
    def to_number(exp) do
        if ?. in exp do
            List.to_float(exp)
        else
            List.to_integer(exp)
        end
    end

    @spec to_charlist(number :: integer() | float()) :: charlist()
    def to_charlist(number) do
        if is_integer(number) do
            Integer.to_charlist(number)
        else
            Float.to_charlist(number)
        end
    end


    @spec root(value :: non_neg_integer(), index :: pos_integer()) :: float()
    def root(_value, index) when index < 2, do: App.Errors.outrange_rootIndex(index)
    def root(value, _index) when value < 0, do: App.Errors.outrange_rootValue(value)
    
    def root(value, index) do
        Float.round(value ** (1 / index), @houses)
    end


    @spec log(value :: pos_integer(), base :: pos_integer()) :: float()
    def log(value, _base) when (value <= 0), do: App.Errors.outrange_logValue(value)
    def log(_value, base) when (base <= 1), do: App.Errors.outrange_logBase(base)

    def log(value, base) do
        :math.log(abs(value)) / :math.log(abs(base))
    end
end
