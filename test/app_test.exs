defmodule AppTest do
	use ExUnit.Case

	@tag :signal
    test "Utiliza soma e subtração" do
		assert App.Parse.parse_start(~c"2+2-90")
		|> List.first()
		|> App.Sintax.sintax_resolver() == [~c"-86"]
	end

	@tag :operator
	test "Utiliza multiplicação e divisão" do
		assert App.Parse.parse_start(~c"56/(98.5*3.09)")
		|> List.first()
		|> App.Sintax.sintax_resolver() == [~c"0.18398962"]
	end

	@tag :bracket
	test "Utiliza parentêses" do
		assert App.Parse.parse_start(~c"(56+8.54)-(24.3-4+(-952.3))")
		|> List.first()
		|> App.Sintax.sintax_resolver() == [~c"996.54"]
	end

	@tag :var_plus
	test "Utiliza soma e subtração de variáveis"  do
		{:ok, agent} = Agent.start(fn -> %{} end)

		App.Parse.parse_start(~c"X+(8+2.5)=89-(90.3/2)")
		|> List.first()
		|> App.Sintax.variable_resolver(agent)

		assert Agent.get(agent, &(&1))[~c"+X"] == [~c"+33.35"]
	end
	
	@tag :var_multiply
	test "Utiliza multiplicação e divisão em variáveis" do
		{:ok, agent} = Agent.start(fn -> %{} end)

		App.Parse.parse_start(~c"5+(6*2)/X+15.5=24.5")
		|> List.first()
		|> App.Sintax.variable_resolver(agent)

		assert Agent.get(agent, &(&1))[~c"+X"] == [~c"3.0"]
	end

	@tag :var_power
	test "Utiliza exponenciação em variáveis" do
		{:ok, agent} = Agent.start(fn -> %{} end)

		App.Parse.parse_start(~c"2*X^3-8=120")
		|> List.first()
		|> App.Sintax.variable_resolver(agent)

		assert Agent.get(agent, &(&1))[~c"+X"] == [~c"+4.0"]
	end

	@tag :var_root
	test "Utiliza raiz em variáveis" do
		{:ok, agent} = Agent.start(fn -> %{} end)

		App.Parse.parse_start(~c"62=34-6*(9.5+2)-<4>{X}+100")
		|> List.first()
		|> App.Sintax.variable_resolver(agent)

		assert Agent.get(agent, &(&1))[~c"+X"] == [~c"+81.0"]
	end
end
