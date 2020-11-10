const std = @import("std");
const json = std.json;

const Lexer = @import("lexer.zig").Lexer;

const TokenIds = [_][]const u8{
    "Invalid",
    "Whitespace",
    "Text",
    "AtxHeader",
    "EOF",
};

pub const TokenId = enum {
    Invalid,
    Whitespace,
    Text,
    AtxHeader,
    EOF,

    pub fn string(self: TokenId) []const u8 {
        const m = @enumToInt(self);
        if (@enumToInt(TokenId.Invalid) <= m and m <= @enumToInt(TokenId.EOF)) {
            return TokenIds[m];
        }
        unreachable;
    }

    pub fn jsonStringify(
        self: @This(),
        options: json.StringifyOptions,
        out_stream: anytype,
    ) !void {
        try json.stringify(self.string(), options, out_stream);
    }
};

pub const Token = struct {
    ID: TokenId,
    startOffset: u32,
    endOffset: u32,
    string: []const u8,
    lineNumber: u32,
    column: u32,
};

pub const TokenRule = fn (lexer: *Lexer) anyerror!?Token;
