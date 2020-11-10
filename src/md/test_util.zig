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

const ValidationOutStream = struct {
    const Self = @This();

    expected_remaining: []const u8,

    DumpBuffer: ?*std.ArrayList(u8) = null,
    pub const OutStream = std.io.OutStream(*Self, Error, write);
    pub const Error = error{
        DumpBufferWriteError,
        DifferentData,
    };

    fn init(exp: []const u8, dumpBuffer: ?*std.ArrayList(u8)) Self {
        return .{
            .DumpBuffer = dumpBuffer,
            .expected_remaining = exp,
        };
    }

    pub fn outStream(self: *Self) OutStream {
        return .{ .context = self };
    }

    fn write(self: *Self, bytes: []const u8) Error!usize {
        if (self.DumpBuffer) |buf| {
            buf.writer().writeAll(bytes) catch |err| {
                return error.DumpBufferWriteError;
            };
        }
        if (self.expected_remaining.len < bytes.len) {
            return error.DifferentData;
        }
        if (!mem.eql(u8, self.expected_remaining[0..bytes.len], bytes)) {
            return error.DifferentData;
        }
        self.expected_remaining = self.expected_remaining[bytes.len..];
        return bytes.len;
    }
};

pub fn mktmp(allocator: *mem.Allocator) ![]const u8 {
    const cwd = try fs.path.resolve(allocator, &[_][]const u8{"."});
    defer allocator.free(cwd);
    var out = try exec(allocator, cwd, true, &[_][]const u8{ "mktemp", "-d" });
    defer allocator.free(out.stdout);
    defer allocator.free(out.stderr);
    // defer allocator.free(out);
    log.Debugf("mktemp return: {}\n", .{out});
    return allocator.dupe(u8, std.mem.trim(u8, out.stdout, &std.ascii.spaces));
}

pub fn writeFile(allocator: *mem.Allocator, absoluteDirectory: []const u8, fileName: []const u8, contents: []const u8) ![]const u8 {
    var filePath = try fs.path.join(allocator, &[_][]const u8{ absoluteDirectory, fileName });
    log.Debugf("writeFile path: {}\n", .{filePath});
    const file = try std.fs.createFileAbsolute(filePath, .{});
    defer file.close();
    try file.writeAll(contents);
    return filePath;
}

pub fn writeJson(allocator: *mem.Allocator, tempDir: []const u8, name: []const u8, value: anytype) ![]const u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    try json.stringify(value, json.StringifyOptions{
        .whitespace = .{
            .indent = .{ .Space = 4 },
            .separator = true,
        },
    }, buf.outStream());
    return writeFile(allocator, tempDir, name, buf.items);
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

pub fn dockerRunJsonDiff(allocator: *mem.Allocator, actualJson: []const u8, expectJson: []const u8) !void {
    const cwd = try fs.path.resolve(allocator, &[_][]const u8{"."});
    defer allocator.free(cwd);
    var filemount = try std.mem.concat(allocator, u8, &[_][]const u8{ actualJson, ":", actualJson });
    defer allocator.free(filemount);
    var file2mount = try std.mem.concat(allocator, u8, &[_][]const u8{ expectJson, ":", expectJson });
    defer allocator.free(file2mount);

    // The long way around until there is a better way to compare json in Zig
    var cmd = &[_][]const u8{ "docker", "run", "-t", "-v", filemount, "-v", file2mount, "-w", cwd, "--rm", "bwowk/json-diff", "-C", expectJson, actualJson };
    try debugPrintExecCommand(allocator, cmd);

    var diff = try exec(allocator, cwd, true, cmd);
    if (diff.term.Exited != 0) {
        log.Errorf("docker run failed:\n{}\n", .{diff.stdout});
        return error.DockerRunFailed;
    }
}

/// compareJsonExpect tests parser output against a json test file containing the expected output
/// - expected: The expected json output. Use @embedFile()!
/// - value: The parser root to test.
/// - dumpJson: If true, only the json value of "value" will be dumped to stdout.
pub fn compareJsonExpect(allocator: *mem.Allocator, expected: []const u8, value: anytype, dumpJson: bool) !void {
    // check with zig stream validator
    var dumpBuf: ?*std.ArrayList(u8) = null;
    if (dumpJson) {
        dumpBuf = &std.ArrayList(u8).init(allocator);
        // defer dumpBuf.deinit();
    }
    var vos = ValidationOutStream.init(expected, dumpBuf);
    json.stringify(value, json.StringifyOptions{
        .whitespace = .{
            .indent = .{ .Space = 4 },
            .separator = true,
        },
    }, vos.outStream()) catch |err| {
        log.Debug("ValidationOutStream failed! Running json-diff...");
        // human readable diff
        var tempDir = try mktmp(allocator);
        defer allocator.free(tempDir);
        var expectJson = try writeFile(allocator, tempDir, "expect.json", expected);
        defer allocator.free(expectJson);
        var actualJson = try writeJson(allocator, tempDir, "actual.json", value);
        defer allocator.free(actualJson);
        try dockerRunJsonDiff(allocator, actualJson, expectJson);
    };
    // _ = try vos.outStream().write("\n");
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
