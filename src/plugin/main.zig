const std = @import("std");
const Plugin = @import("plugin.zig").Plugin;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create plugin instance
    var plugin = Plugin.init(allocator, null);
    defer plugin.deinit();

    // TODO: Initialize JNI bridge
    // TODO: Register native methods
    // TODO: Start plugin
}
