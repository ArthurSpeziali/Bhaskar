defmodule AppTest do
	use ExUnit.Case

	@tag :plus
    test "Soma valores" do
        assert App.Main.main(["2 + 2"]) == "4"
	end

	@tag :minus
	test "Subtrai valores" do
		assert App.Main.main(["76.5 - 34"])
	end

	@tag :bracket
	test "Usa parenteses" do
		assert App.Main.main(["(56 + 8.54) - (24.3 - 4 + (-952.3))"])
	end
end
