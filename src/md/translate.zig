const std = @import("std");
const mem = std.mem;
const parser = @import("parse.zig");
const testUtil = @import("test_util.zig");
const log = @import("log.zig");

pub fn markdownToHtml(allocator: *mem.Allocator, parserContext: parser.Parser, outStream: var) !void {
    for (parserContext.root.items) |item| {
        try parser.Node.htmlStringify(
            item,
            parser.Node.StringifyOptions{
                .whitespace = .{
                    .indent = .{ .Space = 4 },
                    .separator = true,
                },
            },
            outStream,
        );
    }
}

test "Test Convert HTML 32" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const input = try testUtil.getTest(
        allocator,
        32,
        testUtil.TestKey.markdown,
    );

    const expect = try testUtil.getTest(
        allocator,
        32,
        testUtil.TestKey.html,
    );

    log.Debugf("test:\n{}\n-- END OF TEST --\n", .{input});

    var p = parser.Parser.init(std.testing.allocator);
    defer p.deinit();
    try p.parse(input);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try markdownToHtml(allocator, p, buf.outStream());

    try testUtil.testHtmlExpect(expect, buf.items, false);
}
