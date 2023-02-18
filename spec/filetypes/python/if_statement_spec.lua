dofile("./spec/spec_helper.lua")

local Helper = SpecHelper:new("python")

describe("if_statement", function()

  it("if/else inlines with a single assignment", function()
    assert.are.same(
      { [[x = 1 if foo(y) else 2]] },
      Helper:call({
        [[if foo(y):]],
        [[    x = 1]],
        [[else:]],
        [[    x = 2]],
      })
    )
  end)

  it("if/else inlines with a multi assignment", function()
    assert.are.same(
      { [[x = y = z = 1 if foo(a) else 2]] },
      Helper:call({
        [[if foo(a):]],
        [[    x = y = z = 1]],
        [[else:]],
        [[    x = y = z = 2]],
      })
    )
  end)

  it("if/else doesn't inline a multi assignment when identifiers differ (consequence)", function()
    local text = {
      [[if foo(a):]],
      [[    c = y = z = 1]],
      [[else:]],
      [[    x = y = z = 2]],
    }
    assert.are.same(text, text)
  end)

  it("if/else doesn't inline a multi assignment when identifiers differ (alternative)", function()
    local text = {
      [[if foo(a):]],
      [[    x = y = z = 1]],
      [[else:]],
      [[    x = y = c = 2]],
    }
    assert.are.same(text, text)
  end)


  it("if/else inlines with a return", function()
    assert.are.same(
      { [[return 1 if foo(y) else 2]] },
      Helper:call({
        [[if foo(y):]],
        [[    return 1]],
        [[else:]],
        [[    return 2]],
      })
    )
  end)

  it("if/else inlines with function calls", function()
    assert.are.same(
      { [[bar() if foo(y) else baz()]] },
      Helper:call({
        [[if foo(y):]],
        [[    bar()]],
        [[else:]],
        [[    baz()]],
      })
    )
  end)

  it("if/else inlines with parenthesized lambda expr", function()
    assert.are.same(
      { [[x = (lambda y: y + 1) if z is not None else (lambda y: y - 1)]] },
      Helper:call({
        [[if z is not None:]],
        [[    x = (lambda y: y + 1)]],
        [[else:]],
        [[    x = (lambda y: y - 1)]],
      })
    )
  end)

  it("if/else inlines with bare lambda expr (auto parens)", function()
    assert.are.same(
      { [[x = (lambda y: y + 3) if z is not None else (lambda y: y - 4)]] },
      Helper:call({
        [[if z is not None:]],
        [[    x = lambda y: y + 3]],
        [[else:]],
        [[    x = lambda y: y - 4]],
      })
    )
  end)

  it("if/else inlines with bare boolean_operator (auto parens)", function()
    assert.are.same(
      { [[x = (a or b) if z is not None else (c or d)]] },
      Helper:call({
        [[if z is not None:]],
        [[    x = a or b]],
        [[else:]],
        [[    x = c or d]],
      })
    )
  end)

  it("if/else inlines with bare conditional_expression (auto parens)", function()
    assert.are.same(
      { [[x = (3 if a else 4) if z is not None else (5 if b else 6)]] },
      Helper:call({
        [[if z is not None:]],
        [[    x = 3 if a else 4]],
        [[else:]],
        [[    x = 5 if b else 6]],
      })
    )
  end)

  it("if/else inlines with multiline parenthized fn args, boolean op, structures", function()
    assert.are.same(
      {
        [=[y = x = [1, 3] if (foo(a, b) > 100 or foo(c, d) < 200) else (False or True)]=]
      },
      Helper:call(
        {
          [[if (foo(a,]],
          [[        b) > 100 or]],
          [[    foo(c,]],
          [[        d) < 200):]],
          [[    y = x = [1,]],
          [=[             3]]=],
          [[else:]],
          [[    y = x = (False or]],
          [[             True)]],
        }
      )
    )
  end)

end)
