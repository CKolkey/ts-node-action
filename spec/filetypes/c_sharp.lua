dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("c_sharp", { shiftwidth = 4 })

describe("boolean", function()
  it("turns 'true' into 'false'", function()
    assert.are.same(
      { "bool bool = true;" },
      Helper:call({ "bool bool = false;" }, { 1, 13 })
    )
  end)

  it("turns 'false' into 'true'", function()
    assert.are.same(
      { "bool bool = false;" },
      Helper:call({ "bool bool = true;" }, { 1, 13 })
    )
  end)
end)

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

describe("operator", function()
  it("toggles '<= into '>='", function()
    assert.are.same({ "i <= 8" }, Helper:call({ "i >= 8" }, { 1, 3 }))
  end)

  it("toggles '>=' into '<='", function()
    assert.are.same({ "i >= 8" }, Helper:call({ "i <= 8" }, { 1, 3 }))
  end)

  it("toggles '>' into '<'", function()
    assert.are.same({ "i > 8" }, Helper:call({ "i < 8" }, { 1, 3 }))
  end)

  it("toggles '<' into '>'", function()
    assert.are.same({ "i < 8" }, Helper:call({ "i > 8" }, { 1, 3 }))
  end)

  it("toggles '+' into '-'", function()
    assert.are.same({ "i + 8" }, Helper:call({ "i - 8" }, { 1, 3 }))
  end)

  it("toggles '-' into '+'", function()
    assert.are.same({ "i - 8" }, Helper:call({ "i + 8" }, { 1, 3 }))
  end)

  it("toggles '*' into '/'", function()
    assert.are.same({ "i * 8" }, Helper:call({ "i / 8" }, { 1, 3 }))
  end)

  it("toggles '/' into '*'", function()
    assert.are.same({ "i / 8" }, Helper:call({ "i * 8" }, { 1, 3 }))
  end)

  it("toggles '+=' into '-='", function()
    assert.are.same({ "i += 8" }, Helper:call({ "i -= 8" }, { 1, 3 }))
  end)

  it("toggles '-=' into '+='", function()
    assert.are.same({ "i -= 8" }, Helper:call({ "i += 8" }, { 1, 3 }))
  end)

  it("toggles '++' into '--'", function()
    assert.are.same({ "i++" }, Helper:call({ "i--" }, { 1, 2 }))
  end)

  it("toggles '--' into '++'", function()
    assert.are.same({ "i--" }, Helper:call({ "i++" }, { 1, 2 }))
  end)

  it("toggles '==' into '!='", function()
    assert.are.same({ "i == 8" }, Helper:call({ "i != 8" }, { 1, 3 }))
  end)

  it("toggles '!=' into '=='", function()
    assert.are.same({ "i != 8" }, Helper:call({ "i == 8" }, { 1, 3 }))
  end)

  it("toggles '&&' into '||'", function()
    assert.are.same(
      { "i == 8 && x == 9" },
      Helper:call({ "i == 8 || x == 9" }, { 1, 8 })
    )
  end)

  it("toggles '||' into '&&'", function()
    assert.are.same(
      { "i == 8 || x == 9" },
      Helper:call({ "i == 8 && x == 9" }, { 1, 8 })
    )
  end)
end)
