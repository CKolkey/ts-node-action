dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("r", { shiftwidth = 2 })

describe("boolean", function()
	it("turns 'TRUE' into 'FALSE'", function()
		assert.are.same({ "i == FALSE" }, Helper:call({ "i == TRUE" }, { 1, 7 }))
	end)

	it("turns 'FALSE' into 'TRUE'", function()
		assert.are.same({ "i == TRUE" }, Helper:call({ "i == FALSE" }, { 1, 7 }))
	end)
end)
