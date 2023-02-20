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

  it("expands when after a for_statement", function()
    assert.are.same(
      {
        [[for x in range(10):]],
        [[    if x % 2 == 0:]],
        [[        print(x)]],
        [[    else:]],
        [[        print(x + 1)]],
      },
      Helper:call(
        { [[for x in range(10): print(x) if x % 2 == 0 else print(x + 1)]] },
        { 1, 30 }
      )
    )
  end)

  it("expands when after an if_statement", function()
    assert.are.same(
      {
        [[if x % 2 == 0:]],
        [[    if x > 10:]],
        [[        print(x)]],
        [[    else:]],
        [[        print(x + 1)]],
      },
      Helper:call(
        { [[if x % 2 == 0: print(x) if x > 10 else print(x + 1)]] },
        { 1, 25 }
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

  it("expand a multiline expr with comments", function()
    assert.are.same(
      {
        [[if foo(x, y):]],
        [=[    return [3, 4, 5]]=],
        [[else:]],
        [[    return {4, 5, 6} # j]],
      },
      Helper:call(
        {
          [[return [ # a]],
          [[    3, # b]],
          [[    4, # c]],
          [[    5 # d]],
          [[] if foo(x, # e]],
          [[         y) else { # f]],
          [[    4, # g]],
          [[    5, # h]],
          [[    6 # i]],
          [[} # j]],
        },
        { 5, 3 }
      )
    )
  end)

  it("doesn't expand a condition inside a fn call", function()
    local text = {
      [[foo("param1", 4 if foo() > 100 else 5)]],
    }
    assert.are.same(text, Helper:call(text, { 1, 17 }))
  end)

  it("doesn't expand a condition inside a lambda inside a fn call", function()
    local text = {
      [[foo("param1", lambda x: 4 if foo() > 100 else 5)]],
    }
    assert.are.same(text, Helper:call(text, { 1, 26 }))
  end)

  it("doesn't expand inside a list comprehension", function()
    local text = {
      [[foo([x for x in range(10) if x % 2 == 0])]],
    }
    assert.are.same(text, Helper:call(text, { 1, 27 }))
  end)

  it("doesn't expand inside a list", function()
    local text = {
      [=[return [0, 123 if foo() > 100 else 456]]=],
    }
    assert.are.same(text, Helper:call(text, { 1, 16 }))
  end)

end)
