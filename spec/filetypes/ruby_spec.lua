dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("ruby")

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
        [[  puts("hello")]],
        [[else]],
        [[  puts("booooo")]],
        [[end]],
      },
      Helper:call({ [[greet? ? puts("hello") : puts("booooo")]] }, { 1, 7 })
    )
  end)

  pending("inlines to ternary statement", function()
    assert.are.same(
      { [[greet? ? puts("hello", "goodbye") : puts("booooo", "you lack creativity", "tosser")]] },
      Helper:call({
        [[if greet?]],
        [[  puts "hello", "goodbye"]],
        [[else]],
        [[  puts "booooo", "you lack creativity", "tosser"]],
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

  it("doesn't collapse multi-line array with embedded comments", function()
    local text = {
      "[ # a",
      "  1, # b",
      "  2, # c",
      "=begin",
      "a multiline comment here",
      "and one more line",
      "=end",
      "  3 # d",
      "]"
    }

    assert.are.same(text, Helper:call(text))
  end)

  it("doesn't collapse array with nested child comments", function()
    local text = {
      "[",
      "  1,",
      "  2,",
      "  [ # a",
      "    3, # b",
      "    4, # c",
      "=begin",
      "a multiline comment here",
      "and one more line",
      "=end",
      "    5 # d",
      "  ]",
      "]"
    }
    assert.are.same(text, Helper:call(text))
  end)

  it("doesn't collapse array with inline comments", function()
    local text = {
      "[",
      "  1, # no comment",
      "  2,",
      "]"
    }
    assert.are.same(text, Helper:call(text))
  end)

end)

describe("hash", function()
  it("expands single line hash to multiple lines", function()
    assert.are.same(
      {
        "{",
        "  a: 1,",
        "  b: 2,",
        "  c: 3",
        "}"
      },
      Helper:call({ "{ a: 1, b: 2, c: 3 }" })
    )
  end)

  it("collapses multi-line hash to single lines", function()
    assert.are.same(
      { "{ a: 1, b: 2, c: 3 }" },
      Helper:call({
        "{",
        "  a: 1,",
        "  b: 2,",
        "  c: 3",
        "}"
      })
    )
  end)

  it("doesn't expand children", function()
    assert.are.same(
      {
        "{",
        "  a: 1,",
        "  b: ['foo', 'bar'],",
        "  c: { d: 3, e: 4 }",
        "}"
      },
      Helper:call({ "{ a: 1, b: ['foo', 'bar'], c: { d: 3, e: 4 } }" })
    )
  end)

  it("collapses nested children", function()
    assert.are.same(
      { "{ a: 1, b: ['foo', 'bar'], c: { d: 3, e: 4 } }" },
      Helper:call({
        "{",
        "  a: 1,",
        "  b: [",
        "    'foo',",
        "    'bar'",
        "  ],",
        "  c: { ",
        "    d: 3,",
        "    e: 4",
        "  }",
        "}"
      })
    )
  end)
end)

describe("block", function()
  it("collapses a multi-line block into one line (with param)", function()
    assert.are.same(
      { "[1, 2, 3].each { |n| print n }" },
      Helper:call({
        "[1, 2, 3].each do |n|",
        "  print n",
        "end"
      }, { 1, 16 })
    )
  end)

  it("collapses a multi-line block into one line (without param)", function()
    assert.are.same(
      { "[1, 2, 3].each { print n }" },
      Helper:call({
        "[1, 2, 3].each do",
        "  print n",
        "end"
      }, { 1, 16 })
    )
  end)

  it("collapses a multi-line block into one line (with destructured param)", function()
    assert.are.same(
      { "[1, 2, 3].each { |(a, b), c| print n }" },
      Helper:call({
        "[1, 2, 3].each do |(a, b), c|",
        "  print n",
        "end"
      }, { 1, 16 })
    )
  end)
end)

describe("do_block", function()
  it("expands a single-line block into multi line (with param)", function()
    assert.are.same(
      {
        "[1, 2, 3].each do |n|",
        "  print n",
        "end"
      },
      Helper:call({ "[1, 2, 3].each { |n| print n }" }, { 1, 16 })
    )
  end)

  it("expands a single-line block into multi line (without param)", function()
    assert.are.same(
      {
        "[1, 2, 3].each do",
        "  print n",
        "end"
      },
      Helper:call({ "[1, 2, 3].each { print n }" }, { 1, 16 })
    )
  end)

  it("expands a single-line block into multi line (with destructured param)", function()
    assert.are.same(
      {
        "[1, 2, 3].each do |(a, b), c|",
        "  print n",
        "end"
      },
      Helper:call({ "[1, 2, 3].each { |(a, b), c| print n }" }, { 1, 16 })
    )
  end)
end)

describe("pair", function()
  it("converts old style hashes into new style", function()
    assert.are.same(
      { "{ a: 1 }" },
      Helper:call({ "{ :a => 1 }" }, { 1, 6 })
    )
  end)

  it("converts new style hashes into old style", function()
    assert.are.same(
      { "{ :a => 1 }" },
      Helper:call({ "{ a: 1 }" }, { 1, 4 })
    )
  end)

  it("doesn't change non-string/symbol keys", function()
    assert.are.same(
      { "{ [1, 2] => 1 }" },
      Helper:call({ "{ [1, 2] => 1 }" }, { 1, 10 })
    )
  end)
end)

describe("argument_list", function()

end)

describe("method_parameters", function()

end)

describe("constant", function()

end)

describe("identifier", function()

end)
