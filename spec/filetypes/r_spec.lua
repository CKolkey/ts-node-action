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

describe("multiline", function()
	it("expand single line formal parameters to multiline", function()
		assert.are.same({
			"foo <- function(",
			"  bar,",
			"  baz",
			")",
		}, Helper:call({ "foo <- function(bar, baz)" }, { 1, 16 }))
	end)

	it("collapse multiline formal parameters to single line", function()
		assert.are.same(
			{ "foo <- function(bar, baz)" },
			Helper:call({
				"foo <- function(",
				"  bar,",
				"  baz",
				")",
			}, { 1, 16 })
		)
	end)
end)

describe("multiline_args", function()
	it("expand single line arguments to multiline", function()
		assert.are.same({
			"foo(",
			"  bar = buf,",
			"  'baz',",
			"  'bap'",
			")",
		}, Helper:call({ "foo(bar = buf, 'baz', 'bap')" }, { 1, 4 }))
	end)

	it("collapse multiline arguments to single line", function()
		assert.are.same(
			{ "foo(bar = buf, 'baz', 'bap')" },
			Helper:call({
				"foo(",
				"  bar = buf,",
				"  'baz',",
				"  'bap'",
				"  )",
			}, { 1, 4 })
		)
	end)
end)
