defmodule App.Main do
    def main, do: IO.puts("Falta de Argumentos.")
    
    # @spec main(args :: [String.t]) :: String.t
    def main([string_equation]) do

        equation = String.replace(string_equation, " ", "") |>
        String.replace(",", ".") |>
        String.upcase |>
        String.to_charlist

        App.Parse.parse_start(equation)

    end
end

