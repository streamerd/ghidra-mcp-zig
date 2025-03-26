const std = @import("std");
const Allocator = std.mem.Allocator;

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

pub const Function = struct {
    name: []const u8,
    address: u64,
    size: u64,
    decompiled: ?[]const u8,
};

pub const Program = struct {
    allocator: Allocator,
    env: ?*anyopaque,

    pub fn init(allocator: Allocator) Program {
        return Program{
            .allocator = allocator,
            .env = null,
        };
    }

    pub fn deinit(self: *Program) void {
        _ = self; // Suppress unused capture warning
    }

    pub fn setJNIEnv(self: *Program, env: *anyopaque) void {
        self.env = env;
    }
};
