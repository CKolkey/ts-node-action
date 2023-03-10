dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("julia", { shiftwidth = 2 })

describe("operator", function()

	it("toggles '>=' into '<='", function()
		assert.are.same({ "i <= 8" }, Helper:call({ "i >= 8" }, { 1, 3 }))
	end)

end)
