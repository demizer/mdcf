const std = @import("std");
const mem = std.mem;
const json = std.json;
const testing = std.testing;
const assert = std.debug.assert;

const log = @import("log.zig");
const Token = @import("token.zig").Token;
const testUtil = @import("test_util.zig");
const TokenId = @import("token.zig").TokenId;
const Lexer = @import("lexer.zig").Lexer;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = &arena.allocator;

fn runLexerTest(testExampleNumber: u16) !Lexer {
    const out = try testUtil.getTest(allocator, testExampleNumber, testUtil.TestKey.markdown);
    try std.io.getStdOut().writer().print("\n", .{});
    log.Debugf("test:\n{}-- END OF TEST --\n", .{out});
    var t = try Lexer.init(allocator, out);
    while (true) {
        if (try t.next()) |tok| {
            if (tok.ID == TokenId.EOF) {
                log.Debug("Found EOF");
                break;
            }
        }
    }
    return t;
}

test "Lexer Test 001" {
    // "markdown": "\tfoo\tbaz\t\tbim\n",
    var t = try runLexerTest(1);
    defer t.deinit();
    const expectJson = @embedFile("../../test/expect/lexer/testl_001.json");
    if (testUtil.compareJsonExpect(allocator, expectJson, t.tokens.items)) |actualJson| {
        // log.Errorf("TEST FAILED! lexer tokens (in json):\n{}\n", .{actualJson});
        std.os.exit(1);
    }
}

test "Lexer Test 002" {
    // "markdown": "  \tfoo\tbaz\t\tbim\n",
    var t = try runLexerTest(2);
    defer t.deinit();
    const expectJson = @embedFile("../../test/expect/lexer/testl_002.json");
    if (testUtil.compareJsonExpect(allocator, expectJson, t.tokens.items)) |actualJson| {
        // log.Errorf("TEST FAILED! lexer tokens (in json):\n{}\n", .{actualJson});
        std.os.exit(1);
    }
}

test "Lexer Test 003" {
    // "markdown": "    a\ta\n    ὐ\ta\n",
    var t = try runLexerTest(3);
    defer t.deinit();
    const expectJson = @embedFile("../../test/expect/lexer/testl_003.json");
    if (testUtil.compareJsonExpect(allocator, expectJson, t.tokens.items)) |actualJson| {
        // log.Errorf("TEST FAILED! lexer tokens (in json):\n{}\n", .{actualJson});
        std.os.exit(1);
    }
}

test "Lexer Test 032" {
    // "markdown": "# foo\n## foo\n### foo\n#### foo\n##### foo\n###### foo\n",
    var t = try runLexerTest(32);
    defer t.deinit();
    const expectJson = @embedFile("../../test/expect/lexer/testl_032.json");
    if (testUtil.compareJsonExpect(allocator, expectJson, t.tokens.items)) |actualJson| {
        // log.Errorf("TEST FAILED! lexer tokens (in json):\n{}\n", .{actualJson});
        std.os.exit(1);
    }
}
