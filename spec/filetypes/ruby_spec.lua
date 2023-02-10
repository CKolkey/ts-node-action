dofile("./spec/spec_helper.lua")

local Helper = SpecHelper.for_lang("ruby")

describe("integer node", function()
  it("adds underscores to long int", function()
    local node = Helper:build_node([[1000000]])
    assert.equals("1_000_000", Helper:run_action(node))
  end)

  it("removes underscores from long int", function()
    local node = Helper:build_node([[1_000_000]])
    assert.equals("1000000", Helper:run_action(node))
  end)
end)
