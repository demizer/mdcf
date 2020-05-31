const std = @import("std");
const mem = std.mem;
const State = @import("ast.zig").State;
const Parser = @import("parse.zig").Parser;
const Node = @import("parse.zig").Node;
const Lexer = @import("lexer.zig").Lexer;
const TokenId = @import("token.zig").TokenId;

usingnamespace @import("log.zig");

pub fn StateAtxHeader(p: *Parser) !void {
    p.state = Parser.State.AtxHeader;
    if (try p.lex.peekNext()) |tok| {
        if (tok.ID == TokenId.Whitespace and mem.eql(u8, tok.string, " ")) {
            log.Debug("We have a real atx header boys!");
            var openTok = p.lex.lastToken();
            log.Debugf("bloooooooooooooooooooooooooooooooopy {}\n", .{openTok});
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
            };
            // skip the whitespace after the header opening
            try p.lex.skipNext();
            while (try p.lex.next()) |ntok| {
                if (ntok.ID == TokenId.Whitespace and mem.eql(u8, ntok.string, "\n")) {
                    log.Debug("Found a newline, exiting state");
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
                };
                try p.root.append(newChild);
            }
            p.state = Parser.State.Start;
        }
    }
}
