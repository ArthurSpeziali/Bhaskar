defmodule AppTest do
	use ExUnit.Case

	@tag :plus
    test "Some 2 + 2" do
        assert App.Main.main(["2 + 2"]) == "4"
	end
end
