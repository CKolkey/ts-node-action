dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("sql", { shiftwidth = 2 })

describe("boolean", function()
  it("turns 'true' into 'false'", function()
    assert.are.same(
      { "select true" },
      Helper:call({ "select false" }, { 1, 8 })
    )
  end)

  it("turns 'false' into 'true'", function()
    assert.are.same(
      { "select false" },
      Helper:call({ "select true" }, { 1, 8 })
    )
  end)

  it("turns 'TRUE' into 'FALSE'", function()
    assert.are.same(
      { "select TRUE" },
      Helper:call({ "select FALSE" }, { 1, 8 })
    )
  end)

  it("turns 'FALSE' into 'true'", function()
    assert.are.same(
      { "select FALSE" },
      Helper:call({ "select TRUE" }, { 1, 8 })
    )
  end)
end)

describe("operators", function()
  it("turns 'and' into 'or'", function()
    assert.are.same(
      { "select a from b where a < 5 and a > 1" },
      Helper:call({ "select a from b where a < 5 or a > 1" }, { 1, 29 })
    )
  end)

  it("turns '=' into '!='", function()
    assert.are.same(
      { "select a from b where a = 1" },
      Helper:call({ "select a from b where a != 1" }, { 1, 25 })
    )
  end)

  it("turns '!=' into '='", function()
    assert.are.same(
      { "select a from b where a != 1" },
      Helper:call({ "select a from b where a = 1" }, { 1, 25 })
    )
  end)

  it("turns '<' into '>'", function()
    assert.are.same(
      { "select a from b where a < 1" },
      Helper:call({ "select a from b where a > 1" }, { 1, 25 })
    )
  end)

  it("turns '>' into '<'", function()
    assert.are.same(
      { "select a from b where a > 1" },
      Helper:call({ "select a from b where a < 1" }, { 1, 25 })
    )
  end)

  it("turns '<=' into '>='", function()
    assert.are.same(
      { "select a from b where a <= 1" },
      Helper:call({ "select a from b where a >= 1" }, { 1, 25 })
    )
  end)

  it("turns '>=' into '<='", function()
    assert.are.same(
      { "select a from b where a >= 1" },
      Helper:call({ "select a from b where a <= 1" }, { 1, 25 })
    )
  end)

  it("turns '+' into '-'", function()
    assert.are.same(
      { "select a + 1" },
      Helper:call({ "select a - 1" }, { 1, 10 })
    )
  end)

  it("turns '-' into '+'", function()
    assert.are.same(
      { "select a - 1" },
      Helper:call({ "select a + 1" }, { 1, 10 })
    )
  end)

  it("turns '*' into '/'", function()
    assert.are.same(
      { "select a * 1" },
      Helper:call({ "select a / 1" }, { 1, 10 })
    )
  end)

  it("turns '/' into '*'", function()
    assert.are.same(
      { "select a / 1" },
      Helper:call({ "select a * 1" }, { 1, 10 })
    )
  end)
end)

describe("expands and collapses: ", function()
  it("Expands select_expression", function()
    assert.are.same(
      { "select a as c1, b as c2" },
      Helper:call({
        "select a as c1,",
        "b as c2",
      }, { 1, 15 })
    )
  end)

  it("Collapses select_expression", function()
    got = Helper:call({ "select a as c1, b as c2" }, { 1, 15 })
    got[2] = got[2]:match("^%s*(.*)")
    assert.are.same({
      "select a as c1,",
      "b as c2",
    },
    got)
  end)

  it("Expands select_expression with subquery", function()
    assert.are.same(
      { "select a as c1, (select 1) as sq" },
      Helper:call({
        "select a as c1,",
        "(select 1) as sq",
      }, { 1, 15 })
    )
  end)

  it("Collapses select_expression", function()
    got = Helper:call({ "select a as c1, (select 1) as sq" }, { 1, 15 })
    got[2] = got[2]:match("^%s*(.*)")
    assert.are.same({
      "select a as c1,",
      "(select 1) as sq",
    },
    got)
  end)

  it("Expands column_definition in create table statement", function()
    assert.are.same(
      { "create table tab (a int, b float)" },
      Helper:call({
        "create table tab (",
        "a int,",
        "b float",
        ")",
      }, { 1, 18 })
    )
  end)

  it("Collapses column_definition in create table statement", function()
    assert.are.same({
      "create table tab (",
      "  a int,",
      "  b float",
      ")",
    }, Helper:call({ "create table tab (a int, b float)" }, { 1, 18 }))
  end)
end)
