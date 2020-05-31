const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

pub const TokenId = enum {
    Invalid,
    Whitespace,
    Text,
    AtxHeader,
    EOF,
    // const Self = @This();

    // pub fn jsonStringify(
    //     value: Self,
    //     options: StringifyOptions,
    //     out_stream: var,
    // ) !void {
    //     try out_stream.writeAll("[\"something special\",");
    //     try stringify(42, options, out_stream);
    //     try out_stream.writeByte(']');
    // }
};

pub const Token = struct {
    ID: TokenId,
    startOffset: u32,
    endOffset: u32,
    string: []const u8,
    lineNumber: u32,
    column: u32,

    // const Self = @This();

    // pub fn jsonStringify(
    //     value: Self,
    //     options: StringifyOptions,
    //     out_stream: var,
    // ) !void {
    //     try out_stream.writeAll("[\"something special\",");
    //     try stringify(42, options, out_stream);
    //     try out_stream.writeByte(']');
    // }
};

pub const TokenRule = fn (lexer: *Lexer) anyerror!?Token;
