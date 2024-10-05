defmodule App.Errors do
    @type equation_type :: [charlist()]
    defexception message: "Bhaskar Error was found."


    @spec invalid_signal(equation :: charlist()) :: no_return() 
    def invalid_signal(equation) do
        error_make(equation, 1, 1, "Invalid signal character:")
    end

    @spec invalid_float(equation :: charlist(), pos :: non_neg_integer()) :: no_return()
    def invalid_float(equation, pos) do
        error_make(equation, pos, 1, "Invalid decimal number:")
    end

    @spec invalid_operator(equation :: equation_type(), pos :: non_neg_integer()) :: no_return()
    def invalid_operator(equation, pos) do
        count_equation = fn 
            ([], _func) -> 
                0

            (equation, func) ->
                length(hd(equation)) + func.(tl(equation), func)
        end
        
        pos = count_equation.(
            Enum.slice(equation, 0..pos//1),
            count_equation
        )
        error_make(equation, pos, 1, "Invalid operator character:")
    end

    @spec invalid_equality(equation :: equation_type()) :: no_return()
    def invalid_equality(equation) do
        pos = List.flatten(equation)
        |> Enum.find_index(fn item -> 
            item == ?=
        end)
        
        error_make(equation, pos, 1, "Invalid equation's equality:")
    end

    @spec invalid_rootIndex(equation :: charlist()) :: no_return()
    def invalid_rootIndex([last, char, tail]) do
        equation = if last do 
            [last | [char | tail]]
        else
            [char | tail]
        end

        error_make(equation, 0, 1, "Invalid root index:")
    end

    @spec invalid_index(equation :: charlist()) :: no_return()
    def invalid_index([last, char, tail]) do
        if tail == :non do
            error_make(last, 0, 1, "Invalid index:")
        else

            equation = if last do 
                [last | [char | tail]]
            else
                [char | tail]
            end

            error_make(equation, 0, 1, "Invalid index:")
        end
    end

    @spec invalid_char(equation :: charlist()) :: no_return()
    def invalid_char([last, char, tail]) do
        equation = if last do 
            [last | [char | tail]]
        else
            [char | tail]
        end

        error_make(equation, 0, 1, "Invalid character:")
    end

    
    @spec error_make(equation :: equation_type | charlist(), pos :: integer() | nil, status_code :: integer(), string :: String.t()) :: no_return()
    defp error_make(equation, pos, status_code, string) do
        message = List.to_string(equation)
        message = """

        #{string}
        |
        Character (#{pos + 1}): #{message}
        """ <> String.duplicate(" ", pos + 15) <> "↑"

        halt? = :escript.script_name() != ~c"--no-halt"
        if halt? do
            IO.puts(message)

            System.halt(status_code)
        else
            raise(App.Errors, message <> "\n\n")    
        end

    end


end
