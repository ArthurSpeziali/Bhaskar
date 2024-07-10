defmodule App.Main do
    def debug() do
        Mix.ensure_application!(:wx)
        Mix.ensure_application!(:debugger)
    end

    def main([]), do: IO.puts("Falta de Argumentos.")
    
    @spec main(args :: [String.t]) :: no_return()
    def main(args) do
        list_equation = format(
            List.first(args)
        )


        {agent, result} = App.Sintax.sintax_main(list_equation, :agent)
        result = List.last(result)
        variables = Agent.get(agent, &(&1))

        case result do

            [term] ->
                if ?. in term do
                    List.to_float(term)
                    |> Float.round(2)

                else
                    List.to_integer(term)

                end |> IO.puts()
                
                if variables != %{} do
                    print_variables(variables)
                end

        end

    end

    def format(string) do
        String.replace(string, " ", "")
           |> String.replace(",", ".") 
           |> String.upcase
           |> String.to_charlist
           |> App.Parse.parse_start()
    end

    def print_variables(map) do
        IO.puts("\nVariáveis:")

        for {key, [value]} <- map do
            [_signal, key] = key
            value = App.Math.to_number(value) / 1

            IO.puts("#{[key]} -> #{Float.round(value, 2)}")
        end
    end
end

