const std = @import("std");
const mem = std.mem;
const json = std.json;
const testing = std.testing;
const assert = std.debug.assert;

const testUtil = @import("util.zig");

const log = @import("../src/md/log.zig");
const Token = @import("../src/md/token.zig").Token;
const TokenId = @import("../src/md/token.zig").TokenId;
const Lexer = @import("../src/md/lexer.zig").Lexer;
const Parser = @import("../src/md/parse.zig").Parser;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

// "markdown": "\tfoo\tbaz\t\tbim\n",
// "html": "<pre><code>foo\tbaz\t\tbim\n</code></pre>\n",
test "Test Example 001" {
    const testNumber: u8 = 1;
    const parserInput = try testUtil.getTest(allocator, testNumber, testUtil.TestKey.markdown);
    testUtil.dumpTest(parserInput);

    var p = Parser.init(allocator);
    defer p.deinit();
    _ = try p.parse(parserInput);

    const expectLexerJson = @embedFile("expect/lexer/testl_001.json");
    if (try testUtil.compareJsonExpect(allocator, expectLexerJson, p.lex.tokens.items)) |ajson| {
        // log.Errorf("LEXER TEST FAILED! lexer tokens (in json):\n{}\n", .{ajson});
        std.os.exit(1);
    }

    // Used https://codebeautify.org/xmltojson to convert ast from spec to json
    const expectParserJson = @embedFile("expect/parser/testp_001.json");
    if (try testUtil.compareJsonExpect(allocator, expectParserJson, p.root.items)) |ajson| {
        // log.Errorf("PARSER TEST FAILED! parser tree (in json):\n{}\n", .{ajson});
        std.os.exit(1);
    }

    // const expectHtml = try testUtil.getTest(allocator, testNumber, testUtil.TestKey.html);
    // defer allocator.free(expectHtml);
    // if (try testUtil.testHtmlExpect(allocator, expectHtml, &p.root, false)) |ahtml| {
    //     // log.Errorf("HTML TRANSLATE TEST FAILED! html:\n{}\n", .{ahtml});
    //     std.os.exit(1);
    // }
}
