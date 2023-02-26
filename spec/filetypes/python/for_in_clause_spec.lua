dofile("./spec/spec_helper.lua")

local Helper = SpecHelper.new("python", { shiftwidth = 4 })

describe("for_in_clause", function()

  it("expands list assignment for", function()
    assert.are.same(
      {
        "xs = []",
        "for x in range(10):",
        "    xs.append(x)",
      },
      Helper:call({"xs = [x for x in range(10)]"}, {1, 9})
    )
  end)

  it("expands list assignment for/if", function()
    assert.are.same(
      {
        "xs = []",
        "for x in range(10):",
        "    if -x and x - 3 == 0 and abs(x - 1) < 2:",
        "        xs.append(x)",
      },
      Helper:call({
        "xs = [x for x in range(10) if -x and x - 3 == 0 and abs(x - 1) < 2]"
      }, {1, 9})
    )
  end)

  it("expands set assignment for/if", function()
    assert.are.same(
      {
        "xs = set()",
        "for x in range(10):",
        "    if -x and x - 3 == 0 and abs(x - 1) < 2:",
        "        xs.add(x)",
      },
      Helper:call({
        "xs = {x for x in range(10) if -x and x - 3 == 0 and abs(x - 1) < 2}"
      }, {1, 9})
    )
  end)

  it("expands dict assignment for/if", function()
    assert.are.same(
      {
        "xs = {}",
        "for x in range(10):",
        "    if -x and abs(x - 1) < 2:",
        "        xs[x] = x + 1",
      },
      Helper:call({
        "xs = {x: x + 1 for x in range(10) if -x and abs(x - 1) < 2}"
      }, {1, 16})
    )
  end)

  it("expands list return for", function()
    assert.are.same(
      {
        "result = []",
        "for x in range(10):",
        "    result.append(x)",
        "return result",
      },
      Helper:call({
        "return [x for x in range(10)]"
      }, {1, 11})
    )
  end)

  it("expands list return for/if", function()
    assert.are.same(
      {
        "result = []",
        "for x in range(10):",
        "    if -x and abs(x - 1) < 2:",
        "        result.append(x)",
        "return result",
      },
      Helper:call({
        "return [x for x in range(10) if -x and abs(x - 1) < 2]"
      }, {1, 11})
    )
  end)

  it("expands set return for/if", function()
    assert.are.same(
      {
        "result = set()",
        "for x in range(10):",
        "    if -x and abs(x - 1) < 2:",
        "        result.add(x)",
        "return result",
      },
      Helper:call({
        "return {x for x in range(10) if -x and abs(x - 1) < 2}"
      }, {1, 11})
    )
  end)

  it("expands dict return for/if", function()
    assert.are.same(
      {
        "result = {}",
        "for x in range(10):",
        "    if -x and abs(x - 1) < 2:",
        "        result[x] = x + 1",
        "return result",
      },
      Helper:call({
        "return {x: x + 1 for x in range(10) if -x and abs(x - 1) < 2}"
      }, {1, 18})
    )
  end)

  it("doesn't expand generator assignment", function()
    local text = {
      "xs = (x for x in range(10))"
    }
    assert.are.same(text, Helper:call(text, {1, 9}))
  end)

  it("doesn't expand generator return", function()
    local text = {
      "return (x for x in range(10))"
    }
    assert.are.same(text, Helper:call(text, {1, 11}))
  end)

  it("expands a multiline dict assignment with comments", function()
    assert.are.same(
      {
        "a = {}",
        "#  before for 1",
        "for x in range(",
        "        #  for inside arg",
        "        1,",
        "        5, #  for inside arg 2",
        "    ):",
        "    #  before if 1",
        "    if (x < 2 or",
        "            x - 3 == 0):",
        "        # after if 1",
        "        # before body",
        "        a[x] = foo(x) + 1",
      },
      Helper:call({
        "a = { # before body",
        "    x: foo(x) + 1",
        "    #  before for 1",
        "    for x in range(",
        "        #  for inside arg",
        "        1,",
        "        5, #  for inside arg 2",
        "    )",
        "    #  before if 1",
        "    if (x < 2 or",
        "        x - 3 == 0)",
        "    # after if 1",
        "}",
      }, {4, 5})
    )
  end)

  it("expands absurd multiline set assignment with comments", function()
    assert.are.same(
      {
        "a = b = c = set()",
        "#  before for 1",
        "for x in range(",
        "        #  for inside arg",
        "        1,",
        "        5, #  for inside arg 2",
        "    ):",
        "    # before if 1",
        "    if x != y:",
        "        # before for 2",
        "        for z in {",
        "            # for inside arg",
        "            1, 2, 3",
        "            # for inside arg 2",
        "        }:",
        "            # before if 2",
        "            if y != z:",
        "                # after if 2",
        "                # before body",
        "                a.add((x,",
        "                       y, #  y",
        "                       z))",
        "                b.add((x,",
        "                       y, #  y",
        "                       z))",
        "                c.add((x,",
        "                       y, #  y",
        "                       z)) # after comprehension",
      },
      Helper:call({
        "a = b = c = { # before body",
        "             (x,",
        "              y, #  y",
        "              z)",
        "             #  before for 1",
        "             for x in range(",
        "                 #  for inside arg",
        "                 1,",
        "                 5, #  for inside arg 2",
        "                 )",
        "             # before if 1",
        "             if x != y",
        "             # before for 2",
        "             for z in {",
        "                 # for inside arg",
        "                 1, 2, 3",
        "                 # for inside arg 2",
        "                 }",
        "             # before if 2",
        "             if y != z",
        "             # after if 2",
        "             } # after comprehension",
      }, {6, 14})
    )
  end)

end)
