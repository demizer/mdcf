const std = @import("std");
const mem = std.mem;
const log = @import("log.zig");
const testUtil = @import("test_util.zig");
const State = @import("ast.zig").State;
const Parser = @import("parse.zig").Parser;
const Node = @import("parse.zig").Node;
const Lexer = @import("lexer.zig").Lexer;
const TokenId = @import("token.zig").TokenId;

pub fn stateCodeBlock(p: *Parser) !void {
    if (try p.lex.peekNext()) |tok| {
        var openTok = p.lex.lastToken();
        if (openTok.ID == TokenId.Whitespace and mem.eql(u8, openTok.string, "\t") and tok.ID == TokenId.Text) {
            p.state = Parser.State.CodeBlock;
            var newChild = Node{
                .ID = Node.ID.CodeBlock,
                .Value = "\t",
                .PositionStart = Node.Position{
                    .Line = openTok.lineNumber,
                    .Column = openTok.column,
                    .Offset = openTok.startOffset,
                },
                .PositionEnd = undefined,
                .Children = std.ArrayList(Node).init(p.allocator),
                .Level = 0,
            };

            var buf = try std.ArrayListSentineled(u8, 0).init(p.allocator, tok.string);
            defer buf.deinit();

            // skip the whitespace after the codeblock opening
            try p.lex.skipNext();
            var startPos = Node.Position{
                .Line = tok.lineNumber,
                .Column = tok.column,
                .Offset = tok.startOffset,
            };

            while (try p.lex.next()) |ntok| {
                if (ntok.ID == TokenId.Whitespace and mem.eql(u8, ntok.string, "\n")) {
                    // FIXME: loop until de-indent
                    log.Debug("Found a newline, exiting state");
                    try buf.appendSlice(ntok.string);
                    try newChild.Children.append(Node{
                        .ID = Node.ID.Text,
                        .Value = buf.toOwnedSlice(),
                        .PositionStart = startPos,
                        .PositionEnd = Node.Position{
                            .Line = ntok.lineNumber,
                            .Column = ntok.column,
                            .Offset = ntok.endOffset,
                        },
                        .Children = std.ArrayList(Node).init(p.allocator),
                        .Level = 0,
                    });
                    break;
                }
                try buf.appendSlice(ntok.string);
            }

            newChild.PositionEnd = newChild.Children.items[newChild.Children.items.len - 1].PositionEnd;
            try p.root.append(newChild);
            p.state = Parser.State.Start;
        }
    }
}

test "Parser Test 1" {
    var test_fixed_buffer_allocator_memory: [800000 * @sizeOf(u64)]u8 = undefined;
    var fixed_buffer_allocator = std.heap.ThreadSafeFixedBufferAllocator.init(test_fixed_buffer_allocator_memory[0..]);
    var leak_allocator = std.testing.LeakCountAllocator.init(&fixed_buffer_allocator.allocator);
    var allocator = &leak_allocator.allocator;

    const input = try testUtil.getTest(allocator, 1, testUtil.TestKey.markdown);

    // log.config(log.logger.Level.Debug, true);
    std.debug.warn("{}", .{"\n"});
    log.Debugf("test:\n{}-- END OF TEST --\n", .{input});

    var p = Parser.init(allocator);
    defer p.deinit();

    // Used https://codebeautify.org/xmltojson to convert ast from spec to json
    const expectJson = @embedFile("../../test/expect/test1.json");
    const expectHtml = try testUtil.getTest(allocator, 1, testUtil.TestKey.html);

    var out = p.parse(input);

    // FIXME: Would be much easier to debug if we used real json diff...
    //        Run jsondiff in a container: https://github.com/zgrossbart/jdd or... use a zig json diff library.
    try testUtil.testJsonExpect(expectJson, p.root.items, false);
    try testUtil.testHtmlExpect(allocator, expectHtml, &p.root, false);
}
