const std = @import("std");
const mem = std.mem;
const Parser = @import("parse.zig").Parser;
const Node = @import("parse.zig").Node;
const Lexer = @import("lexer.zig").Lexer;
const TokenId = @import("token.zig").TokenId;
const log = @import("log.zig");

// FIXME: should be part of the parser struct, but that would make the parse.zig file massive
// FIXME: https://github.com/ziglang/zig/issues/5132 solves this problem
pub fn stateAtxHeader(p: *Parser) !?Node {
    log.Debug("stateAtxHeader: START");
    defer log.Debug("stateAtxHeader: END");
    if (try p.lex.peekNext()) |tok| {
        if (tok.ID == TokenId.Whitespace and mem.eql(u8, tok.string, " ")) {
            var openTok = if (p.lex.lastToken()) |lt| lt else return null;
            var i: usize = 0;
            var level: usize = 0;
            while (i < openTok.string.len) : ({
                level += 1;
                i += 1;
            }) {}
            var newChild = Node{
                .ID = Node.ID.AtxHeading,
                .Value = null,
                .PositionStart = Node.Position{
                    .Line = openTok.lineNumber,
                    .Column = openTok.column,
                    .Offset = openTok.startOffset,
                },
                .PositionEnd = Node.Position{
                    .Line = openTok.lineNumber,
                    .Column = openTok.column,
                    .Offset = openTok.endOffset,
                },
                .Children = std.ArrayList(Node).init(p.allocator),
                .Level = level,
            };
            // skip the whitespace after the header opening
            try p.lex.skipNext();
            while (try p.lex.next()) |ntok| {
                try p.lex.debugPrintToken("stateAtxHeader: have token", ntok);
                if (ntok.ID == TokenId.EOF or ntok.ID == TokenId.Newline and mem.eql(u8, ntok.string, "\n")) {
                    log.Debug("stateAtxHeader: Found a newline or EOF, exiting state");
                    break;
                }
                var subChild = Node{
                    .ID = Node.ID.Text,
                    .Value = ntok.string,
                    .PositionStart = Node.Position{
                        .Line = ntok.lineNumber,
                        .Column = ntok.column,
                        .Offset = ntok.startOffset,
                    },
                    .PositionEnd = Node.Position{
                        .Line = ntok.lineNumber,
                        .Column = ntok.column,
                        .Offset = ntok.endOffset,
                    },
                    .Children = std.ArrayList(Node).init(p.allocator),
                    .Level = level,
                };
                try newChild.Children.append(subChild);
            }
            newChild.PositionEnd = newChild.Children.items[newChild.Children.items.len - 1].PositionEnd;
            try p.appendNode(newChild);
            return newChild;
        }
    }
    return null;
}
