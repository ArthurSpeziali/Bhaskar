defmodule App.Errors do
    @dialyzer {:nowarn_function, unknow_variable: 1}
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
                length(hd(equation)) + func.(tl(equation))
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

    @spec unknow_char(equation :: charlist()) :: no_return()
    def unknow_char([last, char, tail]) do
        equation = if last do 
            [last | [char | tail]]
        else
            [char | tail]
        end

        error_make(equation, 0, 1, "Unknow character:")
    end

    @spec outrange_rootIndex(index :: integer()) :: no_return()
    def outrange_rootIndex(index) do
        Integer.to_charlist(index)
        |> error_make(0, 1, "Root index out of range:")
    end

    @spec outrange_rootValue(value :: integer()) :: no_return()
    def outrange_rootValue(value) do
        Integer.to_charlist(value)
        |> error_make(0, 1, "Root value out of range:")
    end

    @spec outrange_logBase(base :: integer()) :: no_return()
    def outrange_logBase(base) do
        Integer.to_charlist(base)
        |> error_make(0, 1, "Logarithm base out of range:")
    end

    @spec outrange_logValue(value :: integer()) :: no_return()
    def outrange_logValue(value) do
        Integer.to_charlist(value)
        |> error_make(0, 1, "Logarithm value out of range:")
    end

    @spec unknow_variable(equation :: equation_type()) :: no_return()
    def unknow_variable(equation) do
        {_char, pos} = App.Variable.find_variable(equation, 0)

        error_make(equation, pos + 2, 1, "Unknow variable:")
    end

    @spec outrange_equal(equation :: equation_type()) :: no_return()
    def outrange_equal(equation) do
        equation_find = fn 
            item -> 
                item == ~c"=" || item == ?=
        end

        pos = Enum.find_index(
            List.delete_at(
                equation,
                Enum.find_index(equation, equation_find)
            ) |> List.flatten(),
            equation_find
        )

        error_make(equation, pos + 2, 1, "Two or more equals sign in the equation:")
    end

    @spec invalid_bracketsCount(equation :: integer()) :: no_return()
    def invalid_bracketsCount(count) do
        equation = if count > 0 do
            ~c"("
        else
            ~c")"
        end
        error_make(equation, 0, 1, "Invalid brackets count:")
    end

    @spec invalid_bracketsPos(equation :: charlist()) :: no_return()
    def invalid_bracketsPos(equation) do
        error_make(equation, 0, 1, "Invalid brackets position:")
    end

    @spec unknow_variableValue(equation :: equation_type(), char :: charlist()) :: no_return()
    def unknow_variableValue(equation, char) do
        pos = Enum.find_index(equation, fn item -> 
            item == char
        end)

        error_make(equation, pos + 1, 1, "Unknow variable value:")
    end

    @spec missing_char(equation :: equation_type()) :: no_return()
    def missing_char(equation) do
        pos = List.flatten(equation)
              |> length()

        error_make(equation, pos, 1, "Missing character:")
    end

    
    @spec error_make(equation :: equation_type | charlist(), pos :: integer(), status_code :: integer(), string :: String.t()) :: no_return()
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
