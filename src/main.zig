const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const math = std.math;
const process = std.process;
const md = @import("md/markdown.zig").Markdown;
const log = @import("md/log.zig");
const webview = @import("webview/webview.zig");

var DEBUG = false;
var LOG_LEVEL = log.logger.Level.Error;
var LOG_DATESTAMP = true;

const Cmd = enum {
    view,
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

    log.config(LOG_LEVEL, LOG_DATESTAMP);

    while (arg_i < args.len) : (arg_i += 1) {
        const full_arg = args[arg_i];
        if (mem.startsWith(u8, full_arg, "--")) {
            const arg = full_arg[2..];
            if (mem.eql(u8, arg, "help")) {
                try dumpUsage(std.io.getStdOut());
                return;
            } else if (mem.eql(u8, arg, "debug")) {
                DEBUG = true;
                LOG_LEVEL = log.logger.Level.Debug;
                log.config(LOG_LEVEL, LOG_DATESTAMP);
            } else {
                log.Errorf("Invalid parameter: {}\n", .{full_arg});
                dumpStdErrUsageAndExit();
            }
        } else if (mem.startsWith(u8, full_arg, "-")) {
            const arg = full_arg[1..];
            if (mem.eql(u8, arg, "h")) {
                try dumpUsage(std.io.getStdOut());
                return;
            }
        } else {
            inline for (std.meta.fields(Cmd)) |field| {
                log.Debugf("full_arg: {} field: {}\n", .{ full_arg, field });
                if (mem.eql(u8, full_arg, field.name)) {
                    maybe_cmd = @field(Cmd, field.name);
                    log.Infof("Have command: {}\n", .{field.name});
                    break;
                    // } else {
                    //     std.debug.warn("Invalid command: {}\n", .{full_arg});
                    //     dumpStdErrUsageAndExit();
                    // }
                } else {
                    _ = try input_files.append(full_arg);
                }
            }
        }
    }

    if (args.len <= 1) {
        log.Error("No arguments given!\n");
        dumpStdErrUsageAndExit();
    }

    if (input_files.items.len == 0) {
        log.Error("No input files were given!\n");
        dumpStdErrUsageAndExit();
    }

    try translate(allocator, &input_files);

    if (maybe_cmd) |cmd| {
        switch (cmd) {
            .view => {
                log.Error("Boo");
                var handle = webview.webview_create(1, null);
                webview.webview_set_title(handle, "Foo");
                webview.webview_run(handle);
                // return;
            },
            else => {},
        }
    }
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
        \\  -h, --help            Dump this help text to stdout.
        \\  --debug               Show debug output.
        \\
    );
}
