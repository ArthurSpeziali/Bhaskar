defmodule AppTest do
	use ExUnit.Case

	@tag :plus
    test "Soma valores" do
        assert App.Main.main(["2 + 2"]) == "4"
	end

	@tag :minus
	test "Subtrai valores" do
		assert App.Main.main(["76.5 - 34"]) == "42.5"
	end

	@tag :bracket
	test "Usa parenteses" do
		assert App.Main.main(["(56 + 8.54) - (24.3 - 4 + (-952.3))"]) == "996.54"
	end

	@tag :operator
	test "Usa multiplicação e divisão" do
		assert App.Main.main(["56 / (98.5 * 3.09)"]) == "0.18"
	end
end
