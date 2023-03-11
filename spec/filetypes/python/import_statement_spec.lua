dofile("./spec/spec_helper.lua")

local Helper = SpecHelper.new("python", { shiftwidth = 4 })

describe("import_statement", function()

  it("doesn't cycle with 1 import (same for both)", function()
    assert.are.same(
      {
        [[import bar]],
      },
      Helper:call({
        [[import bar]],
      })
    )
  end)


  it("cycles from single to inline", function()
    assert.are.same(
      {
        [[import bar, baz, qux]],
      },
      Helper:call({
        [[import bar]],
        [[import baz]],
        [[import qux]],
      })
    )
  end)

  it("cycles from inline to single", function()
    assert.are.same(
      {
        [[import bar]],
        [[import baz]],
        [[import qux]],
      },
      Helper:call({
        [[import bar, baz, qux]],
      })
    )
  end)

  it("cycles from inline to single (inline detected w continuation)", function()
    assert.are.same(
      {
        [[import bar]],
        [[import baz]],
      },
      Helper:call({
        [[import bar, \]],
        [[    baz]],
      })
    )
  end)

  it("cycles from inline to single with mixed siblings", function()
    assert.are.same(
      {
        [[import qux]],
        [[import bar]],
        [[import baz]],
      },
      Helper:call({
        [[import qux]],
        [[import bar, baz]],
      }, {2, 1})
    )
  end)

  it("cycles from single to inline only close siblings", function()
    assert.are.same(
      {
        [[from abc import a, b, c]],
        [[import bar, bee, hah]],
        [[from xyz import x, y, z]],
      },
      Helper:call({
        [[from abc import a, b, c]],
        [[import bar]],
        [[import bee]],
        [[import hah]],
        [[from xyz import x, y, z]],
      }, {3, 1})
    )
  end)

  it("cycles with deep relative imports", function()
    assert.are.same(
      {
        [[import foo.bar.baz.qux]],
        [[import fish.sandwich]],
        [[import boo.ghosts]],
      },
      Helper:call({
        [[import foo.bar.baz.qux, fish.sandwich, boo.ghosts]],
      })
    )
  end)

  it("cycles with import aliases", function()
    assert.are.same(
      {
        [[import foo.bar as b]],
        [[import baz as z]],
        [[import qux as q]],
      },
      Helper:call({
        [[import foo.bar as b, baz as z, qux as q]],
      })
    )
  end)

  it("doesn't cycle with comments", function()
    local text = {
      [[import bar # comment]],
      [[import baz # comment]],
      [[import qux # comment]],
    }
    assert.are.same(text, Helper:call(text))
  end)

  it("cycles with sibling comments", function()
    assert.are.same(
      {
        [[from abc import abc]],
        [[# comment]],
        [[import bar]],
        [[import baz]],
        [[import qux]],
        [[# comment]],
        [[from xyz import x, y, z]],
      },
      Helper:call({
        [[from abc import abc]],
        [[# comment]],
        [[import bar, baz, qux]],
        [[# comment]],
        [[from xyz import x, y, z]],
      }, {3, 1})
    )
  end)

  it("cycles to multiline inline (it exceeded config.line_length)", function()
    assert.are.same(
      {
        [[import this.will.be.long, once.its.inlined, it.will.be.too.long, bar, baz, qux]],
        [[import abc, xyz, to.fit.on.one.line]],
      },
      Helper:call({
        [[import this.will.be.long]],
        [[import once.its.inlined]],
        [[import it.will.be.too.long]],
        [[import bar, baz, qux, abc, xyz]],
        [[import to.fit.on.one.line]],
      })
    )
  end)

  it("cycles to multiline inline while indented", function()
    assert.are.same(
      {
        [[def foo():]],
        [[    import this.will.be.long, once.its.inlined, it.will.be.too.long, bar, baz]],
        [[    import qux, abc, xyz, to.fit.on.one.line]],
      },
      Helper:call({
        [[def foo():]],
        [[    import this.will.be.long]],
        [[    import once.its.inlined]],
        [[    import it.will.be.too.long]],
        [[    import bar, baz, qux, abc, xyz]],
        [[    import to.fit.on.one.line]],
      }, {2, 5})
    )
  end)

end)
