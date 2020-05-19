const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const math = std.math;

const TestError = error{TestNotFound};

pub fn getTest(allocator: *mem.Allocator, number: i32) ![]const u8 {
    const cwd = fs.cwd();
    const source = try cwd.readFileAlloc(allocator, "test/commonmark_spec_0.29.json", math.maxInt(usize));
    var json_parser = std.json.Parser.init(allocator, true);
    defer json_parser.deinit();
    var json_tree = try json_parser.parse(source);
    const stdout = &std.io.getStdOut().outStream();
    for (json_tree.root.Array.items) |value, i| {
        var example_num = value.Object.get("example").?.value;
        if (example_num.Integer == number) {
            return value.Object.get("markdown").?.value.String;
        }
    }
    return TestError.TestNotFound;
}
