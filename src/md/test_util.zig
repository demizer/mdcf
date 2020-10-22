const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const math = std.math;
const json = std.json;
const log = @import("log.zig");
const translate = @import("translate.zig");
const Node = @import("parse.zig").Node;

const TestError = error{TestNotFound};

pub const TestKey = enum {
    markdown,
    html,
};

/// Caller owns returned memory
pub fn getTest(allocator: *mem.Allocator, number: i32, key: TestKey) ![]const u8 {
    const cwd = fs.cwd();
    const source = try cwd.readFileAlloc(allocator, "test/commonmark_spec_0.29.json", math.maxInt(usize));
    defer allocator.free(source);
    var json_parser = std.json.Parser.init(allocator, true);
    defer json_parser.deinit();
    var json_tree = try json_parser.parse(source);
    defer json_tree.deinit();
    const stdout = &std.io.getStdOut().outStream();
    for (json_tree.root.Array.items) |value, i| {
        var example_num = value.Object.get("example").?.Integer;
        if (example_num == number) {
            return try allocator.dupe(u8, value.Object.get(@tagName(key)).?.String);
        }
    }
    return TestError.TestNotFound;
}

const ValidationOutStream = struct {
    const Self = @This();
    pub const OutStream = std.io.OutStream(*Self, Error, write);
    pub const Error = error{
        TooMuchData,
        DifferentData,
    };

    expected_remaining: []const u8,
    dump: bool,

    fn init(exp: []const u8, dumpJsonInner: bool) Self {
        return .{ .expected_remaining = exp, .dump = dumpJsonInner };
    }

    pub fn outStream(self: *Self) OutStream {
        return .{ .context = self };
    }

    fn write(self: *Self, bytes: []const u8) Error!usize {
        if (self.dump) {
            std.debug.warn("{}", .{bytes});
        } else {
            if (self.expected_remaining.len < bytes.len) {
                std.debug.warn(
                    \\====== expected this output: =========
                    \\{}
                    \\======== instead found this: =========
                    \\{}
                    \\======================================
                , .{
                    self.expected_remaining,
                    bytes,
                });
                return error.TooMuchData;
            }
            if (!mem.eql(u8, self.expected_remaining[0..bytes.len], bytes)) {
                std.debug.warn(
                    \\====== expected this output: =========
                    \\{}
                    \\======== instead found this: =========
                    \\{}
                    \\======================================
                , .{
                    self.expected_remaining[0..bytes.len],
                    bytes,
                });
                return error.DifferentData;
            }
            self.expected_remaining = self.expected_remaining[bytes.len..];
        }
        return bytes.len;
    }
};

/// testJsonExpect tests parser output against a json test file containing the expected output
/// - expected: The expected json output. Use @embedFile()!
/// - value: The parser root to test.
/// - dumpJson: If true, only the json value of "value" will be dumped to stdout.
pub fn testJsonExpect(expected: []const u8, value: anytype, dumpJson: bool) !void {
    if (dumpJson) {
        log.Debug("dumped_json: ");
    }
    var vos = ValidationOutStream.init(expected, dumpJson);
    try json.stringify(value, json.StringifyOptions{
        .whitespace = .{
            .indent = .{ .Space = 4 },
            .separator = true,
        },
    }, vos.outStream());
    _ = try vos.outStream().write("\n");
    if (!dumpJson) {
        if (vos.expected_remaining.len > 0) return error.NotEnoughData;
    } else {
        return error.DumpJsonEnabled;
    }
}

/// testHtml tests parser output against a json test file containing the expected output
/// - expected: The expected html output. Use @embedFile()!
/// - value: The translated parser output.
/// - dumpHtml: If true, only the json value of "value" will be dumped to stdout.
pub fn testHtmlExpect(allocator: *std.mem.Allocator, expected: []const u8, value: *std.ArrayList(Node), dumpHtml: bool) !void {
    if (dumpHtml) {
        log.Debugf("expect: {}got: ", .{expected});
    }
    var vos = ValidationOutStream.init(expected, dumpHtml);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try translate.markdownToHtml(value, buf.outStream());

    _ = try vos.outStream().write(buf.items);
    // _ = try vos.outStream().write("\n");
    if (!dumpHtml) {
        if (vos.expected_remaining.len > 0) return error.NotEnoughData;
    } else {
        return error.DumpHtmlEnabled;
    }
}
