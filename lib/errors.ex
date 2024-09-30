defmodule App.Errors do
    @type equation_type :: [charlist()]
    defexception message: "Bhaskar Error was found."


    @spec invalid_signal(equation :: charlist(), pos :: non_neg_integer()) :: no_return() 
    def invalid_signal(equation, pos) do
        error_make(equation, pos, 1, "Invalid signal error:")
    end

    @spec invalid_float(equation :: charlist(), pos :: non_neg_integer()) :: no_return()
    def invalid_float(equation, pos) do
        error_make(equation, pos, 1, "Invalid decimal number:")
    end

    
    @spec error_make(equation :: equation_type | charlist(), pos :: integer() | nil, status_code :: integer(), string :: String.t()) :: no_return()
    def error_make(equation, pos, status_code, string) do
        message = List.to_string(equation)
        multiplicator = String.length("#{pos}") + 14 + String.length(message) - 2

        pos = if is_integer(pos) do
            pos + 1
        else
            pos
        end

        message = """

        #{string}
        |
        Character (#{pos}): #{message}
        """ <> String.duplicate(" ", multiplicator) <> "↑"

        halt? = :escript.script_name() != ~c"--no-halt"
        if halt? do
            IO.puts(message)

            System.halt(status_code)
        else
            raise(App.Errors, message <> "\n\n")    
        end

    end


end
