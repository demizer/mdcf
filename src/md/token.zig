const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

pub const TokenId = enum {
    Invalid,
    Whitespace,
    Line,
    LineEnding,
    AtxHeader,
    EOF,
};

pub const Token = struct {
    ID: TokenId,
    start: u32,
    end: u32,
    string: []const u8,
};

pub const TokenRule = fn (lexer: *Lexer) anyerror!?Token;
