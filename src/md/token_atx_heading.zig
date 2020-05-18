const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const assert = std.debug.assert;
const test_util = @import("test_util.zig");
const Token = @import("token.zig").Token;
const TokenId = @import("token.zig").TokenId;
const Lexer = @import("lexer.zig").Lexer;
usingnamespace @import("log.zig");

pub fn ruleAtxHeader(t: *Lexer) !?Token {
    var index: u32 = t.index;
    while (t.getChar(index)) |val| {
        if (val == '#') {
            index += 1;
        } else {
            break;
        }
    }
    if (index > t.index) {
        return t.emit(.AtxHeaderOpen, t.index, index);
    }
    return null;
}

fn checkToken(val: Token, expect: Token) void {
    assert(val.ID == expect.ID);
    assert(val.start == expect.start);
    assert(val.end == expect.end);
    assert(mem.eql(u8, val.string, expect.string));
}

test "atx headings - example 32" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const out = try test_util.getTest(allocator, 32);

    // TODO: move this somplace else
    use_rfc3339_date_handler();

    log.Debugf("test: {}\n-- END OF TEST --\n", .{out});

    var t = try Lexer.init(allocator, out);

    while (true) {
        if (try t.next()) |tok| {
            if (tok.ID == TokenId.EOF) {
                log.Debug("Found EOF");
                break;
            }
        }
    }

    checkToken(t.tokens.items[0], Token{ .ID = TokenId.AtxHeaderOpen, .start = 0, .end = 1, .string = "#" });
    checkToken(t.tokens.items[1], Token{ .ID = TokenId.Whitespace, .start = 1, .end = 2, .string = " " });
    checkToken(t.tokens.items[2], Token{ .ID = TokenId.Line, .start = 2, .end = 5, .string = "foo" });
    checkToken(t.tokens.items[3], Token{ .ID = TokenId.Whitespace, .start = 5, .end = 6, .string = "\n" });
    checkToken(t.tokens.items[4], Token{ .ID = TokenId.AtxHeaderOpen, .start = 6, .end = 8, .string = "##" });
    checkToken(t.tokens.items[5], Token{ .ID = TokenId.Whitespace, .start = 8, .end = 9, .string = " " });
    checkToken(t.tokens.items[6], Token{ .ID = TokenId.Line, .start = 9, .end = 12, .string = "foo" });
    checkToken(t.tokens.items[7], Token{ .ID = TokenId.Whitespace, .start = 12, .end = 13, .string = "\n" });
    checkToken(t.tokens.items[8], Token{ .ID = TokenId.AtxHeaderOpen, .start = 13, .end = 16, .string = "###" });
    checkToken(t.tokens.items[9], Token{ .ID = TokenId.Whitespace, .start = 16, .end = 17, .string = " " });
    checkToken(t.tokens.items[10], Token{ .ID = TokenId.Line, .start = 17, .end = 20, .string = "foo" });
    checkToken(t.tokens.items[11], Token{ .ID = TokenId.Whitespace, .start = 20, .end = 21, .string = "\n" });
    checkToken(t.tokens.items[12], Token{ .ID = TokenId.AtxHeaderOpen, .start = 21, .end = 25, .string = "####" });
    checkToken(t.tokens.items[13], Token{ .ID = TokenId.Whitespace, .start = 25, .end = 26, .string = " " });
    checkToken(t.tokens.items[14], Token{ .ID = TokenId.Line, .start = 26, .end = 29, .string = "foo" });
    checkToken(t.tokens.items[15], Token{ .ID = TokenId.Whitespace, .start = 29, .end = 30, .string = "\n" });
    checkToken(t.tokens.items[16], Token{ .ID = TokenId.AtxHeaderOpen, .start = 30, .end = 35, .string = "#####" });
    checkToken(t.tokens.items[17], Token{ .ID = TokenId.Whitespace, .start = 35, .end = 36, .string = " " });
    checkToken(t.tokens.items[18], Token{ .ID = TokenId.Line, .start = 36, .end = 39, .string = "foo" });
    checkToken(t.tokens.items[19], Token{ .ID = TokenId.Whitespace, .start = 39, .end = 40, .string = "\n" });
    checkToken(t.tokens.items[20], Token{ .ID = TokenId.AtxHeaderOpen, .start = 40, .end = 46, .string = "######" });
    checkToken(t.tokens.items[21], Token{ .ID = TokenId.Whitespace, .start = 46, .end = 47, .string = " " });
    checkToken(t.tokens.items[22], Token{ .ID = TokenId.Line, .start = 47, .end = 50, .string = "foo" });
    checkToken(t.tokens.items[23], Token{ .ID = TokenId.Whitespace, .start = 50, .end = 51, .string = "\n" });
    checkToken(t.tokens.items[24], Token{ .ID = TokenId.EOF, .start = 51, .end = 51, .string = undefined });
}
