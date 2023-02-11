dofile("./spec/spec_helper.lua")

local Helper = SpecHelper:new("ruby")

describe("integer", function()
  it("adds underscores to long int", function()
    assert.are.same("1_000_000", Helper:call("1000000"))
  end)

  it("removes underscores from long int", function()
    assert.are.same("1000000", Helper:call("1_000_000"))
  end)

  it("doesn't change ints less than four places", function()
    assert.are.same("100", Helper:call("100"))
  end)
end)

describe("if_condition", function()
  it("expands from one line to three", function()
    assert.are.same(
      {
        [[if greet?]],
        [[  puts "hello"]],
        [[end]],
      },
      Helper:call({ [[puts "hello" if greet?]], }, { 1, 13 })
    )
  end)

  it("collapses from three lines to one", function()
    assert.are.same(
      [[puts "hello" if greet?]],
      Helper:call({
        [[if greet?]],
        [[  puts "hello"]],
        [[end]],
      })
    )
  end)
end)
