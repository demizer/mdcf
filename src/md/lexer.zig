const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;
const ArrayList = std.ArrayList;
const token = @import("token.zig");
const atxRules = @import("token_atx_heading.zig");
const inlineRules = @import("token_inline.zig");

usingnamespace @import("log.zig");

pub const Lexer = struct {
    buffer: []const u8,
    index: u32,
    rules: ArrayList(token.TokenRule),
    tokens: ArrayList(token.Token),
    start: u32,

    pub fn init(allocator: *mem.Allocator, buffer: []const u8) !Lexer {
        // Skip the UTF-8 BOM if present
        var t = Lexer{
            .buffer = buffer,
            .index = 0,
            .rules = ArrayList(token.TokenRule).init(allocator),
            .tokens = ArrayList(token.Token).init(allocator),
            .start = 0,
        };
        try t.registerRule(ruleWhitespace);
        try t.registerRule(atxRules.ruleAtxHeader);
        try t.registerRule(inlineRules.ruleInline);
        try t.registerRule(ruleEOF);
        return t;
    }

    pub fn deinit(self: *Lexer) void {
        self.rules.deinit();
        self.tokens.deinit();
    }

    pub fn registerRule(self: *Lexer, rule: token.TokenRule) !void {
        try self.rules.append(rule);
    }

    /// Get the next token from the input.
    pub fn next(self: *Lexer) !?token.Token {
        for (self.rules.items) |rule| {
            if (try rule(self)) |v| {
                return v;
            }
        }
        return null;
    }

    /// Peek at the next token.
    pub fn peekNext(self: *Lexer) !?token.Token {
        var indexBefore = self.index;
        var pNext = try self.next();
        self.index = indexBefore;
        return pNext;
    }

    /// Gets a character at index from the source buffer. Returns null if index exceeds the length of the buffer.
    pub fn getChar(self: *Lexer, index: u32) ?u8 {
        if (index >= self.buffer.len) {
            return null;
        }
        return self.buffer[index];
    }

    pub fn emit(self: *Lexer, tok: token.TokenId, start: u32, end: u32) !?token.Token {
        // log.Debugf("start: {} end: {}\n", .{ start, end });
        var str = self.buffer[start..end];
        var newTok = token.Token{
            .ID = tok,
            .start = start,
            .end = end,
            .string = str,
        };
        log.Debugf("emit: {}\n", .{newTok});
        try self.tokens.append(newTok);
        self.index = end;
        return newTok;
    }

    /// Checks for a single whitespace character. Returns true if char is a space character.
    pub fn isSpace(self: *Lexer, char: u8) bool {
        if (char == '\u{0020}') {
            return true;
        }
        return false;
    }

    /// Checks for all the whitespace characters. Returns true if the char is a whitespace.
    pub fn isWhitespace(self: *Lexer, char: u8) bool {
        // A whitespace character is a space (U+0020), tab (U+0009), newline (U+000A), line tabulation (U+000B), form feed
        // (U+000C), or carriage return (U+000D).
        return switch (char) {
            '\u{0020}', '\u{0009}', '\u{000A}', '\u{000B}', '\u{000C}', '\u{000D}' => true,
            else => false,
        };
    }

    pub fn isPunctuation(self: *Lexer, char: u8) bool {
        // Check for ASCII punctuation characters...
        //
        // FIXME: Check against the unicode punctuation tables... there isn't a Zig library that does this that I have found.
        //
        // A punctuation character is an ASCII punctuation character or anything in the general Unicode categories Pc, Pd,
        // Pe, Pf, Pi, Po, or Ps.
        return switch (char) {
            '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~' => true,
            else => false,
        };
    }

    pub fn isCharacter(self: *Lexer, char: u8) bool {
        // TODO: make this more robust by using unicode character sets
        if (!self.isPunctuation(char) and !self.isWhitespace(char)) {
            return true;
        }
        return false;
    }
};

/// Get all the whitespace characters greedly.
pub fn ruleWhitespace(t: *Lexer) !?token.Token {
    var index: u32 = t.index;
    while (t.getChar(index)) |val| {
        if (t.isWhitespace(val)) {
            index += 1;
        } else {
            break;
        }
    }
    if (index > t.index) {
        return t.emit(.Whitespace, t.index, index);
    }
    // log.Debugf("t.index: {} index: {}\n", .{ t.index, index });
    return null;
}

/// Return EOF at the end of the input
pub fn ruleEOF(t: *Lexer) !?token.Token {
    if (t.index == t.buffer.len) {
        return t.emit(.EOF, t.index, t.index);
    }
    return null;
}

test "lexer: peekNext " {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    // TODO: move this somplace else
    use_rfc3339_date_handler();

    const input = "# foo";
    log.Debugf("input:\n{}\n-- END OF TEST --\n", .{input});

    var t = try Lexer.init(allocator, input);
    if (try t.next()) |tok| {
        assert(tok.ID == token.TokenId.AtxHeader);
    }
    if (try t.peekNext()) |tok| {
        assert(tok.ID == token.TokenId.Whitespace);
    }
    if (try t.next()) |tok| {
        assert(tok.ID == token.TokenId.Whitespace);
    }
}
