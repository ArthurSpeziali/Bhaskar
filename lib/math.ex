defmodule App.Math do
    @type equation_type() :: [charlist()]

    @spec resolve(equation_type()) :: equation_type
    def resolve(equation) do
        result = App.Parse.auto_implement(:plus, equation, nil)
                 |> resolve_plus() 

        if is_float(result) do
            [
                Float.round(result, 8)
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
        next = to_number(next)

        result = case operator do
            '*' ->
                if is_float(previous * next) do
                    Float.round(
                        previous * next, 
                        8
                    )
                else
                    previous * next
                end

            '/' -> 
                Float.round(
                    previous / next,
                    8
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

end
