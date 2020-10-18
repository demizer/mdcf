const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;

pub fn ruleAtxHeader(l: *Lexer) !?Token {
    var index: u32 = l.bufIndex;
    while (l.getChar(index)) |val| {
        if (val == '#') {
            index += 1;
        } else {
            break;
        }
    }
    if (index > l.bufIndex) {
        return l.emit(.AtxHeader, l.bufIndex, index);
    }
    return null;
}
