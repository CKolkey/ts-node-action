dofile("./spec/spec_helper.lua")

local Helper = SpecHelper.new("python", { shiftwidth = 4 })

describe("conditional padding", function()
  it("checking 'is not'", function()
    assert.are.same(
      {
        [[x = 1 if y is not None and foo() > 100 else 2]],
      },
      Helper:call({
        "if y is not None and foo() > 100:",
        "    x = 1",
        "else:",
        "    x = 2",
      })
    )
  end)

  it("checking unary and binary '-' operator", function()
    assert.are.same(
      {
        "xs = [x for x in range(10) if x + -3 or -x and x - 3 == 0 and abs(x - 1) < 2]",
      },
      Helper:call({
        "xs = [",
        "    x",
        "    for x in range(10)",
        "    if x + -3 or -x and x - 3 == 0 and abs(x - 1) < 2",
        "]",
      }, { 1, 6 })
    )
  end)

  it("checking 'not in'", function()
    assert.are.same(
      { "print(5 not in list1)" },
      Helper:call({
        "print(",
        "    5 not in list1",
        ")",
      }, { 1, 6 })
    )
  end)
end)
