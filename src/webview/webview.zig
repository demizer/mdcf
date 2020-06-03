const std = @import("std");

pub usingnamespace @cImport({
    @cInclude("webview.h");
});
