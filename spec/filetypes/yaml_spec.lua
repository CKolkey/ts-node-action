dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("yaml", { shiftwidth = 2 })

describe("boolean", function()
  it("turns 'true' into 'false'", function()
    assert.are.same({ "key: false" }, Helper:call({ "key: true" }, { 1, 6 }))
  end)

  it("turns 'false' into 'true'", function()
    assert.are.same({ "key: true" }, Helper:call({ "key: false" }, { 1, 6 }))
  end)
end)
