defmodule App.Math do

    @spec resolve([charlist()]) :: [charlist()]
    def resolve(equation) do
        [
            Integer.to_charlist(
                resolve(:plus, equation)
            )
        ]
    end

    @spec resolve(atom(), [charlist()]) :: integer()
    defp resolve(:plus, []), do: 0
    defp resolve(:plus, [exp | tail]) do

        if ?. in exp do
            List.to_float(exp) + resolve(:plus, tail)
        else
            List.to_integer(exp) + resolve(:plus, tail)
        end

    end
end
