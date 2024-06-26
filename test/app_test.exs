defmodule AppTest do
	use ExUnit.Case

	@tag :signal
    test "Utiliza soma e subtração" do
		assert App.Parse.parse_start('2+2-90')
		|> App.Sintax.sintax_resolver() == ['-86']
	end

	@tag :operator
	test "Utiliza multiplicação e divisão" do
		assert App.Parse.parse_start('56/(98.5*3.09)')
		|> App.Sintax.sintax_resolver() == ['0.18']
	end

	@tag :bracket
	test "Utiliza parentêses" do
		assert App.Parse.parse_start('(56+8.54)-(24.3-4+(-952.3))')
		|> App.Sintax.sintax_resolver() == ['996.54']
	end

end
