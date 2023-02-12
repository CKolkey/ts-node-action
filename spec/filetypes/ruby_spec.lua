dofile("./spec/spec_helper.lua")

local Helper = SpecHelper:new("ruby")

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

describe("if", function()
  it("expands ternary to multiline expression", function()
    assert.are.same(
      {
        [[if greet?]],
        [[  puts "hello"]],
        [[else]],
        [[  puts "booooo"]],
        [[end]],
      },
      Helper:call({ [[greet? ? puts "hello" : puts "booooo"]] }, { 1, 7 })
    )
  end)

  it("inlines to ternary statement", function()
    assert.are.same(
      { [[greet? ? puts "hello" : puts "booooo"]] },
      Helper:call({
        [[if greet?]],
        [[  puts "hello"]],
        [[else]],
        [[  puts "booooo"]],
        [[end]],
      })
    )
  end)
end)

describe("if_modifier", function()
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
      { [[puts "hello" if greet?]] },
      Helper:call({
        [[if greet?]],
        [[  puts "hello"]],
        [[end]],
      })
    )
  end)

  it("can handle more complex conditions", function()
    assert.are.same(
      {
        [[if greet? && 1 == 2 || something * 3 <= 10]],
        [[  puts "hello"]],
        [[end]],
      },
      Helper:call({ [[puts "hello" if greet? && 1 == 2 || something * 3 <= 10]], }, { 1, 13 })
    )
  end)

  it("doesn't change conditionals with multi-line bodies", function()
    local text = {
      [[if greet?]],
      [[  puts "hello"]],
      [[  puts "hello"]],
      [[  puts "hello"]],
      [[end]],
    }

    assert.are.same(text, Helper:call(text))
  end)
end)

describe("unless_modifier", function()
  it("expands from one line to three", function()
    assert.are.same(
      {
        [[unless rude?]],
        [[  puts "hello"]],
        [[end]],
      },
      Helper:call({ [[puts "hello" unless rude?]] }, { 1, 13 })
    )
  end)

  it("collapses from three lines to one", function()
    assert.are.same(
      { [[puts "hello" unless rude?]] },
      Helper:call({
        [[unless rude?]],
        [[  puts "hello"]],
        [[end]],
      })
    )
  end)

  it("can handle more complex conditions", function()
    assert.are.same(
      {
        [[unless rude? && 1 == 2 || something * 3 <= 10]],
        [[  puts "hello"]],
        [[end]],
      },
      Helper:call({ [[puts "hello" unless rude? && 1 == 2 || something * 3 <= 10]], }, { 1, 13 })
    )
  end)
end)

describe("binary", function()
  it("flips == into !=", function()
    assert.are.same({ "1 != 1" }, Helper:call({ "1 == 1" }, { 1, 3 }))
  end)

  it("flips != into ==", function()
    assert.are.same({ "1 == 1" }, Helper:call({ "1 != 1" }, { 1, 3 }))
  end)

  it("flips > into <", function()
    assert.are.same({ "1 < 1" }, Helper:call({ "1 > 1" }, { 1, 3 }))
  end)

  it("flips < into >", function()
    assert.are.same({ "1 > 1" }, Helper:call({ "1 < 1" }, { 1, 3 }))
  end)

  it("flips >= into <=", function()
    assert.are.same({ "1 <= 1" }, Helper:call({ "1 >= 1" }, { 1, 3 }))
  end)

  it("flips <= into >=", function()
    assert.are.same({ "1 >= 1" }, Helper:call({ "1 <= 1" }, { 1, 3 }))
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
    assert.are.same(
      {
        "[",
        "  1,",
        "  2,",
        "  3",
        "]"
      },
      Helper:call({ "[1, 2, 3]" })
    )
  end)

  it("doesn't expand child arrays", function()
    assert.are.same(
      {
        "[",
        "  1,",
        "  2,",
        "  [3, 4, 5]",
        "]"
      },
      Helper:call({ "[1, 2, [3, 4, 5]]" })
    )
  end)

  it("collapses multi-line array to single line", function()
    assert.are.same(
      { "[1, 2, 3]" },
      Helper:call({
        "[",
        "  1,",
        "  2,",
        "  3",
        "]"
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
        "]"
      })
    )
  end)
end)
