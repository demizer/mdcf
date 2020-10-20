const std = @import("std");
const mem = std.mem;
const log = @import("log.zig");
const testUtil = @import("test_util.zig");
const Parser = @import("parse.zig").Parser;
const Token = @import("token.zig").Token;

fn testAllocator() *mem.Allocator {
    // var test_fixed_buffer_allocator_memory: [800000 * @sizeOf(u64)]u8 = undefined;
    // var fixed_buffer_allocator = std.heap.ThreadSafeFixedBufferAllocator.init(test_fixed_buffer_allocator_memory[0..]);
    // var leak_allocator = std.testing.allocator(&fixed_buffer_allocator.allocator);
    // return &leak_allocator.allocator;
    return std.testing.allocator;
}

fn testDumpTest(input: []const u8) void {
    log.config(log.logger.Level.Debug, true);
    std.debug.warn("{}", .{"\n"});
    log.Debugf("test:\n{}-- END OF TEST --\n", .{input});
}

test "Parser Test 1" {
    var allocator = testAllocator();
    const testNumber: u8 = 1;
    const input = try testUtil.getTest(allocator, 1, testUtil.TestKey.markdown);
    testDumpTest(input);

    var p = Parser.init(allocator);
    defer p.deinit();

    // Used https://codebeautify.org/xmltojson to convert ast from spec to json
    const expectJson = @embedFile("../../test/expect/test1.json");
    const expectHtml = try testUtil.getTest(allocator, 1, testUtil.TestKey.html);

    var out = p.parse(input);

    // FIXME: use jsondiff.com to dump better failure output
    try testUtil.testJsonExpect(expectJson, p.root.items, false);
    try testUtil.testHtmlExpect(allocator, expectHtml, &p.root, false);
}

test "Parser Test 2" {
    var allocator = testAllocator();
    const testNumber: u8 = 2;
    const input = try testUtil.getTest(allocator, testNumber, testUtil.TestKey.markdown);
    testDumpTest(input);

    var p = Parser.init(allocator);
    defer p.deinit();

    // Used https://codebeautify.org/xmltojson to convert ast from spec to json
    const expectJson = @embedFile("../../test/expect/test2.json");
    const expectHtml = try testUtil.getTest(allocator, testNumber, testUtil.TestKey.html);

    var out = p.parse(input);

    // FIXME: use jsondiff.com to dump better failure output
    try testUtil.testJsonExpect(expectJson, p.root.items, false);
    try testUtil.testHtmlExpect(allocator, expectHtml, &p.root, false);
}

test "Parser Test 3" {
    var allocator = std.testing.allocator;
    const testNumber: u8 = 3;
    const input = try testUtil.getTest(allocator, testNumber, testUtil.TestKey.markdown);
    testDumpTest(input);

    var p = Parser.init(allocator);
    defer p.deinit();

    // Used https://codebeautify.org/xmltojson to convert ast from spec to json
    const expectJson = @embedFile("../../test/expect/test3.json");
    const expectHtml = try testUtil.getTest(allocator, testNumber, testUtil.TestKey.html);

    var out = p.parse(input);

    // FIXME: use jsondiff.com to dump better failure output
    try testUtil.testJsonExpect(expectJson, p.root.items, true);
    // try testUtil.testHtmlExpect(allocator, expectHtml, &p.root, false);
}

test "Parser Test 32" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const input = try testUtil.getTest(allocator, 32, testUtil.TestKey.markdown);

    log.Debugf("test:\n{}\n-- END OF TEST --\n", .{input});

    var p = Parser.init(std.testing.allocator);
    defer p.deinit();

    // Used https://codebeautify.org/xmltojson to convert ast from spec to json
    const expect = @embedFile("../../test/expect/test32.json");

    var out = p.parse(input);

    // FIXME: Would be much easier to debug if we used real json diff...
    //        Run jsondiff in a container: https://github.com/zgrossbart/jdd or... use a zig json diff library.
    try testUtil.testJsonExpect(expect, p.root.items, false);
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
