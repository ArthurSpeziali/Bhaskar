defmodule App.Main do
    def main, do: IO.puts("Falta de Argumentos.")
    
    @spec main(args :: [String.t]) :: any
    def main(args) do
        equation = format(
            List.first(args)
        )
        
        App.Sintax.sintax_resolver(equation)
                 |> List.to_string()
                 |> IO.puts()
    end

    def format(string) do
        String.replace(string, " ", "")
           |> String.replace(",", ".") 
           |> String.upcase
           |> String.to_charlist
           |> App.Parse.parse_start()

    end
end

