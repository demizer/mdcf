const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

pub const TokenId = enum {
    Invalid,
    Whitespace,
    Text,
    AtxHeader,
    EOF,
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
