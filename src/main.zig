const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const math = std.math;
const process = std.process;
const md = @import("md/markdown.zig").Markdown;

const Cmd = enum {
    View,
};

fn translate(allocator: *mem.Allocator, input_files: *std.ArrayList([]const u8)) !void {
    const stdout = &std.io.getStdOut().outStream();
    const cwd = fs.cwd();
    for (input_files.items) |input_file| {
        const source = try cwd.readFileAlloc(allocator, input_file, math.maxInt(usize));
        // try stdout.print("File: {}\nSource:\n````\n{}````\n", .{ input_file, source });
        try md.renderToHtml(
            allocator,
            source,
            stdout,
        );
    }
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const args = try process.argsAlloc(allocator);
    var arg_i: usize = 1;
    var maybe_cmd: ?Cmd = null;

    var input_files = std.ArrayList([]const u8).init(allocator);

    while (arg_i < args.len) : (arg_i += 1) {
        const full_arg = args[arg_i];
        if (mem.startsWith(u8, full_arg, "--")) {
            const arg = full_arg[2..];
            if (mem.eql(u8, arg, "help")) {
                try dumpUsage(std.io.getStdOut());
                return;
            } else {
                std.debug.warn("Invalid parameter: {}\n", .{full_arg});
                dumpStdErrUsageAndExit();
            }
        } else if (maybe_cmd == null) {
            inline for (std.meta.fields(Cmd)) |field| {
                if (mem.eql(u8, full_arg, field.name)) {
                    maybe_cmd = @field(Cmd, field.name);
                    std.debug.warn("Have command: {}\n", .{field.name});
                    break;
                }
                // } else {
                //     std.debug.warn("Invalid command: {}\n", .{full_arg});
                //     dumpStdErrUsageAndExit();
                // }
            } else {
                _ = try input_files.append(full_arg);
            }
        }
    }

    // const cmd = maybe_cmd orelse {
    //     std.debug.warn("Expected a command parameter\n", .{});
    //     dumpStdErrUsageAndExit();
    // };

    // switch (cmd) {
    //     .tokenize => {
    //         return;
    //     },
    //     else => {},
    // }

    try translate(allocator, &input_files);
}

fn dumpStdErrUsageAndExit() noreturn {
    dumpUsage(std.io.getStdErr()) catch {};
    process.exit(1);
}

fn dumpUsage(file: fs.File) !void {
    _ = try file.write(
        \\Usage: mdcf [command] [options] <input>
        \\
        \\If no commands are specified, the html translated markdown is dumped to stdout.
        \\
        \\Commands:
        \\  view                  Show the translated markdown in webview.
        \\
        \\Options:
        \\  --help                dump this help text to stdout
        \\
    );
}
