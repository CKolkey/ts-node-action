local Helper = SpecHelper.new("sql", { shiftwidth = 2 })


describe("boolean", function()
  it("turns 'true' into 'false'", function()
    assert.are.same({ "false" }, Helper:call({ "true" }))
  end)

  it("turns 'false' into 'true'", function()
    assert.are.same({ "true" }, Helper:call({ "false" }))
  end)
end)


describe("operator", function()
  it("turns 'AND' into 'OR'", function()
    assert.are.same({ "AND" }, Helper:call({ "OR" }))
  end)

  it("turns 'OR' into 'AND'", function()
    assert.are.same({ "OR" }, Helper:call({ "AND" }))
  end)
end)

