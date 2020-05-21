const std = @import("std");

usingnamespace @import("log.zig");

const token = @import("token.zig");
const Lexer = @import("lexer.zig").Lexer;

pub fn ruleInline(l: *Lexer) !?token.Token {
    var index: u32 = l.bufIndex;
    while (l.getChar(index)) |val| {
        if (l.isCharacter(l.buffer[index])) {
            index += 1;
        } else {
            break;
        }
    }
    if (index > l.bufIndex) {
        return l.emit(.Line, l.bufIndex, index);
    }
    return null;
}
