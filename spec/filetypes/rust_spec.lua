dofile("spec/spec_helper.lua")

local Helper = SpecHelper.new("rust", { shiftwidth = 4 })

describe("boolean", function()
    it("toggles 'true' and 'false'", function()
        assert.are.same({ "let i = true;" }, Helper:call({ "let i = false;" }, { 1, 9 }))
        assert.are.same({ "let i = false;" }, Helper:call({ "let i = true;" }, { 1, 9 }))
    end)
end)

describe("friendly integers", function()
    it("1 million to friendly", function()
        assert.are.same({ "x = 1000000" }, Helper:call({
            "x = 1_000_000",}, { 1, 5 }))
    end)

    it("1 million to unfriendly", function()
        assert.are.same({ "x = 1_000_000" }, Helper:call({
            "x = 1000000",}, { 1, 5 }))
    end)
end)

describe("operator", function()
    -- assignment
    it("toggles '-=' and '+='", function()
        assert.are.same({ "i += 8" }, Helper:call({ "i -= 8" }, { 1, 3 }))
        assert.are.same({ "i -= 8" }, Helper:call({ "i += 8" }, { 1, 3 }))
    end)

    it("toggles '/=' and '%='", function()
        assert.are.same({ "i %= 8" }, Helper:call({ "i /= 8" }, { 1, 3 }))
        assert.are.same({ "i /= 8" }, Helper:call({ "i %= 8" }, { 1, 3 }))
    end)

    -- bitwise assignment
    it("toggles '&=' and '|=' and '^='", function()
        assert.are.same({ "i |= 8" }, Helper:call({ "i &= 8" }, { 1, 3 }))
        assert.are.same({ "i ^= 8" }, Helper:call({ "i |= 8" }, { 1, 3 }))
        assert.are.same({ "i &= 8" }, Helper:call({ "i ^= 8" }, { 1, 3 }))
    end)

    -- comparison
    it("toggles '==' and '!='", function()
        assert.are.same({ "i == 8" }, Helper:call({ "i != 8" }, { 1, 3 }))
        assert.are.same({ "i != 8" }, Helper:call({ "i == 8" }, { 1, 3 }))
    end)

    it("toggles '>' and '<'", function()
        assert.are.same({ "i > 8" }, Helper:call({ "i < 8" }, { 1, 3 }))
        assert.are.same({ "i < 8" }, Helper:call({ "i > 8" }, { 1, 3 }))
    end)

    it("toggles '<= and '>='", function()
        assert.are.same({ "i <= 8" }, Helper:call({ "i >= 8" }, { 1, 3 }))
        assert.are.same({ "i >= 8" }, Helper:call({ "i <= 8" }, { 1, 3 }))
    end)

    -- shift
    it("toggles '<<' and '>>'", function()
        assert.are.same({ "i << 8" }, Helper:call({ "i >> 8" }, { 1, 3 }))
        assert.are.same({ "i >> 8" }, Helper:call({ "i << 8" }, { 1, 3 }))
    end)

    -- shift assignment
    it("toggles '<<=' and '>>='", function()
        assert.are.same({ "i >>= 8" }, Helper:call({ "i <<= 8" }, { 1, 3 }))
        assert.are.same({ "i <<= 8" }, Helper:call({ "i >>= 8" }, { 1, 3 }))
    end)

    -- arithmetic
    it("toggles '+' and '-'", function()
        assert.are.same({ "i + 8" }, Helper:call({ "i - 8" }, { 1, 3 }))
        assert.are.same({ "i - 8" }, Helper:call({ "i + 8" }, { 1, 3 }))
    end)

    it("toggles '*' and '/'", function()
        assert.are.same({ "i * 8" }, Helper:call({ "i / 8" }, { 1, 3 }))
        assert.are.same({ "i / 8" }, Helper:call({ "i * 8" }, { 1, 3 }))
    end)

    -- bitwise
    it("toggles '|' and '&'", function()
        assert.are.same({ "i | 8" }, Helper:call({ "i & 8" }, { 1, 3 }))
        assert.are.same({ "i & 8" }, Helper:call({ "i | 8" }, { 1, 3 }))
    end)

    -- logical
    it("toggles '||' and '&&'", function()
        assert.are.same({ "i || 8" }, Helper:call({ "i && 8" }, { 1, 3 }))
        assert.are.same({ "i && 8" }, Helper:call({ "i || 8" }, { 1, 3 }))
    end)
end)

describe("toggle_multiline", function()
    it("use_list", function()
        assert.are.same(
            {
                "use std::collections::{",
                "    HashMap,",
                "    HashSet",
                "};",
            },
            Helper:call(
                {
                    "use std::collections::{HashMap, HashSet};",
                },
                { 1, 23 }
            )
        )

        assert.are.same(
            {
                "use std::collections::{HashMap, HashSet};",
            },
            Helper:call(
                {
                    "use std::collections::{",
                    "    HashMap,",
                    "    HashSet",
                    "};",
                },
                { 1, 23 }
            )
        )
    end)

    it("block", function()
        assert.are.same(
            {
                "fn main() {",
                "    println!(\"main:\\tmodule '{}', file '{}'\", module_path!(), file!());",
                "    submod::hi();",
                "}"
            },
            Helper:call(
                {
                    "fn main() { println!(\"main:\\tmodule '{}', file '{}'\", module_path!(), file!()); submod::hi();  }"
                },
                { 1, 11 }
            )
        )

        assert.are.same(
            {
                "fn main() { println!(\"main:\\tmodule '{}', file '{}'\", module_path!(), file!()); submod::hi();  }"
            },
            Helper:call(
                {
                    "fn main() {",
                    "    println!(\"main:\\tmodule '{}', file '{}'\", module_path!(), file!());",
                    "    submod::hi();",
                    "}"
                },
                { 1, 11 }
            )
        )

        assert.are.same(
            {
                "{",
                "    visitor.visit_char(self.parse_u8()? as char)",
                "}",
            },
            Helper:call(
                {
                    "{ visitor.visit_char(self.parse_u8()? as char) }",
                },
                { 1, 1 }
            )
        )
        assert.are.same(
            {
                "{ visitor.visit_char(self.parse_u8()? as char) }",
            },
            Helper:call(
                {
                    "{",
                    "    visitor.visit_char(self.parse_u8()? as char)",
                    "}",
                },
                { 1, 1 }
            )
        )
    end)

    it("parameters", function()
        assert.are.same(
            {
                "fn main(",
                "    first: u8,",
                "    second: u8",
                ") {",
                "    submod::hi();",
                "}"
            },
            Helper:call(
                {
                    "fn main(first: u8, second: u8) {",
                    "    submod::hi();",
                    "}"
                },
                { 1, 8 }
            )
        )

        assert.are.same(
            {
                "fn main(first: u8, second: u8) {",
                "    submod::hi();",
                "}"
            },
            Helper:call(
                {
                    "fn main(",
                    "    first: u8,",
                    "    second: u8",
                    ") {",
                    "    submod::hi();",
                    "}"
                },
                { 1, 8 }
            )
        )
    end)

    it("arguments", function()
        assert.are.same(
            {
                "list.insert_at_ith(",
                "    0,",
                "    first_value",
                ");"
            },
            Helper:call(
                {
                    "list.insert_at_ith(0, first_value);",
                },
                { 1, 19 }
            )
        )

        assert.are.same(
            {
                "list.insert_at_ith(0, first_value);",
            },
            Helper:call(
                {
                    "list.insert_at_ith(",
                    "    0,",
                    "    first_value",
                    ");",
                },
                { 1, 19 }
            )
        )
    end)

    it("array_expression", function()
        assert.are.same(
            {
                "let bytes: [u8; 3] = [",
                "    1,",
                "    2,",
                "    3",
                "];",
            },
            Helper:call(
                {
                    "let bytes: [u8; 3] = [1, 2, 3];"
                },
                { 1, 22 }
            )
        )

        assert.are.same(
            {
                "let bytes: [u8; 3] = [1, 2, 3];",
            },
            Helper:call(
                {
                    "let bytes: [u8; 3] = [",
                    "    1,",
                    "    2,",
                    "    3",
                    "];",
                },
                { 1, 22 }
            )
        )
    end)

    it("tuple_expression", function()
        assert.are.same(
            {
                "let foo = (",
                "    0.0,",
                "    4.5",
                ")"
            },
            Helper:call(
                {
                    "let foo = (0.0, 4.5)"
                },
                { 1, 11 }
            )
        )

        assert.are.same(
            {
                "let foo = (0.0, 4.5)",
            },
            Helper:call(
                {
                    "let foo = (",
                    "    0.0,",
                    "    4.5",
                    ")",
                },
                { 1, 11 }
            )
        )
    end)

    it("tuple_pattern", function()
        assert.are.same(
            {
                "let (",
                "a,",
                "b",
                ") = foo;"
            },
            Helper:call(
                {
                    "let (a, b) = foo;"
                },
                { 1, 5 }
            )
        )

        assert.are.same(
            {
                "let (a, b) = foo;",
            },
            Helper:call(
                {
                    "let (",
                    "    a,",
                    "    b",
                    ") = foo;",
                },
                { 1, 5 }
            )
        )
    end)

    it("enum_variant_list", function()
        assert.are.same(
            {
                "enum Foo {",
                "    A,",
                "    B,",
                "    C",
                "}",
            },
            Helper:call(
                {
                    "enum Foo { A, B, C }",
                },
                { 1, 10 }
            )
        )

        assert.are.same(
            {
                "enum Foo { A, B, C }",
            },
            Helper:call(
                {
                    "enum Foo {",
                    "    A,",
                    "    B,",
                    "    C",
                    "}",
                },
                { 1, 10 }
            )
        )
    end)

    it("field_initializer_list", function()
        assert.are.same(
            {
                "Foo {",
                "    a: 1,",
                "    b: 2,",
                "    c: 3",
                "}",
            },
            Helper:call(
                {
                    "Foo { a: 1, b: 2, c: 3 }",
                },
                { 1, 5 }
            )
        )

        assert.are.same(
            {
                "Foo { a: 1, b: 2, c: 3 }",
            },
            Helper:call(
                {
                    "Foo {",
                    "    a: 1,",
                    "    b: 2,",
                    "    c: 3",
                    "}",
                },
                { 1, 5 }
            )
        )
    end)

    it("field_declaration_list", function()
        assert.are.same(
            {
                "struct Foo {",
                "    a: i32,",
                "    b: i32,",
                "    c: i32",
                "}",
            },
            Helper:call(
                {
                    "struct Foo { a: i32, b: i32, c: i32 }",
                },
                { 1, 12 }
            )
        )

        assert.are.same(
            {
                "struct Foo { a: i32, b: i32, c: i32 }",
            },
            Helper:call(
                {
                    "struct Foo {",
                    "    a: i32,",
                    "    b: i32,",
                    "    c: i32",
                    "}",
                },
                { 1, 12 }
            )
        )
    end)
end)
