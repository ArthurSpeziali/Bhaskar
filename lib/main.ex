defmodule App.Main do
    def main, do: IO.puts("Falta de Argumentos.")
    
    @spec main(args :: [String.t]) :: any
    def main(args) do
        equation = format(
            List.first(args)
        )
        
        result = App.Sintax.sintax_resolver(equation)
        case result do

            [term] ->
                if ?. in term do
                    List.to_float(term)
                    |> Float.round(2)

                else
                    List.to_integer(term)

                end |> IO.puts()

        end

    end

    def format(string) do
        String.replace(string, " ", "")
           |> String.replace(",", ".") 
           |> String.upcase
           |> String.to_charlist
           |> App.Parse.parse_start()

    end
end

