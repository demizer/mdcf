const std = @import("std");

usingnamespace @import("log.zig");

const token = @import("token.zig");
const Lexer = @import("lexer.zig").Lexer;

pub fn ruleInline(t: *Lexer) !?token.Token {
    var index: u32 = t.index;
    while (t.getChar(index)) |val| {
        if (t.isCharacter(t.buffer[index])) {
            index += 1;
        } else {
            break;
        }
    }
    if (index > t.index) {
        return t.emit(.Line, t.index, index);
    }
    return null;
}
