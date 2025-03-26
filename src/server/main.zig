const std = @import("std");
const Allocator = std.mem.Allocator;
const Plugin = @import("plugin").Plugin;
const jni = @import("plugin").jni;
const MCPServer = @import("mcp.zig").MCPServer;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a dummy bridge for testing
    var bridge = jni.MCPBridge.init(undefined, undefined);
    var plugin = Plugin.init(allocator, &bridge);
    defer plugin.deinit();

    try plugin.start();
}
