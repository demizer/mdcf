const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const assert = std.debug.assert;

const log = @import("log.zig");
const Token = @import("token.zig").Token;
const testUtil = @import("test_util.zig");
const TokenId = @import("token.zig").TokenId;
const checkToken = @import("lexer.zig").checkToken;

test "test example 1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const out = try testUtil.getTest(allocator, 1, testUtil.TestKey.markdown);

    // log.config(log.logger.Level.Debug, true);
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

    // "markdown": "\tfoo\tbaz\t\tbim\n",
    checkToken(t.tokens.items[0], Token{ .ID = TokenId.Whitespace, .startOffset = 0, .endOffset = 0, .string = "\t", .lineNumber = 1, .column = 1 });
    checkToken(t.tokens.items[1], Token{ .ID = TokenId.Text, .startOffset = 1, .endOffset = 3, .string = "foo", .lineNumber = 1, .column = 2 });
    checkToken(t.tokens.items[2], Token{ .ID = TokenId.Whitespace, .startOffset = 4, .endOffset = 4, .string = "\t", .lineNumber = 1, .column = 5 });
    checkToken(t.tokens.items[3], Token{ .ID = TokenId.Text, .startOffset = 5, .endOffset = 7, .string = "baz", .lineNumber = 1, .column = 6 });
    checkToken(t.tokens.items[4], Token{ .ID = TokenId.Whitespace, .startOffset = 8, .endOffset = 9, .string = "\t\t", .lineNumber = 1, .column = 9 });
    checkToken(t.tokens.items[5], Token{ .ID = TokenId.Text, .startOffset = 10, .endOffset = 12, .string = "bim", .lineNumber = 1, .column = 11 });
    checkToken(t.tokens.items[6], Token{ .ID = TokenId.Whitespace, .startOffset = 13, .endOffset = 13, .string = "\n", .lineNumber = 1, .column = 14 });
    checkToken(t.tokens.items[7], Token{ .ID = TokenId.EOF, .startOffset = 14, .endOffset = 14, .string = "", .lineNumber = 1, .column = 14 });
}

test "atx headings - example 32" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const out = try testUtil.getTest(allocator, 32, testUtil.TestKey.markdown);

    log.Debugf("test:\n{}\n-- END OF TEST --\n", .{out});

    var t = try Lexer.init(allocator, out);

    while (true) {
        if (try t.next()) |tok| {
            if (tok.ID == TokenId.EOF) {
                log.Debug("Found EOF");
                break;
            }
        }
    }

    checkToken(t.tokens.items[0], Token{ .ID = TokenId.AtxHeader, .startOffset = 0, .endOffset = 0, .column = 1, .lineNumber = 1, .string = "#" });
    checkToken(t.tokens.items[1], Token{ .ID = TokenId.Whitespace, .startOffset = 1, .endOffset = 1, .column = 2, .lineNumber = 1, .string = " " });
    checkToken(t.tokens.items[2], Token{ .ID = TokenId.Text, .startOffset = 2, .endOffset = 4, .column = 3, .lineNumber = 1, .string = "foo" });
    checkToken(t.tokens.items[3], Token{ .ID = TokenId.Whitespace, .startOffset = 5, .endOffset = 5, .column = 6, .lineNumber = 1, .string = "\n" });
    checkToken(t.tokens.items[4], Token{ .ID = TokenId.AtxHeader, .startOffset = 6, .endOffset = 7, .column = 1, .lineNumber = 2, .string = "##" });
    checkToken(t.tokens.items[5], Token{ .ID = TokenId.Whitespace, .startOffset = 8, .endOffset = 8, .column = 3, .lineNumber = 2, .string = " " });
    checkToken(t.tokens.items[6], Token{ .ID = TokenId.Text, .startOffset = 9, .endOffset = 11, .column = 4, .lineNumber = 2, .string = "foo" });
    checkToken(t.tokens.items[7], Token{ .ID = TokenId.Whitespace, .startOffset = 12, .endOffset = 12, .column = 7, .lineNumber = 2, .string = "\n" });
    checkToken(t.tokens.items[8], Token{ .ID = TokenId.AtxHeader, .startOffset = 13, .endOffset = 15, .column = 1, .lineNumber = 3, .string = "###" });
    checkToken(t.tokens.items[9], Token{ .ID = TokenId.Whitespace, .startOffset = 16, .endOffset = 16, .column = 4, .lineNumber = 3, .string = " " });
    checkToken(t.tokens.items[10], Token{ .ID = TokenId.Text, .startOffset = 17, .endOffset = 19, .column = 5, .lineNumber = 3, .string = "foo" });
    checkToken(t.tokens.items[11], Token{ .ID = TokenId.Whitespace, .startOffset = 20, .endOffset = 20, .column = 8, .lineNumber = 3, .string = "\n" });
    checkToken(t.tokens.items[12], Token{ .ID = TokenId.AtxHeader, .startOffset = 21, .endOffset = 24, .column = 1, .lineNumber = 4, .string = "####" });
    checkToken(t.tokens.items[13], Token{ .ID = TokenId.Whitespace, .startOffset = 25, .endOffset = 25, .column = 5, .lineNumber = 4, .string = " " });
    checkToken(t.tokens.items[14], Token{ .ID = TokenId.Text, .startOffset = 26, .endOffset = 28, .column = 6, .lineNumber = 4, .string = "foo" });
    checkToken(t.tokens.items[15], Token{ .ID = TokenId.Whitespace, .startOffset = 29, .endOffset = 29, .column = 9, .lineNumber = 4, .string = "\n" });
    checkToken(t.tokens.items[16], Token{ .ID = TokenId.AtxHeader, .startOffset = 30, .endOffset = 34, .column = 1, .lineNumber = 5, .string = "#####" });
    checkToken(t.tokens.items[17], Token{ .ID = TokenId.Whitespace, .startOffset = 35, .endOffset = 35, .column = 6, .lineNumber = 5, .string = " " });
    checkToken(t.tokens.items[18], Token{ .ID = TokenId.Text, .startOffset = 36, .endOffset = 38, .column = 7, .lineNumber = 5, .string = "foo" });
    checkToken(t.tokens.items[19], Token{ .ID = TokenId.Whitespace, .startOffset = 39, .endOffset = 39, .column = 10, .lineNumber = 5, .string = "\n" });
    checkToken(t.tokens.items[20], Token{ .ID = TokenId.AtxHeader, .startOffset = 40, .endOffset = 45, .column = 1, .lineNumber = 6, .string = "######" });
    checkToken(t.tokens.items[21], Token{ .ID = TokenId.Whitespace, .startOffset = 46, .endOffset = 46, .column = 7, .lineNumber = 6, .string = " " });
    checkToken(t.tokens.items[22], Token{ .ID = TokenId.Text, .startOffset = 47, .endOffset = 49, .column = 8, .lineNumber = 6, .string = "foo" });
    checkToken(t.tokens.items[23], Token{ .ID = TokenId.Whitespace, .startOffset = 50, .endOffset = 50, .column = 11, .lineNumber = 6, .string = "\n" });
    checkToken(t.tokens.items[24], Token{ .ID = TokenId.EOF, .startOffset = 51, .endOffset = 51, .column = 11, .lineNumber = 6, .string = undefined });
}
