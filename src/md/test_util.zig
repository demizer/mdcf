const std = @import("std");
const fs = std.fs;
const fmt = std.fmt;
const mem = std.mem;
const math = std.math;
const json = std.json;
const log = @import("log.zig");
const translate = @import("translate.zig");
const Node = @import("parse.zig").Node;
const ChildProcess = std.ChildProcess;

const TestError = error{
    TestNotFound,
    CouldNotCreateTempDirectory,
    DockerRunFailed,
};

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

pub fn mktmp(allocator: *mem.Allocator) ![]const u8 {
    const cwd = try fs.path.resolve(allocator, &[_][]const u8{"."});
    defer allocator.free(cwd);
    var out = try exec(allocator, cwd, true, &[_][]const u8{ "mktemp", "-d" });
    defer allocator.free(out.stdout);
    defer allocator.free(out.stderr);
    // defer allocator.free(out);
    log.Debugf("mktemp return: {}\n", .{out});
    return allocator.dupe(u8, fmt.trim(out.stdout));
}

pub fn writeFile(absolute_path: []u8, contents: []const u8) !void {
    log.Debugf("file path: {}\n", .{absolute_path});
    const file = try std.fs.createFileAbsolute(
        absolute_path,
        .{},
    );
    defer file.close();
    try file.writeAll(contents);
}

/// testJsonExpect tests parser output against a json test file containing the expected output
/// - expected: The expected json output. Use @embedFile()!
/// - value: The parser root to test.
/// - dumpJson: If true, only the json value of "value" will be dumped to stdout.
pub fn testJsonExpect(allocator: *mem.Allocator, expected: []const u8, value: anytype, dumpJson: bool) !void {
    if (dumpJson) {
        log.Debug("dumped_json: ");
    }

    var temp_dir = try mktmp(allocator);
    defer allocator.free(temp_dir);

    var file = try fs.path.join(allocator, &[_][]const u8{ temp_dir, "expect.json" });
    defer allocator.free(file);
    try writeFile(file, expected);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try json.stringify(value, json.StringifyOptions{
        .whitespace = .{
            .indent = .{ .Space = 4 },
            .separator = true,
        },
    }, buf.outStream());

    var file2 = try fs.path.join(allocator, &[_][]const u8{ temp_dir, "actual.json" });
    defer allocator.free(file2);
    try writeFile(file2, buf.items);

    const cwd = try fs.path.resolve(allocator, &[_][]const u8{"."});
    defer allocator.free(cwd);
    var filemount = try std.mem.concat(allocator, u8, &[_][]const u8{ file, ":", file });
    defer allocator.free(filemount);
    var file2mount = try std.mem.concat(allocator, u8, &[_][]const u8{ file2, ":", file2 });
    defer allocator.free(file2mount);

    // The long way around until there is a better way to compare json in Zig
    var cmd = &[_][]const u8{ "docker", "run", "-t", "-v", filemount, "-v", file2mount, "-w", cwd, "--rm", "bwowk/json-diff", "-C", file2, file };
    try debugPrintExecCommand(allocator, cmd);

    var diff = try exec(allocator, cwd, true, cmd);
    if (diff.term.Exited != 0) {
        log.Errorf("docker run failed: {}\n", .{diff});
        return error.DockerRunFailed;
    }

    if (dumpJson) {
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

fn exec(allocator: *mem.Allocator, cwd: []const u8, expect_0: bool, argv: []const []const u8) !ChildProcess.ExecResult {
    const max_output_size = 100 * 1024;
    const result = ChildProcess.exec(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = cwd,
        .max_output_bytes = max_output_size,
    }) catch |err| {
        std.debug.warn("The following command failed:\n", .{});
        // printCmd(cwd, argv);
        return err;
    };
    // switch (result.term) {
    //     .Exited => |code| {
    //         if ((code != 0) == expect_0) {
    //             std.debug.warn("The following command exited with error code {}:\n", .{code});
    //             // printCmd(cwd, argv);
    //             std.debug.warn("stderr:\n{}\n", .{result.stderr});
    //             return error.CommandFailed;
    //         }
    //     },
    //     else => {
    //         std.debug.warn("The following command terminated unexpectedly:\n", .{});
    //         // printCmd(cwd, argv);
    //         std.debug.warn("stderr:\n{}\n", .{result.stderr});
    //         return error.CommandFailed;
    //     },
    // }
    return result;
}

pub fn debugPrintExecCommand(allocator: *mem.Allocator, arry: [][]const u8) !void {
    var cmd_buf = std.ArrayList(u8).init(allocator);
    defer cmd_buf.deinit();
    for (arry) |a| {
        try cmd_buf.appendSlice(a);
        try cmd_buf.append(' ');
    }
    log.Debugf("exec cmd: {}\n", .{cmd_buf.items});
}
