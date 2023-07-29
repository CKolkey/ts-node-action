dofile("./spec/spec_helper.lua")

local Helper = SpecHelper.new("python", { shiftwidth = 4 })

local single = "'"
local double = '"'
local triple1 = "'''"
local triple2 = '"""'

describe("string", function()
  it("toggles " .. single .. " into " .. double, function()
    local input = { single .. "string" .. single }
    local want = { double .. "string" .. double }
    assert.are.same(want, Helper:call(input, { 1, 1 }))
    assert.are.same(want, Helper:call(input, { 1, 4 }))
    assert.are.same(want, Helper:call(input, { 1, #input }))
  end)
  it("toggles " .. double .. " into " .. single, function()
    local input = { double .. "string" .. double }
    local want = { single .. "string" .. single }
    assert.are.same(want, Helper:call(input, { 1, 1 }))
    assert.are.same(want, Helper:call(input, { 1, 4 }))
    assert.are.same(want, Helper:call(input, { 1, #input }))
  end)
  it("toggles " .. triple1 .. " into " .. triple2, function()
    local input = { triple1 .. "string" .. triple1 }
    local want = { triple2 .. "string" .. triple2 }
    assert.are.same(want, Helper:call(input, { 1, 1 }))
    assert.are.same(want, Helper:call(input, { 1, 4 }))
    assert.are.same(want, Helper:call(input, { 1, #input }))
  end)
  it("toggles " .. triple2 .. " into " .. triple1, function()
    local input = { triple2 .. "string" .. triple2 }
    local want = { triple1 .. "string" .. triple1 }
    assert.are.same(want, Helper:call(input, { 1, 1 }))
    assert.are.same(want, Helper:call(input, { 1, 4 }))
    assert.are.same(want, Helper:call(input, { 1, #input }))
  end)
  it(
    "toggles multi-line " .. triple2 .. " into multi-line " .. triple1,
    function()
      local input = { triple2, "string", triple2 }
      local want = { triple1, "string", triple1 }
      assert.are.same(want, Helper:call(input, { 1, 1 }))
      assert.are.same(want, Helper:call(input, { 2, 1 }))
      assert.are.same(want, Helper:call(input, { 3, 1 }))
    end
  )
  it(
    "toggles multi-line " .. triple1 .. " into multi-line " .. triple2,
    function()
      local input = { triple1, "string", triple1 }
      local want = { triple2, "string", triple2 }
      assert.are.same(want, Helper:call(input, { 1, 1 }))
      assert.are.same(want, Helper:call(input, { 2, 1 }))
      assert.are.same(want, Helper:call(input, { 3, 1 }))
    end
  )
  it("toggles f-strings", function()
    local input = { "f" .. single .. "string {foo}" .. single }
    local want = { "f" .. double .. "string {foo}" .. double }
    assert.are.same(want, Helper:call(input, { 1, 1 }))
    assert.are.same(want, Helper:call(input, { 1, 4 }))
    assert.are.same(want, Helper:call(input, { 1, #input }))
  end)
  it("toggles multi-line f-strings", function()
    local input = { "f" .. triple2, "string {foo}", triple2 }
    local want = { "f" .. triple1, "string {foo}", triple1 }
    assert.are.same(want, Helper:call(input, { 1, 1 }))
    assert.are.same(want, Helper:call(input, { 2, 1 }))
    assert.are.same(want, Helper:call(input, { 3, 1 }))
  end)
  it("toggles multi-line f-string with nested string", function()
    local input = { "f" .. triple2, 'string {"nested"}', triple2 }
    local want_outer = { "f" .. triple1, 'string {"nested"}', triple1 }
    assert.are.same(want_outer, Helper:call(input, { 1, 1 }))
    assert.are.same(want_outer, Helper:call(input, { 2, 1 }))
    assert.are.same(want_outer, Helper:call(input, { 3, 1 }))

    local want_nested = { "f" .. triple2, "string {'nested'}", triple2 }
    assert.are.same(want_nested, Helper:call(input, { 2, 12 }))
  end)
end)
