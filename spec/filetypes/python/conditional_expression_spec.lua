dofile("./spec/spec_helper.lua")

local Helper = SpecHelper:new("python")

describe("conditional_expression", function()

  it("expands with a single assignment", function()
    assert.are.same(
      {
        [[if foo(y):]],
        [[    x = 1]],
        [[else:]],
        [[    x = 2]],
      },
      Helper:call({ [[x = 1 if foo(y) else 2]] }, { 1, 7 })
    )
  end)

  it("expands with a multi assignment", function()
    assert.are.same(
      {
        [[if foo(y):]],
        [[    x = y = z = 1]],
        [[else:]],
        [[    x = y = z = 2]],
      },
      Helper:call({ [[x = y = z = 1 if foo(y) else 2]] }, { 1, 15 })
    )
  end)

  it("expands with a return", function()
    assert.are.same(
      {
        [[if foo(y):]],
        [[    return 1]],
        [[else:]],
        [[    return 2]],
      },
      Helper:call({ [[return 1 if foo(y) else 2]] }, { 1, 10 })
    )
  end)

  it("expands with function calls", function()
    assert.are.same(
      {
        [[if foo(y):]],
        [[    bar()]],
        [[else:]],
        [[    baz()]],
      },
      Helper:call({ [[bar() if foo(y) else baz()]] }, { 1, 7 })
    )
  end)

  it("expands with both parenthesized lambda expr", function()
    assert.are.same(
      {
        [[if z is not None:]],
        [[    x = (lambda y: y + 1)]],
        [[else:]],
        [[    x = (lambda y: y - 1)]],
      },
      Helper:call(
        { [[x = (lambda y: y + 1) if z is not None else (lambda y: y - 1)]] },
        { 1, 23 }
      )
    )
  end)

  it("doesn't expand with a bare consequence lambda expr ('if' is inside lambda)", function()
    local text = {
      [[x = lambda y: y + 1 if z is not None else lambda y: y - 1]]
    }
    assert.are.same(text, Helper:call(text, { 1, 23 }))
  end)

  it("expands with a parenthesized consequence lambda expr", function()
    assert.are.same(
      {
        [[if z is not None:]],
        [[    x = (lambda y: y + 1)]],
        [[else:]],
        [[    x = lambda y: y - 1]],
      },
      Helper:call(
        { [[x = (lambda y: y + 1) if z is not None else lambda y: y - 1]] },
        { 1, 23 }
      )
    )
  end)

  it("expands with multiline parenthesized_expression", function()
    assert.are.same(
      {
        [[if (foo() > 100 or foo() < 200):]],
        [[    y = x = (1 or 3)]],
        [[else:]],
        [[    y = x = (2 or 4)]],
      },
      Helper:call(
        {
          [[y = x = (1 or]],
          [[         3) if (foo() > 100 or]],
          [[                foo() < 200) else (2 or]],
          [[                                   4)]],
        },
        { 2, 13 }
      )
    )
  end)

  it("expands with multiline structures and fn args", function()
    assert.are.same(
      {
        [[if foo(x, y):]],
        [=[    return [3, 4, 5]]=],
        [[else:]],
        [[    return {4, 5, 6}]],
      },
      Helper:call(
        {
          [[return []],
          [[    3,]],
          [[    4,]],
          [[    5]],
          [[] if foo(x,]],
          [[         y) else {]],
          [[    4,]],
          [[    5,]],
          [[    6]],
          [[}]],
        },
        { 5, 3 }
      )
    )
  end)

end)
