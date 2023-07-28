dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("julia", { shiftwidth = 2 })

describe("boolean", function()
  it("toggles 'true' into 'false'", function()
    assert.are.same({ "i = true" }, Helper:call({ "i = false" }, { 1, 6 }))
  end)

  it("toggles 'false' into 'true'", function()
    assert.are.same({ "i = false" }, Helper:call({ "i = true" }, { 1, 6 }))
  end)
end)

describe("operator", function()
  it("toggles '<= into '>='", function()
    assert.are.same({ "i <= 8" }, Helper:call({ "i >= 8" }, { 1, 3 }))
  end)

  it("toggles '>=' into '<='", function()
    assert.are.same({ "i >= 8" }, Helper:call({ "i <= 8" }, { 1, 3 }))
  end)

  it("toggles '>' into '<'", function()
    assert.are.same({ "i > 8" }, Helper:call({ "i < 8" }, { 1, 3 }))
  end)

  it("toggles '<' into '>'", function()
    assert.are.same({ "i < 8" }, Helper:call({ "i > 8" }, { 1, 3 }))
  end)

  it("toggles '∉' into '∈'", function()
    assert.are.same({ "i ∈ 8" }, Helper:call({ "i ∉ 8" }, { 1, 3 }))
  end)

  it("toggles '∈' into '∉'", function()
    assert.are.same({ "i ∈ 8" }, Helper:call({ "i ∉ 8" }, { 1, 3 }))
  end)

  it("toggles '+' into '-'", function()
    assert.are.same({ "i + 8" }, Helper:call({ "i - 8" }, { 1, 3 }))
  end)

  it("toggles '*' into '/'", function()
    assert.are.same({ "i * 8" }, Helper:call({ "i / 8" }, { 1, 3 }))
  end)

  it("toggles '==' into '!='", function()
    assert.are.same({ "i == 8" }, Helper:call({ "i != 8" }, { 1, 3 }))
  end)

  it("toggles '!=' into '=='", function()
    assert.are.same({ "i != 8" }, Helper:call({ "i == 8" }, { 1, 3 }))
  end)
end)

describe("expand/collapse", function()
  it("expands vector_expression", function()
    assert.are.same(
      { "x = [1, 2]" },
      Helper:call({
        "x = [",
        "  1,",
        "  2",
        "]",
      }, { 1, 5 })
    )
  end)

  it("collapses vector_expression", function()
    assert.are.same(
      { "x = [", "  1,", "  2", "]" },
      Helper:call({ "x = [1, 2]" }, { 1, 5 })
    )
  end)

  it("expands function definition", function()
    assert.are.same(
      { "fn(1, 2; x=true)" },
      Helper:call({
        "fn(",
        "  1,",
        "  2;",
        "  x=true",
        ")",
      }, { 1, 3 })
    )
  end)

  it("collapses function definition", function()
    assert.are.same(
      { "fn(", "  1,", "  2;", "  x=true", ")" },
      Helper:call({ "fn(1, 2; x=true)" }, { 1, 3 })
    )
  end)

  it("expands tuple_expression", function()
    assert.are.same(
      { "x = (1, 2)" },
      Helper:call({
        "x = (",
        "  1,",
        "  2",
        ")",
      }, { 1, 5 })
    )
  end)

  it("collapses tuple_expression", function()
    assert.are.same(
      { "x = (", "  1,", "  2", ")" },
      Helper:call({ "x = (1, 2)" }, { 1, 5 })
    )
  end)

  it("expands dict", function()
    assert.are.same(
      { 'Dict("key1"=>1, "key2"=>2)' },
      Helper:call({
        "Dict(",
        '  "key1"=>1,',
        '  "key2"=>2',
        ")",
      }, { 1, 5 })
    )
  end)

  it("collapses dict", function()
    assert.are.same(
      { "Dict(", '  "key1"=>1,', '  "key2"=>2', ")" },
      Helper:call({ 'Dict("key1"=>1, "key2"=>2)' }, { 1, 5 })
    )
  end)
end)

describe("friendly integers", function()
  it("1 million to friendly", function()
    assert.are.same(
      { "x = 1000000" },
      Helper:call({
        "x = 1_000_000",
      }, { 1, 5 })
    )
  end)

  it("1 million to unfriendly", function()
    assert.are.same(
      { "x = 1_000_000" },
      Helper:call({
        "x = 1000000",
      }, { 1, 5 })
    )
  end)
end)
