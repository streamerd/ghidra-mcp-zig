const std = @import("std");
const Allocator = std.mem.Allocator;
pub const jni = @import("jni/bridge.zig");
const types = @import("types.zig");

pub const PluginError = error{
    InvalidProgram,
    AnalysisFailed,
    DecompilationFailed,
    RenameFailed,
    InvalidAddress,
    InvalidFunction,
    InvalidData,
};

pub const Program = types.Program;
pub const Function = types.Function;

pub const Data = struct {
    name: []const u8,
    address: u64,
    size: u64,
    type: []const u8,
};

pub const Import = struct {
    name: []const u8,
    address: u64,
    library: []const u8,
};

pub const Export = struct {
    name: []const u8,
    address: u64,
    type: []const u8,
};

pub const Plugin = struct {
    allocator: Allocator,
    bridge: *jni.MCPBridge,

    pub fn init(allocator: Allocator, bridge: *jni.MCPBridge) Plugin {
        return .{
            .allocator = allocator,
            .bridge = bridge,
        };
    }

    pub fn deinit(self: *Plugin) void {
        _ = self;
    }

    pub fn start(self: *Plugin) !void {
        _ = self;
    }
};

pub fn init() void {
    // Plugin initialization
}

pub fn deinit() void {
    // Plugin cleanup
}
