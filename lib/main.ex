defmodule App.Main do
    def main, do: IO.puts("Falta de Argumentos.")
    
    @spec main(args :: [String.t]) :: any
    def main(args) do
        equation = format(
            List.first(args)
        )
        
        result = App.Sintax.sintax_verify(equation)
                 |> List.to_string()

        IO.puts(result)
        result
    end

    def format(string) do
        String.replace(string, " ", "")
           |> String.replace(",", ".") 
           |> String.upcase
           |> String.to_charlist
           |> App.Parse.parse_start()

    end
end

