defmodule AppTest do
	use ExUnit.Case

	@tag :signal
    test "Utiliza soma e subtração" do
		assert App.Parse.parse_start('2+2-90')
		|> List.first()
		|> App.Sintax.sintax_resolver() == ['-86']
	end

	@tag :operator
	test "Utiliza multiplicação e divisão" do
		assert App.Parse.parse_start('56/(98.5*3.09)')
		|> List.first()
		|> App.Sintax.sintax_resolver() == ['0.18398962']
	end

	@tag :bracket
	test "Utiliza parentêses" do
		assert App.Parse.parse_start('(56+8.54)-(24.3-4+(-952.3))')
		|> List.first()
		|> App.Sintax.sintax_resolver() == ['996.54']
	end

	@tag :var_plus
	test "Utiliza soma e subtração de variáveis"  do
		{:ok, agent} = Agent.start(fn -> %{} end)

		App.Parse.parse_start('X+(8+2.5)=89-(90.3/2)')
		|> List.first()
		|> App.Sintax.variable_resolver(agent)

		assert Agent.get(agent, &(&1))['+X'] == ['+33.35']
	end
	
	@tag :var_multiply
	test "Utiliza multiplicação e divisão em variáveis" do
		{:ok, agent} = Agent.start(fn -> %{} end)

		App.Parse.parse_start('5+(6*2)/X+15.5=24.5')
		|> List.first()
		|> App.Sintax.variable_resolver(agent)

		assert Agent.get(agent, &(&1))['+X'] == ['3.0']
	end
end
