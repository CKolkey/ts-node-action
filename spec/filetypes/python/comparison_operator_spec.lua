dofile("./spec/spec_helper.lua")

local Helper = SpecHelper.new("python", { shiftwidth = 4 })

describe("comparison_operator", function()

  it("toggles operator in multiline context", function()
    assert.are.same(
      {
        [[if (100 <]],
        [[    foo(x,]],
        [[        y)):]],
        [[    x = 1]],
      },
      Helper:call({
        [[if (100 >]],
        [[    foo(x,]],
        [[        y)):]],
        [[    x = 1]],
      }, {1, 9})
    )
  end)

end)
