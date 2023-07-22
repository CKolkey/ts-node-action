dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("git_rebase")

describe("command", function()
  it("turns 'pick' into 'fixup'", function()
    assert.are.same({ "fixup" }, Helper:call("pick"))
  end)

  it("turns 'fixup' into 'reword'", function()
    assert.are.same({ "reword" }, Helper:call("fixup"))
  end)

  it("turns 'reword' into 'edit'", function()
    assert.are.same({ "edit" }, Helper:call("reword"))
  end)

  it("turns 'edit' into 'squash'", function()
    assert.are.same({ "squash" }, Helper:call("edit"))
  end)

  it("turns 'squash' into 'exec'", function()
    assert.are.same({ "exec" }, Helper:call("squash"))
  end)

  it("turns 'exec' into 'break'", function()
    assert.are.same({ "break" }, Helper:call("exec"))
  end)

  it("turns 'break' into 'drop'", function()
    assert.are.same({ "drop" }, Helper:call("break"))
  end)

  it("turns 'drop' into 'label'", function()
    assert.are.same({ "label" }, Helper:call("drop"))
  end)

  it("turns 'label' into 'reset'", function()
    assert.are.same({ "reset" }, Helper:call("label"))
  end)

  it("turns 'reset' into 'merge'", function()
    assert.are.same({ "merge" }, Helper:call("reset"))
  end)

  it("turns 'merge' into 'pick'", function()
    assert.are.same({ "pick" }, Helper:call("merge"))
  end)

  it("turns 'p' into 'fixup'", function()
    assert.are.same({ "fixup" }, Helper:call("p"))
  end)

  it("turns 'f' into 'reword'", function()
    assert.are.same({ "reword" }, Helper:call("f"))
  end)

  it("turns 'r' into 'edit'", function()
    assert.are.same({ "edit" }, Helper:call("r"))
  end)

  it("turns 'e' into 'squash'", function()
    assert.are.same({ "squash" }, Helper:call("e"))
  end)

  it("turns 's' into 'exec'", function()
    assert.are.same({ "exec" }, Helper:call("s"))
  end)

  it("turns 'x' into 'break'", function()
    assert.are.same({ "break" }, Helper:call("x"))
  end)

  it("turns 'b' into 'drop'", function()
    assert.are.same({ "drop" }, Helper:call("b"))
  end)

  it("turns 'd' into 'label'", function()
    assert.are.same({ "label" }, Helper:call("d"))
  end)

  it("turns 'l' into 'reset'", function()
    assert.are.same({ "reset" }, Helper:call("l"))
  end)

  it("turns 't' into 'merge'", function()
    assert.are.same({ "merge" }, Helper:call("t"))
  end)

  it("turns 'm' into 'pick'", function()
    assert.are.same({ "pick" }, Helper:call("m"))
  end)
end)
