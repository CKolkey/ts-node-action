dofile("spec/spec_helper.lua")

local Helper = SpecHelper:new("lua")

describe("boolean", function()
  it("turns 'true' into 'false'", function()
    assert.are.same({ "local bool = false" }, Helper:call({ "local bool = true" }, { 1, 14 }))
  end)

  it("turns 'false' into 'true'", function()
    assert.are.same({ "local bool = true" }, Helper:call({ "local bool = false" }, { 1, 14 }))
  end)
end)

describe("table_constructor", function()
  it("expands single line table to multiple lines", function()
    assert.are.same(
      {
        "{",
        "  1,",
        "  2,",
        "  3",
        "}"
      },
      Helper:call({ "{ 1, 2, 3 }" })
    )
  end)

  it("collapses multi line table to single lines", function()
    assert.are.same(
      { "{ 1, 2, 3 }" },
      Helper:call({
        "{",
        "  1,",
        "  2,",
        "  3",
        "}"
      })
    )
  end)

  it("expands single line table to multiple lines", function()
    assert.are.same(
      {
        "{",
        "  a = 1,",
        "  b = 2,",
        "  ['c'] = 3",
        "}"
      },
      Helper:call({ "{ a = 1, b = 2, ['c'] = 3 }" })
    )
  end)

  it("collapses multi line table to single lines", function()
    assert.are.same(
      { "{ a = 1, b = 2, ['c'] = 3 }" },
      Helper:call({
        "{",
        "  a = 1,",
        "  b = 2,",
        "  ['c'] = 3",
        "}"
      })
    )
  end)
end)

describe("function_definition (anon)", function()
  it("collapses multi-line function to single line", function()
    assert.are.same(
      { "local a = function(a, b, c) return 1 end" },
      Helper:call({
        "local a = function(a, b, c)",
        "  return 1",
        "end"
      }, { 1, 11 })
    )
  end)

  it("expands single-line function to multi-line", function()
    assert.are.same(
      {
        "local a = function(a, b, c)",
        "  return 1",
        "end"
      },
      Helper:call({ "local a = function(a, b, c) return 1 end" }, { 1, 11 })
    )
  end)

  it("doesn't collapse function with multi-line body", function()
    local text = {
      "local a = function(a, b, c)",
      "  local d = a + b + c",
      "  return d",
      "end"
    }

    assert.are.same(text, Helper:call(text, { 1, 11 }))
  end)
end)


describe("function_declaration (named)", function()
  it("collapses multi-line function to single line", function()
    assert.are.same(
      { "local function a(a, b, c) return 1 end" },
      Helper:call({
        "local function a(a, b, c)",
        "  return 1",
        "end"
      }, { 1, 11 })
    )
  end)

  it("expands single-line function to multi-line", function()
    assert.are.same(
      {
        "local function a(a, b, c)",
        "  return 1",
        "end"
      },
      Helper:call({ "local function a(a, b, c) return 1 end" }, { 1, 11 })
    )
  end)

  it("doesn't collapse function with multi-line body", function()
    local text = {
      "local function a(a, b, c)",
      "  local d = a + b + c",
      "  return d",
      "end"
    }

    assert.are.same(text, Helper:call(text, { 1, 11 }))
  end)
end)
