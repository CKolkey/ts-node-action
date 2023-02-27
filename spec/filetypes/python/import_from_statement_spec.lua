dofile("./spec/spec_helper.lua")

local Helper = SpecHelper.new("python", { shiftwidth = 4 })

describe("import_from_statement", function()


  it("cycles from single to block", function()
    assert.are.same(
      {
        [[from foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[)]],
      },
      Helper:call({
        [[from foo import bar]],
        [[from foo import baz]],
        [[from foo import qux]],
      })
    )
  end)

  it("cycles from inline to block", function()
    assert.are.same(
      {
        [[from foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[)]],
      },
      Helper:call({
        [[from foo import bar, baz, qux]],
      })
    )
  end)

  it("cycles from block to single", function()
    assert.are.same(
      {
        [[from foo import bar]],
        [[from foo import baz]],
        [[from foo import qux]],
      },
      Helper:call({
        [[from foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[)]],
      })
    )
  end)

  it("cycles from block to single (continuation makes it a block)", function()
    assert.are.same(
      {
        [[from foo import bar]],
        [[from foo import baz]],
        [[from foo import qux]],
      },
      Helper:call({
        [[from foo import bar, \]],
        [[    baz, qux]],
      })
    )
  end)

  it("cycles from inline to block with mixed siblings", function()
    assert.are.same(
      {
        [[from foo import (]],
        [[    qux,]],
        [[    bar,]],
        [[    baz,]],
        [[)]],
      },
      Helper:call({
        [[from foo import qux]],
        [[from foo import bar, baz]],
      }, {2, 1})
    )
  end)

  it("cycles from block to single with mixed siblings", function()
    assert.are.same(
      {
        [[from foo import a]],
        [[from foo import b]],
        [[from foo import c]],
        [[from foo import bar]],
        [[from foo import baz]],
        [[from foo import qux]],
        [[from foo import d]],
        [[from foo import e]],
      },
      Helper:call({
        [[from foo import a, b]],
        [[from foo import c]],
        [[from foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[)]],
        [[from foo import d, e]],
      }, {3, 1})
    )
  end)

  it("cycles from inline to block only close siblings", function()
    assert.are.same(
      {
        [[from abc import a, b, c]],
        [[from foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[    bee,]],
        [[    boo,]],
        [[    hah,]],
        [[)]],
        [[from xyz import x, y, z]],
      },
      Helper:call({
        [[from abc import a, b, c]],
        [[from foo import bar, baz, qux]],
        [[from foo import bee, boo]],
        [[from foo import hah]],
        [[from xyz import x, y, z]],
      }, {3, 1})
    )
  end)

  it("cycles with relative imports", function()
    assert.are.same(
      {
        [[from .foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[)]],
      },
      Helper:call({
        [[from .foo import bar, baz, qux]],
      })
    )
  end)

  it("cycles with relative imports", function()
    assert.are.same(
      {
        [[from .foo import bar]],
        [[from .foo import baz]],
        [[from .foo import qux]],
      },
      Helper:call({
        [[from .foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[)]],
      })
    )
  end)

  it("cycles with deep relative imports", function()
    assert.are.same(
      {
        [[from .foo.bar.baz import (]],
        [[    qux,]],
        [[    bee,]],
        [[    boo,]],
        [[)]],
      },
      Helper:call({
        [[from .foo.bar.baz import qux, bee, boo]],
      })
    )
  end)

  it("cycles with multi-level relative imports", function()
    assert.are.same(
      {
        [[from ...foo import (]],
        [[    bar,]],
        [[    baz,]],
        [[    qux,]],
        [[)]],
      },
      Helper:call({
        [[from ...foo import bar, baz, qux]],
      })
    )
  end)

  it("cycles with import aliases", function()
    assert.are.same(
      {
        [[from foo import (]],
        [[    bar as b,]],
        [[    baz as z,]],
        [[    qux as q,]],
        [[)]],
      },
      Helper:call({
        [[from foo import bar as b, baz as z, qux as q]],
      })
    )
  end)

  it("doesn't cycle with embedded comments", function()
    local text = {
      [[from foo import (]],
      [[    bar, # comment]],
      [[    baz, # comment]],
      [[    qux, # comment]],
      [[)]],
    }
    assert.are.same(text, Helper:call(text))
  end)

  it("cycles with sibling comments", function()
    assert.are.same(
      {
        [[from foo import bar]],
        [[# comment]],
        [[from foo import (]],
        [[    baz,]],
        [[)]],
        [[# comment]],
        [[from foo import qux]],
      },
      Helper:call({
        [[from foo import bar]],
        [[# comment]],
        [[from foo import baz]],
        [[# comment]],
        [[from foo import qux]],
      }, {3, 1})
    )
  end)
end)
