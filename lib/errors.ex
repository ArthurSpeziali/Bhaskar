defmodule App.Errors do
    @type equation_type :: [charlist()]
    @halt false
    defexception message: "Bhaskar Error was found."


    @spec invalid_signal(char :: char(), tail :: char(), last :: char()) :: no_return() 
    def invalid_signal(char, tail, last) do
        equation = [last, char, tail]
        error_make(equation, nil, 1)
    end

    
    @spec error_make(equation :: equation_type | charlist(), pos :: integer() | nil, status_code :: integer()) :: no_return()
    def error_make(equation, pos, status_code) do
        message = List.to_string(equation)
        multiplicator = String.length("#{pos}") + 14 + String.length(message) - 2

        pos = if is_integer(pos) do
            pos + 1
        else
            pos
        end

        message = """

        Invalid signal error:
        |
        Character (#{pos}): #{message}
        """ <> String.duplicate(" ", multiplicator) <> "↑" <> "\n"
        
        if @halt do
            IO.puts(message)
            System.halt(status_code)
        else
            raise(App.Errors, message)    
        end

    end


end
