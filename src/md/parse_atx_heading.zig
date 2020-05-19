const std = @import("std");
const State = @import("ast.zig").State;
const Parser = @import("parser.zig").Parser;
const Lexer = @import("lexer.zig").Lexer;
const TokenId = @import("token.zig").TokenId;

usingnamespace @import("log.zig");

pub fn AtxHeaderTrans(p: *Parser) !?AstNode {
    var nt = p.PeekNext();

    if (try p.peekNext()) |tok| {
        if (nt.ID == TokenId.AtxHeaderOpen) {
            p.State = State.AtxHeader;
            log.Debug("Have state AtxHeader");
        }
    }
}
