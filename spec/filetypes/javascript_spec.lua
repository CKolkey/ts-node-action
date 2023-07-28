dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("javascript", { shiftwidth = 2 })

describe("integer", function()
  it("adds underscores to long int", function()
    assert.are.same({ "1_000_000" }, Helper:call("1000000"))
  end)

  it("removes underscores from long int", function()
    assert.are.same({ "1000000" }, Helper:call("1_000_000"))
  end)

  it("doesn't change ints less than four places", function()
    assert.are.same({ "100" }, Helper:call("100"))
  end)
end)

describe("boolean", function()
  it("turns 'true' into 'false'", function()
    assert.are.same({ "false" }, Helper:call({ "true" }))
  end)

  it("turns 'false' into 'true'", function()
    assert.are.same({ "true" }, Helper:call({ "false" }))
  end)
end)

describe("array", function()
  it("expands single line array to multiple lines", function()
    assert.are.same({
      "[",
      "  1,",
      "  2,",
      "  3",
      "]",
    }, Helper:call({ "[1, 2, 3]" }))
  end)

  it("doesn't expand child arrays", function()
    assert.are.same({
      "[",
      "  1,",
      "  2,",
      "  [3, 4, 5]",
      "]",
    }, Helper:call({ "[1, 2, [3, 4, 5]]" }))
  end)

  it("collapses multi-line array to single line", function()
    assert.are.same(
      { "[1, 2, 3]" },
      Helper:call({
        "[",
        "  1,",
        "  2,",
        "  3",
        "]",
      })
    )
  end)

  it("collapses child arrays", function()
    assert.are.same(
      { "[1, 2, [3, 4, 5]]" },
      Helper:call({
        "[",
        "  1,",
        "  2,",
        "  [",
        "    3,",
        "    4,",
        "    5",
        "  ]",
        "]",
      })
    )
  end)
end)
